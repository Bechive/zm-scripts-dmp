#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\clientfield_shared;
#using scripts\mp\gametypes\_spawning;
#using scripts\mp\_util;
#using scripts\mp\killstreaks\_qrdrone;
#using scripts\mp\killstreaks\_rcbomb;
#using scripts\shared\vehicle_death_shared;

#insert scripts\shared\shared.gsh;

#using_animtree ( "mp_vehicles" );

#namespace vehicle;

REGISTER_SYSTEM( "vehicle", &__init__, undefined )

function __init__()
{
	// We can control whether vehicle occupants can take damage (such as from bullets)
	SetDvar( "scr_veh_driversarehidden", "1" );
	SetDvar( "scr_veh_driversareinvulnerable", "1" );
	
	// "cleanuptime" must pass before veh is considered for cleanup (either by abandonment or drift)
	// these are given in seconds
	SetDvar( "scr_veh_alive_cleanuptimemin", "119" );
	SetDvar( "scr_veh_alive_cleanuptimemax", "120" );
	SetDvar( "scr_veh_dead_cleanuptimemin", "20" );
	SetDvar( "scr_veh_dead_cleanuptimemax", "30" );
	
	// These cleanuptime factors only modify cleanup due to abandonment or drift,
	// i.e. the cleanup of an alive vehicle.  Once the vehicle dies and becomes a
	// husk, only the cleanuptimemin and cleanuptimemax values apply.
	SetDvar( "scr_veh_cleanuptime_dmgfactor_min", "0.33" );
	SetDvar( "scr_veh_cleanuptime_dmgfactor_max", "1.0" );
	SetDvar( "scr_veh_cleanuptime_dmgfactor_deadtread", "0.25" ); // decrease the damage factor ( which scales wait time ) by this much for each tread that has been completely destroyed
	SetDvar( "scr_veh_cleanuptime_dmgfraction_curve_begin", "0.0" ); // this is the amount of damage at which the damage factor affecting wait time will be at max
	SetDvar( "scr_veh_cleanuptime_dmgfraction_curve_end", "1.0" ); // this is the amount of damage at which the damage factor affecting wait time will be at min
	
	SetDvar( "scr_veh_cleanupabandoned", "1" ); // Decide whether to cleanup abandoned vehicles
	SetDvar( "scr_veh_cleanupdrifted", "1" ); // Decide whether to cleanup drifted vehicles
	SetDvar( "scr_veh_cleanupmaxspeedmph", "1" ); // If it's going slower than this, then the vehicle can be cleaned up
	SetDvar( "scr_veh_cleanupmindistancefeet", "75" ); // If it's at least this far from its original position, then the vehicle can be cleaned up
	SetDvar( "scr_veh_waittillstoppedandmindist_maxtime", "10" );
	SetDvar( "scr_veh_waittillstoppedandmindist_maxtimeenabledistfeet", "5" );
	
	// Respawn time is the wait between cleaning up an old vehicle
	// and spawning a new replacement vehicle.
	// these are given in seconds
	SetDvar( "scr_veh_respawnafterhuskcleanup", "1" ); // if true, vehicle respawn kicks off after husk cleanup.  otherwise, kicks off after live vehicle is killed
	SetDvar( "scr_veh_respawntimemin", "50" );
	SetDvar( "scr_veh_respawntimemax", "90" );
	SetDvar( "scr_veh_respawnwait_maxiterations", "30" );
	SetDvar( "scr_veh_respawnwait_iterationwaitseconds", "1" );
	
	SetDvar( "scr_veh_disablerespawn", "0" );//turn off the default respawning system, the game mode will need to take care of respawning us.
	SetDvar( "scr_veh_disableoverturndamage", "0" );// turn on damage when the vehicle is overturned by default
	
	// Explodes when killed or when dvar scr_veh_explode_on_cleanup is not zero
	SetDvar( "scr_veh_explosion_spawnfx", "1" ); // Whether or not to create an explosion FX when the vehicle is destroyed
	SetDvar( "scr_veh_explosion_doradiusdamage", "1" ); // whether or not to hurt nearby entities when the vehicle is destroyed
	SetDvar( "scr_veh_explosion_radius", "256" );
	SetDvar( "scr_veh_explosion_mindamage", "20" );
	SetDvar( "scr_veh_explosion_maxdamage", "200" );
	

	SetDvar( "scr_veh_ondeath_createhusk", "1" ); // Whether or not to init a burnt-out husk for players to use as cover when the vehicle is destroyed
	SetDvar( "scr_veh_ondeath_usevehicleashusk", "1" ); // if true, husks will be the vehicle entities themselves.  otherwise, husk will be a spawn("script_model")	
	SetDvar( "scr_veh_explosion_husk_forcepointvariance", "30" ); // controls the "spin" when the vehicle husk is launched
	SetDvar( "scr_veh_explosion_husk_horzvelocityvariance", "25" );
	SetDvar( "scr_veh_explosion_husk_vertvelocitymin", "100" );
	SetDvar( "scr_veh_explosion_husk_vertvelocitymax", "200" );
	
	
	SetDvar( "scr_veh_explode_on_cleanup", "1" ); ///< if not "exploding", then "disappearing".  this only affect auto-cleanup case, not when vehicle is destroyed.  destroyed vehicle always explodes
	SetDvar( "scr_veh_disappear_maxwaittime", "60" ); ///< # seconds at which test for "player too close" and "player can see" will timeout and the husk will be cleaned up anyway
	SetDvar( "scr_veh_disappear_maxpreventdistancefeet", "30" ); ///< If vehicle closer to the player than this, then it won't be cleaned up
	SetDvar( "scr_veh_disappear_maxpreventvisibilityfeet", "150" ); ///< Only apply visibility check if vehicle is closer to the player than this
	
	SetDvar( "scr_veh_health_tank", "1350" ); // default health
	
	level.vehicle_drivers_are_invulnerable = GetDvarint( "scr_veh_driversareinvulnerable" );

	level.onEjectOccupants =&vehicle_eject_all_occupants;// Callback function to allow custom code when a vehicle is overturned and needs to eject occupants
	
	level.vehicleHealths[ "panzer4_mp" ] = 2600;
	level.vehicleHealths[ "t34_mp" ] = 2600;
	
	SetDvar( "scr_veh_health_jeep", "700" ); 

	
	if ( init_vehicle_entities() )
	{
		level.vehicle_explosion_effect= "_t6/vehicle/vexplosion/fx_vexplode_helicopter_exp_mp"; // kaboom!	

		level.veh_husk_models = [];
		
		if ( isdefined( level.use_new_veh_husks ) )
		{
			level.veh_husk_models[ "t34_mp" ] = "veh_t34_destroyed_mp";
			//level.veh_husk_models[ "panzer4_mp" ] = "veh_panzer4_destroyed_mp";
		}
		
		if ( isdefined( level.onAddVehicleHusks) )
		{
			[[level.onAddVehicleHusks]]();
		}
		
		//level._effect["tanksquish"] = "_t6/maps/see2/fx_body_blood_splat";//TODO T7 - contact FX team to get proper replacement
	}
	
	// for clientscripts
	chopper_player_get_on_gun = %int_huey_gunner_on;
	chopper_door_open = %v_huey_door_open;
	chopper_door_open_state = %v_huey_door_open_state;
	chopper_door_closed_state = %v_huey_door_close_state;

	killbrushes = GetEntArray( "water_killbrush", "targetname" );

	foreach( brush in killbrushes )
	{
		brush thread water_killbrush_think();
	}

	return;
}

function water_killbrush_think()
{
	for( ;; )
	{
		self waittill( "trigger", entity );

		if ( isdefined( entity ) )
		{
			if ( isdefined( entity.targetname ) )
			{
				if ( entity.targetname == "rcbomb" )
				{
					entity notify( "rcbomb_shutdown" );
				}
				else if ( entity.targetname == "talon" && !IS_TRUE( entity.dead ) )
				{
					entity notify( "death" );
				}
			}

			if ( isdefined( entity.heliType ) && entity.heliType == "qrdrone" )
			{
				entity qrdrone::QRDrone_force_destroy();
			}
		}
	}
}

function initialize_vehicle_damage_effects_for_level()
{

	/*
	Vehicle damage effects are stored in level.vehicles_damage_states[]
	where the array key is the GDT vehicle-type name for the particular vehicle.
	For example, "sherman_mp" --> level.vehicles_damage_states["sherman_mp"]
	The default MP vehicle is "defaultvehicle_mp". This is used for vehicles who do not have a custom entry in the vehicles_damage_states[] array.
	
	Here we setup the vehicle damage effects response behaviors for all vehicles, using a data structure layout as follows:
	struct s_vehicle_damage_state
	{
		float health_percentage; // apply effect(s) from effect_array[] when vehicle health is <= this amount
		struct s_effect_array
		{
			id damage_effect; // this is the damage effect to apply
			string sound_effect; // this is the sound effect to play
			string vehicle_tag; // this is the tag on the vehicle where the effect should be applied
		} effect_array[];
	};
	So, when a vehicle's health percentage becomes <= s_vehicle_damage_effects.health_percentage,
	all the effects listed in s_vehicle_damage_effects.effect_array[] are applied as defined
	*/
	
	// damage indices
	k_mild_damage_index= 0;
	k_moderate_damage_index= 1;
	k_severe_damage_index= 2;
	k_total_damage_index= 3;
	
	// health_percentage constants
	k_mild_damage_health_percentage= 0.85;
	k_moderate_damage_health_percentage= 0.55;
	k_severe_damage_health_percentage= 0.35;
	k_total_damage_health_percentage= 0;
	level.k_mild_damage_health_percentage = k_mild_damage_health_percentage;
	level.k_moderate_damage_health_percentage = k_moderate_damage_health_percentage;
	level.k_severe_damage_health_percentage = k_severe_damage_health_percentage;
	level.k_total_damage_health_percentage = k_total_damage_health_percentage;
	
	level.vehicles_damage_states= [];
	level.vehicles_husk_effects = [];
	level.vehicles_damage_treadfx = [];
	
	// setup the default vehicle
	vehicle_name= get_default_vehicle_name();
	{
		level.vehicles_damage_states[vehicle_name]= [];
		level.vehicles_damage_treadfx[vehicle_name] = [];

		// mild damage
		{
			level.vehicles_damage_states[vehicle_name][k_mild_damage_index]= SpawnStruct();
			level.vehicles_damage_states[vehicle_name][k_mild_damage_index].health_percentage= k_mild_damage_health_percentage;
			level.vehicles_damage_states[vehicle_name][k_mild_damage_index].effect_array= [];
			// effect '0' - placed @ "tag_origin"
			level.vehicles_damage_states[vehicle_name][k_mild_damage_index].effect_array[0]= SpawnStruct();
			level.vehicles_damage_states[vehicle_name][k_mild_damage_index].effect_array[0].damage_effect= "_t6/vehicle/vfire/fx_tank_sherman_smldr"; // smoldering (smoke puffs)//TODO T7 - contact FX team to get proper replacement
			level.vehicles_damage_states[vehicle_name][k_mild_damage_index].effect_array[0].sound_effect= undefined;
			level.vehicles_damage_states[vehicle_name][k_mild_damage_index].effect_array[0].vehicle_tag= "tag_origin";
		}
		// moderate damage
		{
			level.vehicles_damage_states[vehicle_name][k_moderate_damage_index]= SpawnStruct();
			level.vehicles_damage_states[vehicle_name][k_moderate_damage_index].health_percentage= k_moderate_damage_health_percentage;
			level.vehicles_damage_states[vehicle_name][k_moderate_damage_index].effect_array= [];
			// effect '0' - placed @ "tag_origin"
			level.vehicles_damage_states[vehicle_name][k_moderate_damage_index].effect_array[0]= SpawnStruct();
			level.vehicles_damage_states[vehicle_name][k_moderate_damage_index].effect_array[0].damage_effect= "_t6/vehicle/vfire/fx_vfire_med_12"; // flames & more smoke//TODO T7 - contact FX team to get proper replacement
			level.vehicles_damage_states[vehicle_name][k_moderate_damage_index].effect_array[0].sound_effect= undefined;
			level.vehicles_damage_states[vehicle_name][k_moderate_damage_index].effect_array[0].vehicle_tag= "tag_origin";
		}
		// severe damage
		{
			level.vehicles_damage_states[vehicle_name][k_severe_damage_index]= SpawnStruct();
			level.vehicles_damage_states[vehicle_name][k_severe_damage_index].health_percentage= k_severe_damage_health_percentage;
			level.vehicles_damage_states[vehicle_name][k_severe_damage_index].effect_array= [];
			// effect '0' - placed @ "tag_origin"
			level.vehicles_damage_states[vehicle_name][k_severe_damage_index].effect_array[0]= SpawnStruct();
			level.vehicles_damage_states[vehicle_name][k_severe_damage_index].effect_array[0].damage_effect= "_t6/vehicle/vfire/fx_vfire_sherman"; // pillar of smoke//TODO T7 - contact FX team to get proper replacement
			level.vehicles_damage_states[vehicle_name][k_severe_damage_index].effect_array[0].sound_effect= undefined;
			level.vehicles_damage_states[vehicle_name][k_severe_damage_index].effect_array[0].vehicle_tag= "tag_origin";
		}
		// total damage
		{
			level.vehicles_damage_states[vehicle_name][k_total_damage_index]= SpawnStruct();
			level.vehicles_damage_states[vehicle_name][k_total_damage_index].health_percentage= k_total_damage_health_percentage;
			level.vehicles_damage_states[vehicle_name][k_total_damage_index].effect_array= [];
			// effect '0' - placed @ "tag_origin"
			level.vehicles_damage_states[vehicle_name][k_total_damage_index].effect_array[0]= SpawnStruct();
			level.vehicles_damage_states[vehicle_name][k_total_damage_index].effect_array[0].damage_effect= "_t6/vehicle/vexplosion/fx_vexplode_helicopter_exp_mp";
			level.vehicles_damage_states[vehicle_name][k_total_damage_index].effect_array[0].sound_effect= "vehicle_explo"; // kaboom!
			level.vehicles_damage_states[vehicle_name][k_total_damage_index].effect_array[0].vehicle_tag= "tag_origin";
		}
		
		
		{
			default_husk_effects = SpawnStruct();
			default_husk_effects.damage_effect = undefined;
			default_husk_effects.sound_effect = undefined;
			default_husk_effects.vehicle_tag = "tag_origin";
			
			level.vehicles_husk_effects[ vehicle_name ] = default_husk_effects;
		}
	}

//	_t34::build_damage_states();
//	_panzeriv::build_damage_states();
	
	return;
}

//string
function get_vehicle_name(
	vehicle)
{
	name= "";
	
	if (isdefined(vehicle))
	{
		if (isdefined(vehicle.vehicletype))
		{
			name= vehicle.vehicletype;
		}
	}
	
	return name;
}

//string
function get_default_vehicle_name()
{
	return "defaultvehicle_mp";
}

//string
function get_vehicle_name_key_for_damage_states(
	vehicle)
{
	vehicle_name= get_vehicle_name(vehicle);
	
	if (!isdefined(level.vehicles_damage_states[vehicle_name]))
	{
		vehicle_name= get_default_vehicle_name();
	}
	
	return vehicle_name;
}

//int
function get_vehicle_damage_state_index_from_health_percentage(
	vehicle)
{
	damage_state_index= -1;
	vehicle_name= get_vehicle_name_key_for_damage_states();
	
	for (test_index= 0; test_index<level.vehicles_damage_states[vehicle_name].size; test_index++)
	{
		if (vehicle.current_health_percentage<=level.vehicles_damage_states[vehicle_name][test_index].health_percentage)
		{
			damage_state_index= test_index;
		}
		else
		{
			break;
		}
	}
	
	return damage_state_index;
}


// called each time a vehicle takes damage
function update_damage_effects(
	vehicle,
	attacker)
{
	if (vehicle.initial_state.health>0)
	{
		previous_damage_state_index= get_vehicle_damage_state_index_from_health_percentage(vehicle);
		vehicle.current_health_percentage= vehicle.health/vehicle.initial_state.health;
		current_damage_state_index= get_vehicle_damage_state_index_from_health_percentage(vehicle);
		// if we have reached a new damage state, play associated effects
		if (previous_damage_state_index!=current_damage_state_index)
		{
			vehicle notify ( "damage_state_changed" );
			if (previous_damage_state_index<0)
			{
				start_damage_state_index= 0;
			}
			else
			{
				start_damage_state_index= previous_damage_state_index+1;
			}
			play_damage_state_effects(vehicle, start_damage_state_index, current_damage_state_index);
			if ( vehicle.health <= 0 )
			{
				vehicle kill_vehicle(attacker);
			}
		}
	}
	
	return;
}


function play_damage_state_effects(
	vehicle,
	start_damage_state_index,
	end_damage_state_index)
{
	vehicle_name= get_vehicle_name_key_for_damage_states( vehicle );
	
	// play effects for all damage states from start_damage_state_index --> end_damage_state_index
	for (damage_state_index= start_damage_state_index; damage_state_index<=end_damage_state_index; damage_state_index++)
	{
		for (effect_index= 0;
			effect_index<level.vehicles_damage_states[vehicle_name][damage_state_index].effect_array.size;
			effect_index++)
		{
			effects = level.vehicles_damage_states[ vehicle_name ][ damage_state_index ].effect_array[ effect_index ];
			vehicle thread play_vehicle_effects( effects );
		}
	}
	
	return;
}


function play_vehicle_effects( effects, isDamagedTread )
{
	self endon( "delete" );
	self endon( "removed" );
	
	if ( !isdefined( isDamagedTread ) || isDamagedTread == 0 )
	{
		self endon( "damage_state_changed" );
	}

	// if there is an associated sound effect, play it
	if ( isdefined( effects.sound_effect ) )
	{
		self PlaySound( effects.sound_effect );
	}

	waitTime = 0;
	if ( isdefined ( effects.damage_effect_loop_time ) )
	{
		waitTime = effects.damage_effect_loop_time;
	}

	while ( waitTime > 0 )
	{
		// if the specified effect was loaded, play it on the associated vehicle tag
		if ( isdefined( effects.damage_effect ) )
		{
			PlayFxOnTag( effects.damage_effect, self, effects.vehicle_tag );
		}
		wait( waitTime );
	}
}


function init_vehicle_entities()
{
	vehicles = getentarray( "script_vehicle", "classname" );
	array::thread_all( vehicles,&init_original_vehicle );
	
	if ( isdefined( vehicles ) )
	{
		return vehicles.size;
	}
	
	return 0;
}


function precache_vehicles()
{
	// Last time I tested, this is actually not called from anywhere
}


function register_vehicle()
{
	// Register vehicle husk
	if ( !isdefined( level.vehicles_list ) )
	{
		level.vehicles_list = [];
	}
	
	level.vehicles_list[ level.vehicles_list.size ] = self;
}


// Before spawning a new vehicle, we need to bookkeep our list
// of instantiated vehicles.  If spawning the new vehicle would cause us to go
// over the max vehicle limit, then we need to force-delete
// the oldest (dead) ones to make room.

function manage_vehicles()
{
	if ( !isdefined( level.vehicles_list ) )
	{
		return true;
	}
	else
	{
		MAX_VEHICLES = GetMaxVehicles();
		
		{
			// Consolidate array - Husks might have been cleaned up in the interim
			
			newArray = [];
			
			for ( i = 0; i < level.vehicles_list.size; i++ )
			{
				if ( isdefined( level.vehicles_list[ i ] ) )
				{
					newArray[ newArray.size ] = level.vehicles_list[ i ];
				}
			}
			
			level.vehicles_list = newArray;
		}
		
		
		// make sure there's room for one more
		vehiclesToDelete = ( level.vehicles_list.size + 1 ) - MAX_VEHICLES;
		
		
		if ( vehiclesToDelete > 0 )
		{
			newArray = [];
			
			for ( i = 0; i < level.vehicles_list.size; i++ )
			{
				vehicle = level.vehicles_list[ i ];
				
				if ( vehiclesToDelete > 0 )
				{
					// ".permanentlyRemoved" vehicles will never be really deleted
					if ( isdefined( vehicle.is_husk ) && !isdefined( vehicle.permanentlyRemoved ) )
					{
						deleted = vehicle husk_do_cleanup();
						
						if ( deleted )
						{
							vehiclesToDelete--;
							continue;
						}
					}
				}
				
				newArray[ newArray.size ] = vehicle;
			}
			
			level.vehicles_list = newArray;
		}
		
		return level.vehicles_list.size < MAX_VEHICLES;
	}
}


/@
"Name: init_vehicle( )"
"Summary: Initializes a vehicle entity when the game starts"
"Module: Vehicle"
"Example: vehicle init_vehicle();"
"SPMP: multiplayer"
@/ 
function init_vehicle()
{
	self register_vehicle();
	

	// setting the tank health here so it is universal
	// we should do the same for the other vehicles
	if ( isdefined( level.vehicleHealths ) && isdefined( level.vehicleHealths[ self.vehicletype ] ) )
	{
		self.maxhealth = level.vehicleHealths[ self.vehicletype ];
	}
	else
	{
		self.maxhealth = GetDvarint( "scr_veh_health_tank");
/#
		println( "No health specified for vehicle type "+self.vehicletype+"! Using default..." );
#/
	}
	self.health = self.maxhealth;
		
	self vehicle_record_initial_values();
	
	self init_vehicle_threads();
	
	system::wait_till( "spawning" );

	// add the influencer to block all teams
	self spawning::create_entity_masked_enemy_influencer( "vehicle", 0 );
}


function initialize_vehicle_damage_state_data()
{
	if (self.initial_state.health>0)
	{
		self.current_health_percentage= self.health/self.initial_state.health;
		self.previous_health_percentage= self.health/self.initial_state.health;
	}
	else
	{
		self.current_health_percentage= 1;
		self.previous_health_percentage= 1;
	}
	
	return;
}

function init_original_vehicle()
{
	// this is a temporary hack trying to resolve the "!cent->pose.fx.effect"
	// crash bug.  Basically I think the bug is caused by deleteing the original 
	// tanks that were in the bsp
	self.original_vehicle = true;
	
	self init_vehicle();
}

function player_wait_exit_vehicle_t()
{
	// Don't endon "death".  Player will receive
	// "exit_vehicle" message when killed in a vehicle
	self endon( "disconnect" );
	
	self waittill( "exit_vehicle", vehicle );
	self player_update_vehicle_hud( false, vehicle );
}



function player_update_vehicle_hud( show, vehicle )
{
	if( show )
	{
		if ( !isdefined( self.vehicleHud ) )
		{
			self.vehicleHud = hud::createBar( (1, 1, 1), 64, 16 );
			self.vehicleHud hud::setPoint( "CENTER", "BOTTOM", 0, -40 );
			self.vehicleHud.alpha = 0.75;
		}

		self.vehicleHud hud::updateBar( vehicle.health / vehicle.initial_state.health );
	}
	else
	{
		if ( isdefined( self.vehicleHud ) )
		{
			self.vehicleHud hud::destroyElem();
		}
	}

	if ( GetDvarString( "scr_vehicle_healthnumbers" )!= "" )
	{
		if ( GetDvarint( "scr_vehicle_healthnumbers" )!= 0 )
		{
			if( show )
			{
				if ( !isdefined( self.vehicleHudHealthNumbers ) )
				{
					self.vehicleHudHealthNumbers = hud::createFontString( "default", 2.0 );
					self.vehicleHudHealthNumbers hud::setParent( self.vehicleHud );
					self.vehicleHudHealthNumbers hud::setPoint( "LEFT", "RIGHT", 8, 0 );
					self.vehicleHudHealthNumbers.alpha = 0.75;
					self.vehicleHudHealthNumbers.hideWhenInMenu = false;
					self.vehicleHudHealthNumbers.archived = false;
				}

				self.vehicleHudHealthNumbers setValue( vehicle.health );
			}
			else
			{
				if ( isdefined( self.vehicleHudHealthNumbers ) )
				{
					self.vehicleHudHealthNumbers hud::destroyElem();
				}
			}
		}
	}
}


function init_vehicle_threads()
{
	self thread vehicle_abandoned_by_drift_t();
	self thread vehicle_abandoned_by_occupants_t();
	self thread vehicle_damage_t();
	self thread vehicle_ghost_entering_occupants_t();
	
	self thread vehicle_recycle_spawner_t();
	self thread vehicle_disconnect_paths();
	
	self thread vehicle_wait_tread_damage();

	self thread vehicle_overturn_eject_occupants();
	
	if (GetDvarint( "scr_veh_disableoverturndamage") == 0)
	{
		self thread vehicle_overturn_suicide();
	}
}

/@
"Name: build_template( <type> , <model> , <typeoverride> )"
"Summary: called in individual vehicle file - mandatory to call this in all vehicle files at the top!"
"Module: vehicle_build( vehicle.gsc )"
"CallOn: "
"MandatoryArg: <type> : vehicle type to set"
"MandatoryArg: <model> : model to set( this is usually generated by the level script )"
"OptionalArg: <typeoverride> : this overrides the type, used for copying a vehicle script"
"Example: 	build_template( "bmp", model, type );"
"SPMP: singleplayer"
@/ 

function build_template( type, model, typeoverride )
{
	if( isdefined( typeoverride ) )
		type = typeoverride; 

	if( !isdefined( level.vehicle_death_fx ) )
		level.vehicle_death_fx = []; 
	if( 	!isdefined( level.vehicle_death_fx[ type ] ) )
		level.vehicle_death_fx[ type ] = []; // can have overrides
	
	level.vehicle_compassicon[ type ] = false; 
	level.vehicle_team[ type ] = "axis"; 
	level.vehicle_life[ type ] = 999; 
	level.vehicle_hasMainTurret[ model ] = false; 
	level.vehicle_mainTurrets[ model ] = [];
	level.vtmodel = model; 
	level.vttype = type; 
}

/@
"Name: build_rumble( <rumble> , <scale> , <duration> , <radius> , <basetime> , <randomaditionaltime> )"
"Summary: called in individual vehicle file - define amount of radius damage to be set on each vehicle"
"Module: vehicle_build( vehicle.gsc )"
"CallOn: "
"MandatoryArg: <rumble> :  rumble asset"
"MandatoryArg: <scale> : scale"
"MandatoryArg: <duration> : duration"
"MandatoryArg: <radius> : radius"
"MandatoryArg: <basetime> : time to wait between rumbles"
"MandatoryArg: <randomaditionaltime> : random amount of time to add to basetime"
"Example: 			build_rumble( "tank_rumble", 0.15, 4.5, 600, 1, 1 );"
"SPMP: singleplayer"
@/ 

function build_rumble( rumble, scale, duration, radius, basetime, randomaditionaltime )
{
	if( !isdefined( level.vehicle_rumble ) )
		level.vehicle_rumble = []; 
	struct = build_quake( scale, duration, radius, basetime, randomaditionaltime );
	assert( isdefined( rumble ) );
	struct.rumble = rumble; 
	level.vehicle_rumble[ level.vttype ] = struct; 
}

function build_quake( scale, duration, radius, basetime, randomaditionaltime )
{
	struct = spawnstruct();
	struct.scale = scale; 
	struct.duration = duration; 
	struct.radius = radius; 
	if( isdefined( basetime ) )
		struct.basetime = basetime; 
	if( isdefined( randomaditionaltime ) )
		struct.randomaditionaltime = randomaditionaltime; 
	return struct; 
}

/@
"Name: build_exhaust( <exhaust_effect_str> )"
"Summary: called in individual vehicle file - assign an exhaust effect to this vehicle!"
"Module: vehicle_build( vehicle.gsc )"
"CallOn: "
"MandatoryArg: <exhaust_effect_str> : exhaust effect in string format"
"Example: 	build_exhaust( "_t6/vehicle/exhaust/fx_exhaust_tank" );"
"SPMP: singleplayer"
@/ 

function build_exhaust( effect )
{
	level.vehicle_exhaust[ level.vtmodel ] = effect;
}


// =====================================================================================
// Abandonment Code

function vehicle_abandoned_by_drift_t()
{
	self endon( "transmute" );
	self endon( "death" );
	self endon( "delete" );
	
	self wait_then_cleanup_vehicle( "Drift Test", "scr_veh_cleanupdrifted" );
}


function vehicle_abandoned_by_occupants_timeout_t()
{
	self endon( "transmute" );
	self endon( "death" );
	self endon( "delete" );
	
	self wait_then_cleanup_vehicle( "Abandon Test", "scr_veh_cleanupabandoned" );
}


function wait_then_cleanup_vehicle( test_name, cleanup_dvar_name )
{
	self endon( "enter_vehicle" );
	
	self wait_until_severely_damaged();
	self do_alive_cleanup_wait( test_name );
	self wait_for_vehicle_to_stop_outside_min_radius(); // unoccupied vehicle can be being pushed!
	self cleanup( test_name, cleanup_dvar_name,&vehicle_recycle );
}


function wait_until_severely_damaged()
{
	while ( 1 )
	{
		health_percentage = self.health / self.initial_state.health;
		
		self waittill( "damage" );
		
		health_percentage = self.health / self.initial_state.health;
		
		if ( health_percentage < level.k_severe_damage_health_percentage )
			break;
	}
}


function get_random_cleanup_wait_time( state )
{
	varnamePrefix = "scr_veh_" + state + "_cleanuptime";
	minTime = getdvarfloat( varnamePrefix + "min" );
	maxTime = getdvarfloat( varnamePrefix + "max" );	
	
	if ( maxTime > minTime )
	{
		return RandomFloatRange( minTime, maxTime );
	}
	else
	{
		return maxTime;
	}
}


function do_alive_cleanup_wait( test_name )
{
	initialRandomWaitSeconds = get_random_cleanup_wait_time( "alive" );
		
	secondsWaited = 0.0;
	seconds_per_iteration = 1.0;
	
	while ( true )
	{	
		curve_begin = GetDvarfloat( "scr_veh_cleanuptime_dmgfraction_curve_begin" );
		curve_end = GetDvarfloat( "scr_veh_cleanuptime_dmgfraction_curve_end" );
		
		factor_min = GetDvarfloat( "scr_veh_cleanuptime_dmgfactor_min" );
		factor_max = GetDvarfloat( "scr_veh_cleanuptime_dmgfactor_max" );
		
		treadDeadDamageFactor = GetDvarfloat( "scr_veh_cleanuptime_dmgfactor_deadtread" );
		
	
		damageFraction = 0.0;
	
		if ( self is_vehicle() )
		{
			damageFraction = ( self.initial_state.health - self.health ) / self.initial_state.health;	
		}
		else // is husk
		{
			damageFraction = 1.0;
		}
	
		damageFactor = 0.0;
	
		if ( damageFraction <= curve_begin )
		{
			damageFactor = factor_max;
		}
		else if ( damageFraction >= curve_end )
		{
			damageFactor = factor_min;
		}
		else
		{
			dydx = ( factor_min - factor_max ) / ( curve_end - curve_begin );
			damageFactor = factor_max + ( damageFraction - curve_begin ) * dydx;
		}
	
		totalSecsToWait = initialRandomWaitSeconds * damageFactor;
		
		if ( secondsWaited >= totalSecsToWait )
		{
			break;
		}
		
		wait seconds_per_iteration;
		secondsWaited = secondsWaited + seconds_per_iteration;
	}
}


function do_dead_cleanup_wait( test_name )
{
	total_secs_to_wait = get_random_cleanup_wait_time( "dead" );
		
	seconds_waited = 0.0;
	seconds_per_iteration = 1.0;
	
	while ( seconds_waited < total_secs_to_wait )
	{	
		wait seconds_per_iteration;
		seconds_waited = seconds_waited + seconds_per_iteration;
	}
}


function cleanup( test_name, cleanup_dvar_name, cleanup_func )
{
	keep_waiting = true;

	while ( keep_waiting )
	{
		cleanupEnabled = !isdefined( cleanup_dvar_name )
			|| getdvarint( cleanup_dvar_name ) != 0;
		
		if ( cleanupEnabled != 0 )
		{
			self [[cleanup_func]]();
			break;
		}
		
		keep_waiting = false;
	}
}

function vehicle_wait_tread_damage()
{
	self endon( "death" );
	self endon( "delete" );

	vehicle_name= get_vehicle_name(self);
	
	while ( 1 )
	{
		self waittill ( "broken", brokenNotify );
		if ( brokenNotify == "left_tread_destroyed" )
		{
			if ( isdefined( level.vehicles_damage_treadfx[vehicle_name] ) && isdefined( level.vehicles_damage_treadfx[vehicle_name][0] ) )
			{
				self thread play_vehicle_effects( level.vehicles_damage_treadfx[vehicle_name][0], true );
			}
		}
		else if ( brokenNotify == "right_tread_destroyed" )
		{
			if ( isdefined( level.vehicles_damage_treadfx[vehicle_name] ) && isdefined( level.vehicles_damage_treadfx[vehicle_name][1] ) )
			{
				self thread play_vehicle_effects( level.vehicles_damage_treadfx[vehicle_name][1], true );
			}
		}
	}
}

function wait_for_vehicle_to_stop_outside_min_radius()
{
	maxWaitTime = GetDvarfloat( "scr_veh_waittillstoppedandmindist_maxtime" );
	iterationWaitSeconds = 1.0;
	
	maxWaitTimeEnableDistInches = 12 * GetDvarfloat( "scr_veh_waittillstoppedandmindist_maxtimeenabledistfeet" );
	
	initialOrigin = self.initial_state.origin;
	
	for ( totalSecondsWaited = 0.0; totalSecondsWaited < maxWaitTime; totalSecondsWaited += iterationWaitSeconds )
	{
		// We don't want to disappear it if someone is
		// currently pushing it with another vehicle
		speedMPH = self GetSpeedMPH();
		cutoffMPH = GetDvarfloat( "scr_veh_cleanupmaxspeedmph" );
		
		if ( speedMPH > cutoffMPH )
		{
		}
		else
		{
			break;
		}
		
		wait iterationWaitSeconds;
	}
}


function vehicle_abandoned_by_occupants_t()
{
	self endon( "transmute" );
	self endon( "death" );
	self endon( "delete" );
	
	while ( 1 )
	{
		self waittill( "exit_vehicle" );
		
		occupants = self GetVehOccupants();
		
		if ( occupants.size == 0 )
		{
			self play_start_stop_sound( "tank_shutdown_sfx" );
			self thread vehicle_abandoned_by_occupants_timeout_t();
		}
	}
}


function play_start_stop_sound( sound_alias, modulation )
{
	if ( isdefined( self.start_stop_sfxid ) )
	{
		//stopSound( self.start_stop_sfxid );
	}
	
	self.start_stop_sfxid = self playSound( sound_alias );
}


// this function should be replaced by code in cg_player.cpp cg_player() 
// we should just not be rendering the player when in a non-visible seat
function vehicle_ghost_entering_occupants_t()
{
	self endon( "transmute" );
	self endon( "death" );
	self endon( "delete" );
	
	//if ( self vehicle_is_tank() )
	{
		while ( 1 )
		{
			self waittill( "enter_vehicle", player, seat );
			
			isDriver = seat == 0;
			
			if ( GetDvarint( "scr_veh_driversarehidden" ) != 0
				&& isDriver )
			{
				player Ghost();
			}
			
			
			{
				occupants = self GetVehOccupants();
				
				if ( occupants.size == 1 )
				{
					self play_start_stop_sound( "tank_startup_sfx" );
				}
			}
			
			
			player thread player_change_seat_handler_t( self );
			player thread player_leave_vehicle_cleanup_t( self );
		}
	}
}


function player_is_occupant_invulnerable( sMeansOfDeath )
{
	if ( self IsRemoteControlling() )
		return false;
		
	if (!isdefined(level.vehicle_drivers_are_invulnerable))
		level.vehicle_drivers_are_invulnerable = false;
		
	invulnerable = ( level.vehicle_drivers_are_invulnerable	&& ( self player_is_driver() ) );
	
	return invulnerable;
}


function player_is_driver()
{
	if ( !isalive(self) )
		return false;
		
	vehicle = self GetVehicleOccupied();
	
	if ( isdefined( vehicle ) )
	{
		seat = vehicle GetOccupantSeat( self );
		
		if ( isdefined(seat) && seat == 0 )
			return true;
	}
	
	return false;
}


// this function should be replaced by code in cg_player.cpp cg_player() 
// we should just not be rendering the player when in a non-visible seat
function player_change_seat_handler_t( vehicle )
{
	self endon( "disconnect" );
	self endon( "exit_vehicle" );

	while ( 1 ) 
	{
		self waittill( "change_seat", vehicle, oldSeat, newSeat );
		
		isDriver = newSeat == 0;
		
		if ( isDriver )
		{
			if ( GetDvarint( "scr_veh_driversarehidden" ) != 0 )
			{
				self Ghost();
			}
		}
		else
		{
			self Show();
		}
	}
}


// this function should be replaced by code in cg_player.cpp cg_player() 
// we should just not be rendering the player when in a non-visible seat
function player_leave_vehicle_cleanup_t( vehicle )
{
	self endon( "disconnect" );
	self waittill( "exit_vehicle" );
	currentWeapon = self getCurrentWeapon();
	
	if( self.lastWeapon != currentWeapon && self.lastWeapon != level.weaponNone )
		self switchToWeapon( self.lastWeapon );

	self Show();
}


function vehicle_is_tank()
{
	return self.vehicletype == "sherman_mp"
		|| self.vehicletype == "panzer4_mp"
		|| self.vehicletype == "type97_mp"
		|| self.vehicletype == "t34_mp";
}

// =====================================================================================


function vehicle_record_initial_values()
{
	if ( !isdefined( self.initial_state ) )
	{
		self.initial_state= SpawnStruct();
	}
	
	if ( isdefined( self.origin ) )
	{
		self.initial_state.origin= self.origin;
	}
	
	if ( isdefined( self.angles ) )
	{
		self.initial_state.angles= self.angles;
	}
	
	if ( isdefined( self.health ) )
	{
		self.initial_state.health= self.health;
	}

	self initialize_vehicle_damage_state_data();
	
	return;
}


function vehicle_should_explode_on_cleanup()
{
	return GetDvarint( "scr_veh_explode_on_cleanup" ) != 0;
}


function vehicle_recycle()
{
	self wait_for_unnoticeable_cleanup_opportunity();
	self.recycling = true;
	self suicide();
}

function wait_for_vehicle_overturn()
{
	self endon( "transmute" );
	self endon( "death" );
	self endon( "delete" );

	worldup = anglestoup((0,90,0));
	
	overturned = 0;
	
	while (!overturned)	
	{
		if ( isdefined( self.angles ) )
		{
			up = AnglesToUp( self.angles );
			dot = vectordot(up, worldup);
			if (dot <= 0.0)
				overturned = 1;
		}
		
		if (!overturned)
			wait (1.0);
	}
}

function vehicle_overturn_eject_occupants()
{
	self endon( "transmute" );
	self endon( "death" );
	self endon( "delete" );

	for(;;)
	{
		self waittill( "veh_ejectoccupants" );

		if ( isdefined( level.onEjectOccupants ) )
		{
			[[level.onEjectOccupants]]();
		}

		wait .25;
	}
}

function vehicle_eject_all_occupants()
{
	occupants = self GetVehOccupants();
	if ( isdefined( occupants ) )
	{
		for ( i = 0; i < occupants.size; i++ )
		{
			if ( isdefined( occupants[i] ) )
			{
				occupants[i] Unlink();
			}
		}
	}
}

function vehicle_overturn_suicide()
{
	self endon( "transmute" );
	self endon( "death" );
	self endon( "delete" );
	
	self wait_for_vehicle_overturn();

	seconds = RandomFloatRange( 5, 7 );
	wait seconds;
	
	damageOrigin = self.origin + (0,0,25);
	self finishVehicleRadiusDamage(self, self, 32000, 32000, 32000, 0, "MOD_EXPLOSIVE", level.weaponNone,  damageOrigin, 400, -1, (0,0,1), 0);
}

function suicide()
{
	self kill_vehicle( self );
}

function kill_vehicle( attacker )
{
	damageOrigin = self.origin + (0,0,1);
	self finishVehicleRadiusDamage(attacker, attacker, 32000, 32000, 10, 0, "MOD_EXPLOSIVE", level.weaponNone,  damageOrigin, 400, -1, (0,0,1), 0);
}

function value_with_default( preferred_value, default_value )
{
	if ( isdefined( preferred_value ) )
	{
		return preferred_value;
	}
	
	return default_value;
}


function vehicle_transmute( attacker )
{
	deathOrigin = self.origin;
	deathAngles = self.angles;
	
	
	vehicle_name = get_vehicle_name_key_for_damage_states( self );
	
	
	respawn_parameters = SpawnStruct();
	respawn_parameters.origin = self.initial_state.origin;
	respawn_parameters.angles = self.initial_state.angles;
	respawn_parameters.health = self.initial_state.health;
	respawn_parameters.targetname = value_with_default( self.targetname, "" );
	respawn_parameters.vehicletype = value_with_default( self.vehicletype, "" );
	respawn_parameters.destructibledef = self.destructibledef; // Vehicle may or may not be a destructible vehicle
	
	
	vehicleWasDestroyed = !isdefined( self.recycling );

	if ( vehicleWasDestroyed
		|| vehicle_should_explode_on_cleanup() )
	{
		_spawn_explosion( deathOrigin );
		
		if ( vehicleWasDestroyed
			&& GetDvarint( "scr_veh_explosion_doradiusdamage" ) != 0 )
		{
			// Vehicle is exploding, so damage nearby entities
			// Damage first, so doesn't affect other entities spawned
			// by this function
			
			explosionRadius = GetDvarint( "scr_veh_explosion_radius" );
			explosionMinDamage = GetDvarint( "scr_veh_explosion_mindamage" );
			explosionMaxDamage = GetDvarint( "scr_veh_explosion_maxdamage" );
			self kill_vehicle(attacker);
			self RadiusDamage( deathOrigin, explosionRadius, explosionMaxDamage, explosionMinDamage, attacker, "MOD_EXPLOSIVE", GetWeapon( self.vehicletype + "_explosion" ) );////////////////XXXXXXXXXXXXXXXXX COLLATERAL DAMAGE
		}
	}
	
	
	self notify( "transmute" );
	
		
	respawn_vehicle_now = true;
	
	if ( vehicleWasDestroyed
		&& GetDvarint( "scr_veh_ondeath_createhusk" ) != 0 )
	{
		// Spawn burned out husk for players to use as cover
		
		if ( GetDvarint( "scr_veh_ondeath_usevehicleashusk" ) != 0 )
		{
			husk = self;
			self.is_husk = true;
		}
		else
		{
			husk = _spawn_husk( deathOrigin, deathAngles, self.vehmodel );
		}
			
		husk _init_husk( vehicle_name, respawn_parameters );
		
		if ( GetDvarint( "scr_veh_respawnafterhuskcleanup" ) != 0 )
		{
			respawn_vehicle_now = false;
		}
	}
	
	
	if ( !isdefined( self.is_husk ) )
	{
		self remove_vehicle_from_world();
	}

	if ( GetDvarint( "scr_veh_disablerespawn" ) != 0 ) //The Vehicle Mayhem gamemode handles spawning the vehicles, so it does not need to respawn here
	{
		respawn_vehicle_now = false;
	}

	if ( respawn_vehicle_now )
	{
		respawn_vehicle( respawn_parameters );
	}
}


function respawn_vehicle( respawn_parameters )
{	
	{
		minTime = GetDvarint( "scr_veh_respawntimemin" );
		maxTime = GetDvarint( "scr_veh_respawntimemax" );
		seconds = RandomFloatRange( minTime, maxTime );
		wait seconds;
	}
	
	
	wait_until_vehicle_position_wont_telefrag( respawn_parameters.origin );
	
			
	if ( !manage_vehicles() ) // make sure we don't hit max vehicle limit
	{
		/#
		iprintln("Vehicle can't respawn because MAX_VEHICLES has been reached and none of the vehicles could be cleaned up.");
		#/
	}
	else
	{		
		if ( isdefined( respawn_parameters.destructibledef ) ) // passing undefined argument doesn't make the server happy
		{
			vehicle = SpawnVehicle(
				respawn_parameters.vehicletype,
				respawn_parameters.origin,
				respawn_parameters.angles,
				respawn_parameters.targetname,
				respawn_parameters.destructibledef );
		}
		else
		{
			vehicle = SpawnVehicle(
				respawn_parameters.vehicletype,
				respawn_parameters.origin,
				respawn_parameters.angles,
				respawn_parameters.targetname );
		}
		
		vehicle.vehicletype = respawn_parameters.vehicletype;
		vehicle.destructibledef = respawn_parameters.destructibledef;
		vehicle.health = respawn_parameters.health;
		
		vehicle init_vehicle();
	
		vehicle vehicle_telefrag_griefers_at_position( respawn_parameters.origin );
	}
}


function remove_vehicle_from_world()
{
	// this is a temporary hack trying to resolve the "!cent->pose.fx.effect"
	// crash bug.  Basically I think the bug is caused by deleteing the original 
	// tanks that were in the bsp

	self notify ( "removed" );
	
	if ( isdefined( self.original_vehicle ) )
	{
		if ( !isdefined( self.permanentlyRemoved ) )
		{
			self.permanentlyRemoved = true; // Mark that it has been permanently removed from the world
			self thread hide_vehicle(); // threaded because it calls a wait()
		}
		
		return false;
	}
	else 
	{
		self _delete_entity();
		return true;
	}
}


function _delete_entity()
{
	/#
	//iprintln("$e" + ( self GetEntNum() ) + " is deleting");
	#/
	
	self Delete();
}


function hide_vehicle()
{
	under_the_world = ( self.origin[0], self.origin[1], self.origin[2] - 10000 );
	self.origin = under_the_world;

	wait 0.1;
	self Hide();
	
	self notify( "hidden_permanently" );
}


function wait_for_unnoticeable_cleanup_opportunity()
{	
	maxPreventDistanceFeet = GetDvarint( "scr_veh_disappear_maxpreventdistancefeet" );
	maxPreventVisibilityFeet = GetDvarint( "scr_veh_disappear_maxpreventvisibilityfeet" );
	
	maxPreventDistanceInchesSq = 144 * maxPreventDistanceFeet * maxPreventDistanceFeet;
	maxPreventVisibilityInchesSq = 144 * maxPreventVisibilityFeet * maxPreventVisibilityFeet;
	

	maxSecondsToWait = GetDvarfloat( "scr_veh_disappear_maxwaittime" );	
	iterationWaitSeconds = 1.0;
	
	for ( secondsWaited = 0.0; secondsWaited < maxSecondsToWait; secondsWaited += iterationWaitSeconds )
	{
		players_s = util::get_all_alive_players_s();
		
		okToCleanup = true;
		
		for ( j = 0; j < players_s.a.size && okToCleanup; j++ )
		{
			player = players_s.a[ j ];
			distInchesSq = DistanceSquared( self.origin, player.origin );
			
			if ( distInchesSq < maxPreventDistanceInchesSq )
			{
				okToCleanup = false;
			}
			else if ( distInchesSq < maxPreventVisibilityInchesSq )
			{
				vehicleVisibilityFromPlayer = self SightConeTrace( player.origin, player, AnglesToForward( player.angles ) );
				
				if ( vehicleVisibilityFromPlayer > 0 )
				{
					okToCleanup = false;
				}
			}
		}
		
		if ( okToCleanup )
		{
			return;
		}
	
		wait iterationWaitSeconds;
	}
}


function wait_until_vehicle_position_wont_telefrag( position )
{
	maxIterations = GetDvarint( "scr_veh_respawnwait_maxiterations" );
	iterationWaitSeconds = GetDvarint( "scr_veh_respawnwait_iterationwaitseconds" );
	
	for ( i = 0; i < maxIterations; i++ )
	{
		if ( !vehicle_position_will_telefrag( position ) )
		{
			return;
		}
		
		wait iterationWaitSeconds;
	}
}


function vehicle_position_will_telefrag( position )
{
	players_s = util::get_all_alive_players_s();
	
	for ( i = 0; i < players_s.a.size; i++ )
	{
		if ( players_s.a[ i ] player_vehicle_position_will_telefrag( position ) )
		{
			return true;
		}
	}
	
	return false;
}


function vehicle_telefrag_griefers_at_position( position )
{
	attacker = self;
	inflictor = self;

	players_s = util::get_all_alive_players_s();
	
	for ( i = 0; i < players_s.a.size; i++ )
	{
		player = players_s.a[ i ];
		
		if ( player player_vehicle_position_will_telefrag( position ) )
		{
			player DoDamage( 20000, player.origin + ( 0, 0, 1 ), attacker, inflictor, "none" );
		}
	}
}


function player_vehicle_position_will_telefrag( position )
{
	distanceInches = 20 * 12; ///< 20 ft., in inches
	minDistInchesSq = distanceInches * distanceInches;
	
	distInchesSq = DistanceSquared( self.origin, position );
	
	return distInchesSq < minDistInchesSq;
}


function vehicle_recycle_spawner_t()
{
	self endon( "delete" );
	
	self waittill( "death", attacker ); // "vehicle Delete()" sends death message too!!!
	
	if ( isdefined( self ) )
	{
		self vehicle_transmute( attacker );
	}
}


function vehicle_play_explosion_sound()
{
	self playSound( "car_explo_large" );
}


function vehicle_damage_t()
{
	self endon( "delete" );
	self endon( "removed" );
	
	for( ;; )
	{
		self waittill ( "damage", damage, attacker );

		players = GetPlayers();
		for ( i = 0 ; i < players.size ; i++ )
		{
			if ( !isalive(players[i]) )
				continue;
				
			vehicle = players[i] GetVehicleOccupied();
			if ( isdefined( vehicle) && self == vehicle && players[i] player_is_driver() )
			{
				if (damage>0)
				{
					// ^^^ earthquake() will generate an SRE if scale <= 0
					earthquake( damage/400, 1.0, players[i].origin, 512, players[i] );
				}
				
				if ( damage > 100.0 )
				{
/#
					println( "Playing heavy rumble." );
#/
					players[i] PlayRumbleOnEntity( "tank_damage_heavy_mp" );
				}
				else if ( damage > 10.0 )
				{
/#
					println( "Playing light rumble." );
#/
					players[i] PlayRumbleOnEntity( "tank_damage_light_mp" );
				}
			}
		}
		
		update_damage_effects(self, attacker);
		if ( self.health <= 0 )
		{
			return;
		}
	}
}


// =====================================================================================
// Burnt-Out Husk Code
	
function _spawn_husk( origin, angles, modelname )
{	
	husk = spawn( "script_model", origin );
	husk.angles = angles;
	husk SetModel( modelname );
	
	husk.health = 1;
	husk SetCanDamage( false ); ///< Does this really work?  It doesn't for players, but might for other entities
	
	return husk;
}


function is_vehicle()
{
	// Could check classname=="script_vehicle", but this is a little more general purpose, I think
	return isdefined( self.vehicletype );
}


function swap_to_husk_model()
{
	if ( isdefined( self.vehicletype ) )
	{
		husk_model = level.veh_husk_models[ self.vehicletype ];
		
		if ( isdefined( husk_model ) )
		{
			self SetModel( husk_model );
		}
	}
}


function _init_husk( vehicle_name, respawn_parameters )
{
	self swap_to_husk_model();

	effects = level.vehicles_husk_effects[ vehicle_name ];
	self play_vehicle_effects( effects );
	
	
	self.respawn_parameters = respawn_parameters;
	
	
	forcePointVariance = GetDvarint( "scr_veh_explosion_husk_forcepointvariance" );
	horzVelocityVariance = GetDvarint( "scr_veh_explosion_husk_horzvelocityvariance" );
	vertVelocityMin = GetDvarint( "scr_veh_explosion_husk_vertvelocitymin" );
	vertVelocityMax = GetDvarint( "scr_veh_explosion_husk_vertvelocitymax" );
	
	
	forcePointX = RandomFloatRange( 0-forcePointVariance, forcePointVariance );
	forcePointY = RandomFloatRange( 0-forcePointVariance, forcePointVariance );
	forcePoint = ( forcePointX, forcePointY, 0 );

	forcePoint += self.origin;
	
	initialVelocityX = RandomFloatRange( 0-horzVelocityVariance, horzVelocityVariance );
	initialVelocityY = RandomFloatRange( 0-horzVelocityVariance, horzVelocityVariance );
	initialVelocityZ = RandomFloatRange( vertVelocityMin, vertVelocityMax );
	initialVelocity = ( initialVelocityX, initialVelocityY, initialVelocityZ );
	
	
	if ( self is_vehicle() )
	{
		self LaunchVehicle( initialVelocity, forcePoint );
	}
	else
	{
		self PhysicsLaunch( forcePoint, initialVelocity );
	}
	
	
	self thread husk_cleanup_t();
}


function husk_cleanup_t()
{
	self endon( "death" ); // ent Delete() actually sends the "death" message!!!
	self endon( "delete" );
	self endon( "hidden_permanently" );
	
	
	respawn_parameters = self.respawn_parameters;
	
	
	self do_dead_cleanup_wait( "Husk Cleanup Test" );
	
	self wait_for_unnoticeable_cleanup_opportunity();
	
	
	self thread final_husk_cleanup_t( respawn_parameters ); // break off new thread to avoid end-ons
}


function final_husk_cleanup_t( respawn_parameters )
{
	self husk_do_cleanup(); // causes endons, which is why we broke this off into a new thread
	
	if ( GetDvarint( "scr_veh_respawnafterhuskcleanup" ) != 0 )
	{
		if ( GetDvarint( "scr_veh_disablerespawn" ) == 0 ) //The Vehicle Mayhem gamemode handles spawning the vehicles, so it does not need to respawn here
		{
			respawn_vehicle( respawn_parameters );
		}	
	}
}


// Returns true only if the entity is actually deleted, rather than just hidden.
function husk_do_cleanup()
{
	// Don't ever let vehicles just blink out.  Spawn a VFX
	// explosion that doesn't injur any surrounding entities,
	// just to mask the blink out, in case players are
	// looking in the direction of this vehicle husk.
	self _spawn_explosion( self.origin );
	
	
	if ( self is_vehicle() )
	{
		return self remove_vehicle_from_world();
	}
	else
	{
		self _delete_entity();
		return true;
	}
}

// =====================================================================================


// =====================================================================================
// Explosion Code
	
function _spawn_explosion( origin )
{
	if ( GetDvarint( "scr_veh_explosion_spawnfx" ) == 0 )
	{
		return;
	}
	
	if ( isdefined( level.vehicle_explosion_effect ) )
	{
		forward = ( 0, 0, 1 );
		
		rot = randomfloat( 360 );
		up = ( cos( rot ), sin( rot ), 0 );
		
		PlayFX( level.vehicle_explosion_effect, origin, forward, up );
	}
	
	thread _play_sound_in_space( "vehicle_explo", origin );
}


// NOTE: This function was copied from sab.gsc.  Should be centralized somewhere...
function _play_sound_in_space( soundEffectName, origin )
{
	org = Spawn( "script_origin", origin );
	org.origin = origin;
	org PlaySoundWithNotify( soundEffectName, "sounddone"  );
	org waittill( "sounddone" );
	org delete();
}

// =====================================================================================

function vehicle_kill_disconnect_paths_forever()
{
	self notify( "kill_disconnect_paths_forever" );
}

function vehicle_disconnect_paths()
{
/*	MPAI_PETER_TODO
	self endon( "death" );
	self endon( "kill_disconnect_paths_forever" );
	if ( isdefined( self.script_disconnectpaths ) && !self.script_disconnectpaths )
	{
		self.dontDisconnectPaths = true;// lets other parts of the script know not to disconnect script
		return;		
	}
	wait( randomfloat( 1 ) );
	while( isdefined( self ) )
	{
		if( self getspeed() < 1 )
		{
			if ( !isdefined( self.dontDisconnectPaths ) )
			self disconnectpaths();
			self notify( "speed_zero_path_disconnect" );
			while( self getspeed() < 1 )
				wait .05; 
		}
		self connectpaths();
		wait 1; 
	}
 */
}

function follow_path( node )
{
	self endon("death");
	
	assert( isdefined( node ), "vehicle_path() called without a path" );
	self notify( "newpath" );

	 // dynamicpaths unique.  node isn't defined by info vehicle node calls to this function
	if( isdefined( node ) )
	{
		self.attachedpath = node; 
	}
	
	pathstart = self.attachedpath; 
	self.currentNode = self.attachedpath; 

	if( !isdefined( pathstart ) )
	{
		return; 
	}

	self AttachPath( pathstart );
	self StartPath();

	self endon( "newpath" );

	nextpoint = pathstart;

	while ( isdefined( nextpoint ) )
	{
		self waittill( "reached_node", nextpoint );	

		self.currentNode = nextpoint;
		
		// the sweet stuff! Pathpoints handled in script as triggers!
		nextpoint notify( "trigger", self );

		if ( isdefined( nextpoint.script_noteworthy ) )
		{
			self notify( nextpoint.script_noteworthy );
			self notify( "noteworthy", nextpoint.script_noteworthy, nextpoint );
		}
		
		waittillframeend; 
	}
}

function InitVehicleMap()
{
	thread VehicleMainThread();
	
	level.vehicle_map = 1;
}

function VehicleMainThread()
{
	//"siegebot";
	//"siegebot_boss";
	//"quadtank";
	
	//spawn_nodes = getentarray( "veh_spawn_point", "targetname" );
	spawn_nodes = struct::get_array( "veh_spawn_point", "targetname" );

	for( i = 0; i < spawn_nodes.size; i++ )
	{
		spawn_node = spawn_nodes[i];
		
		veh_name = spawn_node.script_noteworthy;
		time_interval = int(spawn_node.script_parameters);
		
		if( !isdefined( veh_name ) )
			continue;
		
		thread VehicleSpawnThread( veh_name, spawn_node.origin, spawn_node.angles, time_interval );
		WAIT_SERVER_FRAME;
	}
}

function VehicleSpawnThread( veh_name, origin, angles, time_interval )
{
	level endon( "game_ended" );
	
	veh_spawner = GetEnt( veh_name + "_spawner", "targetname" );
	
	while( 1 )
	{
		vehicle = veh_spawner SpawnFromSpawner( veh_name, true, true, true );
		if( !isdefined( vehicle ) )
		{
	   		wait RandomFloatRange( 1.0, 2.0 );
	   		continue;
		}
			
		vehicle ASMRequestSubstate( "locomotion@movement" );
		
		WAIT_SERVER_FRAME;
		
		vehicle MakeVehicleUsable();
		if( Target_isTarget( vehicle ) )
			Target_Remove( vehicle );
		vehicle.origin = origin;
		vehicle.angles = angles;
		vehicle.noJumping = true;
		vehicle.forceDamageFeedback = true;
		vehicle.vehkilloccupantsondeath = true;
		vehicle DisableAimAssist();
		
		vehicle thread VehicleTeamThread();
		
		vehicle waittill( "death" );
		vehicle vehicle_death::DeleteWhenSafe( 0.25 );
		
		if( isdefined( time_interval ) )
			wait time_interval;
	}
}

function VehicleTeamThread()
{
	vehicle = self;
	vehicle endon( "death" );
	
	while( 1 )
	{
		vehicle waittill( "enter_vehicle", player );
		vehicle setteam( player.team );
		//vehicle SetHighDetail( true );
		vehicle clientfield::set( "toggle_lights", CF_TOGGLE_LIGHTS_OFF );
		if( !Target_isTarget( vehicle ) )
		{
			if( isdefined( vehicle.targetOffset ) )
				Target_Set( vehicle, vehicle.targetOffset );	
			else
				Target_Set( vehicle, ( 0, 0, 0 ) );	
		}
		
		vehicle thread WatchPlayerExitRequestThread( player );
		
		vehicle waittill( "exit_vehicle", player );
		vehicle setteam( "neutral" );	
		//vehicle SetHighDetail( false );
		vehicle clientfield::set( "toggle_lights", CF_TOGGLE_LIGHTS_ON );
		if( Target_isTarget( vehicle ) )
			Target_Remove( vehicle );
	}
}

function WatchPlayerExitRequestThread( player )
{
	level endon( "game_ended" );
	player endon ( "death" );
	player endon( "disconnect" );		
	
	vehicle = self;

	vehicle endon( "death" );
	
	wait 1.5;
	
	while( true )
	{
		timeUsed = 0;
		while( player UseButtonPressed() )
		{
			timeUsed += 0.05;
			if( timeUsed > 0.25 )
			{
				player unlink();
				return;
			}
			WAIT_SERVER_FRAME;
		}
		WAIT_SERVER_FRAME;
	}	
}

		
		
