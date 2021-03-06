#using scripts\codescripts\struct;

#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\flagsys_shared;
#using scripts\shared\visionset_mgr_shared;
#using scripts\shared\spawner_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#using scripts\shared\abilities\_ability_player;
#using scripts\shared\abilities\_ability_util;
#using scripts\shared\abilities\gadgets\_gadget_camo;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;
#insert scripts\shared\abilities\_ability_util.gsh;
#insert scripts\shared\abilities\gadgets\_gadget_vision_pulse.gsh;

#define AI_HEAT_HIGHLIGHTED_CONSTANT_SIZE 				true	
#define VISION_PULSE_MISS_ALIAS							"gdt_vision_pulse_no_hits"

REGISTER_SYSTEM( "gadget_vision_pulse", &__init__, undefined )

function __init__()
{
	ability_player::register_gadget_activation_callbacks( GADGET_TYPE_VISION_PULSE, &gadget_vision_pulse_on, &gadget_vision_pulse_off );
	ability_player::register_gadget_possession_callbacks( GADGET_TYPE_VISION_PULSE, &gadget_vision_pulse_on_give, &gadget_vision_pulse_on_take );
	ability_player::register_gadget_flicker_callbacks( GADGET_TYPE_VISION_PULSE, &gadget_vision_pulse_on_flicker );
	ability_player::register_gadget_is_inuse_callbacks( GADGET_TYPE_VISION_PULSE, &gadget_vision_pulse_is_inuse );
	ability_player::register_gadget_is_flickering_callbacks( GADGET_TYPE_VISION_PULSE, &gadget_vision_pulse_is_flickering );

	callback::on_connect( &gadget_vision_pulse_on_connect );
	callback::on_spawned( &gadget_vision_pulse_on_spawn );
	
	clientfield::register( "toplayer", "vision_pulse_active" , VERSION_SHIP, 1, "int" );
	
	if ( !IsDefined( level.vsmgr_prio_visionset_visionpulse ) )
	{
		level.vsmgr_prio_visionset_visionpulse = VISION_PULSE_VISIONSET_PRIORITY;
	}
		
	visionset_mgr::register_info( "visionset", VISION_PULSE_VISIONSET_ALIAS, VERSION_SHIP, level.vsmgr_prio_visionset_visionpulse, VISION_PULSE_VISIONSET_STEPS, true, &visionset_mgr::ramp_in_out_thread_per_player_death_shutdown, false );
}

function gadget_vision_pulse_is_inuse( slot )
{
	// returns true when the gadget is on
	return self flagsys::get( "gadget_vision_pulse_on" );
}

function gadget_vision_pulse_is_flickering( slot )
{
	// returns true when the gadget is flickering
	return self GadgetFlickering( slot );
}

function gadget_vision_pulse_on_flicker( slot, weapon )
{
	// excuted when the gadget flickers
	self thread gadget_vision_pulse_flicker( slot, weapon );
}

function gadget_vision_pulse_on_give( slot, weapon )
{
	// executed when gadget is added to the players inventory
}

function gadget_vision_pulse_on_take( slot, weapon )
{
	// executed when gadget is removed from the players inventory
}

//self is the player
function gadget_vision_pulse_on_connect()
{
	// setup up stuff on player connect	
}

function gadget_vision_pulse_on_spawn()
{
	self.visionPulseActivateTime = 0;
	self.visionPulseArray = [];
	self.visionPulseOrigin = undefined;
	self.visionPulseOriginArray = [];
	
	if( isDefined( self._pulse_ent ) )
	{
		self._pulse_ent delete();
	}
}

function gadget_vision_pulse_ramp_hold_func()
{
	self util::waittill_any_timeout( VISION_PULSE_VISIONSET_RAMP_HOLD, "ramp_out_visionset" );
}

function gadget_vision_pulse_watch_death()
{
	self notify ( "vision_pulse_watch_death" );
	self endon ( "vision_pulse_watch_death" );
	self endon ( "disconnect" );
	self waittill ( "death" );
	visionset_mgr::deactivate( "visionset", VISION_PULSE_VISIONSET_ALIAS, self );
	if( isDefined( self._pulse_ent ) )
	{
		self._pulse_ent delete();
	}
}

function gadget_vision_pulse_watch_emp()
{
	self notify ( "vision_pulse_watch_emp" );
	self endon ( "vision_pulse_watch_emp" );
	self endon ( "disconnect" );
	
	while( 1 )
	{
		if( self IsEMPJammed() )
		{
			visionset_mgr::deactivate( "visionset", VISION_PULSE_VISIONSET_ALIAS, self );
			self notify ( "emp_vp_jammed" );
			break;
		}
		WAIT_SERVER_FRAME;
	}
	
	if( isDefined( self._pulse_ent ) )
	{
		self._pulse_ent delete();
	}
}

function gadget_vision_pulse_on( slot, weapon )
{
	if ( IsDefined( self._pulse_ent ) )
	{
		return;
	}
	
	// excecutes when the gadget is turned on
	self flagsys::set( "gadget_vision_pulse_on" );	

	self thread gadget_vision_pulse_start( slot, weapon );
	visionset_mgr::activate( "visionset", VISION_PULSE_VISIONSET_ALIAS, self, VISION_PULSE_VISIONSET_RAMP_IN, &gadget_vision_pulse_ramp_hold_func, VISION_PULSE_VISIONSET_RAMP_OUT );
	self thread gadget_vision_pulse_watch_death();
	self thread gadget_vision_pulse_watch_emp();
	self clientfield::set_to_player( "vision_pulse_active", 1 );
}

function gadget_vision_pulse_off( slot, weapon )
{
	// excecutes when the gadget is turned off`
	self flagsys::clear( "gadget_vision_pulse_on" );
	
	self clientfield::set_to_player( "vision_pulse_active", 0 );
}

function gadget_vision_pulse_start( slot, weapon )
{
	self endon ( "disconnect" );
	self endon ( "death" );
	self endon ( "emp_vp_jammed" );
	
	wait 0.1;

	if ( IsDefined( self._pulse_ent ) )
	{
		return;
	}	

	self._pulse_ent = spawn( "script_model", self.origin );
	self._pulse_ent SetModel( "tag_origin" );

	self GadgetSetEntity( slot, self._pulse_ent );
	self GadgetSetActivateTime( slot, GetTime() );
	
	self set_gadget_vision_pulse_status( "Activated" );
	//self PlaySound ( "gdt_vision_pulse" );
	self.visionPulseActivateTime = getTime();
	enemyArray = level.players;
	
	gadget = GetWeapon( "gadget_vision_pulse" );
	visionPulseArray = ArraySort( enemyArray, self._pulse_ent.origin, true, undefined, gadget.gadget_pulse_max_range );
	self.visionPulseOrigin = self._pulse_ent.origin;
	self.visionPulseArray = [];
	self.visionPulseOriginArray = [];
	spottedEnemy = false;
	self.visionPulseSpottedEnemy = [];
	self.visionPulseSpottedEnemyTime = getTime();
	for ( i = 0; i < visionPulseArray.size; i++ )
	{
		if ( visionPulseArray[i] _gadget_camo::camo_is_inuse() == false )
		{
			self.visionPulseArray[self.visionPulseArray.size] = visionPulseArray[i];
			self.visionPulseOriginArray[self.visionPulseOriginArray.size] = visionPulseArray[i].origin;
			
			if ( IsAlive( visionPulseArray[i] ) && visionPulseArray[i].team != self.team )
			{
				spottedEnemy = true;
				self.visionPulseSpottedEnemy[self.visionPulseSpottedEnemy.size] = visionPulseArray[i];
			}
		}
	}

	self wait_until_is_done( slot, self._gadgets_player[slot].gadget_pulse_duration );
	
	if ( spottedEnemy && isdefined( level.playGadgetSuccess ) )
    {
		self [[ level.playGadgetSuccess ]]( weapon );
    }
	else
	{
		self playsoundtoplayer( VISION_PULSE_MISS_ALIAS, self );
		self notify( "ramp_out_visionset" );
	}
	
	self set_gadget_vision_pulse_status( "Done" );

	self._pulse_ent delete();
}

function wait_until_is_done( slot, timePulse )
{
	startTime = GetTime();

	while ( 1 )
	{
		wait 0.25;

		currentTime = GetTime();
		if ( currentTime > startTime + timePulse )
		{
			return;
		}
	}
}

function gadget_vision_pulse_flicker( slot, weapon )
{
	self endon( "disconnect" );

	time = GetTime();	

	if ( !self gadget_vision_pulse_is_inuse( slot ) )
	{
		return;
	}	

	eventTime = self._gadgets_player[slot].gadget_flickertime;

	self set_gadget_vision_pulse_status( "^1" + "Flickering.", eventTime );

	while( 1 )
	{		
		if ( !self GadgetFlickering( slot ) )
		{
			set_gadget_vision_pulse_status( "^2" + "Normal" );
			return;
		}

		wait( 0.25 );
	}
}


function set_gadget_vision_pulse_status( status, time )
{
	timeStr = "";

	if ( IsDefined( time ) )
	{
		timeStr = "^3" + ", time: " + time;
	}
	
	if ( GetDvarInt( "scr_cpower_debug_prints" ) > 0 )
		self IPrintlnBold( "Vision Pulse:" + status + timeStr );
}