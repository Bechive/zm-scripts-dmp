#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\challenges_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\dev_shared;
#using scripts\shared\damagefeedback_shared;
#using scripts\shared\entityheadicons_shared;
#using scripts\shared\flagsys_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\player_shared;
#using scripts\shared\scoreevents_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\vehicle_shared;
#using scripts\shared\weapons_shared;
#using scripts\shared\weapons\_hive_gun;
#using scripts\shared\weapons\_satchel_charge;
#using scripts\shared\weapons\_trophy_system;
#using scripts\shared\weapons\_weaponobjects;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;
#insert scripts\shared\weapons\_weaponobjects.gsh;

#define MAX_PROJECTILE_WEAPONOBJECTS 4
	
#precache( "lui_menu_data", "spikeLauncherCounter.spikesReady" );
#precache( "lui_menu_data", "spikeLauncherCounter.blasting" );

#precache( "string", "MP_DEFUSING_EXPLOSIVE" );
#precache( "string", "PLATFORM_SATCHEL_CHARGE_DOUBLE_TAP" );

#precache( "fx", "_t6/weapon/claymore/fx_claymore_laser" );
#precache( "fx", "explosions/fx_exp_equipment_lg" );
#precache( "fx", "killstreaks/fx_emp_explosion_equip" );
#precache( "fx", "_t6/explosions/fx_exp_equipment" );
#precache( "fx", "explosions/fx_exp_equipment_lg" );
#precache( "fx", "weapon/fx_equip_light_os" );

#precache( "triggerstring", "MP_BOUNCINGBETTY_HACKING" );
#precache( "triggerstring", "MP_BOUNCINGBETTY_PICKUP" );
#precache( "triggerstring", "MP_HATCHET_PICKUP");
#precache( "triggerstring", "MP_CLAYMORE_PICKUP");
#precache( "triggerstring", "MP_BOUNCINGBETTY_PICKUP");
#precache( "triggerstring", "MP_TROPHY_SYSTEM_PICKUP");
#precache( "triggerstring", "MP_ACOUSTIC_SENSOR_PICKUP");
#precache( "triggerstring", "MP_CAMERA_SPIKE_PICKUP");
#precache( "triggerstring", "MP_SATCHEL_CHARGE_PICKUP");
#precache( "triggerstring", "MP_SCRAMBLER_PICKUP");
#precache( "triggerstring", "MP_SHOCK_CHARGE_PICKUP");
#precache( "triggerstring", "MP_TROPHY_SYSTEM_DESTROY");
#precache( "triggerstring", "MP_SENSOR_GRENADE_DESTROY");
#precache( "triggerstring", "MP_CLAYMORE_HACKING");
#precache( "triggerstring", "MP_BOUNCINGBETTY_HACKING");
#precache( "triggerstring", "MP_TROPHY_SYSTEM_HACKING");
#precache( "triggerstring", "MP_ACOUSTIC_SENSOR_HACKING");
#precache( "triggerstring", "MP_CAMERA_SPIKE_HACKING");
#precache( "triggerstring", "MP_SATCHEL_CHARGE_HACKING");
#precache( "triggerstring", "MP_SCRAMBLER_HACKING");

#namespace weaponobjects;

function init_shared()
{
	callback::on_start_gametype( &start_gametype );
	
	clientfield::register( "toplayer", "proximity_alarm", VERSION_SHIP, 2, "int" );	
	clientfield::register( "clientuimodel", "hudItems.proximityAlarm", VERSION_SHIP, 2, "int" ); // registered client-side in raw/ui/uieditor/clientfieldmodels.lua
	clientfield::register( "missile", "retrievable", VERSION_SHIP, 1, "int" );
	clientfield::register( "scriptmover", "retrievable", VERSION_SHIP, 1, "int" );
	clientfield::register( "missile", "enemyequip", VERSION_SHIP, 2, "int" );
	clientfield::register( "scriptmover", "enemyequip", VERSION_SHIP, 2, "int" );
	clientfield::register( "missile", "teamequip", VERSION_SHIP, 1, "int" );
	
	level.supplementalWatcherObjects = [];
	
}

function updateDvars()
{
}

function start_gametype()
{
	coneangle = GetDvarInt( "scr_weaponobject_coneangle", 70 );
	mindist = GetDvarInt( "scr_weaponobject_mindist", 20 );
	graceperiod = GetDvarFloat( "scr_weaponobject_graceperiod", 0.6 );
	radius = GetDvarInt( "scr_weaponobject_radius", 192 );

	callback::on_connect( &on_player_connect );
	callback::on_spawned( &on_player_spawned );

	level.watcherWeapons = [];
	level.watcherWeapons = getWatcherWeapons();

	level.retrievableWeapons = [];
	level.retrievableWeapons = getRetrievableWeapons();

	level.weaponobjectexplodethisframe = false;

	if ( GetDvarString( "scr_deleteexplosivesonspawn") == "" )
	{
		SetDvar("scr_deleteexplosivesonspawn", 1);
	}
	
	level.deleteExplosivesOnSpawn = GetDvarInt( "scr_deleteexplosivesonspawn");

	level.claymoreFXid = "_t6/weapon/claymore/fx_claymore_laser";
	level._equipment_spark_fx = "explosions/fx_exp_equipment_lg";
	level._equipment_fizzleout_fx = "explosions/fx_exp_equipment_lg";
	level._equipment_emp_destroy_fx = "killstreaks/fx_emp_explosion_equip";
	level._equipment_explode_fx = "_t6/explosions/fx_exp_equipment";
	level._equipment_explode_fx_lg = "explosions/fx_exp_equipment_lg";
	level._effect[ "powerLight" ] = "weapon/fx_equip_light_os";

	setUpRetrievableHintStrings();
	
	level.weaponobjects_hacker_trigger_width = 32; 
	level.weaponobjects_hacker_trigger_height = 32;		
}

function setUpRetrievableHintStrings()
{
	createRetrievableHint("hatchet", &"MP_HATCHET_PICKUP");
	createRetrievableHint("claymore", &"MP_CLAYMORE_PICKUP");
	createRetrievableHint("bouncingbetty", &"MP_BOUNCINGBETTY_PICKUP");
	createRetrievableHint("trophy_system", &"MP_TROPHY_SYSTEM_PICKUP");
	createRetrievableHint("acoustic_sensor", &"MP_ACOUSTIC_SENSOR_PICKUP");
	//createRetrievableHint("sensor_grenade", &"MP_SENSOR_GRENADE_PICKUP");
	createRetrievableHint("camera_spike", &"MP_CAMERA_SPIKE_PICKUP");
	createRetrievableHint("satchel_charge", &"MP_SATCHEL_CHARGE_PICKUP");
	createRetrievableHint("scrambler", &"MP_SCRAMBLER_PICKUP");
	createRetrievableHint("proximity_grenade", &"MP_SHOCK_CHARGE_PICKUP");

	createDestroyHint( "trophy_system", &"MP_TROPHY_SYSTEM_DESTROY");
	createDestroyHint( "sensor_grenade", &"MP_SENSOR_GRENADE_DESTROY");

	createHackerHint("claymore", &"MP_CLAYMORE_HACKING");
	createHackerHint("bouncingbetty", &"MP_BOUNCINGBETTY_HACKING");
	createHackerHint("trophy_system", &"MP_TROPHY_SYSTEM_HACKING");
	createHackerHint("acoustic_sensor", &"MP_ACOUSTIC_SENSOR_HACKING");
	//createHackerHint("sensor_grenade", &"MP_SENSOR_GRENADE_HACKING");
	createHackerHint("camera_spike", &"MP_CAMERA_SPIKE_HACKING");
	createHackerHint("satchel_charge", &"MP_SATCHEL_CHARGE_HACKING");
	createHackerHint("scrambler", &"MP_SCRAMBLER_HACKING");
}

function on_player_connect()
{
	if ( isdefined( level._weaponobjects_on_player_connect_override ) )
	{
		level thread [[level._weaponobjects_on_player_connect_override]]();
		return;
	}

	self.usedWeapons = false;
	self.hits = 0;
}

function on_player_spawned() // self == player
{
	self endon("disconnect");

	pixbeginevent("onPlayerSpawned");		
	
	if ( !isdefined( self.watchersInitialized ) )
	{
		self createBaseWatchers();
		
		self callback::callback_weapon_watcher();

		//Ensure that the watcher name is the weapon name minus _mp if you want to add weapon specific functionality.
		self createClaymoreWatcher();
		self createRCBombWatcher();
		self createQRDroneWatcher();
		self createPlayerHelicopterWatcher();
		//self createKniferangWatcher();
		self createHatchetWatcher();
		self createSpecialCrossbowWatcher();
		self createTactInsertWatcher();
		self hive_gun::createFireflyPodWatcher();

		//set up retrievable specific fields
		self setupRetrievableWatcher();
	
		self thread watchWeaponObjectUsage();
		
		self.watchersInitialized = true;
	}
	
	self resetWatchers();
	
	self trophy_system::ammo_reset();	
	
	pixendevent();
}

function resetWatchers()
{
	if ( !isdefined(self.weaponObjectWatcherArray) )
	{
		return undefined;
	}
	
	team = self.team;
	
	foreach( watcher in self.weaponObjectWatcherArray )
	{
		resetWeaponObjectWatcher( watcher, team );
	}	
}

function createBaseWatchers()
{
	//Check for die on respawn weapons
	foreach( index, weapon in level.watcherWeapons )
	{
		self createWeaponObjectWatcher( weapon.name, self.team );
	}

	//Check for retrievable weapons
	foreach( index, weapon in level.retrievableWeapons )
	{
		self createWeaponObjectWatcher( weapon.name, self.team );
	}
}

function setupRetrievableWatcher()
{
	//Check for retrievable weapons
	for( i = 0; i < level.retrievableWeapons.size; i++ )
	{
		watcher = getWeaponObjectWatcherByWeapon( level.retrievableWeapons[i] );
		if( isdefined( watcher ) )
		{
			if( !isdefined( watcher.onSpawnRetrieveTriggers ) )
				watcher.onSpawnRetrieveTriggers =&onSpawnRetrievableWeaponObject;
	
			if ( !isdefined( watcher.onDestroyed ))
				watcher.onDestroyed =&onDestroyed;
	
			if( !isdefined( watcher.pickUp ) )
				watcher.pickUp =&pickUp;
		}
	}
}

function createSpecialCrossbowWatcherTypes( weaponName )
{
	watcher = self createUseWeaponObjectWatcher( weaponName, self.team );
	watcher.onDetonateCallback = &deleteEnt;
	watcher.onDamage =&voidOnDamage;
	
	if ( IS_TRUE( level.b_crossbow_bolt_destroy_on_impact ) ) // PORTIZ 7/5/16: override crossbow bolt lingering/retrieval, since behavior is set up here in script instead of through GDT
	{
		watcher.onSpawn = &onSpawnCrossbowBoltImpact;
		watcher.onSpawnRetrieveTriggers = &voidOnSpawnRetrieveTriggers;
		watcher.pickUp = &voidPickUp;
	}
	else
	{
		watcher.onSpawn = &onSpawnCrossbowBolt;
		watcher.onSpawnRetrieveTriggers =&onSpawnSpecialCrossbowTrigger;
		watcher.pickUp = &pickUpCrossbowBolt;
	}
}

function createSpecialCrossbowWatcher() // self == player
{
	createSpecialCrossbowWatcherTypes( "special_crossbow" );
	createSpecialCrossbowWatcherTypes( "special_crossbowlh" );
	createSpecialCrossbowWatcherTypes( "special_crossbow_dw" );
	
	if ( IS_TRUE( level.b_create_upgraded_crossbow_watchers ) ) // PORTIZ 7/5/16: ZM maps can set to true to include upgraded crossbows
	{
		createSpecialCrossbowWatcherTypes( "special_crossbowlh_upgraded" );
		createSpecialCrossbowWatcherTypes( "special_crossbow_dw_upgraded" );
	}
}

function createHatchetWatcher() // self == player
{
	watcher = self createUseWeaponObjectWatcher( "hatchet", self.team );
	watcher.onDetonateCallback = &deleteEnt;
	watcher.onSpawn =&onSpawnHatchet;
	watcher.onDamage =&voidOnDamage;
	watcher.onSpawnRetrieveTriggers =&onSpawnHatchetTrigger;
}

function createTactInsertWatcher() // self == player
{
	watcher = self createUseWeaponObjectWatcher( "tactical_insertion", self.team );
	watcher.playDestroyedDialog = false;
}

function createRCBombWatcher() // self == player
{
	watcher = self createUseWeaponObjectWatcher( "rcbomb", self.team );

	watcher.altDetonate = false;
	watcher.headIcon = false;
	watcher.isMovable = true;
	watcher.ownerGetsAssist = true;
	watcher.playDestroyedDialog = false;
	watcher.deleteOnKillbrush = false;

	watcher.onDetonateCallback = level.rcbombOnBlowUp;
	watcher.stunTime = 1;
	watcher.notEquipment = true;
}

function createQRDroneWatcher() // self == player
{
	watcher = self createUseWeaponObjectWatcher( "qrdrone", self.team );

	watcher.altDetonate = false;
	watcher.headIcon = false;
	watcher.isMovable = true;
	watcher.ownerGetsAssist = true;
	watcher.playDestroyedDialog = false;
	watcher.deleteOnKillbrush = false;

	watcher.onDetonateCallback = level.qrdroneOnBlowUp;
	watcher.onDamage = level.qrdroneOnDamage;
	watcher.stunTime = 5;
	watcher.notEquipment = true;
}

function getSpikeLauncherActiveSpikeCount( watcher )
{
	// the spike launcher generates a new weapon when fired to handle detonation so make sure we're only counting the bolts
	currentItemCount = 0;
	foreach ( obj in watcher.objectArray )
	{
		if ( IsDefined(obj) && obj.item !== watcher.weapon )
		{
			currentItemCount++;
		}
	}
	return currentItemCount;
}

function watchSpikeLauncherItemCountChanged( watcher )	// self == player
{
	self endon( "death" );
	lastItemCount = undefined;
	while ( 1 )
	{
		self waittill( "weapon_change", weapon );
		
		while ( weapon.name == "spike_launcher" )
		{
			// the spike launcher generates a new weapon when fired to handle detonation so make sure we're only counting the bolts
			currentItemCount = getSpikeLauncherActiveSpikeCount( watcher );
				
			if ( currentItemCount !== lastItemCount )
			{
				self SetControllerUIModelValue( "spikeLauncherCounter.spikesReady", currentItemCount );
				lastItemCount = currentItemCount;
			}
			
			wait 0.1;
			weapon = self GetCurrentWeapon();
		}
	}
}

function spikesDetonating( watcher ) // self == player
{
	spikeCount = getSpikeLauncherActiveSpikeCount( watcher );
	
	if ( spikeCount > 0 )
	{
		self SetControllerUIModelValue( "spikeLauncherCounter.blasting", 1 );
		wait 2;
		self SetControllerUIModelValue( "spikeLauncherCounter.blasting", 0 );
	}
}

function createSpikeLauncherWatcher(weapon) // self == player
{
	watcher = self weaponobjects::createUseWeaponObjectWatcher( weapon, self.team );
	watcher.altName = "spike_charge";
	watcher.altWeapon = GetWeapon( "spike_charge" );
	watcher.altDetonate = false;
	watcher.watchForFire = true;
	watcher.hackable = true;
	watcher.hackerToolRadius = level.equipmentHackerToolRadius;
	watcher.hackerToolTimeMs = level.equipmentHackerToolTimeMs;
	watcher.headIcon = false;
	watcher.onDetonateCallback = &spikeDetonate;
	watcher.onStun = &weaponobjects::weaponStun;
	watcher.stunTime = 1;
	watcher.ownerGetsAssist = true;
	watcher.detonateStationary = false;
	watcher.detonationDelay = 0.0;
	watcher.detonationSound = "wpn_claymore_alert";
	watcher.onDetonationHandle = &spikesDetonating;
	self thread watchSpikeLauncherItemCountChanged( watcher );
}

function createPlayerHelicopterWatcher() // self == player
{
	watcher = self createUseWeaponObjectWatcher( "helicopter_player", self.team );

	watcher.altDetonate = true;
	watcher.headIcon = false;
	
	watcher.notEquipment = true;
}

function createClaymoreWatcher() // self == player
{
	watcher = self createProximityWeaponObjectWatcher( "claymore", self.team );
	watcher.watchForFire = true;
	watcher.onDetonateCallback = &claymoreDetonate;
	watcher.activateSound = "wpn_claymore_alert";
	watcher.hackable = true;
	watcher.hackerToolRadius = level.equipmentHackerToolRadius;
	watcher.hackerToolTimeMs = level.equipmentHackerToolTimeMs;
	watcher.ownerGetsAssist = true;

	detectionConeAngle = GetDvarInt( "scr_weaponobject_coneangle" );
	watcher.detectionDot = cos( detectionConeAngle );
	watcher.detectionMinDist = GetDvarInt( "scr_weaponobject_mindist" );
	watcher.detectionGracePeriod = GetDvarFloat( "scr_weaponobject_graceperiod" );
	watcher.detonateRadius = GetDvarInt( "scr_weaponobject_radius" );
	watcher.onStun =&weaponStun;
	watcher.stunTime = 1;
}

function voidOnSpawn( unused0, unused1 )
{
}

function voidOnDamage( unused0 )
{
}

function voidOnSpawnRetrieveTriggers( unused0, unused1 )
{	
}

function voidPickUp( unused0, unused1 )
{
}

function deleteEnt( attacker, emp, target )
{
	self delete();
}

function clearFXOnDeath( fx )
{
	fx endon("death");
	self util::waittill_any( "death", "hacked" );
	fx delete();
}

//
// generic watcher code
//

function deleteWeaponObjectInstance()
{
	if ( !isdefined( self ) )
		return;

	if ( isdefined( self.mineMover ) )
	{
		if ( isdefined( self.mineMover.killCamEnt ) )
		{
			self.mineMover.killCamEnt delete();
		}

		self.mineMover delete();
	}

	self delete();
}

function deleteWeaponObjectArray() 
{
	if ( isdefined( self.objectArray ) ) 
	{
		foreach( weaponObject in self.objectArray )
		{
			weaponObject deleteWeaponObjectInstance();
		}
	}
	
	self.objectArray = [];
}

function delayedSpikeDetonation( attacker, weapon )
{
//	wait 0.05;//flip the execute order back - previous wait will have flipped the thread order coming into this function - we want the charges to go off in the order they were placed
	if (!IsDefined(self.owner.spikeDelay))
	{
		self.owner.spikeDelay = 0;
	}
	const delayTimeIncrement = 0.3;
	delayTime = self.owner.spikeDelay;
	owner = self.owner;
	self.owner.spikeDelay += delayTimeIncrement;//delay between successive blasts
	waittillframeend;//make sure any other thread that wants to fire this frame uses an incrementing time value, if it's zero it won't wait and everyone will get zero time delay
	wait delayTime;
	owner.spikeDelay -= delayTimeIncrement;
	if (IsDefined(self))
	{
		self weaponobjects::weaponDetonate( attacker, weapon );
	}
}

function spikeDetonate( attacker, weapon, target )
{
	if ( IsDefined( weapon ) && weapon.isValid )
	{
		if ( isdefined( attacker ) )
		{
			if ( self.owner util::IsEnemyPlayer( attacker ) )
			{
//				attacker challenges::destroyedExplosive( weapon );
//				scoreevents::processScoreEvent( "destroyed_c4", attacker, self.owner, weapon );
			}
		
		}
	}
	
	thread delayedSpikeDetonation(attacker, weapon);
}

function claymoreDetonate( attacker, weapon, target )
{
	if ( !isdefined( weapon ) || !weapon.isEmp )
	{
		//PlayFX( level._equipment_explode_fx_lg, self.origin );
	}

	if ( isdefined(attacker) && self.owner util::IsEnemyPlayer( attacker ) )
	{
		attacker challenges::destroyedExplosive( weapon );
		scoreevents::processScoreEvent( "destroyed_claymore", attacker, self.owner, weapon );
	}
	
	weaponobjects::weaponDetonate( attacker, weapon );
}


function weaponDetonate( attacker, weapon )
{
	if ( IsDefined( weapon ) && weapon.isEmp )
	{
		self delete();
		return;
	}
	
	if ( isdefined( attacker ) )
	{
		if ( isdefined( self.owner ) && ( attacker != self.owner ) )
		{
			self.playDialog = true;
		}
		
		if ( IsPlayer( attacker ) )
		{
			self Detonate( attacker );
		}
		else
		{
			self Detonate();
		}
	}
	else if ( isdefined( self.owner ) && isplayer( self.owner ) )
	{
		self.playDialog = false;
		self Detonate( self.owner );
	}
	else
	{
		self Detonate();
	}
}

function detonateWhenStationary( object, delay, attacker, weapon )
{
	level endon( "game_ended" );
	
	object endon( "death" );
	object endon( "hacked" );
	object endon( "detonating" );


	if ( object isOnGround() == false )
	{
		object waittill( "stationary" );
	}
	
	self thread waitAndDetonate( object, delay, attacker, weapon );
}

function waitAndDetonate( object, delay, attacker, weapon )
{
	object endon("death");
	object endon("hacked");

	if ( !isdefined( attacker ) && !isdefined( weapon ) && object.weapon.proximityalarmactivationdelay > 0 )
	{
		// no double armed_detonation_wait detonations
		if ( IS_TRUE( object.armed_detonation_wait ) )
		{
			return;
		}	
		
		object.armed_detonation_wait = true;
		
		while ( !IS_TRUE( object.proximity_deployed ) )
		{
			WAIT_SERVER_FRAME;
		}
	}
	
	// no double detonations
	if ( IS_TRUE( object.detonated ) )
	{
		return;
	}
	
	object.detonated = true;
	
	object notify( "detonating" );
	
	isEmpDetonated = IsDefined( weapon ) && weapon.isemp;
	
	if ( isEmpDetonated && object.weapon.doEmpDestroyFx )
	{
		object.stun_fx = true;

		PlayFX( level._equipment_emp_destroy_fx, object.origin + ( 0, 0, 5 ) , ( 0, RandomFloat( 360 ), 0 ) );
		empFxDelay = 1.1;
	}

	if ( !isdefined( self.onDetonateCallback ) )
	{
		return;
	}	
	
	if ( !isEmpDetonated && !isdefined( weapon ) )
	{		
		if ( isdefined( self.detonationDelay ) && self.detonationDelay > 0.0 )
		{
			if ( isdefined( self.detonationSound ) )
			{
				object playsound ( self.detonationSound );		
			}
			
			delay = self.detonationDelay;
		}
	}
	else if ( isdefined( empFxDelay ) )
	{
		delay = empFxDelay;
	}
	
	if ( delay > 0 )
	{
		wait ( delay );
	}
	
	// "destroyed_explosive" notify, for challenges
	if ( isdefined( attacker ) && IsPlayer( attacker ) && isdefined( attacker.pers["team"] ) && isdefined( object.owner ) && isdefined( object.owner.pers["team"] ) )
	{
		if ( level.teambased )
		{
			if ( attacker.pers["team"] != object.owner.pers["team"] )
			{
				attacker notify("destroyed_explosive");
				//attacker _properks::destroyedEquipment();
			}
		}
		else
		{
			if ( attacker != object.owner )
			{
				attacker notify("destroyed_explosive");
				//attacker _properks::destroyedEquipment();
			}
		}
	}
	
	object [[self.onDetonateCallback]]( attacker, weapon, undefined );	
}

function waitAndFizzleOut( object, delay )
{
	object endon("death");
	object endon("hacked");

	// no double detonations
	if ( isdefined( object.detonated ) && object.detonated == true )
	{
		return;
	}
	
	object.detonated = true;
	
	object notify( "fizzleout" );
	
	if ( delay > 0 )
	{
		wait ( delay );
	}

	if ( !isdefined( self.onFizzleOut ) )
	{
		self deleteEnt();
		return;
	}	
	
	object [[self.onFizzleOut]]();	
}

function detonateWeaponObjectArray( forceDetonation, weapon ) 
{
	undetonated = [];
	if ( isdefined(self.objectArray) ) 
	{
		for ( i = 0; i < self.objectArray.size; i++ )
		{
			if ( isdefined( self.objectArray[i] ) )
			{
				// weapon is stunned, but can be detonated later
				if ( self.objectArray[i] isstunned() && forceDetonation == false )
				{
					undetonated[undetonated.size] = self.objectArray[i];
					continue;
				}				
		
				if ( isdefined( weapon ) )
				{
					// hacked weapon, don't destroy other weapons not of the same
					if ( weapon util::isHacked() && weapon.name != self.objectArray[i].weapon.name )
					{
						undetonated[undetonated.size] = self.objectArray[i];
						continue;
					}
					// planted weapon, don't destroy hacked weapons not of the same
					else if ( self.objectArray[i] util::isHacked() && weapon.name != self.objectArray[i].weapon.name )
					{
						undetonated[undetonated.size] = self.objectArray[i];
						continue;
					}					
				}
				
				// detonateStationary watcher, don't destroy until stationary
				if ( isdefined( self.detonateStationary ) && self.detonateStationary && forceDetonation == false )
				{
					self thread detonateWhenStationary( self.objectArray[i], 0.0, undefined, weapon );
				}
				else
				{
					self thread waitAndDetonate( self.objectArray[i], 0.0, undefined, weapon );
				}
			}
		}
	}
	
	self.objectArray = undetonated;
}

function addWeaponObjectToWatcher( watcherName, weapon_instance )
{
	watcher = getWeaponObjectWatcher( watcherName );
	assert( isdefined( watcher ), "Weapon object watcher " + watcherName + " does not exist" );

	self addWeaponObject( watcher, weapon_instance );
}

function addWeaponObject( watcher, weapon_instance, weapon )
{
	if( !isdefined( watcher.storeDifferentObject ) )
		watcher.objectArray[watcher.objectArray.size] = weapon_instance;
		
	if ( !IsDefined( weapon ) )
	{
		weapon = watcher.weapon;
	}

	weapon_instance.owner = self;
	weapon_instance.detonated = false;
	weapon_instance.weapon = weapon;
	
	if( isdefined( watcher.onDamage ) )
	{
		weapon_instance thread [[watcher.onDamage]]( watcher );
	}
	else
	{
		weapon_instance thread weaponObjectDamage( watcher );
	}
	
	weapon_instance.ownerGetsAssist = watcher.ownerGetsAssist;
	weapon_instance.destroyedByEmp = watcher.destroyedByEmp;
	
	if ( isdefined( watcher.onSpawn ) )
		weapon_instance thread [[watcher.onSpawn]]( watcher, self );

	if ( isdefined( watcher.onSpawnFX ) )
		weapon_instance thread [[watcher.onSpawnFX]]();
		
	weapon_instance thread setupReconEffect();

	if( isdefined( watcher.onSpawnRetrieveTriggers ) )
		weapon_instance thread [[watcher.onSpawnRetrieveTriggers]](watcher, self);

	if ( watcher.hackable )
		weapon_instance thread hackerInit( watcher );

	if( watcher.playDestroyedDialog )
	{
		weapon_instance thread playDialogOnDeath( self );
		weapon_instance thread watchObjectDamage( self );
	}

	if( watcher.deleteOnKillbrush )
	{
		if ( isdefined ( level.deleteOnKillbrushOverride ) ) 
		{
			weapon_instance thread [[level.deleteOnKillbrushOverride]]( self, watcher );
		}
		else
		{
			weapon_instance thread deleteOnKillbrush( self );
		}
	}	
	
	if ( weapon_instance useTeamEquipmentClientField( watcher ) )
	{
		weapon_instance clientfield::set( "teamequip", 1 );
	}
	
	if ( watcher.timeOut )
	{
		weapon_instance thread weapon_object_timeout( watcher );
	}
	
	weapon_instance thread delete_on_notify( self );
		
	weapon_instance thread cleanupWatcherOnDeath( watcher );
}

function cleanupWatcherOnDeath( watcher ) // call on weapon entity
{
	self waittill( "death" );
	
	if ( isdefined( watcher ) && isdefined( watcher.objectarray ) )
	{
		removeWeaponObject( watcher, self );
	}
	
	if ( isdefined( self ) && ( self.delete_on_death === true ) )
	{
		self deleteWeaponObjectInstance();
	}
}

function weapon_object_timeout( watcher )
{
	self endon( "death" );
	
	wait ( watcher.timeOut );
	
	self deleteEnt();
}

function delete_on_notify( e_player )
{
	e_player endon( "disconnect" );
	self endon( "death" );
	
	e_player waittill( "delete_weapon_objects" );
	
	self Delete();
}

// call on player
function deleteWeaponObjectHelper( weapon_ent )
{
	watcher = self getWeaponObjectWatcherByWeapon( weapon_ent.weapon );
	if ( !isdefined( watcher ) )
	{
		return;
	}

	removeWeaponObject( watcher, weapon_ent );
}

function removeWeaponObject( watcher, weapon_ent )
{
	watcher.objectArray = array::remove_undefined( watcher.objectArray );
	ArrayRemoveValue( watcher.objectArray, weapon_ent );
}

function cleanWeaponObjectArray( watcher )
{
	watcher.objectArray = array::remove_undefined( watcher.objectArray );
}

function weapon_object_do_DamageFeedBack( weapon, attacker )
{
	if ( isdefined( weapon ) && isdefined( attacker ) )
	{
		if ( weapon.doDamageFeedback )
		{
			// if we're not on the same team then show damage feedback
			if ( level.teambased && self.owner.team != attacker.team )
			{
				if ( damagefeedback::doDamageFeedback( weapon, attacker ) )
					attacker damagefeedback::update();
			}
			// for ffa just make sure the owner isn't the same
			else if ( !level.teambased && self.owner != attacker )
			{
				if ( damagefeedback::doDamageFeedback( weapon, attacker ) )
					attacker damagefeedback::update();
			}
		}
	}	
}

function weaponObjectDamage( watcher ) // self == weapon object
{
	self endon( "death" );
	self endon( "hacked" );
	self endon( "detonating" );

	self setcandamage(true);
	self.maxhealth = 100000;
	self.health = self.maxhealth;
	self.damageTaken = 0;

	attacker = undefined;
	
	while ( 1 )
	{
		self waittill ( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, weapon, iDFlags );		
		
		self.damageTaken += damage;
		
		if ( !isPlayer( attacker ) && isdefined( attacker.owner ) )
		{
			attacker = attacker.owner;	
		}
		
		if ( isdefined( weapon ) )
		{
			// do damage feedback
			self weapon_object_do_DamageFeedBack( weapon, attacker );
			
			// most equipment should be flash/concussion-able, so it'll disable for a short period of time
			// check to see if the equipment has been flashed/concussed and disable it
			if ( watcher.stunTime > 0 && weapon.doStun )
			{
				self thread stunStart( watcher, watcher.stunTime );				
				continue;
			}			
		}		
		
		// we're currently allowing the owner/teammate to flash their own		
		if ( level.teambased && IsPlayer( attacker ) && isdefined( self.owner ) )
 		{
			// if we're not hardcore and the team is the same, do not destroy
			if( !level.hardcoreMode && self.owner.team == attacker.pers["team"] && self.owner != attacker )
			{
				continue;
			}
		}

		if ( IsDefined( watcher.shouldDamage ) && !(self [[watcher.shouldDamage]]( watcher, attacker, weapon, damage )) )
		{
			continue;
		}
			
		// TODO: figure out if this is needed anymore
		// don't allow people to destroy satchel on their team if FF is off
		// don't bother with the FF check on vehicles as it will already have been done in 
		// the vehicle damage callback
		if ( !isvehicle( self ) && !friendlyFireCheck( self.owner, attacker ) )
			continue;

		break;
	}
	
	if ( level.weaponobjectexplodethisframe )
		wait .1 + randomfloat(.4);
	else
		wait .05;
	
	if (!isdefined(self))
		return;
	
	level.weaponobjectexplodethisframe = true;
	
	thread resetWeaponObjectExplodeThisFrame();
	
	self entityheadicons::setEntityHeadIcon("none");
	
	if ( isdefined( type ) && (isSubStr( type, "MOD_GRENADE_SPLASH" ) || isSubStr( type, "MOD_GRENADE" ) || isSubStr( type, "MOD_EXPLOSIVE" )) )
		self.wasChained = true;
	
	if ( isdefined( iDFlags ) && (iDFlags & IDFLAGS_PENETRATION) )
	{
		self.wasDamagedFromBulletPenetration = true;
		//attacker _properks::shotEquipment( self.owner, iDFlags );
	}
	
	self.wasDamaged = true;
	
	watcher thread waitAndDetonate( self, 0.0, attacker, weapon );

	// won't get here; got death notify.
}

//Notify player that their equipment was destroyed
function playDialogOnDeath( owner )
{
	owner endon("death");
	owner endon("disconnect");
	self endon( "hacked" );

	self waittill( "death" );

	if( isdefined(self.playDialog) && self.playDialog )
	{
		if( isdefined( level.playEquipmentDestroyedOnPlayer ) )
		{
			owner [[level.playEquipmentDestroyedOnPlayer]]( );
		}		
	}		
}

function watchObjectDamage( owner )
{
	owner endon("death");
	owner endon("disconnect");
	self endon( "hacked" );
	self endon( "death" );

	while(1)
	{
		self waittill( "damage", damage, attacker );

		if( isdefined(attacker) && isPlayer(attacker) && attacker != owner )
		{
			self.playDialog = true;
		}
		else
		{
			self.playDialog = false;
		}
	}
}

function stunStart( watcher, time )
{
	self endon ( "death" );

	if ( self isStunned() )
	{
		return;
	}

	if ( isdefined( self.cameraHead ) )
	{
		//self.cameraHead clientfield::set( "cf_m_stun", 1 );
	}
	//self clientfield::set( "cf_m_stun", 1 );
	
	// allow specific effects
	if ( isdefined( watcher.onStun ) )
		self thread [[watcher.onStun]]();
	
	if ( watcher.name == "rcbomb" )
	{
		self.owner util::freeze_player_controls( true );
	}
	
	if ( isdefined( time ) )
	{
		wait ( time );
	}
	else
	{
		return;
	}

	if ( watcher.name == "rcbomb" )
	{
		self.owner util::freeze_player_controls( false );
	}
	
	self stunStop();
}

function stunStop()
{
	self notify ( "not_stunned" );
	if ( isdefined( self.cameraHead ) )
	{
		//self.cameraHead clientfield::set( "cf_m_stun", 0 );
	}
	//self clientfield::set( "cf_m_stun", 0 );
}

function weaponStun() // self == weapon object
{
	self endon( "death" );
	self endon( "not_stunned" );
	
	origin = self GetTagOrigin( "tag_fx" );

	if ( !isdefined( origin ) )
	{
		origin = self.origin + ( 0, 0, 10 );
	}

	self.stun_fx = spawn( "script_model", origin );
	self.stun_fx SetModel( "tag_origin" );
	self thread stunFxThink( self.stun_fx );
	wait ( 0.1 );

	PlayFXOnTag( level._equipment_spark_fx, self.stun_fx, "tag_origin" );
	
}

function stunFxThink( fx )
{
	fx endon("death");
	self util::waittill_any( "death", "not_stunned" );
	fx delete();
}

function isStunned()
{
	return ( isdefined( self.stun_fx ) );
}

function weaponObjectFizzleOut()
{
	self endon( "death" );
	
	PlayFX( level._equipment_fizzleout_fx, self.origin );
		
	deleteEnt();
}

function resetWeaponObjectExplodeThisFrame()
{
	wait .05;
	level.weaponobjectexplodethisframe = false;
}

function getWeaponObjectWatcher( name )
{
	if ( !isdefined(self.weaponObjectWatcherArray) )
	{
		return undefined;
	}
	
	for ( watcher = 0; watcher < self.weaponObjectWatcherArray.size; watcher++ )
	{
		if ( self.weaponObjectWatcherArray[watcher].name == name || (isdefined(self.weaponObjectWatcherArray[watcher].altName) && self.weaponObjectWatcherArray[watcher].altName == name) )
		{
			return self.weaponObjectWatcherArray[watcher];
		}
	}
	
	return undefined;
}

function getWeaponObjectWatcherByWeapon( weapon ) // self == player
{
	if ( !isdefined(self.weaponObjectWatcherArray) )
	{
		return undefined;
	}
	
	for ( watcher = 0; watcher < self.weaponObjectWatcherArray.size; watcher++ )
	{
		if ( isdefined(self.weaponObjectWatcherArray[watcher].weapon) && ( self.weaponObjectWatcherArray[watcher].weapon == weapon || self.weaponObjectWatcherArray[watcher].weapon == weapon.rootWeapon ) )
		{
			return self.weaponObjectWatcherArray[watcher];
		}
		if ( isdefined(self.weaponObjectWatcherArray[watcher].weapon) && isdefined(self.weaponObjectWatcherArray[watcher].altWeapon) && self.weaponObjectWatcherArray[watcher].altWeapon == weapon )
		{
			return self.weaponObjectWatcherArray[watcher];
		}
	}
	
	return undefined;
}

function resetWeaponObjectWatcher( watcher, ownerTeam )
{
	if ( watcher.deleteOnPlayerSpawn == 1 || ( isdefined( watcher.ownerTeam ) && watcher.ownerTeam != ownerTeam ) )
	{
		self notify( "weapon_object_destroyed" );
		watcher deleteWeaponObjectArray();
	}
	
	// player may have switched teams
	watcher.ownerTeam = ownerTeam;
}

function createWeaponObjectWatcher( weaponname, ownerTeam )
{
	if ( !isdefined(self.weaponObjectWatcherArray) )
	{
		self.weaponObjectWatcherArray = [];
	}
	
	weaponObjectWatcher = getWeaponObjectWatcher( weaponname );

	if ( !isdefined( weaponObjectWatcher ) )
	{ 
		weaponObjectWatcher = SpawnStruct();
		self.weaponObjectWatcherArray[self.weaponObjectWatcherArray.size] = weaponObjectWatcher;
	
		weaponObjectWatcher.name = weaponname;
		weaponObjectWatcher.type = "use";
		weaponObjectWatcher.weapon = GetWeapon( weaponname );
		weaponObjectWatcher.watchForFire = false;
		weaponObjectWatcher.hackable = false;
		weaponObjectWatcher.altDetonate = false;
		weaponObjectWatcher.detectable = true;
		weaponObjectWatcher.headIcon = false;
		weaponObjectWatcher.stunTime = 0;
		weaponObjectWatcher.timeOut = 0;
		weaponObjectWatcher.destroyedByEmp = true;
		weaponObjectWatcher.activateSound = undefined;
		weaponObjectWatcher.ignoreDirection = undefined;
		weaponObjectWatcher.immediateDetonation = undefined; 
		weaponObjectWatcher.deploySound = weaponObjectWatcher.weapon.firesound;
		weaponObjectWatcher.deploySoundPlayer = weaponObjectWatcher.weapon.firesoundplayer;
		weaponObjectWatcher.pickUpSound = weaponObjectWatcher.weapon.pickupsound;
		weaponObjectWatcher.pickUpSoundPlayer = weaponObjectWatcher.weapon.pickupsoundplayer;
		weaponObjectWatcher.altWeapon = weaponObjectWatcher.weapon.altweapon;
		weaponObjectWatcher.ownerGetsAssist = false;
		weaponObjectWatcher.playDestroyedDialog = true;
		weaponObjectWatcher.deleteOnKillbrush = true;
		weaponObjectWatcher.deleteOnDifferentObjectSpawn = true;
		weaponObjectWatcher.enemyDestroy = false;
		weaponObjectWatcher.deleteOnPlayerSpawn = level.deleteExplosivesOnSpawn;
		weaponObjectWatcher.ignoreVehicles = false;
		weaponObjectWatcher.ignoreAI = false;
		weaponObjectWatcher.activationDelay = 0;
		
		// callbacks
		weaponObjectWatcher.onSpawn = undefined;
		weaponObjectWatcher.onSpawnFX = undefined;
		weaponObjectWatcher.onSpawnRetrieveTriggers = undefined;
		weaponObjectWatcher.onDetonateCallback = undefined;
		weaponObjectWatcher.onStun = undefined;
		weaponObjectWatcher.onStunFinished = undefined;
		weaponObjectWatcher.onDestroyed = undefined;
		weaponObjectWatcher.onFizzleOut = &weaponobjects::weaponObjectFizzleOut;
		weaponObjectWatcher.shouldDamage = undefined;
		weaponObjectWatcher.onSupplementalDetonateCallback = undefined;

		if ( !isdefined( weaponObjectWatcher.objectArray ) )
			weaponObjectWatcher.objectArray = [];
	}

	resetWeaponObjectWatcher( weaponObjectWatcher, ownerTeam );
	
	return weaponObjectWatcher;
}

function createUseWeaponObjectWatcher( weaponname, ownerTeam )
{
	weaponObjectWatcher = createWeaponObjectWatcher( weaponname, ownerTeam );

	weaponObjectWatcher.type = "use";
	weaponObjectWatcher.onSpawn =&onSpawnUseWeaponObject;

	return weaponObjectWatcher;
}

function createProximityWeaponObjectWatcher( weaponname, ownerTeam )
{
	weaponObjectWatcher = createWeaponObjectWatcher( weaponname, ownerTeam );

	weaponObjectWatcher.type = "proximity";
	weaponObjectWatcher.onSpawn =&onSpawnProximityWeaponObject;

	detectionConeAngle = GetDvarInt( "scr_weaponobject_coneangle" );
	weaponObjectWatcher.detectionDot = cos( detectionConeAngle );
	weaponObjectWatcher.detectionMinDist = GetDvarInt( "scr_weaponobject_mindist" );
	weaponObjectWatcher.detectionGracePeriod = GetDvarFloat( "scr_weaponobject_graceperiod" );
	weaponObjectWatcher.detonateRadius = GetDvarInt( "scr_weaponobject_radius" );
	
	return weaponObjectWatcher;
}

function commonOnSpawnUseWeaponObject( watcher, owner ) // self == weapon (for example: the claymore)
{
	level endon ( "game_ended" );
	self endon ( "death" );
	self endon ( "hacked" );

	if ( watcher.detectable )
	{
//		if ( isdefined(watcher.isMovable) && watcher.isMovable )
//			self thread weaponObjectDetectionMovable( owner.pers["team"] );
//		else
//			self thread weaponObjectDetectionTrigger_wait( owner.pers["team"] );
		
		if ( watcher.headIcon && level.teamBased )
		{
			self util::waitTillNotMoving();
			
			if ( isdefined( self ) )
			{
				offset = self.weapon.weaponHeadObjectiveHeight;
				
				v_up = AnglesToUp( self.angles );
				x_offset = abs( v_up[0] );
				y_offset = abs( v_up[1] );
				z_offset = abs( v_up[2] );
				
				if( x_offset > y_offset && x_offset > z_offset )
				{
					//v_up = v_up * ( 1, 0, 0 );
				}
				else if( y_offset > x_offset && y_offset > z_offset )
				{
					//v_up = v_up * ( 0, 1, 0 );
				}
				else if( z_offset > x_offset && z_offset > y_offset )
				{
					v_up = v_up * ( 0, 0, 1 );
				}
				
				up_offset_modified = v_up * offset;
				up_offset = AnglesToUp( self.angles ) * offset;
				
				objective = GetEquipmentHeadObjective( self.weapon );
				self entityheadicons::setEntityHeadIcon( owner.pers["team"], owner, up_offset, objective );
			}
		}
	}
}

function WasProximityAlarmActivatedBySelf()
{
	return isdefined( self.owner.ProximityAmlarmEnt ) && self.owner.ProximityAmlarmEnt == self;
}

function ProximityAlarmActivate( active, watcher )
{
	if ( !IsDefined( self.owner ) || !IsPlayer( self.owner ) )
	{
		return;
	}
	
	if ( active && !isdefined( self.owner.ProximityAmlarmEnt ) )
	{
		self.owner.ProximityAmlarmEnt = self;
		self.owner clientfield::set_to_player( "proximity_alarm", PROXIMITY_ALARM_ON );
		self.owner clientfield::set_player_uimodel( "hudItems.proximityAlarm", PROXIMITY_ALARM_ON );
	}
	else
	{
		if ( !isdefined( self ) || self WasProximityAlarmActivatedBySelf() || self.owner clientfield::get_to_player( "proximity_alarm" ) == PROXIMITY_ALARM_DEPLOYED )
		{
			self.owner.ProximityAmlarmEnt = undefined;
			self.owner clientfield::set_to_player( "proximity_alarm", PROXIMITY_ALARM_OFF );
			self.owner clientfield::set_player_uimodel( "hudItems.proximityAlarm", PROXIMITY_ALARM_OFF );
		}
	}
	
}

function ProximityAlarmLoop( watcher, owner ) // self == weapon entity (for example: the claymore)
{
	level endon ( "game_ended" );
	self endon ( "death" );
	self endon ( "hacked" );
	self endon( "detonating" );
	
	if ( self.weapon.proximityalarminnerradius <= 0 )
	{
		return;
	}
	
	self util::waitTillNotMoving();
	
	delayTimeSec = self.weapon.proximityalarmactivationdelay / 1000;
	
	if ( delayTimeSec > 0 )
	{
		wait delayTimeSec;
		
		if ( !IsDefined( self ) )
		{
			return;
		}
	}	
	
	if( !IS_TRUE( self.owner._disable_proximity_alarms ) )
	{
		self.owner clientfield::set_to_player( "proximity_alarm", PROXIMITY_ALARM_DEPLOYED );
		self.owner clientfield::set_player_uimodel( "hudItems.proximityAlarm", PROXIMITY_ALARM_DEPLOYED );
	}
	
	self.proximity_deployed = true;
	
	alarmStatusOld =  "notify";
	alarmStatus = "off";
	
	// this is executing for each equipment with proximity alarm
	// the loop will turn on/off the alarm
	// the loop will play proximityAlarmActivateSound when going from 'off' to 'on'
	while ( 1 )
	{
		wait( .05 );
		
		if ( !IsDefined( self.owner ) || !IsPlayer( self.owner ) )
		{
			return;
		}
		
		if ( IsAlive( self.owner ) == false && self.owner util::isUsingRemote() == false )
		{
			self ProximityAlarmActivate( false, watcher );
			return;
		}
		
		if( IS_TRUE( self.owner._disable_proximity_alarms ) )
		{
			self ProximityAlarmActivate( false, watcher );
		}
		else if ( (alarmStatus != alarmStatusOld) || (alarmStatus == "on" && !isdefined( self.owner.ProximityAmlarmEnt )) ) // check if there is a change in the alarm status
		{
			if ( alarmStatus == "on" )
			{
				// the alarm turns on if it was not already on
				if ( alarmStatusOld == "off" && isdefined( watcher ) && isdefined( watcher.proximityAlarmActivateSound ) )
				{
					// play alarm activated sound, plays only once even if more players come within range
					//self playsound( watcher.proximityAlarmActivateSound );
					//changed this playsound to the line below because the sound origin was slightly below ground and occluding the sound.
					playsoundatposition( watcher.proximityAlarmActivateSound , (self.origin + (0,0,32)) );
				}
				
				// turn on the alarm
				self ProximityAlarmActivate( true, watcher );
			}
			else
			{				
				// turn off the alarm
				self ProximityAlarmActivate( false, watcher );
			}
			
			alarmStatusOld = alarmStatus;
		}
		
		alarmStatus =  "off";
		
		actors = GetActorArray();
		players = Getplayers();
		detectEntities = arraycombine( players, actors, false, false );

		foreach ( entity in detectEntities )
		{
			wait( .05 ); // only handle 1 player per frame

			if ( !isdefined( entity ) )
			{
				continue;
			}
			
			owner = entity;
			if( IsActor( entity ) && ( !isDefined( entity.isAiClone ) || !entity.isAiClone ) )
			{
				continue;
			}
			else if( isActor( entity ) )
			{
				owner = entity.owner;
			}
			
			if ( entity.team == "spectator" )
			{
				continue;
			}			
			
			{
				if( owner HasPerk( "specialty_detectexplosive" ) )
				{
					continue;
				}
				if ( isdefined( self.owner ) && owner == self.owner )
				{
					continue;
				}
				if ( !friendlyFireCheck( self.owner, owner, 0 ) )
				{	
					continue;
				}
			}
	
			if ( self isstunned() ) 
				continue;
	
			if( !IsAlive( entity ) )
				continue;
			
			if ( isdefined( watcher.immunespecialty ) && owner hasPerk( watcher.immunespecialty ) )
				continue;
				
			radius = self.weapon.proximityalarmouterradius;
			distanceSqr = DistanceSquared( self.origin, entity.origin );
			
			if ( radius * radius < distanceSqr )
			{								
				// this player is outside outer radius
				continue;
			}
			
			if ( entity damageConeTrace( self.origin, self ) == 0 )			
			{
				// this player cannot be damaged
				continue;
			}
			
			if ( alarmStatusOld == "on" )
			{
				// this player is inside outer radius and the alarm was already on
				alarmStatus = "on";
				break;
			}
			
			radius = self.weapon.proximityalarminnerradius;
			
			if ( radius * radius < distanceSqr )
			{
				// this player is not triggering the alarm
				continue;
			}			
			
			// this player is inside the inner radius 
			alarmStatus = "on";
			break;
		}
	}	
}

// self is the entity with proximity alarm
function commonOnSpawnUseWeaponObjectProximityAlarm( watcher, owner ) // self == weapon entity (for example: the claymore)
{	
	// waits until self is dead
	self ProximityAlarmLoop( watcher, owner );
	
	// cleans up after self death	
	self ProximityAlarmActivate( false, watcher );

	
}

function onSpawnUseWeaponObject( watcher, owner ) // self == weapon (for example: the claymore)
{
	self thread commonOnSpawnUseWeaponObject(watcher, owner);
	self thread commonOnSpawnUseWeaponObjectProximityAlarm(watcher, owner);
}

function onSpawnProximityWeaponObject( watcher, owner ) // self == weapon (for example: the claymore)
{
	self.protected_entities = [];
	
	self thread commonOnSpawnUseWeaponObject(watcher, owner);

	if ( isdefined( level._proximityWeaponObjectDetonation_override ) )
	{
		self thread [[level._proximityWeaponObjectDetonation_override]]( watcher );
	}
	else
	{
		self thread proximityWeaponObjectDetonation( watcher );
	}
}

function watchWeaponObjectUsage() // self == player
{
	self endon( "disconnect" );
	
	if ( !isdefined(self.weaponObjectWatcherArray) )
	{
		self.weaponObjectWatcherArray = [];
	}
	
	self thread watchWeaponObjectSpawn( "grenade_fire" );
	self thread watchWeaponObjectSpawn( "grenade_launcher_fire" );
	self thread watchWeaponObjectSpawn( "missile_fire" );
	self thread watchWeaponObjectDetonation();
	self thread watchWeaponObjectAltDetonation();
	self thread watchWeaponObjectAltDetonate();
	self thread deleteWeaponObjectsOn();	
}

// check for projectile type weapon objects spawning
function watchWeaponObjectSpawn( notify_type ) // self == player
{
	self notify( "watchWeaponObjectSpawn_" + notify_type );
	self endon( "watchWeaponObjectSpawn_" + notify_type );
	self endon( "disconnect" );

	while(1)
	{
		self waittill( notify_type, weapon_instance, weapon );
		
		if( ( IS_BONUSZM || IS_TRUE( level.projectiles_should_ignore_world_pause ) ) && IsDefined( weapon_instance ) )
		{
			weapon_instance SetIgnorePauseWorld( true );
		}

		// need to increment the used stat for claymore and c4
		if ( weapon.setUsedStat && !self util::isHacked() )
		{
			self AddWeaponStat( weapon, "used", 1 );
		}

		watcher = getWeaponObjectWatcherByWeapon( weapon );
		if ( isdefined( watcher ) )
		{	
			// remove any empty objects
			cleanWeaponObjectArray( watcher );

			if ( weapon.maxinstancesallowed )
			{
				// This allows you to have only a certain number of this weapon object type in the world 
				// Once you reach the max the first will "fizzle out".
				if(  watcher.objectarray.size > (weapon.maxinstancesallowed - 1))
				{
					watcher thread waitAndFizzleOut( watcher.objectarray[0], 0.1 );
					watcher.objectarray[0] = undefined;

					cleanWeaponObjectArray( watcher );
				}
			}
	
			self addWeaponObject( watcher, weapon_instance );
		}
	}
}

function anyObjectsInWorld( weapon )
{
	objectsInWorld = false;
	for( i = 0; i < self.weaponObjectWatcherArray.size; i++)
	{
		if( self.weaponObjectWatcherArray[i].weapon != weapon )
			continue;

		if( isdefined( self.weaponObjectWatcherArray[i].onDetonateCallback ) && self.weaponObjectWatcherArray[i].objectarray.size > 0 )
		{
			objectsInWorld = true;
			break;
		}
	}
	return objectsInWorld;
}

function weaponObjectDetectionMovable( ownerTeam ) // self == weapon (for example: the claymore)
{
	self endon ( "end_detection" );
	level endon ( "game_ended" );
	self endon ( "death" );
	self endon ( "hacked" );

	if ( !level.teambased )
		return;

	self.detectId = "rcBomb" + getTime() + randomInt( 1000000 );
}


function setIconPos( item, icon, heightIncrease )
{
	icon.x = item.origin[0];
	icon.y = item.origin[1];
	icon.z = item.origin[2]+heightIncrease;
}

function weaponObjectDetectionTrigger_wait( ownerTeam ) // self == weapon (for example: the claymore)
{
	self endon ( "death" );
	self endon ( "hacked" );
	self endon( "detonating" );

	util::waitTillNotMoving();

	self thread weaponObjectDetectionTrigger( ownerTeam );
}

function weaponObjectDetectionTrigger( ownerTeam ) // self == weapon (for example: the claymore)
{
	trigger = spawn( "trigger_radius", self.origin-(0,0,128), 0, 512, 256 );
	trigger.detectId = "trigger" + getTime() + randomInt( 1000000 );
	
	trigger SetHintLowPriority( true );

	self util::waittill_any( "death", "hacked", "detonating" );
	trigger notify ( "end_detection" );

	if ( isdefined( trigger.bombSquadIcon ) )
		trigger.bombSquadIcon destroy();
	
	trigger delete();	
}

function hackerTriggerSetVisibility( owner )
{
	self endon( "death" );
	
	assert( IsPlayer( owner ) );

	ownerTeam = owner.pers["team"];

	for ( ;; )
	{
		if ( level.teamBased )
		{
			self SetVisibleToAllExceptTeam( ownerTeam );
			self SetExcludeTeamForTrigger( ownerTeam );
		}
		else
		{
			self SetVisibleToAll();
			self SetTeamForTrigger( "none" );
		}

		if ( isdefined( owner ) ) 
		{
			self SetInvisibleToPlayer( owner );
		}
	
		level util::waittill_any( "player_spawned", "joined_team" );
	}
}

function hackerNotMoving()
{
	self endon( "death" );
	self util::waitTillNotMoving();
	self notify( "landed" );
}

function hackerInit( watcher )
{
	self thread hackerNotMoving();

	event = self util::waittill_any_return( "death", "landed" );

	if ( event == "death" )
	{
		return;
	}

	triggerOrigin = self.origin;
	if ( "" != self.weapon.hackerTriggerOriginTag )
	{
		triggerOrigin = self GetTagOrigin( self.weapon.hackerTriggerOriginTag );
	}

	// set up a trigger for a hacker
	self.hackerTrigger = spawn( "trigger_radius_use", triggerOrigin, level.weaponobjects_hacker_trigger_width, level.weaponobjects_hacker_trigger_height );

	self.hackerTrigger SetHintLowPriority( true );
	self.hackerTrigger SetCursorHint( "HINT_NOICON", self );
	self.hackerTrigger SetIgnoreEntForTrigger( self );

	self.hackerTrigger EnableLinkTo();
	self.hackerTrigger LinkTo( self );

	if( isdefined( level.hackerHints[self.weapon.name] ) )
	{
		self.hackerTrigger SetHintString( level.hackerHints[self.weapon.name].hint );
	}
	else
	{
		self.hackerTrigger SetHintString( &"MP_GENERIC_HACKING" );
	}

	
	self.hackerTrigger SetPerkForTrigger( "specialty_disarmexplosive" );
	self.hackerTrigger thread hackerTriggerSetVisibility( self.owner );
	
	self thread hackerThink( self.hackerTrigger, watcher );
}

function hackerThink( trigger, watcher ) // self == weapon_instance
{
	self endon( "death" );

	for ( ;; )
	{
		trigger waittill( "trigger", player, instant );

		if ( !isdefined( instant ) && !trigger hackerResult( player, self.owner ) )
		{
			continue;
		}

		self ItemHacked( watcher, player );

		// the hacker thread will be respawned with the new owner, this thread can be killed
		return;
	}
}

function ItemHacked( watcher, player )
{
	self ProximityAlarmActivate( false, watcher );
	
	self.owner hackerRemoveWeapon( self );

	if( isdefined( level.playEquipmentHackedOnPlayer ) )
	{
		self.owner [[level.playEquipmentHackedOnPlayer]]( );
	}		

	if ( self.weapon.ammoCountEquipment > 0 && isdefined( self.ammo ) )
	{
		ammoLeftEquipment = self.ammo;
		
		if ( self.weapon.rootWeapon == GetWeapon( "trophy_system" ) )
		{
			player trophy_system::ammo_weapon_hacked( ammoLeftEquipment );
		}
	}	
	
	self.hacked = true;
	self SetMissileOwner( player );
	self SetTeam( player.pers["team"] );	
	self.owner = player;	
	self clientfield::set( "retrievable", 0 );

	if ( self.weapon.doHackedStats )
	{
		scoreevents::processScoreEvent( "hacked", player );
		player AddWeaponStat( GetWeapon( "pda_hack" ), "CombatRecordStat", 1 );
		
		player challenges::hackedOrDestroyedEquipment();
	}

	// detonation info for the C4
	if ( self.weapon.rootWeapon == level.weaponSatchelCharge && isdefined( player.lowerMessage ) )
	{
		player.lowerMessage SetText( &"PLATFORM_SATCHEL_CHARGE_DOUBLE_TAP" );
		player.lowerMessage.alpha = 1;
		player.lowerMessage FadeOverTime( 2.0 );
		player.lowerMessage.alpha = 0;
	}

	// kill the previous owner's threads
	self notify( "hacked", player );
	level notify( "hacked", self, player );

	if ( isdefined( self.cameraHead ) )
	{
		self.cameraHead notify( "hacked", player );
	}

	WAIT_SERVER_FRAME; // let current threads clean up from the 'hacked' notify
	
	if ( isdefined( player ) && player.sessionstate == "playing" )
	{
		// this will re-initialize the watcher system for this equipment
		player notify( "grenade_fire", self, self.weapon, true );
	}
	else
	{
		watcher thread waitAndDetonate( self, 0.0, undefined, self.weapon );
	}
}

function hackerUnfreezePlayer( player )
{
	self endon( "hack_done" );
	self waittill( "death" );

	if ( isdefined( player ) )
	{
		player util::freeze_player_controls( false );
		player EnableWeapons();
	}
}

function hackerResult( player, owner ) // self == trigger_radius
{
	success = true;
	time = GetTime();
	hackTime = GetDvarfloat( "perk_disarmExplosiveTime" );

	if ( !canHack( player, owner, true ) )
	{
		return false;
	}

	self thread hackerUnfreezePlayer( player );

	while ( time + ( hackTime * 1000 ) > GetTime() )
	{
		if ( !canHack( player, owner, false ) )
		{
			success = false;
			break;
		}

		if ( !player UseButtonPressed() )
		{
			success = false;
			break;
		}

		if ( !isdefined( self ) )
		{
			success = false;
			break;
		}

	/*
		if ( !player IsTouching( self ) )
		{
			success = false;
			break;
		}
	*/

		player util::freeze_player_controls( true );
		player DisableWeapons();

		if ( !isdefined( self.progressBar ) )
		{
			self.progressBar = player hud::createPrimaryProgressBar();
			self.progressBar.lastUseRate = -1;
			self.progressBar hud::showElem();
			self.progressBar hud::updateBar( 0.01, 1 / hackTime );

			self.progressText = player hud::createPrimaryProgressBarText();
			self.progressText setText( &"MP_HACKING" );
			self.progressText hud::showElem();
			player PlayLocalSound ( "evt_hacker_hacking" );
		}
		
		WAIT_SERVER_FRAME;
	}

	if ( isdefined( player ) )
	{
		player util::freeze_player_controls( false );
		player EnableWeapons();
	}

	if ( isdefined( self.progressBar ) )
	{
		self.progressBar hud::destroyElem();
		self.progressText hud::destroyElem();
	}

	if ( isdefined( self ) )
	{
		self notify( "hack_done" );
	}

	return success;
}

function canHack( player, owner, weapon_check )
{
	if ( !isdefined( player ) )
		return false;
	
	if ( !IsPlayer( player ) )
		return false;

	if ( !IsAlive( player ) )
		return false;

	if ( !isdefined( owner ) )
		return false;

	if ( owner == player )
		return false;
		
	if ( level.teambased && player.team == owner.team )
		return false;

	if ( ( isdefined( player.isDefusing ) && player.isDefusing ) )
		return false;

	if ( ( isdefined( player.isPlanting ) && player.isPlanting ) )
		return false;

	if ( isdefined( player.proxBar ) && !player.proxBar.hidden )
		return false;

	if ( isdefined( player.revivingTeammate ) && player.revivingTeammate == true )
		return false;

	if ( !player IsOnGround() )
		return false;
		
	if ( player IsInVehicle() )
		return false;

	if ( player IsWeaponViewOnlyLinked() )
		return false;

	if ( !player HasPerk( "specialty_disarmexplosive" ) )
		return false;

	if ( player IsEMPJammed() )
		return false;

	if ( isdefined( player.laststand ) && player.laststand )
		return false;

	if ( weapon_check )
	{
		if ( player IsThrowingGrenade() )
			return false;

		if ( player IsSwitchingWeapons() )
			return false;

		if ( player IsMeleeing() )
			return false;

		weapon = player GetCurrentWeapon(); 

		if ( !isdefined( weapon ) )
			return false;

		if ( weapon == level.weaponNone )
			return false;

		if ( weapon.isEquipment && player IsFiring() )
			return false;

		if ( weapon.isSpecificUse )
			return false;
	}

	return true;
}

function hackerRemoveWeapon( weapon_instance )
{
	for( i = 0; i < self.weaponObjectWatcherArray.size; i++)
	{
		if( self.weaponObjectWatcherArray[i].weapon != weapon_instance.weapon.rootWeapon )
		{
			continue;
		}

		// remove any empty objects and the hacked object
		removeWeaponObject( self.weaponObjectWatcherArray[i], weapon_instance );

		return;
	}
}

function proximityWeaponObject_CreateDamageArea( watcher )
{
	damagearea = spawn("trigger_radius", self.origin + (0,0,0-watcher.detonateRadius), level.aiTriggerSpawnFlags | level.vehicleTriggerSpawnFlags, watcher.detonateRadius, watcher.detonateRadius*2);
	damagearea EnableLinkTo();
	damagearea LinkTo( self );

	self thread deleteOnDeath( damagearea );
	
	return damagearea;
}

function proximityWeaponObject_ValidTriggerEntity( watcher, ent )
{
	{
		if ( isdefined( self.owner ) && ent == self.owner )
			return false;
		if ( IsVehicle( ent ) )
		{
			if ( watcher.ignoreVehicles )
				return false;
			
			if ( self.owner === ent.owner ) // owner's own vehicle
				return false;
		}
	
		if ( !friendlyFireCheck( self.owner, ent, 0 ) )
			return false;
	
		if ( watcher.ignoreVehicles && IsAI( ent ) && !IS_TRUE( ent.isAiClone ) )
			return false;
	}
	if ( ( lengthsquared( ent getVelocity() ) < 10 ) && !isdefined( watcher.immediateDetonation ) )
		return false;
	
	if ( !ent shouldAffectWeaponObject( self, watcher ) )
		return false;
	
	if ( self isstunned() ) 
		return false;
	
	if( IsPlayer( ent ) )
	{
		if ( !IsAlive(ent) ) //Make sure player watching their killcam won't set it off
			return false;
	
		if ( isdefined( watcher.immunespecialty ) && ent hasPerk( watcher.immunespecialty ) )
			return false;
	}
	
	return true;
}

function	proximityWeaponObject_RemoveSpawnProtectOnDeath( ent )
{
	self endon("death");
	
	ent util::waittill_any("death", "disconnected");
	
	ArrayRemoveValue( self.protected_entities, ent );
}

function	proximityWeaponObject_SpawnProtect( watcher, ent )
{
	self endon("death");
	ent endon("death");
	ent endon("disconnect");
	
	self.protected_entities[self.protected_entities.size] = ent;
	
	// this function will not get cleaned up until either ent dies which should not cause problems
	self thread proximityWeaponObject_RemoveSpawnProtectOnDeath( ent );
	
	radius_sqr = watcher.detonateRadius * watcher.detonateRadius;
	
	while ( 1 )
	{
		if ( DistanceSquared( ent.origin, self.origin ) > radius_sqr )
		{
			ArrayRemoveValue( self.protected_entities, ent );
			return;
		}
		
		wait( 0.5 );
	}
}

function proximityWeaponObject_IsSpawnProtected( watcher, ent )
{
		if( !IsPlayer( ent ) )
			return false;
			
		foreach( protected_ent in self.protected_entities )
		{
			if ( protected_ent == ent )
				return true;
		}
		
		linked_to = self GetLinkedEnt();
		if (linked_to === ent )
			return false;

		if ( ent player::is_spawn_protected() )
		{
			self thread proximityWeaponObject_SpawnProtect( watcher, ent );
			return true;
		}
		
		return false;
}

function proximityWeaponObject_DoDetonation( watcher, ent, traceOrigin )
{	
	self endon( "death" );
	self endon( "hacked" );

	self notify( "kill_target_detection" );

	if ( isdefined(watcher.activateSound) )
	{
		self playsound (watcher.activateSound);
	}
	
	wait watcher.detectionGracePeriod;

	if ( IsPlayer( ent ) && ent HasPerk( "specialty_delayexplosive" ) )
	{
		wait( GetDvarfloat( "perk_delayExplosiveTime" ) );
	}
	
	self entityheadicons::setEntityHeadIcon("none");
	
	// move up one unit	
	self.origin = traceOrigin;
	
	if ( isdefined( self.owner ) && isplayer( self.owner ) )
	{	
		self [[watcher.onDetonateCallback]]( self.owner, undefined, ent );
	}
	else
	{
		self [[watcher.onDetonateCallback]]( undefined, undefined, ent );
	}
}

function proximityWeaponObject_ActivationDelay( watcher )
{
	self util::waitTillNotMoving();

	if ( watcher.activationDelay )
	{
		wait( watcher.activationDelay );
	}
}

function proximityWeaponObject_WaitTillFrameEndAndDoDetonation( watcher, ent, traceOrigin )
{
	self endon( "death" );

	dist = Distance( ent.origin, self.origin );
	
	if ( isdefined( self.activated_entity_distance ) )
	{
		if ( dist < self.activated_entity_distance )
		{
			// this is a closer target
			self notify( "better_target" );
		}
		else
		{
			// the other target was better
			return;
		}
	}
	
	self endon( "better_target" );
	self.activated_entity_distance = dist;
	
	// this allows anything that is in the trigger to have a chance to be the target
	// so we can pick the closest instead of just picking the first numerically
	wait(0.05);
	
	proximityWeaponObject_DoDetonation( watcher, ent, traceOrigin );
}

function proximityWeaponObjectDetonation( watcher )
{
	self endon( "death" );
	self endon( "hacked" );
	self endon( "kill_target_detection" );
	
	proximityWeaponObject_ActivationDelay( watcher );
	
	damagearea = proximityWeaponObject_CreateDamageArea( watcher );
	
	up = AnglesToUp( self.angles );
	traceOrigin = self.origin + up;

	while(1)
	{
		damagearea waittill("trigger", ent);
	
		if ( !proximityWeaponObject_ValidTriggerEntity( watcher, ent ) )
			continue;

		if ( proximityWeaponObject_IsSpawnProtected( watcher, ent ) )
			continue;
			
		if ( ent damageConeTrace( traceOrigin, self ) > 0 )
		{
			thread proximityWeaponObject_WaitTillFrameEndAndDoDetonation( watcher, ent, traceOrigin );
		}
	}
}

function shouldAffectWeaponObject( object, watcher )
{
	radius = object.weapon.explosionRadius;
	distanceSqr = DistanceSquared( self.origin, object.origin );
	
	// this fixes an issue where if the object is above head height
	// the players head can set it off but the radius damage check 
	// looks at the origin of the player
	if ( radius * radius < distanceSqr )
		return false;
	
	pos = self.origin + (0,0,32);
	
	if( isdefined( watcher.ignoreDirection ) )
	{
		return true;
	}

	dirToPos = pos - object.origin;
	objectForward = anglesToForward( object.angles );
	
	dist = vectorDot( dirToPos, objectForward );
	if ( dist < watcher.detectionMinDist )
		return false;
	
	dirToPos = vectornormalize( dirToPos );
	
	dot = vectorDot( dirToPos, objectForward );
	return ( dot > watcher.detectionDot );
}

function deleteOnDeath(ent)
{
	self util::waittill_any("death", "hacked");
		wait .05;
	if ( isdefined(ent) )
		ent delete();
}

function testKillbrushOnStationary( a_killbrushes, player ) // self == weaponobject
{
	player endon( "disconnect" );
	self endon( "death" );

	self waittill( "stationary" );
	
	foreach ( trig in a_killbrushes )
	{
		if ( isdefined( trig ) && self IsTouching( trig ) )
		{
			if ( !trig IsTriggerEnabled() )
			{
				continue;
			}
			
			if ( SPAWNFLAG( self, SPAWNFLAG_TRIGGER_HURT_PLAYER_ONLY ) )
			{
				continue;
			}
			
			if ( self.origin[ 2 ]  > player.origin[ 2 ] )
			{
				break;
			}

			if ( isdefined( self ) )
			{
				self delete();
			}

			return;
		}
	}
}

function deleteOnKillbrush(player)
{
	player endon( "disconnect" );
	self endon( "death" );
	self endon( "stationary" );
			
	a_killbrushes = GetEntArray( "trigger_hurt","classname" );

	self thread testKillbrushOnStationary( a_killbrushes, player );

	while( 1 )
	{
		a_killbrushes = GetEntArray( "trigger_hurt","classname" );

		for ( i = 0; i < a_killbrushes.size; i++)
		{
			if ( self IsTouching( a_killbrushes[ i ] ) )
			{		
				if ( !a_killbrushes[ i ] IsTriggerEnabled() )
				{
					continue;
				}
				
				if ( SPAWNFLAG( self, SPAWNFLAG_TRIGGER_HURT_PLAYER_ONLY ) )
				{
					continue;
				}
				
				if( self.origin[ 2 ] > player.origin[ 2 ] )
				{
					break;
				}

				if ( isdefined( self ) )
				{
					self delete();
				}

				return;
			}
		}
	
		wait 0.1;
	}	
}


function watchWeaponObjectAltDetonation() // self == player
{
	self endon("disconnect");

	while( 1 )
	{
		self waittill( "alt_detonate" );

		if ( !IsAlive( self ) || ( self util::isUsingRemote() ) )
		{
			continue;
		}
		
		for ( watcher = 0; watcher < self.weaponObjectWatcherArray.size; watcher++ )
		{
			if ( self.weaponObjectWatcherArray[watcher].altDetonate )
			{
				self.weaponObjectWatcherArray[watcher] detonateWeaponObjectArray( false );
			}
		}
	}
}


function watchWeaponObjectAltDetonate() // self == player
{
	self endon( "disconnect" );	
	level endon( "game_ended" );
	
	buttonTime = 0;
	for( ;; )
	{
		self waittill( "doubletap_detonate" );
		
		if ( !IsAlive( self ) && !( self util::isUsingRemote() ) )
		{
			continue;
		}
		
		self notify ( "alt_detonate" );
		
		WAIT_SERVER_FRAME;
	}
}

function watchWeaponObjectDetonation() // self == player
{
	self endon( "disconnect" );
	
	while( 1 )
	{
		self waittill( "detonate" );

		if ( self isUsingOffhand() )
		{
			weap = self getCurrentOffhand();
		}
		else
		{
			weap = self getCurrentWeapon();
		}

		watcher = getWeaponObjectWatcherByWeapon( weap );
		
		if ( isdefined( watcher ) )
		{
			if ( isdefined( watcher.onDetonationHandle ) )
			{
				self thread [[watcher.onDetonationHandle]]( watcher );
			}
			
			watcher detonateWeaponObjectArray( false );
		}
	}
}

function cleanUpWatchers()
{
	if ( !isdefined(self.weaponObjectWatcherArray) )
	{
		assert( "Can't clean Up watechers" );
		return;
	}
			
	watchers = [];
	
	// make a psudo copy of the watchers out of the player 
	// so that when the player ent gets cleaned we still have
	// the object arrays to clean up
	for ( watcher = 0; watcher < self.weaponObjectWatcherArray.size; watcher++ )
	{
		weaponObjectWatcher = SpawnStruct();
		watchers[watchers.size] = weaponObjectWatcher;
		weaponObjectWatcher.objectArray = [];
		
		if ( isdefined(  self.weaponObjectWatcherArray[watcher].objectArray ) )
		{
			weaponObjectWatcher.objectArray =  self.weaponObjectWatcherArray[watcher].objectArray;
		}
	}
	
	wait .05;
	
	for ( watcher = 0; watcher < watchers.size; watcher++ )
	{
		watchers[watcher] deleteWeaponObjectArray();
	}
}


function watchForDisconnectCleanUp()
{
	self waittill( "disconnect" );
	
	cleanUpWatchers();
}

function deleteWeaponObjectsOn() // self == player
{
	self thread watchForDisconnectCleanUp();

	self endon( "disconnect" );
	
	if( !isPlayer( self ))
	{
		return;
	}
	
	while(1)
	{
		msg = self util::waittill_any_return( "joined_team", "joined_spectators", "death" );	
		
		// only need this because util::waittill_any_return will endon death if we dont pass it in
		if ( msg == "death" )
			continue;

		cleanUpWatchers();
	}
}

function saydamaged(orig, amount)
{
}

function showHeadIcon( trigger )
{
	triggerDetectId = trigger.detectId;
	useId = -1;
	for ( index = 0; index < 4; index++ )
	{
		detectId = self.bombSquadIcons[index].detectId;

		if ( detectId == triggerDetectId )
			return;
			
		if ( detectId == "" )
			useId = index;
	}
	
	if ( useId < 0 )
		return;

	self.bombSquadIds[triggerDetectId] = true;
	
	self.bombSquadIcons[useId].x = trigger.origin[0];
	self.bombSquadIcons[useId].y = trigger.origin[1];
	self.bombSquadIcons[useId].z = trigger.origin[2]+24+128;

	self.bombSquadIcons[useId] fadeOverTime( 0.25 );
	self.bombSquadIcons[useId].alpha = 1;
	self.bombSquadIcons[useId].detectId = trigger.detectId;
	
	while ( isAlive( self ) && isdefined( trigger ) && self isTouching( trigger ) )
		WAIT_SERVER_FRAME;
		
	if ( !isdefined( self ) )
		return;
		
	self.bombSquadIcons[useId].detectId = "";
	self.bombSquadIcons[useId] fadeOverTime( 0.25 );
	self.bombSquadIcons[useId].alpha = 0;
	self.bombSquadIds[triggerDetectId] = undefined;
}

// returns true if damage should be done to the item given its owner and the attacker
function friendlyFireCheck( owner, attacker, forcedFriendlyFireRule )
{
	if ( !isdefined(owner) ) // owner has disconnected? allow it
		return true;
	
	if ( !level.teamBased ) // not a team based mode? allow it
		return true;

	friendlyFireRule = [[ level.figure_out_friendly_fire ]]( undefined ); // there is no victim here
	if ( isdefined( forcedFriendlyFireRule ) )
		friendlyFireRule = forcedFriendlyFireRule;
	
	if ( friendlyFireRule != 0 ) // friendly fire is on? allow it
		return true;
	
	if ( attacker == owner ) // owner may attack his own items
		return true;
	
	if ( isplayer( attacker ) )
	{
		if ( !isdefined(attacker.pers["team"])) // attacker not on a team? allow it
			return true;
		
		if ( attacker.pers["team"] != owner.pers["team"] ) // attacker not on the same team as the owner? allow it
			return true;
	}
	else if ( IsActor(attacker) )
	{
		if ( attacker.team != owner.pers["team"] ) // attacker not on the same team as the owner? allow it
			return true; 
	}	
	else if ( isvehicle( attacker ) )
	{
		if ( isdefined(attacker.owner) && IsPlayer(attacker.owner) )
		{
			if ( attacker.owner.pers["team"] != owner.pers["team"] )
				return true;
		}
		else
		{
			occupant_team = attacker vehicle::vehicle_get_occupant_team();
			if ( occupant_team != owner.pers["team"] && occupant_team != "spectator" ) // attacker not on the same team as the owner? allow it
				return true; 
		}
	}	

	return false; // disallow it
}

function onSpawnHatchet( watcher, player )
{
	if ( isdefined( level.playThrowHatchet ) )
	{
		player [[level.playThrowHatchet]]();
	}
}

function onSpawnCrossbowBolt( watcher, player )
{
	self.delete_on_death = true;
	self thread onSpawnCrossbowBolt_internal( watcher, player );
}

function onSpawnCrossbowBolt_internal( watcher, player )
{
	player endon( "disconnect" );
	self endon( "death" );
	
	wait 0.25; // wait before setting takedamage

	linkedEnt = self GetLinkedEnt();
	if ( !isdefined( linkedEnt ) || !IsVehicle( linkedEnt ) )
	{
		self.takedamage = false;
	}
	else
	{
		self.takedamage = true;
		
		if ( IsVehicle( linkedEnt ) )
		{
			self thread dieOnEntityDeath( linkedEnt, player );
		}
	}
}

function dieOnEntityDeath( entity, player )
{
	player endon( "disconnect" );
	self endon( "death" );
	
	alreadyDead = ( ( entity.dead === true ) || ( isdefined( entity.health ) && entity.health < 0 ) );
	
	if ( !alreadyDead )
	{
		entity waittill( "death" );
	}

	self notify( "death" );
}

function onSpawnCrossbowBoltImpact( s_watcher, e_player )
{
	self.delete_on_death = true;
	self thread onSpawnCrossbowBoltImpact_internal( s_watcher, e_player );
}

// PORTIZ 7/5/16: crossbow bolt will be deleted when it impacts
function onSpawnCrossbowBoltImpact_internal( s_watcher, e_player )
{
	self endon( "death" );
	e_player endon( "disconnect" );
	
	self waittill( "stationary" );
	
	s_watcher thread waitAndFizzleOut( self, 0 ); // use fizzle out to make use of existing FX and logic
	
	foreach ( n_index, e_object in s_watcher.objectarray )
	{
		if ( self == e_object )
		{
			s_watcher.objectarray[ n_index ] = undefined;
		}
	}
	
	cleanWeaponObjectArray( s_watcher );
}

function onSpawnSpecialCrossbowTrigger( watcher, player ) // self == weapon_instance (for example: the claymore)
{
	self endon( "death" );

	self SetOwner( player );
	self SetTeam( player.pers["team"] );
	self.owner = player;
	self.oldAngles = self.angles;

	self util::waitTillNotMoving();
	waittillframeend;

	if( player.pers["team"] == "spectator" )
	{
		return;
	}
	
	triggerOrigin = self.origin;
	triggerParentEnt = undefined;

	if ( isdefined( self.stuckToPlayer ) )
	{
		if ( IsAlive( self.stuckToPlayer ) || !isdefined( self.stuckToPlayer.body ) )
		{
			if ( IsAlive( self.stuckToPlayer ) )
			{
				// Drop the arrow to the ground if it doesn't kill the player.
				triggerParentEnt = self;
				self Unlink();
				self.angles = self.oldAngles;
				self launch( (5,5,5) );
				self util::waitTillNotMoving();
				waittillframeend;
			}
			else
			{
				triggerParentEnt = self.stuckToPlayer;
			}
		}
		else
		{
			triggerParentEnt = self.stuckToPlayer.body;
		}
	}
	
	if ( isdefined( triggerParentEnt ) )
		triggerOrigin = triggerParentEnt.origin + ( 0, 0, 10 );

	if ( self.weapon.ShownRetrievable )
	{
		self clientfield::set( "retrievable", 1 );
	}
	
	self.hatchetPickUpTrigger = spawn( "trigger_radius", triggerOrigin, 0, 50, 50 );

	self.hatchetPickUpTrigger EnableLinkTo();
	self.hatchetPickUpTrigger LinkTo( self );

	if ( isdefined( triggerParentEnt ) )
	{
		self.hatchetPickUpTrigger linkto( triggerParentEnt );
	}

	self thread watchSpecialCrossbowTrigger( self.hatchetPickUpTrigger, watcher.pickUp, watcher.pickUpSoundPlayer, watcher.pickUpSound );

	self thread watchShutdown( player );
}

function watchSpecialCrossbowTrigger( trigger, callback, playerSoundOnUse, npcSoundOnUse ) // self == weapon (for example: the claymore)
{
	self endon( "delete" );
	self endon( "hacked" );

	while ( true )
	{
		trigger waittill( "trigger", player );
			
		if ( !isAlive( player ) )
			continue;
			
		if ( isdefined( trigger.claimedBy ) && ( player != trigger.claimedBy ) )
			continue;
		
		crossbow_weapon = player get_player_crossbow_weapon();
		if ( !isdefined( crossbow_weapon ) )
			continue;
		
		stock_ammo = player GetWeaponAmmoStock( crossbow_weapon );
		if( stock_ammo >= crossbow_weapon.maxammo )
			continue;

		if ( isdefined( playerSoundOnUse ) )
			player playLocalSound( playerSoundOnUse );
		if ( isdefined( npcSoundOnUse ) )
			player playSound( npcSoundOnUse );

		self thread [[callback]]( player, crossbow_weapon );
	}
}

function onSpawnHatchetTrigger( watcher, player ) // self == weapon_instance (for example: the claymore)
{
	self endon( "death" );

	self SetOwner( player );
	self SetTeam( player.pers["team"] );
	self.owner = player;
	self.oldAngles = self.angles;

	self util::waitTillNotMoving();
	waittillframeend;

	if( player.pers["team"] == "spectator" )
	{
		return;
	}
	
	triggerOrigin = self.origin;
	triggerParentEnt = undefined;

	if ( isdefined( self.stuckToPlayer ) )
	{
		if ( IsAlive( self.stuckToPlayer ) || !isdefined( self.stuckToPlayer.body ) )
		{
			if ( IsAlive( self.stuckToPlayer ) )
			{
				// Drop the hatchet to the ground if it doesn't kill the player.
				triggerParentEnt = self;
				self Unlink();
				self.angles = self.oldAngles;
				self launch( (5,5,5) );
				self util::waitTillNotMoving();
				waittillframeend;
			}
			else
			{
				triggerParentEnt = self.stuckToPlayer;
			}
		}
		else
		{
			triggerParentEnt = self.stuckToPlayer.body;
		}
	}
	
	if ( isdefined( triggerParentEnt ) )
		triggerOrigin = triggerParentEnt.origin + ( 0, 0, 10 );

	if ( self.weapon.ShownRetrievable )
	{
		self clientfield::set( "retrievable", 1 );
	}
	
	self.hatchetPickUpTrigger = spawn( "trigger_radius", triggerOrigin, 0, 50, 50 );

	self.hatchetPickUpTrigger EnableLinkTo();
	self.hatchetPickUpTrigger LinkTo( self );

	if ( isdefined( triggerParentEnt ) )
	{
		self.hatchetPickUpTrigger linkto( triggerParentEnt );
	}

	self thread watchHatchetTrigger( self.hatchetPickUpTrigger, watcher.pickUp, watcher.pickUpSoundPlayer, watcher.pickUpSound );

	self thread watchShutdown( player );
}

function watchHatchetTrigger( trigger, callback, playerSoundOnUse, npcSoundOnUse ) // self == weapon (for example: the claymore)
{
	self endon( "delete" );
	self endon( "hacked" );

	while ( true )
	{
		trigger waittill( "trigger", player );
			
		if ( !isAlive( player ) )
			continue;
			
		if ( !player isOnGround() && !player IsPlayerSwimming() )
			continue;
			
		if ( isdefined( trigger.claimedBy ) && ( player != trigger.claimedBy ) )
			continue;

		heldWeapon = player get_held_weapon_match_or_root_match( self.weapon ); 
		if ( !IsDefined( heldWeapon ) )
		{
			continue;
		}

		maxAmmo = 0;
		
		if ( heldWeapon == player.grenadeTypePrimary && isdefined( player.grenadeTypePrimaryCount ) && player.grenadeTypePrimaryCount > 0 )
		{
			maxAmmo = player.grenadeTypePrimaryCount;
		}
		else if ( heldWeapon == player.grenadeTypeSecondary && isdefined( player.grenadeTypeSecondaryCount ) && player.grenadeTypeSecondaryCount > 0 )
		{
			maxAmmo = player.grenadeTypeSecondaryCount;
		}
		
		if ( maxAmmo == 0 )
		{
			continue;
		}
		
		clip_ammo = player GetWeaponAmmoClip( heldWeapon );

		if( clip_ammo >= maxAmmo )
		{
			continue;
		}

		if ( isdefined( playerSoundOnUse ) )
			player playLocalSound( playerSoundOnUse );
		if ( isdefined( npcSoundOnUse ) )
			player playSound( npcSoundOnUse );

		self thread [[callback]]( player );
	}
}

function get_held_weapon_match_or_root_match( weapon )
{
	pweapons = self GetWeaponsList( true ); 
	
	foreach( pweapon in pweapons )
	{
		if ( pweapon == weapon )
		{
			return pweapon; 
		}
	}
	
	foreach( pweapon in pweapons )
	{
		if ( pweapon.rootweapon == weapon.rootweapon )
		{
			return pweapon; 
		}
	}
	
	return undefined; 
}

function get_player_crossbow_weapon()
{
	pweapons = self GetWeaponsList( true ); 

	crossbow = GetWeapon( "special_crossbow" );
	crossbow_dw = GetWeapon( "special_crossbow_dw" );	
	// crossbowlh = GetWeapon( "special_crossbowlh" ); // doesn't seem to be needed
	
	foreach( pweapon in pweapons )
	{
		if ( pweapon.rootweapon == crossbow || pweapon.rootweapon == crossbow_dw )
		{
			return pweapon; 
		}
	}
	
	return undefined; 	
}

function onSpawnRetrievableWeaponObject( watcher, player ) // self == weapon (for example: the claymore)
{
	self endon( "death" );
	self endon( "hacked" );

	self SetOwner( player );
	self SetTeam( player.pers["team"] );
	self.owner = player;
	self.oldAngles = self.angles;

	self util::waitTillNotMoving();

	if ( watcher.activationDelay )
	{
		wait( watcher.activationDelay );
	}

	waittillframeend;

	if(player.pers["team"] == "spectator")
	{
		return;
	}
	
	triggerOrigin = self.origin;
	triggerParentEnt = undefined;
	if ( isdefined( self.stuckToPlayer ) )
	{
		if ( IsAlive( self.stuckToPlayer ) || !isdefined( self.stuckToPlayer.body ) )
		{
			triggerParentEnt = self.stuckToPlayer;
		}
		else
		{
			triggerParentEnt = self.stuckToPlayer.body;
		}
	}
	
	if ( isdefined( triggerParentEnt ) )
	{
		triggerOrigin = triggerParentEnt.origin + ( 0, 0, 10 );
	}
	else
	{
		// move the trigger 1 unit along the up axis to prevent the it
		// from failing the sight trace in player_use
		up = AnglesToUp( self.angles );
		triggerOrigin = self.origin + up;
	}
	
	if ( !self util::isHacked() )
	{
		if ( self.weapon.ShownRetrievable )
		{
			self clientfield::set( "retrievable", 1 );
		}
	
		self.pickUpTrigger = spawn( "trigger_radius_use", triggerOrigin );
		self.pickUpTrigger SetHintLowPriority( true );
		self.pickUpTrigger SetCursorHint( "HINT_NOICON", self );
		self.pickUpTrigger EnableLinkTo();
		self.pickUpTrigger LinkTo( self );
		self.pickUpTrigger SetInvisibleToAll();
		self.pickUpTrigger SetVisibleToPlayer( player );
		
		if( isdefined(level.retrieveHints[watcher.name]) )
		{
			self.pickUpTrigger SetHintString( level.retrieveHints[watcher.name].hint );
		}
		else
		{
			self.pickUpTrigger SetHintString( &"MP_GENERIC_PICKUP" );
		}
	
		self.pickUpTrigger SetTeamForTrigger( player.pers["team"] );
		
		if ( isdefined( triggerParentEnt ) )
		{
			self.pickUpTrigger linkto( triggerParentEnt );
		}
		
		self thread watchUseTrigger( self.pickUpTrigger, watcher.pickUp, watcher.pickUpSoundPlayer, watcher.pickUpSound );
		
		if ( isdefined( watcher.pickup_trigger_listener ) )
		{
			self thread [[watcher.pickup_trigger_listener]]( self.pickUpTrigger, player );
		}
	}	

	if ( watcher.enemyDestroy )
	{
		self.enemyTrigger = spawn( "trigger_radius_use", triggerOrigin );
		self.enemyTrigger SetCursorHint( "HINT_NOICON", self );
		self.enemyTrigger EnableLinkTo();
		self.enemyTrigger LinkTo( self );
		self.enemyTrigger SetInvisibleToPlayer( player );

		if ( level.teamBased )
		{
			self.enemyTrigger SetExcludeTeamForTrigger( player.team );
			self.enemyTrigger.triggerTeamIgnore = self.team;
		}

		if( isdefined(level.destroyHints[watcher.name]) )
		{
			self.enemyTrigger SetHintString( level.destroyHints[watcher.name].hint );
		}
		else
		{
			self.enemyTrigger SetHintString( &"MP_GENERIC_DESTROY" );
		}

		self thread watchUseTrigger( self.enemyTrigger, watcher.onDestroyed );
	}	

	self thread watchShutdown( player );
}

function destroyEnt()
{
	self delete();
}

function pickUp( player ) // self == weapon_instance (for example: the claymore)
{
	if ( !self.weapon.anyPlayerCanRetrieve && isdefined( self.owner ) && self.owner != player )
	{
		return;
	}	
	
	pikedWeapon = self.weapon;
	
	if ( self.weapon.ammoCountEquipment > 0 && isdefined( self.ammo ) )
	{
		ammoLeftEquipment = self.ammo;
	}
	
	self notify( "picked_up" );
	self.playDialog = false;
	self destroyEnt();	
	
	heldWeapon = player get_held_weapon_match_or_root_match( self.weapon ); 	
	if ( !IsDefined( heldWeapon ) )
	{
		return;
	}	
	
	maxAmmo = 0;
		
	if ( heldWeapon == player.grenadeTypePrimary && isdefined( player.grenadeTypePrimaryCount ) && player.grenadeTypePrimaryCount > 0 )
	{
		maxAmmo = player.grenadeTypePrimaryCount;
	}
	else if ( heldWeapon == player.grenadeTypeSecondary && isdefined( player.grenadeTypeSecondaryCount ) && player.grenadeTypeSecondaryCount > 0 )
	{
		maxAmmo = player.grenadeTypeSecondaryCount;
	}
	
	if ( maxAmmo == 0 )
	{
		return;
	}
	
	clip_ammo = player GetWeaponAmmoClip( heldWeapon );

	if( clip_ammo < maxAmmo )
	{
		clip_ammo++;
	}	
	
	if ( isdefined ( ammoLeftEquipment ) )
	{
		if ( pikedWeapon.rootWeapon == GetWeapon( "trophy_system" ) )
		{
			player trophy_system::ammo_weapon_pickup( ammoLeftEquipment );
		}
	}	
	
	player setWeaponAmmoClip( heldWeapon, clip_ammo );
}

function pickUpCrossbowBolt( player, heldWeapon ) // self == weapon_instance (for example: the crossbow bolt)
{
	self notify( "picked_up" );
	self.playDialog = false;
	self destroyEnt();	

	// note: ammo limits should be regulated in watchSpecialCrossbowTrigger
	stock_ammo = player GetWeaponAmmoStock( heldWeapon );
	stock_ammo++;
	player SetWeaponAmmoStock( heldWeapon, stock_ammo );
}

function onDestroyed( attacker ) // self == weapon object
{
	PlayFX( level._effect["tacticalInsertionFizzle"], self.origin );
	self playsound ("dst_tac_insert_break");

	if( isdefined( level.playEquipmentDestroyedOnPlayer ) )
	{
		self.owner [[level.playEquipmentDestroyedOnPlayer]]();
	}	
	
	self delete(); // will call watchShutdow() to clean up the trigger ents
}

function watchShutdown( player ) // self == weapon (for example: the claymore)
{
	self util::waittill_any( "death", "hacked", "detonating" );

	pickUpTrigger = self.pickUpTrigger;
	hackerTrigger = self.hackerTrigger;
	hatchetPickUpTrigger = self.hatchetPickUpTrigger;
	enemyTrigger = self.enemyTrigger;
	
	if( isdefined( pickUpTrigger ) )
		pickUpTrigger delete();

	if( isdefined( hackerTrigger ) )
	{
		if ( isdefined( hackerTrigger.progressBar ) )
		{
			hackerTrigger.progressBar hud::destroyElem();
			hackerTrigger.progressText hud::destroyElem();
		}
		hackerTrigger delete();
	}

	if( isdefined( hatchetPickUpTrigger ) )
		hatchetPickUpTrigger delete();

	if ( isdefined( enemyTrigger ))
	{
		enemyTrigger delete();
	}
}

function watchUseTrigger( trigger, callback, playerSoundOnUse, npcSoundOnUse ) // self == weapon (for example: the claymore)
{
	self endon( "delete" );
	self endon( "hacked" );
	
	while ( true )
	{
		trigger waittill( "trigger", player );
			
		if ( isdefined( self.detonated ) && self.detonated == true )
		{
			if ( isdefined( trigger ) )
			{
				trigger delete();
			}
			return;
		}
		
		if ( !isAlive( player ) )
			continue;		
				
		if ( isdefined( trigger.triggerTeam ) && ( player.pers["team"] != trigger.triggerTeam ) )
			continue;
			
		if ( isdefined( trigger.triggerTeamIgnore ) && ( player.team == trigger.triggerTeamIgnore ) )
			continue;

		if ( isdefined( trigger.claimedBy ) && ( player != trigger.claimedBy ) )
			continue;

		grenade = player.throwingGrenade;
		weapon = player GetCurrentWeapon();

		if ( weapon.isEquipment )
		{
			grenade = false;
		}
			
		if ( player useButtonPressed() && !grenade && !player meleeButtonPressed() )
		{
			if ( isdefined( playerSoundOnUse ) )
				player playLocalSound( playerSoundOnUse );
			if ( isdefined( npcSoundOnUse ) )
				player playSound( npcSoundOnUse );
			self thread [[callback]]( player );
		}
	}
}

function createRetrievableHint(name, hint)
{
	retrieveHint = spawnStruct();

	retrieveHint.name = name;
	retrieveHint.hint = hint;

	level.retrieveHints[name] = retrieveHint;
}

function createHackerHint(name, hint)
{
	hackerHint = spawnStruct();

	hackerHint.name = name;
	hackerHint.hint = hint;

	level.hackerHints[name] = hackerHint;
}

function createDestroyHint(name, hint)
{
	destroyHint = spawnStruct();

	destroyHint.name = name;
	destroyHint.hint = hint;

	level.destroyHints[name] = destroyHint;
}

function setupReconEffect()
{
	if ( !isdefined( self ) )
		return;
		
	if ( self.weapon.ShownEnemyExplo || self.weapon.ShownEnemyEquip )
	{
		if( IS_TRUE( self.hacked ) )
		{
			self clientfield::set( "enemyequip", ENEMY_EQUIPMENT_SHADER_HACKED );
		}
		else
		{
			self clientfield::set( "enemyequip", ENEMY_EQUIPMENT_SHADER_ACTIVE );
		}
	}
}

function useTeamEquipmentClientField( watcher )
{
	if ( isdefined( watcher ) )
	{
		if ( !isdefined( watcher.notEquipment ) )
		{
			if ( isdefined( self ) )
			{
				//if ( self.type == "missile" )
				{
					return true;
				}
			}
		}
	}	
	
	return false;
}

function GetWatcherForWeapon( weapon )
{
	if ( !isdefined( self ) )
	{
		return undefined;
	}

	if ( !IsPlayer( self ) )
	{
		return undefined;
	}

	for ( i = 0; i < self.weaponObjectWatcherArray.size; i++ )
	{
		if ( self.weaponObjectWatcherArray[i].weapon != weapon )
		{ 
			continue;
		}

		return ( self.weaponObjectWatcherArray[i] );
	}

	return undefined;
}

// secondary items which need to be cleaned up during an emp
// most primary watcher items are in the level.missileEntities list
function destroy_other_teams_supplemental_watcher_objects( attacker, weapon )
{
	if( level.teamBased )
	{
		foreach( team in level.teams )
		{
			if( team == attacker.team )
			{
				continue;
			}
				
			destroy_supplemental_watcher_objects( attacker, team, weapon );
		}
	}
	
	destroy_supplemental_watcher_objects( attacker, "free", weapon );
}

function destroy_supplemental_watcher_objects( attacker, team, weapon )
{
	foreach ( item in level.supplementalWatcherObjects )
	{
		if ( !isdefined( item.weapon ) )
		{
			continue;
		}

		if ( !isdefined( item.owner ) )
		{
			continue;
		}

		if ( isdefined( team ) && item.owner.team != team ) 
		{
			continue;
		}
		else if ( item.owner == attacker )
		{
			continue;
		}

		watcher = item.owner getWatcherForWeapon( item.weapon );

		if ( !isdefined( watcher ) || !IsDefined( watcher.onSupplementalDetonateCallback ) )
		{
			continue;
		}

		item thread [[watcher.onSupplementalDetonateCallback]]();
	}
}

function add_supplemental_object( object )
{
	level.supplementalWatcherObjects[ level.supplementalWatcherObjects.size ] = object;
	object thread watch_supplemental_object_death();
}

function watch_supplemental_object_death() // self == object
{
	self waittill( "death" );
	ArrayRemoveValue( level.supplementalWatcherObjects, self ); 
}

