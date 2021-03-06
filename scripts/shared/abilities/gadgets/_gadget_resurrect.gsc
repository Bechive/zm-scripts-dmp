#using scripts\codescripts\struct;

#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\flagsys_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\visionset_mgr_shared;
#using scripts\shared\weapons\_smokegrenade;
#using scripts\shared\_oob;

#using scripts\shared\abilities\_ability_player;
#using scripts\shared\abilities\_ability_power;
#using scripts\shared\abilities\_ability_util;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;
#insert scripts\shared\abilities\_ability_util.gsh;
#insert scripts\shared\abilities\gadgets\_gadget_resurrect.gsh;

#namespace resurrect;

REGISTER_SYSTEM( "gadget_resurrect", &__init__, undefined )

#precache( "fx", RESURRECT_WORLD_HINT_FX );
#precache( "fx", RESURRECT_BODY_DISSAPPEAR_FX );
#precache( "fx", RESURRECT_SPAWN_FX );
#precache( "fx", RESURRECT_SMOKE_FX );

#precache( "eventstring", "create_rejack_timer" );

function __init__()
{
	clientfield::register( "allplayers", "resurrecting" , VERSION_SHIP, 1, "int" );
	clientfield::register( "toplayer", "resurrect_state" , VERSION_SHIP, RESURRECT_STATE_BITS, "int" );
	clientfield::register( "clientuimodel", "hudItems.rejack.activationWindowEntered", VERSION_SHIP, 1, "int" );
	clientfield::register( "clientuimodel", "hudItems.rejack.rejackActivated", VERSION_SHIP, 1, "int" );
	
	ability_player::register_gadget_activation_callbacks( GADGET_TYPE_RESURRECT, &gadget_resurrect_on, &gadget_resurrect_off );
	ability_player::register_gadget_possession_callbacks( GADGET_TYPE_RESURRECT, &gadget_resurrect_on_give, &gadget_resurrect_on_take );
	ability_player::register_gadget_flicker_callbacks( GADGET_TYPE_RESURRECT, &gadget_resurrect_on_flicker );
	ability_player::register_gadget_is_inuse_callbacks( GADGET_TYPE_RESURRECT, &gadget_resurrect_is_inuse );
	ability_player::register_gadget_is_flickering_callbacks( GADGET_TYPE_RESURRECT, &gadget_resurrect_is_flickering );
	ability_player::register_gadget_primed_callbacks( GADGET_TYPE_RESURRECT, &gadget_resurrect_is_primed );
	ability_player::register_gadget_ready_callbacks( GADGET_TYPE_RESURRECT, &gadget_resurrect_is_ready );
	
	callback::on_connect( &gadget_resurrect_on_connect );
	callback::on_spawned( &gadget_resurrect_on_spawned );
	
	if ( !IsDefined( level.vsmgr_prio_visionset_resurrect ) )
	{
		level.vsmgr_prio_visionset_resurrect = RESURRECT_VISIONSET_PRIORITY;
	}
	
	if ( !IsDefined( level.vsmgr_prio_visionset_resurrect_up ) )
	{
		level.vsmgr_prio_visionset_resurrect_up = RESURRECT_VISIONSET_UP_PRIORITY;
	}
	
	visionset_mgr::register_info( "visionset", RESURRECT_VISIONSET_ALIAS, VERSION_SHIP, level.vsmgr_prio_visionset_resurrect, RESURRECT_VISIONSET_STEPS, true, &visionset_mgr::ramp_in_out_thread_per_player_death_shutdown, false );
	visionset_mgr::register_info( "visionset", RESURRECT_VISIONSET_UP_ALIAS, VERSION_SHIP, level.vsmgr_prio_visionset_resurrect_up, RESURRECT_VISIONSET_UP_STEPS, true, &visionset_mgr::ramp_in_out_thread_per_player_death_shutdown, false );
}

function gadget_resurrect_is_inuse( slot )
{
	return self GadgetIsActive( slot );
}

function gadget_resurrect_is_flickering( slot )
{
	return self GadgetFlickering( slot );
}

function gadget_resurrect_on_flicker( slot, weapon )
{
}

function gadget_resurrect_on_give( slot, weapon )
{
	self.usedResurrect = false;
	self.resurrect_weapon = weapon;
	//self.overridePlayerDeadStatus = &gadget_resurrect_is_player_predead;
	//self.secondaryDeathCamTime = &gadget_resurrect_secondary_deathcam_time;	
}

function gadget_resurrect_on_take( slot, weapon )
{
	// executed when gadget is removed from the players inventory
	
	self.overridePlayerDeadStatus = undefined;
	self.resurrect_weapon = undefined;	
	self.secondaryDeathCamTime = undefined;
	
	self notify("resurrect_taken");
}

//self is the player
function gadget_resurrect_on_spawned()
{
	self clientfield::set_player_uimodel( "hudItems.rejack.activationWindowEntered", 0 );
	self util::show_hud( 1 ); 
	self._disable_proximity_alarms = false;
	// executed when gadget is added to the players inventory
	self flagsys::clear( "gadget_resurrect_ready" );
	self flagsys::clear( "gadget_resurrect_pending" );
	
	if ( self flagsys::get( "gadget_resurrect_activated" ) )
	{
		self thread do_resurrected_on_spawned_player_fx();
		
		self thread resurrect_drain_power();
		
		self flagsys::clear( "gadget_resurrect_activated" ); 
	}
}

function resurrect_drain_power( amount )
{
	if ( isdefined( self.resurrect_weapon ) )
	{
		slot = self GadgetGetSlot( self.resurrect_weapon );
		if ( slot >= GADGET_HELD_0 && slot < GADGET_HELD_COUNT )
		{
			if ( IsDefined( amount ))
			{
				self GadgetPowerChange( slot, amount );
			}
			else
			{
				self GadgetStateChange( slot, self.resurrect_weapon, GADGET_ACTION_ON );
			}			
		}
	}	
}

//self is the player
function gadget_resurrect_on_connect()
{
	// setup up stuff on player connect
}

function gadget_resurrect_on( slot, weapon )
{
	// excecutes when the gadget is turned on
}

function watch_smoke_detonate()
{
	self endon( "player_input_suicide" );
	self endon( "player_input_revive" );
	self endon( "disconnect" );
	self endon( "death" );
	level endon("game_ended");
	
	while( 1 ) 
	{
		if( ( ( self IsPlayerSwimming() ) || ( self isOnGround() ) ) && !( self iswallrunning() ) && !( self istraversing() ) )
		{
			smoke_weapon = GetWeapon( RESURRECT_SMOKE_WEAPON_NAME );
			stat_weapon = GetWeapon( RESURRECT_WEAPON_NAME );
			smokeEffect = smokegrenade::smokeDetonate( self, stat_weapon, smoke_weapon, self.origin, REJACK_SMOKE_SIGHT_BLOCK_RADIUS, REJACK_SMOKE_FX_LIFETIME_SECONDS, REJACK_SMOKE_SIGHT_BLOCK_TIME );
			smokeEffect thread watch_smoke_effect_watch_suicide( self );
			smokeEffect thread watch_smoke_effect_watch_resurrect( self );
			smokeEffect thread watch_smoke_death( self );
			return;
		}
		
		WAIT_SERVER_FRAME;
	}
}

function watch_smoke_death( player ) // self is effect
{
	self endon( "death" );
	
	player util::waittill_any_timeout( REJACK_SMOKE_FX_LIFETIME_SECONDS, "disconnect", "death" );
	
	self delete();
}

function watch_smoke_effect_watch_suicide( player ) // self is effect
{
	self endon( "death" );
	
	player waittill ( "player_input_suicide" );
	
	self delete();
}

function watch_smoke_effect_watch_resurrect( player ) // self is effect
{
	self endon( "death" );
	
	player waittill ( "player_input_revive" );
	
	wait( REJACK_SMOKE_FX_LIFETIME_AFTER_REJACK );
	
	self delete();
}

function gadget_resurrect_is_primed( slot, weapon ) // self == player
{
	if ( isdefined( self.resurrect_not_allowed_by ) )
		return;

	self StartResurrectViewAngleTransition();
	self.lastWaterDamageTime = GetTime();
	self._disable_proximity_alarms = true;
	self thread watch_smoke_detonate();
	self util::show_hud( 0 ); 
	visionset_mgr::activate( "visionset", RESURRECT_VISIONSET_ALIAS, self, RESURRECT_VISIONSET_RAMP_IN, RESURRECT_VISIONSET_RAMP_HOLD, RESURRECT_VISIONSET_RAMP_OUT );
	self clientfield::set_to_player( "resurrect_state", RESURRECT_STATE_DOWN );
	self shellshock( RESURRECT_SHELLSHOCK, REJACK_ACTIVATION_WINDOW_SECONDS + REJACK_ACTIVATION_DELAY_SECONDS, false );
}

function gadget_resurrect_is_ready( slot, weapon )
{
	return; 

	self flagsys::set( "gadget_resurrect_ready" );
	self thread resurrect_breadcrumbs( slot );
	self thread resurrect_watch_for_death( slot,weapon );
}

function gadget_resurrect_start( slot, weapon )
{
	wait 0.1;
	self GadgetSetActivateTime( slot, GetTime() );
	self thread resurrect_delay( weapon );
}

function gadget_resurrect_off( slot, weapon )
{
	self notify( "gadget_resurrect_off" );
	
	// excecutes when the gadget is turned off
}

function resurrect_delay( weapon )
{
	self endon ( "disconnect" );
	self endon("game_ended");
	self endon ( "death" );
	
	self notify( "resurrect_delay" );
	self endon( "resurrect_delay" );
	
}

function overrideSpawn(isPredictedSpawn)
{	
	if ( !self flagsys::get( "gadget_resurrect_ready" ) )
		return false;
	if ( !self flagsys::get( "gadget_resurrect_activated" ) )
		return false;

	if (!IsDefined(	self.resurrect_origin ))
	{
		self.resurrect_origin = self.origin;
		self.resurrect_angles = self.angles;
	}
	
	return true;
}


function is_jumping()
{
	// checking PMF_JUMPING in code would give more accurate results
	ground_ent = self GetGroundEnt();
	return (!isdefined(ground_ent));
}


function player_position_valid()
{
	//if ( self IsWallRunning() || self is_jumping() )
		//return false;
	if ( self clientfield::get_to_player( "out_of_bounds" ) )
		return false;
	
	return true;
}


function resurrect_breadcrumbs(slot)
{
	self endon("disconnect");
	self endon("game_ended");
	self endon("resurrect_taken");
	self.resurrect_slot = slot;

	while(1)
	{
		if (IsAlive(self) && self player_position_valid() )
		{
			self.resurrect_origin = self.origin;
			self.resurrect_angles = self.angles;
		}
		wait 1;
	}
	
}


function glow_for_time( time )
{
	self endon("disconnect");
	self clientfield::set( "resurrecting", 1 );
	wait time;
	self clientfield::set( "resurrecting", 0 );
}

function wait_for_time( time, msg )
{
	self endon("disconnect");
	self endon("game_ended");
	
	self endon(msg);
	wait time;
	self notify(msg);
}

function wait_for_activate( msg )
{
	self endon("disconnect");
	self endon("game_ended");
	
	self endon(msg);
	while(1)
	{
		if ( self OffhandSpecialButtonPressed() )
		{
			self flagsys::set( "gadget_resurrect_activated" ); 
			self notify(msg);
		}
		WAIT_SERVER_FRAME;
	}
}

function bot_wait_for_activate( msg, time )
{
	self endon("disconnect");
	self endon("game_ended");
	
	self endon(msg);
	
	if ( !self util::is_bot() )
	{
		return;
	}	
	
	time = int( time + 1 );
	
	randWait = RandomInt( time );
	
	wait randWait;
	
	self flagsys::set( "gadget_resurrect_activated" ); 
	self notify(msg);	
}

function do_resurrect_hint_fx()
{
	offset = (0,0,40);
	fxOrg = spawn( "script_model", self.resurrect_origin + offset );
	fxOrg SetModel( "tag_origin" );

	fx = PlayFxOnTag( RESURRECT_WORLD_HINT_FX, fxOrg, "tag_origin" );
	
	self waittill("resurrect_time_or_activate");	
	
	fxOrg delete();
}

function do_resurrected_on_dead_body_fx()
{
	if ( isdefined( self.body ) )
	{
		fx = PlayFx( RESURRECT_BODY_DISSAPPEAR_FX, self.body.origin );
		
		self.body NotSolid();
		self.body Ghost();
	}	
}

function do_resurrected_on_spawned_player_fx()
{
	playsoundatposition( RESURRECT_SPAWN_SOUND, self.origin );
	
	fx = PlayFx( RESURRECT_SPAWN_FX, self.origin );
}

function resurrect_watch_for_death( slot, weapon )
{
	self endon("disconnect");
	self endon("game_ended");

	self waittill("death"); 
	
	resurrect_time = 3;
	
	if ( IsDefined( weapon.gadget_resurrect_duration) )
	{
		resurrect_time = weapon.gadget_resurrect_duration / 1000.0;
	}
	
	self.usedResurrect = false;
	
	self flagsys::clear( "gadget_resurrect_activated" );
	self flagsys::set( "gadget_resurrect_pending" );
	self.resurrect_available_time = GetTime();
	
	self thread wait_for_time(resurrect_time,"resurrect_time_or_activate");
	
	self thread wait_for_activate("resurrect_time_or_activate");
	self thread bot_wait_for_activate("resurrect_time_or_activate", resurrect_time );
	
	self thread do_resurrect_hint_fx();
	
	self waittill("resurrect_time_or_activate");
	
	self flagsys::clear( "gadget_resurrect_pending" );
	
	if ( self flagsys::get( "gadget_resurrect_activated" ) )
	{
		self thread do_resurrected_on_dead_body_fx();
		
		self notify ( "end_death_delay" );
		self notify ( "end_killcam" );
		
		self.cancelKillcam = true;
		self.usedResurrect = true;
		
		self notify ( "end_death_delay" );
		self notify( "force_spawn" );
		
		if ( !IS_TRUE( REJACK_RESET_SCORESTREAK ) )
		{
			self.pers["resetMomentumOnSpawn"] = false;
		}
		
		if ( isdefined( level.playGadgetSuccess ) )
	    {
			self [[ level.playGadgetSuccess ]]( weapon, "resurrectSuccessDelay" );
		}
		
		//self thread glow_for_time( 7 );
	}
}



function gadget_resurrect_delay_updateTeamStatus()
{
	if ( self flagsys::get( "gadget_resurrect_ready" ) )
	{
		return true;
	}
	
	return false;
}

function gadget_resurrect_is_player_predead()
{
	should_not_be_dead = false;
	if ( self.sessionstate == "playing" && isAlive( self ) )
		should_not_be_dead = true;
		
	if ( self flagsys::get( "gadget_resurrect_pending" ) )
	{
		return true;
	}
	
	return should_not_be_dead;
}

function gadget_resurrect_secondary_deathcam_time()
{
	if ( self flagsys::get( "gadget_resurrect_pending" ) && IsDefined(self.resurrect_available_time) )
	{
		resurrect_time = 3000;
		
		weapon = self.resurrect_weapon;	
		if ( IsDefined(weapon.gadget_resurrect_duration) )
			resurrect_time = weapon.gadget_resurrect_duration;
		
		time_left = resurrect_time - ( GetTime() - self.resurrect_available_time );
		
		if ( time_left > 0 )
		{
			return time_left / 1000.0;
		}
	}
	
	return 0.0;
}
	
function enter_rejack_standby() // self == player
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon("game_ended");

	self.rejack_activate_requested = false;
	
	if( isDefined( level.resetPlayerScorestreaks ) )
	{
		[[level.resetPlayerScorestreaks]]( self );
	}
	
	self init_rejack_ui();
	self thread watch_rejack_activate_requested();
	self thread watch_rejack_suicide();
	wait REJACK_ACTIVATION_DELAY_SECONDS;
	self thread watch_rejack_activate();
	self thread watch_rejack_timeout();
	self thread watch_bad_trigger_touch();
}

function rejack_suicide()
{
	self notify( "heroAbility_off" );
	visionset_mgr::deactivate( "visionset", RESURRECT_VISIONSET_ALIAS, self );
	self thread remove_rejack_ui();
	self util::show_hud( 1 ); 
	player_suicide();
}

function watch_bad_trigger_touch()
{
	self endon( "player_input_revive" );
	self endon( "player_input_suicide" );
	self endon( "disconnect" );
	self endon( "death" );
	level endon("game_ended");
			
	a_killbrushes = GetEntArray( "trigger_hurt","classname" );

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

				self rejack_suicide();
			}
		}
		
		if( self oob::IsTouchingAnyOOBTrigger() )
		{
			self rejack_suicide();
		}
	
		WAIT_SERVER_FRAME;
	}
}

function watch_rejack_timeout() // self == player
{
	self endon( "player_input_revive" );
	self endon( "player_input_suicide" );
	self endon( "disconnect" );
	self endon( "death" );
	level endon("game_ended");
	
	wait REJACK_ACTIVATION_WINDOW_SECONDS;
	
	self playsound ("mpl_rejack_suicide_timeout"); 
	self thread resurrect_drain_power( -REJACK_ENTER_POWER_PENALTY );
	self rejack_suicide();
}

function watch_rejack_suicide() // self == player
{
	self endon( "player_input_revive" );
	self endon( "disconnect" );
	self endon( "death" );
	level endon("game_ended");

	while ( self UseButtonPressed())
	{
		wait 1;
	}

	if ( IS_TRUE( self.laststand ))
	{
		startTime = GetTime();
		while ( true )
		{
			if( !( self usebuttonpressed() ) )
			{
				startTime = GetTime();
			}
			
			if( startTime + RESURRECT_HELD_DURATION < GetTime() )
			{
				self rejack_suicide();
				self playsound ("mpl_rejack_suicide");
				return;
			}
			
			wait .01;
		}
	}
}

function reload_clip_on_stand()
{
	weapons = self GetWeaponsListPrimaries();
	for ( i = 0; i < weapons.size; i++ )
	{
		self ReloadWeaponAmmo( weapons[i] );
	}
}

function watch_rejack_activate_requested()
{
	self endon( "player_input_suicide" );
	self endon( "player_input_revive" );
	self endon( "disconnect" );
	self endon( "death" );
	level endon("game_ended");
	
	while ( self OffhandSpecialButtonPressed())
	{
		WAIT_SERVER_FRAME;
	}
	
	self.rejack_activate_requested = false;
	while( !self.rejack_activate_requested )
	{
		if( self OffhandSpecialButtonPressed() )
		{
			self.rejack_activate_requested = true;
		}
		WAIT_SERVER_FRAME;
	}
}

function watch_rejack_activate() // self == player
{
	self endon( "player_input_suicide" );
	self endon( "disconnect" );
	self endon( "death" );
	level endon("game_ended");
	
	if ( IS_TRUE( self.laststand ))
	{
		while ( true )
		{
			WAIT_SERVER_FRAME;

			if( IS_TRUE( self.rejack_activate_requested ) )
			{
				self notify( "player_input_revive" );
				if( isDefined( level.start_player_health_regen ) )
				{
					self thread [[level.start_player_health_regen]]();	// Manually restart the health regen as it gets ended because of the player killed
				}
				self._disable_proximity_alarms = false;
				self thread do_resurrected_on_spawned_player_fx();
				self thread resurrect_drain_power();				
				self thread rejack_ui_activate();
				visionset_mgr::deactivate( "visionset", RESURRECT_VISIONSET_ALIAS, self );
				visionset_mgr::activate( "visionset", RESURRECT_VISIONSET_UP_ALIAS, self, RESURRECT_VISIONSET_UP_RAMP_IN, RESURRECT_VISIONSET_UP_RAMP_HOLD, RESURRECT_VISIONSET_UP_RAMP_OUT );
				self clientfield::set_to_player( "resurrect_state", RESURRECT_STATE_UP );
				self stopshellshock();
				//self SetEverHadWeaponAll( false ); 
				self reload_clip_on_stand();
				level notify( "hero_gadget_activated", self );
				self notify( "hero_gadget_activated" );
				return;
			}
		}
	}
}

function init_rejack_ui()
{
	self clientfield::set_player_uimodel( "hudItems.rejack.activationWindowEntered", 1 );
	self LUINotifyEvent( &"create_rejack_timer", 1, GetTime() + ( int( REJACK_ACTIVATION_WINDOW_SECONDS * 1000 ) ) );
	self clientfield::set_player_uimodel( "hudItems.rejack.rejackActivated", 0 );	
}

function remove_rejack_ui()
{
	self endon( "disconnect" );
	
	wait 1.5;
	self clientfield::set_player_uimodel( "hudItems.rejack.activationWindowEntered", 0 );
	self util::show_hud( 1 ); 
}

function rejack_ui_activate()
{
	self clientfield::set_player_uimodel( "hudItems.rejack.rejackActivated", 1 );
	self thread remove_rejack_ui();
}

function player_suicide() // self == player
{
	self._disable_proximity_alarms = false;
	self notify( "player_input_suicide" );
	self clientfield::set_to_player( "resurrect_state", RESURRECT_STATE_NONE );
	self thread resurrect_drain_power( -REJACK_ENTER_POWER_PENALTY );
}