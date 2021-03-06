#using scripts\codescripts\struct;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\vehicle_shared;
#using scripts\mp\_util;
#using scripts\mp\_vehicle;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;



// _qrdrone.csc
// Sets up clientside behavior for the qrdrone

#define UAV_REMOTE_MAX_PAST_RANGE 200
#define UAV_REMOTE_MIN_HELI_PROXIMITY 150
#define UAV_REMOTE_MAX_HELI_PROXIMITY 300

#precache( "client_fx", "killstreaks/fx_drgnfire_light_red_3p" );
#precache( "client_fx", "killstreaks/fx_drgnfire_light_green_3p" );
#precache( "client_fx", "killstreaks/fx_drgnfire_light_green_1p" );

#namespace qrdrone;

REGISTER_SYSTEM( "qrdrone", &__init__, undefined )
	
function __init__()
{
	type = "qrdrone_mp";
	
	clientfield::register( "helicopter", "qrdrone_state", VERSION_SHIP, 3, "int",&stateChange, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "vehicle", "qrdrone_state", VERSION_SHIP, 3, "int",&stateChange, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );

	level._effect["qrdrone_enemy_light"] = "killstreaks/fx_drgnfire_light_red_3p";
	level._effect["qrdrone_friendly_light"] = "killstreaks/fx_drgnfire_light_green_3p";
	level._effect["qrdrone_viewmodel_light"] = "killstreaks/fx_drgnfire_light_green_1p";

	// vehicle flags	
	clientfield::register( "helicopter", "qrdrone_countdown", VERSION_SHIP, 1, "int", &start_blink, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "helicopter", "qrdrone_timeout", VERSION_SHIP, 1, "int", &final_blink, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );

	clientfield::register( "vehicle", "qrdrone_countdown", VERSION_SHIP, 1, "int", &start_blink, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "vehicle", "qrdrone_timeout", VERSION_SHIP, 1, "int", &final_blink, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "vehicle", "qrdrone_out_of_range", VERSION_SHIP, 1, "int", &out_of_range_update, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );	

	vehicle::add_vehicletype_callback( "qrdrone_mp",&spawned );	
}

function spawned( localClientNum ) // self == qrdrone
{
	self util::waittill_dobj( localClientNum );

	self thread restartFX( localClientNum, QRDRONE_FX_DEFAULT );

	self thread collisionHandler(localClientNum);
	self thread engineStutterHandler(localClientNum);
	self thread QRDrone_watch_distance();
}

//******************************************************************
//                                                                 *
//                                                                 *
//******************************************************************
function stateChange( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	self endon("entityshutdown");
	self util::waittill_dobj( localClientNum );

	self restartFX( localClientNum, newVal );
}

//******************************************************************
//                                                                 *
//                                                                 *
//******************************************************************
function restartFX( localClientNum, blinkStage ) // self == qrdrone
{
	self notify( "restart_fx" );

	/#println( "Restart QRDrone FX: stage " + blinkStage );#/

	switch( blinkStage )
	{
		case QRDRONE_FX_DEFAULT:
		{
			self spawn_solid_fx( localClientNum );
			break;
		}
		case QRDRONE_FX_BLINK:
		{
			self.fx_interval = 1.0;
			self spawn_blinking_fx( localClientNum );
			break;
		}
		case QRDRONE_FX_FINAL_BLINK:
		{
			self.fx_interval = .133;
			self spawn_blinking_fx( localClientNum );
			break;
		}
		case QRDRONE_FX_DEATH:
		{
			self notify( "stopfx" );
			self notify( "fx_death" );
			return;
		}
	}

	self thread watchRestartFX( localClientNum );
}

//******************************************************************
//                                                                 *
//                                                                 *
//******************************************************************
function watchRestartFX( localClientNum )
{
	self endon("entityshutdown");

	level util::waittill_any( "demo_jump", "player_switch", "killcam_begin", "killcam_end" );

	self restartFX( localClientNum, clientfield::get( "qrdrone_state" ));
}

//******************************************************************
//                                                                 *
//                                                                 *
//******************************************************************
function spawn_solid_fx( localClientNum ) // self == qrdrone
{
	if ( self IsLocalClientDriver( localClientNum ) )
	{
		fx_handle = playfxontag( localClientNum, level._effect["qrdrone_viewmodel_light"], self, "tag_body" );		
	}
	else if ( self util::friend_not_foe( localClientNum ) )
	{
		fx_handle = playfxontag( localClientNum, level._effect["qrdrone_friendly_light"], self, "tag_body" );
	}
	else
	{
		fx_handle = playfxontag( localClientNum, level._effect["qrdrone_enemy_light"], self, "tag_body" );
	}

	self thread cleanupFX( localClientNum, fx_handle );
}

//******************************************************************
//                                                                 *
//                                                                 *
//******************************************************************
function spawn_blinking_fx( localClientNum )
{
	self thread blink_fx_and_sound( localClientNum, "wpn_qr_alert" );
}

//******************************************************************
//                                                                 *
//                                                                 *
//******************************************************************
function blink_fx_and_sound( localClientNum, soundAlias )
{
	self endon( "entityshutdown" );
	self endon( "restart_fx" );
	self endon( "fx_death" );

	if ( !isdefined( self.interval ) )
	{
		self.interval = 1.0;
	}
	
	while(1)
	{
		self PlaySound( localClientNum, soundAlias );
		
		self spawn_solid_fx( localClientNum );
		util::server_wait( localClientNum, self.interval / 2);

		self notify( "stopfx" );
		
		util::server_wait( localClientNum, self.interval / 2);
		self.interval = (self.interval / 1.17);

		if (self.interval < .1)
		{
			self.interval = .1;
		}	
	}
}

//******************************************************************
//                                                                 *
//                                                                 *
//******************************************************************
function cleanupFX( localClientNum, handle )
{
	self util::waittill_any( "entityshutdown", "blink", "stopfx", "restart_fx" );
	stopfx( localClientNum, handle );
}

function start_blink( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	if (!newVal)
		return;
		
	self notify("blink");
}

// this second state is necessary so killcams show the appropriate "fast blink" state
function final_blink( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	if (!newVal)
		return;
	
	self.interval = .133;
}

function out_of_range_update( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	model = GetUIModel( GetUIModelForController( localClientNum ), "vehicle.outOfRange" );
	if ( isdefined( model ) )
	{
		SetUIModelValue( model, newVal );
	}
}

function loop_local_sound( localClientNum, alias, interval, fx )
{
	self endon( "entityshutdown" );
	self endon( "stopfx" );

	level endon( "demo_jump" );
	level endon( "player_switch" );

	// also playing the blinking light fx with the sound

	if ( !isdefined( self.interval ) )
	{
		self.interval = interval;
	}
	
	while(1)
	{
		self PlaySound( localClientNum, alias );
		
		self spawn_solid_fx( localClientNum );
		util::server_wait( localClientNum, self.interval / 2);

		self notify( "stopfx" );
		
		util::server_wait( localClientNum, self.interval / 2);
		self.interval = (self.interval / 1.17);

		if (self.interval < .1)
		{
			self.interval = .1;
		}	
	}
}

function check_for_player_switch_or_time_jump( localClientNum )
{
	self endon("entityshutdown");

	level util::waittill_any( "demo_jump", "player_switch", "killcam_begin" );
	self notify( "stopfx" );

	waittillframeend;

	self thread blink_light( localClientNum );
	
	if ( isdefined( self.blinkStartTime ) && self.blinkStartTime <= level.serverTime )
	{
		self.interval = 1;
		self thread start_blink( localClientNum, true );
	}
	else
	{
		self spawn_solid_fx( localClientNum );
	}
	
	self thread check_for_player_switch_or_time_jump( localClientNum );
}

function blink_light( localClientNum )
{
	self endon("entityshutdown");
	level endon( "demo_jump" );
	level endon( "player_switch" );
	level endon( "killcam_begin" );	

	self waittill("blink");
	
	if ( !isdefined( self.blinkStartTime ) )
	{
		self.blinkStartTime = level.serverTime;
	}	

	if ( self IsLocalClientDriver( localClientNum ) )
	{
		self thread loop_local_sound( localClientNum, "wpn_qr_alert", 1, level._effect["qrdrone_viewmodel_light"] );
	}
	else if ( self util::friend_not_foe( localClientNum ) )
	{
		self thread loop_local_sound( localClientNum, "wpn_qr_alert", 1, level._effect["qrdrone_friendly_light"] );
	}
	else
	{
		self thread loop_local_sound( localClientNum, "wpn_qr_alert", 1, level._effect["qrdrone_enemy_light"] );
	}
}


function collisionHandler( localClientNum )
{
	self endon( "entityshutdown" );
	
	while( 1 )
	{
		self waittill( "veh_collision", hip, hitn, hit_intensity );

		driver_local_client = self GetLocalClientDriver();
		
		if( isdefined( driver_local_client ) )
		{
			//println( "veh_collision " + hit_intensity );
			player = getlocalplayer( driver_local_client );

			if( isdefined( player ) )
			{
				// todo - play sound here also
				if( hit_intensity > 15 )
				{
					player PlayRumbleOnEntity( driver_local_client, "damage_heavy" );
				}
				else
				{
					player PlayRumbleOnEntity( driver_local_client, "damage_light" );
				}
			}
		}
	}
}

function engineStutterHandler( localClientNum )
{
	self endon( "entityshutdown" );
	
	while( 1 )
	{
		self waittill( "veh_engine_stutter" );
		if ( self IsLocalClientDriver( localClientNum ) )
		{
			player = getlocalplayer( localClientNum );
			
			if( isdefined( player ) )
			{
				player PlayRumbleOnEntity( localClientNum, "rcbomb_engine_stutter" );
			}
		}
	}
}

function getMinimumFlyHeight()
{	
	if ( !isdefined( level.airsupportHeightScale ) ) 
		level.airsupportHeightScale = 1;

	airsupport_height = struct::get( "air_support_height", "targetname");
	if ( isdefined(airsupport_height) )
	{
		planeFlyHeight = airsupport_height.origin[2];
	}
	else
	{
/#
		PrintLn("WARNING:  Missing air_support_height entity in the map.  Using default height.");
#/
		// original system
		planeFlyHeight = 850;
	
		if ( isdefined( level.airsupportHeightScale ) )
		{
			level.airsupportHeightScale = GetDvarInt( "scr_airsupportHeightScale", level.airsupportHeightScale );	
			planeFlyHeight *= GetDvarInt( "scr_airsupportHeightScale", level.airsupportHeightScale );	
		}
		
		if ( isdefined( level.forceAirsupportMapHeight ) )
		{
			planeFlyHeight += level.forceAirsupportMapHeight;
		}	
	}
	
	return planeFlyHeight;
}

function QRDrone_watch_distance()
{
	self endon ("entityshutdown" );
	
	qrdrone_height = struct::get( "qrdrone_height", "targetname");
	if ( isdefined(qrdrone_height) )
	{
		self.maxHeight = qrdrone_height.origin[2];
	}
	else
	{
		self.maxHeight = int(getMinimumFlyHeight());
	}
	
	self.maxDistance = 12800;		
	
	level.mapCenter = GetMapCenter();
	
	self.minHeight = level.mapCenter[2] - 800;		

	//	shouldn't be possible to start out of range, but just in case
	inRangePos = self.origin;	

	soundent = spawn (0, self.origin, "script_origin" );
	soundent linkto(self);
	
	// end static on vehicle death
	self thread QRDrone_staticStopOnDeath( soundent );
	
	//	loop
	while ( true )
	{
		if ( !self QRDrone_in_range() )
		{
			//	increase static with distance from exit point or distance to heli in proximity
			staticAlpha = 0;		
			while ( !self QRDrone_in_range() )
			{	                        
				if ( isdefined( self.heliInProximity ) )
				{
					dist = distance( self.origin, self.heliInProximity.origin );
					staticAlpha = 1 - ( (dist-UAV_REMOTE_MIN_HELI_PROXIMITY) / (UAV_REMOTE_MAX_HELI_PROXIMITY-UAV_REMOTE_MIN_HELI_PROXIMITY) );
				}
				else
				{
					dist = distance( self.origin, inRangePos );
					staticAlpha = min( 1, dist/UAV_REMOTE_MAX_PAST_RANGE );	
				}

				
				// SOUND: put sound code here to change the volume of the static while the player is 
				// in static.  staticAlpha will be 0 - 1. 0 being no static, 1 being full static.

				
				sid = soundent playloopsound ( "veh_qrdrone_static_lp", .2 );
				self vehicle::set_static_amount( staticAlpha * 2 );

				wait ( 0.05 );
			}
			
			
			//	fade out static
			self thread QRDrone_staticFade( staticAlpha, soundent, sid );
	
		}		
		inRangePos = self.origin;
		wait ( 0.05 );
	}
}


function QRDrone_in_range()
{
	if ( self.origin[2] < self.maxHeight && self.origin[2] > self.minHeight )
	{
		if ( self isInsideHeightLock() )
		{
				return true;
		}
	}
	return false;
}


function QRDrone_staticFade( staticAlpha, sndent, sid )
{
	self endon ( "entityshutdown" );
	while( self QRDrone_in_range() )
	{
		staticAlpha -= 0.05;
		if ( staticAlpha <= 0 )
		{
			// SOUND: Put call here to completely turn static sound off
			sndent StopAllLoopSounds (.5);
			//delete sid;
			self vehicle::set_static_amount( 0 );
			break;
		}
		
		// SOUND:  Put call here to change volume of static based on staticAlpha
		setsoundvolumerate( sid, .6 );
		setsoundvolume( sid, staticAlpha );
		
		self vehicle::set_static_amount( staticAlpha * 2 );
	
			
		wait( 0.05 );
	}
}

function QRDrone_staticStopOnDeath( sndent )
{
	self waittill ( "entityshutdown" );
	sndent StopAllLoopSounds (.1);
	sndent delete();
}
