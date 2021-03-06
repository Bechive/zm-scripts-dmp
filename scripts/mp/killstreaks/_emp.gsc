#using scripts\codescripts\struct;
#using scripts\mp\_util;
#using scripts\mp\gametypes\_hostmigration;
#using scripts\mp\killstreaks\_airsupport;
#using scripts\mp\killstreaks\_emp;
#using scripts\mp\killstreaks\_killstreakrules;
#using scripts\mp\killstreaks\_killstreak_bundles;
#using scripts\mp\killstreaks\_killstreak_hacking;
#using scripts\mp\killstreaks\_killstreaks;
#using scripts\mp\killstreaks\_placeables;
#using scripts\mp\teams\_teams;
#using scripts\mp\teams\_teams;
#using scripts\shared\callbacks_shared;
#using scripts\shared\challenges_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\hostmigration_shared;
#using scripts\shared\killstreaks_shared;
#using scripts\shared\killstreaks_shared;
#using scripts\shared\popups_shared;
#using scripts\shared\turret_shared;
#using scripts\shared\util_shared;
#using scripts\shared\vehicle_shared;
#using scripts\shared\weapons\_weaponobjects;
#using scripts\shared\scoreevents_shared;

#insert scripts\mp\_hacker_tool.gsh;
#insert scripts\mp\killstreaks\_killstreaks.gsh;
#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using_animtree ( "mp_emp_power_core" );

#precache( "string", "KILLSTREAK_EARNED_EMP" );
#precache( "string", "KILLSTREAK_EMP_NOT_AVAILABLE" );
#precache( "string", "KILLSTREAK_EMP_INBOUND" );
#precache( "string", "KILLSTREAK_EMP_HACKED" );
#precache( "string", "KILLSTREAK_DESTROYED_EMP" );
#precache( "triggerstring", "KILLSTREAK_EMP_PLACE_TURRET_HINT" );
#precache( "triggerstring", "KILLSTREAK_EMP_INVALID_TURRET_LOCATION" );
#precache( "triggerstring", "KILLSTREAK_EMP_TURRET_PICKUP" );
#precache( "string", "mpl_killstreak_emp_activate" );

#precache( "fx", "killstreaks/fx_emp_exp_death" );

#define EMP_NAME "emp"
#define EMP_VEHICLE_NAME "emp_turret"

#namespace emp;

function init()
{
	bundle = struct::get_script_bundle( "killstreak", "killstreak_emp" );
	level.empKillstreakBundle = bundle;
	
	level.ActivePlayerEMPs = [];
	level.ActiveEMPs = [];
	foreach( team in level.teams )
	{
		level.ActiveEMPs[ team ] = false;
	}

	level.enemyEMPActiveFunc = &EnemyEMPActive;
	
	level thread EMPTracker();
	
	killstreaks::register( EMP_NAME, EMP_NAME, "killstreak_emp", "emp_used", &ActivateEMP );
	killstreaks::register_strings( EMP_NAME, &"KILLSTREAK_EARNED_EMP", &"KILLSTREAK_EMP_NOT_AVAILABLE", &"KILLSTREAK_EMP_INBOUND", undefined, &"KILLSTREAK_EMP_HACKED", false );
	killstreaks::register_dialog( EMP_NAME, "mpl_killstreak_emp_activate", "empDialogBundle", undefined, "friendlyEmp", "enemyEmp", "enemyEmpMultiple", "friendlyEmpHacked", "enemyEmpHacked", "requestEmp", "threatEmp" );

	clientfield::register( "scriptmover", "emp_turret_init", VERSION_SHIP, 1, "int" ); // re-export model in close position to save this clientfield
	clientfield::register( "vehicle", "emp_turret_deploy", VERSION_SHIP, 1, "int" );
		
	spinAnim = %o_turret_emp_core_spin;
	deployAnim = %o_turret_emp_core_deploy;
		
	callback::on_spawned( &OnPlayerSpawned );
	callback::on_connect( &OnPlayerConnect );
	vehicle::add_main_callback( EMP_VEHICLE_NAME, &InitTurretVehicle );
}

function InitTurretVehicle()
{
	turretVehicle = self;
	
	turretVehicle killstreaks::setup_health( EMP_NAME );
	turretVehicle.damageTaken = 0;
	turretVehicle.health = turretVehicle.maxhealth;
	
	turretVehicle clientfield::set( "enemyvehicle", ENEMY_VEHICLE_ACTIVE );
	turretVehicle.soundmod = "drone_land"; // TODO: update this to the correct value

	turretVehicle.overrideVehicleDamage = &OnTurretDamage;
	turretVehicle.overrideVehicleDeath = &OnTurretDeath;

	Target_Set( turretVehicle, ( 0, 0, 36 ) );
}

function OnPlayerSpawned()
{
	self endon( "disconnect" );
	
	self UpdateEMP();
}

function OnPlayerConnect()
{
	self.entNum = self getEntityNumber();
	level.ActivePlayerEMPs[ self.entNum ] = false;
}

function ActivateEMP()
{
	player = self;
	
	killstreakId = player killstreakrules::killstreakStart( EMP_NAME, player.team, false, false );
	if( killstreakId == INVALID_KILLSTREAK_ID )
	{
		return false;
	}
	
	bundle = level.empKillstreakBundle;

	empBase = player placeables::SpawnPlaceable( EMP_NAME, killstreakId, &OnPlaceEMP, &OnCancelPlacement, undefined, &OnShutdown, undefined, undefined,
	                                           	 EMP_MODEL, EMP_VALID_PLACEMENT_MODEL, EMP_INVALID_PLACEMENT_MODEL, true, "", undefined, undefined, 0,
												 bundle.ksPlaceableHint, bundle.ksPlaceableInvalidLocationHint );

	empBase thread util::ghost_wait_show_to_player( player );
	empBase.otherModel thread util::ghost_wait_show_to_others( player );
	empBase clientfield::set( "emp_turret_init", 1 );
	empBase.otherModel clientfield::set( "emp_turret_init", 1 );

	event = empBase util::waittill_any_return( "placed", "cancelled", "death" );
	if( event != "placed" )
	{
		return false;
	}
	
	return true;
}

function OnPlaceEMP( emp )
{
	player = self;
	assert( IsPlayer( player ) );
	assert( !isdefined( emp.vehicle ) );

	emp.vehicle = SpawnVehicle( EMP_VEHICLE_NAME, emp.origin, emp.angles );
	emp.vehicle thread util::ghost_wait_show( 0.05 );

	emp.vehicle.killstreakType = emp.killstreakType; // need to do this for enable_hacking

	emp.vehicle.owner = player;
	emp.vehicle SetOwner( player );
	emp.vehicle.ownerEntNum = player.entNum;
	emp.vehicle.parentStruct = emp;
	
	player.EMPTime = GetTime();
	player killstreaks::play_killstreak_start_dialog( EMP_NAME, player.pers["team"], emp.killstreakId );
	player AddWeaponStat( GetWeapon( EMP_NAME ), "used", 1 );
	level thread popups::DisplayKillstreakTeamMessageToAll( EMP_NAME, player );
	emp.vehicle killstreaks::configure_team( EMP_NAME, emp.killstreakId, player );
	emp.vehicle killstreak_hacking::enable_hacking( EMP_NAME, &HackedCallbackPre, &HackedCallbackPost );
	emp thread killstreaks::WaitForTimeout( EMP_NAME, EMP_DURATION, &on_timeout, "death" );
	if ( IsSentient( emp.vehicle ) == false )
		emp.vehicle MakeSentient(); // so other sentients will consider this as a potential enemy

	emp.vehicle vehicle::disconnect_paths( 0, false );

	// perform deploy on separate thread because of the wait delays
	// always complete OnPlace() in same frame for killstreak accounting; otherwise exploits can happen
	player thread DeployEmpTurret( emp );
}

function DeployEmpTurret( emp )
{
	player = self;
	
	player endon( "disconnect" );
	player endon( "joined_team" );
	player endon( "joined_spectators" );

	emp endon( "death" );

	// deploy emp
	emp.vehicle UseAnimTree( #animtree );
	emp.vehicle SetAnim( %o_turret_emp_core_deploy, 1.0 );
	length = GetAnimLength( %o_turret_emp_core_deploy );
	emp.vehicle clientfield::set( "emp_turret_deploy", 1 );
	wait length * 0.75;

	// fire emp pulse
	emp.vehicle thread PlayEMPFx();
	emp.vehicle playsound( "mpl_emp_turret_activate" );
	emp.vehicle SetAnim( %o_turret_emp_core_spin, 1.0 );

	// Jam Enemies and destroy other scorestreaks!
	player thread EMP_JamEnemies( emp, false );
	
	wait length * 0.25;
	emp.vehicle ClearAnim( %o_turret_emp_core_deploy, 0 ); // stop deploy anim
}

function HackedCallbackPre( hacker )
{
	emp_vehicle = self;
	emp_vehicle clientfield::set( "enemyvehicle", ENEMY_VEHICLE_HACKED );
	emp_vehicle.parentStruct killstreaks::configure_team( EMP_NAME, emp_vehicle.parentStruct.killstreakId, hacker, undefined, undefined, undefined, true );
}

function HackedCallbackPost( hacker )
{
	emp_vehicle = self;
	hacker thread EMP_JamEnemies( emp_vehicle.parentStruct, true );
}

function DoneEMPFx( fxTagOrigin )
{
	PlayFx( "killstreaks/fx_emp_exp_death", fxTagOrigin );
	playsoundatposition( "mpl_emp_turret_deactivate", fxTagOrigin );
}

function PlayEMPFx()
{
	emp_vehicle = self;
	emp_vehicle playloopsound( "mpl_emp_turret_loop_close" );
		
	WAIT_SERVER_FRAME; // workaround for a bug where the fx would not play on subsequent deployment of power cores
}

function on_timeout()
{
	emp = self;
	
	if ( isdefined( emp.vehicle ) )
	{
		fxTagOrigin = emp.vehicle GetTagorigin( EMP_FX_TAG );
		DoneEMPFx( fxTagOrigin );
	}
	ShutdownEMP( emp );
}

function OnCancelPlacement( emp )
{
	StopEMP( emp.team, emp.ownerEntNum, emp.originalTeam, emp.killstreakId );
}

function OnTurretDamage( eInflictor, attacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, vDamageOrigin, psOffsetTime, damageFromUnderneath, modelIndex, partName, vSurfaceNormal )
{
	empDamage = 0; // emp power core is not affected by emp damage

	iDamage = self killstreaks::OnDamagePerWeapon( EMP_NAME, attacker, iDamage, iDFlags, sMeansOfDeath, weapon, self.maxhealth, undefined, self.maxhealth*0.4, undefined, empDamage, undefined, true, 1.0 );
	self.damageTaken += iDamage;
	
	// turret death
	if ( self.damageTaken > self.maxHealth && !isdefined( self.will_die ) )
	{
		self.will_die = true;
		self thread OnDeathAfterFrameEnd( attacker, weapon );
	}

	return iDamage;
}

function OnTurretDeath( inflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime )
{
	// currently, OnTurretDeath is not getting called, so we call OnDeath directly from OnTurretDamage
	self OnDeath( attacker, weapon );
}

function OnDeathAfterFrameEnd( attacker, weapon )
{
	waittillframeend;

	if ( isdefined( self ) )
	{
		self OnDeath( attacker, weapon );
	}
}

function OnDeath( attacker, weapon )
{
	emp_vehicle = self;
	
	fxTagOrigin = self GetTagorigin( EMP_FX_TAG );
	DoneEMPFx( fxTagOrigin );
	if ( isdefined( attacker ) && IsPlayer( attacker ) && ( !isdefined( emp_vehicle.owner ) ||  emp_vehicle.owner util::IsEnemyPlayer( attacker ) ) )
	{
		attacker challenges::destroyScoreStreak( weapon, false, true, false );
		attacker challenges::destroyNonAirScoreStreak_PostStatsLock( weapon );
		attacker AddPlayerStat( "destroy_turret", 1 );
		attacker AddWeaponStat( weapon, "destroy_turret", 1 );
		scoreevents::processScoreEvent( "destroyed_emp", attacker, emp_vehicle.owner, weapon );
		LUINotifyEvent( &"player_callout", 2, &"KILLSTREAK_DESTROYED_EMP", attacker.entnum );
	}

	if ( isdefined( attacker ) && isdefined( emp_vehicle.owner ) && ( attacker != emp_vehicle.owner ) )
		emp_vehicle killstreaks::play_destroyed_dialog_on_owner( EMP_NAME, emp_vehicle.parentStruct.killstreakId );
	
	ShutdownEMP( emp_vehicle.parentStruct );
}

function OnShutdown( emp )
{
	ShutdownEMP( emp );
}

function ShutdownEMP( emp )
{
	if (!isdefined( emp ) )
		return;
	
	if ( isdefined( emp.already_shutdown ) )
		return;
	
	emp.already_shutdown = true;

	if ( isdefined( emp.vehicle ) )
		emp.vehicle clientfield::set( "emp_turret_deploy", 0 );

	StopEMP( emp.team, emp.OwnerEntNum, emp.originalTeam, emp.killstreakId );
	
	if ( isdefined( emp.otherModel ) )
	{
		emp.otherModel delete();
	}
	
	if ( isdefined( emp.vehicle ) )
	{
		emp.vehicle delete();
	}
	
	emp delete();
}

function StopEMP( currentTeam, currentOwnerEntNum, originalTeam, killstreakID ) 
{
	StopEMPEffect( currentTeam, currentOwnerEntNum );
	StopEMPRule( originalTeam, killstreakID );
}
	
function StopEMPEffect( team, ownerEntNum ) 
{
	level.ActiveEMPs[ team ] = false;
	level.ActivePlayerEMPs[ ownerEntNum ] = false;
	level notify ( "emp_updated" );
}
	
function StopEMPRule( killstreakOriginalTeam, killstreakId )
{	
	killstreakrules::killstreakStop( EMP_NAME, killstreakOriginalTeam, killstreakId );
}

function HasActiveEMP()
{
	return ( level.ActivePlayerEMPs[ self.entNum ] );
}

function TeamHasActiveEMP( team )
{
	return ( level.ActiveEMPs[ team ] > 0 );
}

function EnemyEMPActive()
{
	if( level.teamBased )
	{
		foreach( team in level.teams )
		{
			if( ( team != self.team ) && TeamHasActiveEMP( team ) )
			{
				return true;
			}
		}
	}
	else
	{
		enemies = self teams::GetEnemyPlayers();
		foreach( player in enemies )
		{
			if( player HasActiveEMP() )
			{
				return true;
			}
		}
	}
	
	return false;
}

function EnemyEMPOwner()
{
	enemies = self teams::GetEnemyPlayers();
	foreach( player in enemies )
	{
		if( player HasActiveEMP() )
		{
			return player;
		}
	}

	return undefined;
}

function EMP_JamEnemies( empEnt, hacked )
{
	level endon ( "game_ended" );
	self endon( "killstreak_hacked" );
	
	if( level.teamBased )
	{
		if ( hacked ) 
		{
			level.ActiveEMPs[ empEnt.OriginalTeam ] = false;
		}
		level.ActiveEMPs[ self.team ] = true;
	}
	
	if( hacked )
	{
		level.ActivePlayerEMPs[ empEnt.originalOwnerEntNum ] = false;
	}
	level.ActivePlayerEMPs[ self.entNum ] = true;
	level notify( "emp_updated" );
	level notify( "emp_deployed" );

	VisionSetNaked( "flash_grenade", 1.5 );
	wait ( 0.1 );
	VisionSetNaked( "flash_grenade", 0 );
	VisionSetNaked( GetDvarString( "mapname" ), 5.0 );
	
	empKillstreakWeapon = GetWeapon( "emp" );
	empKillstreakWeapon.isEmpKillstreak = true;
	level killstreaks::DestroyOtherTeamsActiveVehicles( self, empKillstreakWeapon );
	level killstreaks::DestroyOtherTeamsEquipment( self, empKillstreakWeapon );
	level weaponobjects::destroy_other_teams_supplemental_watcher_objects( self, empKillstreakWeapon );
}

function EMPTracker()
{
	level endon ( "game_ended" );
	
	while( true )
	{
		level waittill( "emp_updated" );
		
		foreach ( player in level.players )
		{
			player UpdateEMP();
		}
	}
}

function UpdateEMP()
{
	player = self;
	
	enemy_emp_active = player EnemyEMPActive();
	player setEMPJammed( enemy_emp_active );

	emped = player isEMPJammed(); // ask because a perk may stop it
	player clientfield::set_to_player( "empd_monitor_distance", emped );
	
	if( emped )
	{
		player notify( "emp_jammed" );
	}
}
