#using scripts\codescripts\struct;

#using scripts\shared\math_shared;
#using scripts\shared\statemachine_shared;
#using scripts\shared\system_shared;
#using scripts\shared\array_shared;
#using scripts\shared\util_shared;

#using scripts\shared\vehicle_shared;
#using scripts\shared\vehicle_death_shared;
#using scripts\shared\vehicle_ai_shared;
#using scripts\shared\clientfield_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\statemachine.gsh;
#insert scripts\shared\archetype_shared\archetype_shared.gsh;

#insert scripts\shared\ai\utility.gsh;
#insert scripts\shared\version.gsh;

#define WASP_MOVE_DIST_MIN							80
#define WASP_MOVE_DIST_MAX							500

#define WASP_ENEMY_TOO_CLOSE_DIST					250

#define WASP_GROUP_RADIUS							140
#define WASP_GROUP_SIZE								3
	
#define WASP_GUARD_ACQUIRE_ENEMY_DIST				1000
#define WASP_GUARD_LOSE_ENEMY_DIST					1200
#define WASP_GUARD_KEEP_ENEMY_DIST					300

#define WASP_HOVER_RADIUS							50

#define WASP_NEARGOAL_DIST							40
	
#using_animtree( "generic" );
	
#namespace wasp;

REGISTER_SYSTEM( "wasp", &__init__, undefined )

function __init__()
{	
	vehicle::add_main_callback( "wasp", &wasp_initialize );
	clientfield::register( "vehicle", "rocket_wasp_hijacked", VERSION_SHIP, 1, "int" );
}

function wasp_initialize()
{
	self UseAnimTree( #animtree );
	
	Target_Set( self, ( 0, 0, 0 ) );

	self.health = self.healthdefault;

	self vehicle::friendly_fire_shield();

	self EnableAimAssist();
	self SetNearGoalNotifyDist( WASP_NEARGOAL_DIST );
	
	//self SetVehicleAvoidance( true ); // this is ORCA avoidance

	self SetHoverParams( WASP_HOVER_RADIUS, 100.0, 100.0 );
	
	self.fovcosine = 0; // +/-90 degrees = 180
	self.fovcosinebusy = 0;	//+/- 55 degrees = 110 fov

	self.vehAirCraftCollisionEnabled = true;

	assert( isdefined( self.scriptbundlesettings ) );

	self.settings = struct::get_script_bundle( "vehiclecustomsettings", self.scriptbundlesettings );
	self.goalRadius = 999999;
	self.goalHeight = 999999;
	self SetGoal( self.origin, false, self.goalRadius, self.goalHeight );

	self.variant = "mg";

	if ( IsSubStr( self.vehicleType, "rocket" ) )
	{
		self.variant = "rocket";
	}
	
	self.overrideVehicleDamage = &drone_callback_damage;
	self.allowFriendlyFireDamageOverride = &drone_AllowFriendlyFireDamage;

	self thread vehicle_ai::nudge_collision();

	//disable some cybercom abilities
	if( IsDefined( level.vehicle_initializer_cb ) )
	{
    	[[level.vehicle_initializer_cb]]( self );
	}

	if ( self.variant === "rocket" )
	{
		self.ignoreFireFly = true;
		self vehicle_ai::InitThreatBias();
	}

	init_guard_points();
	
	defaultRole();
}

function defaultRole()
{
	self vehicle_ai::init_state_machine_for_role( "default" );

    self vehicle_ai::get_state_callbacks( "combat" ).enter_func = &state_combat_enter;
    self vehicle_ai::get_state_callbacks( "combat" ).update_func = &state_combat_update;

    self vehicle_ai::get_state_callbacks( "death" ).update_func = &state_death_update;
    
    self vehicle_ai::get_state_callbacks( "driving" ).update_func = &wasp_driving;

    self vehicle_ai::get_state_callbacks( "emped" ).update_func = &state_emped_update;

	self vehicle_ai::add_state( "guard",
		&state_guard_enter,
		&state_guard_update,
		&state_guard_exit );

	vehicle_ai::add_utility_connection( "combat", "guard", &state_guard_can_enter );
	vehicle_ai::add_utility_connection( "guard", "combat" );
	vehicle_ai::add_interrupt_connection( "guard",	"emped",	"emped" );
	vehicle_ai::add_interrupt_connection( "guard",	"surge",	"surge" );
	vehicle_ai::add_interrupt_connection( "guard",	"off",		"shut_off" );
	vehicle_ai::add_interrupt_connection( "guard",	"pain",		"pain" );
	vehicle_ai::add_interrupt_connection( "guard",	"driving",	"enter_vehicle" );

	vehicle_ai::StartInitialState( "combat" );
}

// ----------------------------------------------
// State: death
// ----------------------------------------------
function state_death_update( params )
{
	self endon( "death" );

	if ( isArray( self.followers ) )
	{
		foreach( follower in self.followers )
		{
			if ( isdefined( follower ) )
			{
				follower.leader = undefined;
			}
		}
	}

	death_type = vehicle_ai::get_death_type( params );

	// gib death
	if ( !isdefined( death_type ) && isdefined( params ) )
	{
		if ( isdefined( params.weapon ) )
		{
			if ( params.weapon.doannihilate )
			{
				death_type = "gibbed";
			}
			else if ( params.weapon.dogibbing && isdefined( params.attacker ) )
			{
				dist = Distance( self.origin, params.attacker.origin );
				if ( dist < params.weapon.maxgibdistance )
				{
					gib_chance = 1.0 - ( dist / params.weapon.maxgibdistance );
					//if( RandomFloatRange( 0.0, 1.0 ) < gib_chance )
					if ( RandomFloatRange( 0.0, 2.0 ) < gib_chance )	// less chance for now, weapons are tuned to gib too much
					{
						death_type = "gibbed";
					}
				}
			}
		}

		if ( isdefined( params.meansOfDeath ) )
		{
			meansOfDeath = params.meansOfDeath;
			if ( meansOfDeath === "MOD_EXPLOSIVE" || meansOfDeath === "MOD_GRENADE_SPLASH" || meansOfDeath === "MOD_PROJECTILE_SPLASH" || meansOfDeath === "MOD_PROJECTILE" )
			{
				death_type = "gibbed";
			}
		}
	}

	// crash
	if ( !isdefined( death_type ) )
	{
		crash_style = RandomInt( 3 );
		switch( crash_style )
		{
		case 0: 
			// barrel_rolling camera is too crazy, so show gibbed to the player instead
			if ( self.hijacked === true )
			{ 
				params.death_type = "gibbed";
				vehicle_ai::defaultstate_death_update( params );
			}
			else
			{
				vehicle_death::barrel_rolling_crash(); 
			}
			break;

		case 1: vehicle_death::plane_crash(); break;
		default: vehicle_death::random_crash( params.vDir );
		}
		self vehicle_death::DeleteWhenSafe();
	}
	else
	{
		params.death_type = death_type;
		vehicle_ai::defaultstate_death_update( params );
	}
}

// ----------------------------------------------
// State: emped
// ----------------------------------------------
function state_emped_update( params )
{
	self endon ( "death" );
	self endon ( "change_state" );

	WAIT_SERVER_FRAME;

	gravity = 400;

	self notify( "end_nudge_collision" );

	// emp down time
	empdowntime = params.notify_param[0];
	assert( isdefined( empdowntime ) );
	vehicle_ai::Cooldown( "emped_timer", empdowntime );

	wait RandomFloat( 0.2 );

	// give it a spin
	ang_vel = self GetAngularVelocity();
	pitch_vel = math::randomSign() * RandomFloatRange( 200, 250 );
	yaw_vel = math::randomSign() * RandomFloatRange( 200, 250 );
	roll_vel = math::randomSign() * RandomFloatRange( 200, 250 );
	ang_vel += ( pitch_vel, yaw_vel, roll_vel );
	self SetAngularVelocity( ang_vel );

	// let it fall
	if ( IsPointInNavVolume( self.origin, "navvolume_small" ) )
	{
		self.position_before_fall = self.origin;
	}

	self CancelAIMove();
	self SetPhysAcceleration( ( 0, 0, -gravity ) );
	
	killonimpact_speed = self.settings.killonimpact_speed;
	if( self.health <= 20 )
	{
		killonimpact_speed = 1;
	}
	
	self fall_and_bounce( killonimpact_speed, self.settings.killonimpact_time );

	self notify( "landed" );

	// forcefully stablize just in case
	self SetVehVelocity( ( 0, 0, 0 ) );
	self SetPhysAcceleration( ( 0, 0, -gravity * 0.1 ) );
	self SetAngularVelocity( ( 0, 0, 0 ) );

	// wait emp down time
	while( !vehicle_ai::IsCooldownReady( "emped_timer" ) )
	{
		timeLeft = max( vehicle_ai::GetCooldownLeft( "emped_timer" ), 0.5 );
		wait timeLeft;
	}

	// get back up
	self.abnormal_status.emped = false;
	self vehicle::toggle_emp_fx( false );
	self vehicle_ai::emp_startup_fx();
	
	bootup_timer = 1.6;
	while( bootup_timer > 0 )
	{
		self vehicle::lights_on();
		wait 0.4;
		self vehicle::lights_off();
		wait 0.4;
		bootup_timer -= 0.8;
	}
	
	self vehicle::lights_on();
	
	if ( isdefined( self.position_before_fall ) )
	{ 
		originoffset = (0,0,5);
		goalpoint = self GetClosestPointOnNavVolume( self.origin + originoffset, 50 );
		if ( isdefined( goalpoint ) && SightTracePassed( self.origin + originoffset, goalpoint, false, self ) )
		{	
			self SetVehGoalPos( goalpoint, false, false );
			self util::waittill_any_timeout( 0.3, "near_goal", "goal" );

			if ( isdefined( self.enemy ) )
			{
				self SetLookAtEnt( self.enemy );
			}

			startTime = GetTime();
			self.current_pathto_pos = self.position_before_fall;
			foundGoal = self SetVehGoalPos( self.current_pathto_pos, true, true );
			while ( !foundGoal && vehicle_ai::TimeSince( startTime ) < 3 )
			{
				foundGoal = self SetVehGoalPos( self.current_pathto_pos, true, true );
				wait 0.3;
			}

			if ( foundGoal )
			{
				self util::waittill_any_timeout( 1, "near_goal", "goal" );
			}
			else
			{
				self SetVehGoalPos( self.origin, true, false );
			}
			wait 1;
			self.position_before_fall = undefined;
			self vehicle_ai::evaluate_connections();
		}
	}

	// not able to get up
	self vehicle::lights_off();
}

function fall_and_bounce( killOnImpact_speed, killOnImpact_time )
{
	self endon( "death" );
	self endon( "change_state" );

	maxBounceTime = 3;
	bounceScale = 0.3;
	velocityLoss = 0.3;
	maxAngle = 12;
	bouncedTime = 0;
	angularVelStablizeParams = ( 0.3, 0.5, 0.2 ); // stablize pitch and roll more
	anglesStablizeInitialScale = 0.6;
	anglesStablizeIncrement = 0.2;

	fallStart = GetTime();
	while ( bouncedTime < maxBounceTime && LengthSquared( self.velocity ) > SQR( 10 ) )
	{
		self waittill( "veh_collision", impact_vel, normal );

		// if too fast or dropping for too long, kill on impact
		if ( LengthSquared( impact_vel ) > SQR( killOnImpact_speed ) || ( vehicle_ai::TimeSince( fallStart ) > killOnImpact_time && LengthSquared( impact_vel ) > SQR( killOnImpact_speed * 0.8 ) ) )
		{
			self kill();
		}
		// don't have a safe point to get back to
		else if ( !isdefined( self.position_before_fall ) )
		{
			self kill();
		}
		else
		{
			fallStart = GetTime();
		}

		// bounce velocity
		oldvelocity = self.velocity; // current velocity (self.velocity) and impact velocity (impact_vel) can be very different
		vel_hitDir = -VectorProjection( impact_vel, normal ); // negate of impact velocity along surface normal is the bounce velocity
		vel_hitDirUp = VectorProjection( vel_hitDir, (0,0,1) );

		velscale = min( bounceScale * ( bouncedTime + 1 ), 0.9 ); // don't go too big
		newVelocity = ( oldvelocity - VectorProjection( oldvelocity, vel_hitDir ) ) * ( 1 - velocityLoss ); // clear velocity in bounce direction, and add velocity loss
		newVelocity += vel_hitDir * velscale; // add bounce velocity

		// adjust angular velocity and angles so it lays flat on ground
		shouldBounce = ( VectorDot( normal, (0,0,1) ) > 0.76 ); // roughly 45 degrees
		if ( shouldBounce )
		{
			// stablize angular velocity
			// stablize more if velocity is low
			velocityLengthSqr = LengthSquared( newVelocity );
			stablizeScale = MapFloat( SQR( 5 ), SQR( 60 ), 0.1, 1, velocityLengthSqr );

			ang_vel = self GetAngularVelocity();
			ang_vel *= angularVelStablizeParams * stablizeScale;
			self SetAngularVelocity( ang_vel );

			// bring angles to flat
			angles = self.angles;
			anglesStablizeScale = min( anglesStablizeInitialScale - bouncedTime * anglesStablizeIncrement, 0.1 ); // don't go too small
			pitch = angles[0];
			yaw = angles[1];
			roll = angles[2];
			surfaceAngles = VectorToAngles( normal );
			surfaceRoll = surfaceAngles[2];
			if ( pitch < -maxAngle || pitch > maxAngle )
			{
				pitch *= anglesStablizeScale;
			}
			if ( roll < surfaceRoll - maxAngle || roll > surfaceRoll + maxAngle )
			{
				roll = LerpFloat( surfaceRoll, roll, anglesStablizeScale );
			}
			self.angles = ( pitch, yaw, roll ); // setting the angles clears the velocity so we have to set velocity after this
		}

		self SetVehVelocity( newVelocity );
		self vehicle_ai::collision_fx( normal );

		if ( shouldBounce )
		{
			bouncedTime++;
		}
	}
}

// ----------------------------------------------
// State: guard
// ----------------------------------------------
function init_guard_points()
{
	self._guard_points = [];
	ARRAY_ADD( self._guard_points, (150, -110, 110) );
	ARRAY_ADD( self._guard_points, (150, 110, 110) );
	ARRAY_ADD( self._guard_points, (120, -110, 80) );
	ARRAY_ADD( self._guard_points, (120, 110, 80) );
	ARRAY_ADD( self._guard_points, (180, 0, 140) );
}

function get_guard_points( owner )
{
	assert( self._guard_points.size > 0, "wasp has no guard points" );

	
	points_array = [];

	foreach( point in self._guard_points )
	{
		offset = RotatePoint( point, owner.angles );
		worldPoint = offset + owner.origin + owner GetVelocity() * 0.5;
		//ARRAY_ADD( self.debugpointsarray, worldPoint );
		
		if ( IsPointInNavVolume( worldPoint, "navvolume_small" ) )
		{
			ARRAY_ADD( points_array, worldPoint );
		}
	}

	if ( points_array.size < 1 )
	{
		queryResult = PositionQuery_Source_Navigation( owner.origin + (0,0,50), 25, 200, 100, 1.2 * self.radius, self );
		PositionQuery_Filter_Sight( queryResult, owner.origin + (0,0,10), (0, 0, 0), self, 3 );

		foreach( point in queryResult.data )
		{
			if ( point.visibility === true && BulletTracePassed( owner.origin + (0,0,10), point.origin, false, self, self, false, true ) )
			{
				ARRAY_ADD( points_array, point.origin );
			}
		}
	}

	return points_array;
}

function state_guard_can_enter( from_state, to_state, connection )
{
	if ( self.enable_guard !== true || !isdefined( self.owner ) )
	{
		return false;
	}
		
	if ( !isdefined( self.enemy ) || !self VehSeenRecently( self.enemy, 3 ) )
	{
		return true;
	}

	// if enemy is far away from owner, and wasp is not very close to it
	if ( DistanceSquared( self.owner.origin, self.enemy.origin ) > SQR( WASP_GUARD_LOSE_ENEMY_DIST ) &&
		DistanceSquared( self.origin, self.enemy.origin ) > SQR( WASP_GUARD_KEEP_ENEMY_DIST ) )
	{
		return true;
	}

	if ( !IsPointInNavVolume( self.origin, "navvolume_small" ) )
	{
		return true;
	}

	return false;
}

function state_guard_enter( params )
{
	if ( self.enable_target_laser === true )
	{
		self LaserOff();
	}

	self update_main_guard();
}

function update_main_guard()
{
	if ( isdefined( self.owner ) && !isAlive( self.owner.main_guard ) || self.owner.main_guard.owner !== self.owner )
	{
		self.owner.main_guard = self;
	}
}

function state_guard_exit( params )
{
	if ( isdefined( self.owner ) && self.owner.main_guard === self )
	{
		self.owner.main_guard = undefined;
	}
}

function test_get_back_point( point )
{
	if ( SightTracePassed( self.origin, point, false, self ) )
	{
		if ( BulletTracePassed( self.origin, point, false, self, self, false, true ) )
		{
			return 1;
		}

		return 0;
	}

	return -1;
}

function test_get_back_queryresult( queryResult )
{
	getbackPoint = undefined;
	foreach( point in queryResult.data )
	{
		testresult = test_get_back_point( point.origin );
		if ( testresult == 1 )
		{
			return point.origin;
		}
		else if ( testresult == 0 )
		{
			WAIT_SERVER_FRAME;
		}
	}

	return undefined;
}

function state_guard_update( params )
{
	self endon( "death" );
	self endon( "change_state" );

	self SetHoverParams( 20.0, 40.0, 30.0 );

	timeNotAtGoal = GetTime();
	pointIndex = 0;
	stuckCount = 0;

	while( 1 )
	{
		if( isdefined( self.enemy ) && DistanceSquared( self.owner.origin, self.enemy.origin ) < SQR( WASP_GUARD_ACQUIRE_ENEMY_DIST ) && self VehSeenRecently( self.enemy, 1 ) && IsPointInNavVolume( self.origin, "navvolume_small" ) )
		{
			self vehicle_ai::evaluate_connections();
			wait 1;
		}
		else
		{
			owner = self.owner;
			if ( !isdefined( owner ) )
			{
				wait 1;
				continue;
			}

			usePathfinding = true;
			onNavVolume = IsPointInNavVolume( self.origin, "navvolume_small" );
			if ( !onNavVolume )
			{
				// off nav volume, try getting back
				getbackPoint = undefined;

				// try closest point
				pointOnNavVolume = self GetClosestPointOnNavVolume( self.origin, 500 );
				if ( isdefined( pointOnNavVolume ) )
				{
					if ( test_get_back_point( pointOnNavVolume ) == 1 )
					{
						getbackPoint = pointOnNavVolume;
					}
				}

				// try query points on horizontal level
				if ( !isdefined( getbackPoint ) )
				{
					queryResult = PositionQuery_Source_Navigation( self.origin, 0, 1500, 200, 80, self );
					getbackPoint = test_get_back_queryresult( queryResult );
				}

				// try vertical points
				if ( !isdefined( getbackPoint ) )
				{
					queryResult = PositionQuery_Source_Navigation( self.origin, 0, 300, 700, 30, self );
					getbackPoint = test_get_back_queryresult( queryResult );
				}

				if ( isdefined( getbackPoint ) )
				{
					if ( DistanceSquared( getbackPoint, self.origin ) > SQR( WASP_NEARGOAL_DIST * 0.5 ) )
					{
						self.current_pathto_pos = getbackPoint;
						usePathfinding = false;
						self.vehAirCraftCollisionEnabled = false;
					}
					else
					{
						onNavVolume = true;
					}
				}
				else
				{
					stuckCount++;
					if ( stuckCount == 1 )
					{
						stuckLocation = self.origin;
					}
					else if ( stuckCount > 10 )
					{
					/# 
						assert( false, "Wasp fall outside of NavVolume at " + self.origin );
					#/
						self Kill();
					}
				}
			}

			if ( onNavVolume )
			{
				self update_main_guard();

				if ( owner.main_guard === self )
				{
					guardPoints = get_guard_points( owner );
					if ( guardPoints.size < 1 )
					{
						wait 1;
						continue;
					}

					stuckCount = 0;
					self.vehAirCraftCollisionEnabled = true;

					if ( guardPoints.size <= pointIndex )
					{
						pointIndex = RandomInt( Int( min( self._guard_points.size, guardPoints.size ) ) );
						timeNotAtGoal = GetTime();
					}

					self.current_pathto_pos = guardPoints[pointIndex];
				}
				else
				{ 
					main_guard = owner.main_guard;
					if( isalive( main_guard ) && isdefined( main_guard.current_pathto_pos ) )
					{
						query_position = main_guard.current_pathto_pos;
						queryResult = PositionQuery_Source_Navigation( query_position, 20, WASP_GROUP_RADIUS, 100, 20, self, 15 );

						if ( queryResult.data.size > 0 )
						{
							self.current_pathto_pos = queryResult.data[ queryResult.data.size - 1 ].origin;
						}
					}
				}
			}

			if ( IsDefined( self.current_pathto_pos ) )
			{
				distanceToGoalSq = DistanceSquared( self.current_pathto_pos, self.origin );
				if ( !onNavVolume || distanceToGoalSq > SQR( 60 ) )
				{
					if ( distanceToGoalSq > SQR( 600 ) )
					{
						self SetSpeed( self.settings.defaultMoveSpeed * 2 );
					}
					else if ( distanceToGoalSq < SQR( 100 ) )
					{
						self SetSpeed( self.settings.defaultMoveSpeed * 0.3 );
					}
					else
					{
						self SetSpeed( self.settings.defaultMoveSpeed );
					}

					timeNotAtGoal = GetTime();
				}
				else // already at goal
				{
					if ( vehicle_ai::TimeSince( timeNotAtGoal ) > 4 )
					{
						pointIndex = RandomInt( self._guard_points.size );
						timeNotAtGoal = GetTime();
					}

					wait 0.2;
					continue;
				}

				if ( self SetVehGoalPos( self.current_pathto_pos, true, usePathfinding ) )
				{
					self playsound ( "veh_wasp_direction" );

					self ClearLookAtEnt();
					self notify( "fire_stop" ); // stop shooting
					//self.noshoot = true;

					self thread path_update_interrupt();
					if ( onNavVolume )
					{
						self vehicle_ai::waittill_pathing_done( 1 );
					}
					else
					{
						self vehicle_ai::waittill_pathing_done();
					}
					//self.noshoot = undefined;
				}
				else
				{
					wait 0.5;
				}
			}
			else
			{
				wait 0.5;
			}
		}
	}
}

// ----------------------------------------------
// State: combat
// ----------------------------------------------
function state_combat_enter( params )
{
	if ( self.enable_target_laser === true )
	{
		self LaserOn();
	}

	if ( IsDefined( self.owner ) && IsDefined( self.owner.enemy ) )
	{
		self.favoriteEnemy = self.owner.enemy;
	}
	self thread turretFireUpdate();
}

function turretFireUpdate()
{
	self endon( "death" );
	self endon( "change_state" );

	isRocketType = ( self.variant === "rocket" );
	
	while( 1 )
	{
		if( isdefined( self.enemy ) && self VehCanSee( self.enemy ) )
		{
			if( DistanceSquared( self.enemy.origin, self.origin ) < SQR( 0.5 * ( self.settings.engagementDistMin + self.settings.engagementDistMax ) * 3 ) ) 
			{
				self SetLookAtEnt( self.enemy );

				if( isRocketType )
				{
					self SetTurretTargetEnt( self.enemy, self.enemy GetVelocity() * 0.3 - vehicle_ai::GetTargetEyeOffset( self.enemy ) * 0.3 );
				}
				else
				{
					self SetTurretTargetEnt( self.enemy, -vehicle_ai::GetTargetEyeOffset( self.enemy ) * 0.3 );
				}
				
				startAim = GetTime();
				while ( !self.turretontarget && vehicle_ai::TimeSince( startAim ) < 3 )
				{
					wait 0.2;
				}

				if ( isdefined( self.enemy ) && self.turretontarget && self.noshoot !== true )
				{
					if( isRocketType )
					{
						for( i = 0; i < 2 && isdefined( self.enemy ); i++ )
						{
							self FireWeapon( 0, self.enemy );
							fired = true;
							wait 0.25;
						}
					}
					else
					{
						self vehicle_ai::fire_for_time( RandomFloatRange( self.settings.turret_fire_burst_min, self.settings.turret_fire_burst_max ), 0, self.enemy );
					}
					
					if( isdefined( self.settings.turret_cooldown_max ) )
					{
						DEFAULT( self.settings.turret_cooldown_min, 0 );	
						wait( RandomFloatRange( self.settings.turret_cooldown_min, self.settings.turret_cooldown_max ) );
					}
				}
				else
				{
					if( isdefined( self.settings.turret_enemy_detect_freq ) )
						wait self.settings.turret_enemy_detect_freq;
				}

				self SetTurretTargetRelativeAngles( (15,0,0), 0 );
			}

			if( isRocketType )
			{
				if( isdefined( self.enemy ) && IsAI( self.enemy ) )
				{
					wait( RandomFloatRange( 4, 7 ) );
				}
				else
				{
					wait( RandomFloatRange( 3, 5 ) );
				}
			}
			else
			{
				if( isdefined( self.enemy ) && IsAI( self.enemy ) )
				{
					wait( RandomFloatRange( 2, 2.5 ) );
				}
				else
				{
					wait( RandomFloatRange( 0.5, 1.5 ) );
				}
			}
		}
		else
		{
			wait 0.4;
		}
	}
}


function path_update_interrupt()
{
	self endon( "death" );
	self endon( "change_state" );
	self endon( "near_goal" );
	self endon( "reached_end_node" );

	old_enemy = self.enemy;
	
	wait 1;
	
	while( 1 )
	{
		if( isdefined( self.current_pathto_pos ) )
		{
			if( distance2dSquared( self.current_pathto_pos, self.goalpos ) > SQR( self.goalradius ) )
			{
				wait 0.2;
				self notify( "near_goal" );
			}
		}

		if ( isdefined( self.enemy ) )
		{
			if ( self.noshoot !== true && self VehCanSee( self.enemy ) )
			{
				self SetTurretTargetEnt( self.enemy );
				self SetLookAtEnt( self.enemy );
			}

			if( !isdefined( old_enemy ) )
			{
				self notify( "near_goal" );		// new enemy
			}
			else if( self.enemy != old_enemy )
			{
				self notify( "near_goal" );		// new enemy
			}
			
			if( self VehCanSee( self.enemy ) && distance2dSquared( self.origin, self.enemy.origin ) < SQR( WASP_ENEMY_TOO_CLOSE_DIST ) )
			{
				self notify( "near_goal" );
			}
		}
		
		wait 0.2;
	}
}

function wait_till_something_happens( timeout )
{
	self endon( "change_state" );
	self endon( "death" );
	
	wait 0.1;
	
	time = timeout;
	cant_see_count = 0;
	
	while( time > 0 ) 
	{	
		if( isdefined( self.current_pathto_pos ) )
		{
			if( distanceSquared( self.current_pathto_pos, self.goalpos ) > SQR( self.goalradius ) )
			{
				break;
			}
		}
		
		if( isdefined( self.enemy ) )
		{
			if ( !self vehCanSee( self.enemy ) )
			{
				cant_see_count++;
				if( cant_see_count >= 3 )
				{
					break;
				}
			}
			else
			{
				cant_see_count = 0;
			}
			
			if( distance2dSquared( self.origin, self.enemy.origin ) < SQR( WASP_ENEMY_TOO_CLOSE_DIST ) )
			{
				break;
			}
		
			// height check
			goalHeight = self.enemy.origin[2] + 0.5 * ( self.settings.engagementHeightMin + self.settings.engagementHeightMax );
			distFromPreferredHeight = abs( self.origin[2] - goalHeight );
			if ( distFromPreferredHeight > 100 )
			{
				break;
			}
		
			if( isplayer( self.enemy ) && self.enemy islookingat( self ) )
			{
				if ( math::cointoss() )
				{
					wait RandomFloatRange( 0.1, 0.5 );
				}

				self drop_leader();	// gotta move away fast, we'll pick him up again in a bit
				break;
			}
		}
		
		if( isdefined( self.leader ) && isdefined( self.leader.current_pathto_pos ) )
		{
			if( distanceSquared( self.origin, self.leader.current_pathto_pos ) > SQR( WASP_GROUP_RADIUS + 25 ) )
			{
				//wait RandomFloatRange( 0.1, 0.3 );
				break;
			}
		}
		
		wait 0.3;
		time -= 0.3;
	}
}

function drop_leader()
{
	if( isdefined( self.leader ) )
	{
		ArrayRemoveValue( self.leader.followers, self );
		self.leader = undefined;
	}
}

function update_leader()
{
	//if self.no_group is set to true, don't find a leader
	if( isdefined( self.no_group ) && self.no_group == true )
	{
		return;
	}
	
	if( isdefined( self.leader ) )
	{
		return;	// already have a leader
	}
	
	if( isdefined( self.followers ) )
	{
		self.followers = array::remove_dead( self.followers, false );
		if( self.followers.size > 0 )	// we are a leader
		{
			return;
		}
	}
	
	team_mates = GetAITeamArray( self.team );
	
	foreach( guy in team_mates )
	{
		if( isdefined( guy.archetype ) && guy.archetype == "wasp" )
		{
			if( isdefined( guy.leader ) )
			{
				continue;	// guy is already a follower
			}
			
			if( guy == self )
			{
				continue;
			}
			
			if( distanceSquared( self.origin, guy.origin ) > SQR( 700 ) )
			{
				continue;	// guy too far
			}
			
			if( !isdefined( guy.followers ) )
			{
				guy.followers = [];
			}
			
			if( guy.followers.size >= WASP_GROUP_SIZE-1 )
			{
				continue; 	// already full group
			}
			
			// found a leader
			guy.followers[ guy.followers.size ] = self;
			self.leader = guy;
			break;
		}
	}
}

function should_fly_forward( distanceToGoalSq )
{
	if ( self.always_face_enemy === true )
	{
		return false;
	}

	if( distanceToGoalSq < SQR( 250 ) )
	{
		return false;
	}
	
	// always face enemy when backing away
	if( isdefined( self.enemy ) )
	{
		to_goal = VectorNormalize( self.current_pathto_pos - self.origin );
		to_enemy = VectorNormalize( self.enemy.origin - self.origin );
		
		dot = VectorDot( to_goal, to_enemy );
		if( abs( dot ) > 0.7 )
		{
			return false;
		}
	}
	
	if( distanceToGoalSq > SQR( 400 ) )
	{
		return RandomInt( 100 ) > 25;
	}
	
	return RandomInt( 100 ) > 50;
}

function state_combat_update( params )
{
	self endon( "change_state" );
	self endon( "death" );

	// allow script to set goalpos and whatever else before moving
	wait .1;

	stuckCount = 0;
	
	for( ;; )
	{
		self SetSpeed( self.settings.defaultMoveSpeed );
		
		self update_leader();

		if ( IS_TRUE( self.inpain ) )
		{
			wait 0.1;
		}
		else
		{
			if ( self.enable_guard === true )
			{
				self vehicle_ai::evaluate_connections();
			}

			if ( IsDefined( self.enemy ) )
			{
				self SetTurretTargetEnt( self.enemy );
				self SetLookAtEnt( self.enemy );

				self wait_till_something_happens( RandomFloatRange( 2, 5 ) );
			}

			if ( !IsDefined( self.enemy ) )
			{
				self ClearLookAtEnt();

				AIArray = GetAITeamArray( "all" );
				foreach ( AI in AIArray )
				{
					self GetPerfectInfo( AI );
				}

				players = GetPlayers( "all" );
				foreach ( player in players )
				{
					self GetPerfectInfo( player );
				}

				wait 1;
			}

			usePathfinding = true;
			onNavVolume = IsPointInNavVolume( self.origin, "navvolume_small" );
			if ( !onNavVolume )
			{
				// off nav volume, try getting back
				getbackPoint = undefined;

				if ( self.aggresive_navvolume_recover === true ) // MP specific
				{
					self vehicle_ai::evaluate_connections();
				}

				pointOnNavVolume = self GetClosestPointOnNavVolume( self.origin, 100 );
				if ( isdefined( pointOnNavVolume ) )
				{
					if ( SightTracePassed( self.origin, pointOnNavVolume, false, self ) )
					{
						getbackPoint = pointOnNavVolume;
					}
				}

				if ( !isdefined( getbackPoint ) )
				{
					queryResult = PositionQuery_Source_Navigation( self.origin, 0, 200, 100, 2 * self.radius, self );
					PositionQuery_Filter_Sight( queryResult, self.origin, (0, 0, 0), self, 1 );
					getbackPoint = undefined;
					foreach( point in queryResult.data )
					{
						if ( point.visibility === true )
						{
							getbackPoint = point.origin;
							break;
						}
					}
				}

				if ( isdefined( getbackPoint ) )
				{
					self.current_pathto_pos = getbackPoint;
					usePathfinding = false;
				}
				else
				{
					stuckCount++;
					if ( stuckCount == 1 )
					{
						stuckLocation = self.origin;
					}
					else if ( stuckCount > 10 )
					{
						assert( false, "Wasp fall outside of NavVolume at " + self.origin );
						self Kill();
					}
				}
			}
			else
			{
				stuckCount = 0;

				if( self.goalforced )
				{
					goalpos = self GetClosestPointOnNavVolume( self.goalpos, 100 );
					if ( isdefined( goalpos ) )
					{
						self.current_pathto_pos = goalpos;
						usePathfinding = true;
					}
					else
					{
						self.current_pathto_pos = self.goalpos;
						usePathfinding = false;
					}
				}
				else if ( IsDefined( self.enemy ) )
				{
					self.current_pathto_pos = GetNextMovePosition_tactical();
					usePathfinding = true;
				}
				else
				{
					self.current_pathto_pos = GetNextMovePosition_wander();
					usePathfinding = true;
				}
			}

			if ( IsDefined( self.current_pathto_pos ) )
			{
				distanceToGoalSq = DistanceSquared( self.current_pathto_pos, self.origin );

				if ( !onNavVolume || distanceToGoalSq > SQR( WASP_HOVER_RADIUS * 1.5 ) )
				{
					if ( distanceToGoalSq > SQR( 2000 ) )
					{
						self SetSpeed( self.settings.defaultMoveSpeed * 2 );
					}

					if ( self SetVehGoalPos( self.current_pathto_pos, true, usePathfinding ) )
					{
						if ( IsDefined( self.enemy ) )
						{
							self playsound ( "veh_wasp_direction" );
						}
						else
						{
							self playsound ( "veh_wasp_vox" );
						}

						if ( should_fly_forward( distanceToGoalSq ) )
						{
							// fly foward if flying far
							self ClearLookAtEnt();
							self notify( "fire_stop" ); // stop shooting
							self.noshoot = true;
						}
						self thread path_update_interrupt();
						self vehicle_ai::waittill_pathing_done();
						self.noshoot = undefined;
					}
				}
			}
		}
	}
}

function GetNextMovePosition_wander() // no self.enemy
{
	queryMultiplier = 1;

	queryResult = PositionQuery_Source_Navigation( self.origin, WASP_MOVE_DIST_MIN, WASP_MOVE_DIST_MAX * queryMultiplier, 130, 3 * self.radius * queryMultiplier, self, self.radius * queryMultiplier );
	PositionQuery_Filter_DistanceToGoal( queryResult, self );
	vehicle_ai::PositionQuery_Filter_OutOfGoalAnchor( queryResult );

	self.isOnNav = queryResult.centerOnNav;

	best_point = undefined;
	best_score = -999999;

	foreach ( point in queryResult.data )
	{
		randomScore = randomFloatRange( 0, 100 );
		distToOriginScore = point.distToOrigin2D * 0.2;

		point.score += randomScore + distToOriginScore;
		ADD_POINT_SCORE(point, "distToOrigin", distToOriginScore );
		
		if ( point.score > best_score )
		{
			best_score = point.score;
			best_point = point;
		}
	}

	self vehicle_ai::PositionQuery_DebugScores( queryResult );

	if( !isdefined( best_point ) )
	{
		return undefined;
	}

	return best_point.origin;
}

function GetNextMovePosition_tactical() // has self.enemy
{
	if( !isdefined( self.enemy ) ) 
	{
		return self GetNextMovePosition_wander();
	}
	
	// distance based multipliers
	selfDistToTarget = Distance2D( self.origin, self.enemy.origin );

	goodDist = 0.5 * ( self.settings.engagementDistMin + self.settings.engagementDistMax );

	closeDist = 1.2 * goodDist;
	farDist = 3 * goodDist;

	queryMultiplier = MapFloat( closeDist, farDist, 1, 3, selfDistToTarget );
	
	preferedHeightRange = 35;
	randomness = 30;

	avoid_locations = [];
	avoid_radius = 50;
	
	// query
	if( isalive( self.leader ) && isdefined( self.leader.current_pathto_pos ) )
	{
		query_position = self.leader.current_pathto_pos;
		
		queryResult = PositionQuery_Source_Navigation( query_position, 0, WASP_GROUP_RADIUS, 100, 35, self, 25 );
		
		/*foreach( guy in self.leader.followers )
		{
			if( isdefined( guy ) && guy != self )
			{
				if( isdefined( guy.current_pathto_pos ) )
				{
					avoid_locations[ avoid_locations.size ] = guy.current_pathto_pos;
				}
			}
		}*/
	}
	else if ( isalive( self.owner ) && self.enable_guard === true )
	{
		ownerorigin = self GetClosestPointOnNavVolume( self.owner.origin + (0,0,40), 50 );
		if ( isdefined( ownerorigin ) )
		{
			queryResult = PositionQuery_Source_Navigation( ownerorigin, 0, WASP_MOVE_DIST_MAX * min( queryMultiplier, 1.5 ), 130, 3 * self.radius, self );
			if ( isdefined( queryResult ) && isdefined( queryResult.data ) )
			{
				PositionQuery_Filter_Sight( queryResult, self.owner GetEye(), (0, 0, 0), self, 5, self, "visowner" );
				PositionQuery_Filter_Sight( queryResult, self.enemy GetEye(), (0, 0, 0), self, 5, self, "visenemy" );
				foreach ( point in queryResult.data )
				{
					if ( point.visowner === true )
					{
						ADD_POINT_SCORE( point, "visowner", 300 );
					}
		
					if ( point.visenemy === true )
					{
						ADD_POINT_SCORE( point, "visenemy", 300 );
					}
				}
			}
		}
	}
	else
	{
		queryResult = PositionQuery_Source_Navigation( self.origin, 0, WASP_MOVE_DIST_MAX * min( queryMultiplier, 2 ), 130, 3 * self.radius * queryMultiplier, self, 2.2 * self.radius * queryMultiplier );
		
		team_mates = GetAITeamArray( self.team );
		
		avoid_radius = WASP_GROUP_RADIUS;
	
		foreach( guy in team_mates )
		{
			if( isdefined( guy.archetype ) && guy.archetype == "wasp" )
			{
				// avoid other leaders if we are a leader
				if( isdefined( guy.followers ) &&  guy.followers.size > 0 && guy != self )
				{
					if( isdefined( guy.current_pathto_pos ) )
					{
						avoid_locations[ avoid_locations.size ] = guy.current_pathto_pos;
					}
				}
			}
		}
	}

	//If there are no data points to query for points to path to, then just return out undefined
	if( !isdefined( queryResult ) || !isdefined( queryResult.data ) || queryResult.data.size == 0)
	{
		return undefined;
	}

	// filter
	PositionQuery_Filter_DistanceToGoal( queryResult, self );
	PositionQuery_Filter_InClaimedLocation( queryResult, self );
	self vehicle_ai::PositionQuery_Filter_OutOfGoalAnchor( queryResult );
	self vehicle_ai::PositionQuery_Filter_EngagementDist( queryResult, self.enemy, self.settings.engagementDistMin, self.settings.engagementDistMax );
	self vehicle_ai::PositionQuery_Filter_EngagementHeight( queryResult, self.enemy, self.settings.engagementHeightMin, self.settings.engagementHeightMax );
	
	// score points
	best_point = undefined;
	best_score = -999999;

	foreach ( point in queryResult.data )
	{
		ADD_POINT_SCORE( point, "random", randomFloatRange( 0, randomness ) );
		
		ADD_POINT_SCORE( point, "engagementDist", -point.distAwayFromEngagementArea );
		ADD_POINT_SCORE( point, "height", -point.distEngagementHeight * 1.4 );

		if( point.disttoorigin2d < 120 )
		{
			ADD_POINT_SCORE( point, "tooCloseToSelf", (120 - point.disttoorigin2d) * -1.5 );
		}
		
		foreach( location in avoid_locations )
		{
			if( distanceSquared( point.origin, location ) < SQR( avoid_radius ) )
			{
				ADD_POINT_SCORE( point, "tooCloseToOthers", -avoid_radius );
			}
		}

		if( point.inClaimedLocation )
		{
			ADD_POINT_SCORE( point, "inClaimedLocation", -500 );
		}

		if ( point.score > best_score )
		{
			best_score = point.score;
			best_point = point;
		}
	}
	
	self vehicle_ai::PositionQuery_DebugScores( queryResult );

	if( !isdefined( best_point ) )
	{
		return undefined;
	}

	
	return best_point.origin;
}

function drone_callback_damage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, vDamageOrigin, psOffsetTime, damageFromUnderneath, modelIndex, partName, vSurfaceNormal )
{
	iDamage = vehicle_ai::shared_callback_damage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, vDamageOrigin, psOffsetTime, damageFromUnderneath, modelIndex, partName, vSurfaceNormal );

	return iDamage;
}

function drone_AllowFriendlyFireDamage( eInflictor, eAttacker, sMeansOfDeath, weapon )
{
	if ( isdefined( eAttacker ) && isdefined( eAttacker.archetype ) && isdefined( sMeansOfDeath )
		 && eAttacker.archetype == ARCHETYPE_WASP && sMeansOfDeath == "MOD_EXPLOSIVE" )
	{
		return true;
	}

	return false;
}

// ----------------------------------------------
// State: driving
// ----------------------------------------------

function wasp_driving( params )
{
	self endon( "change_state" );
	
	driver = self GetSeatOccupant( 0 );
	
	if( isPlayer( driver ) )
	{
		clientfield::set( "rocket_wasp_hijacked", 1 );
	}
	
	if( isPlayer( driver ) && isDefined( self.playerDrivenVersion) )
	{
		self thread wasp_manage_camera_swaps();
	}
	
}

function wasp_manage_camera_swaps()
{
	self endon ( "death" );
	self endon ( "change_state" );
	
	driver = self GetSeatOccupant( 0 );
	
	driver endon( "disconnect" );
	
	cam_low_type = self.vehicletype;
	cam_high_type = self.playerDrivenVersion;
}
