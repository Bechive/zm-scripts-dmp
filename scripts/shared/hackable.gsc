#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

#namespace hackable;

REGISTER_SYSTEM( "hackable", &init, undefined )

#define DEFAULT_HACKABLE_HACK_TIME 	GetDvarFloat("scr_hacker_default_hack_time")
#define DEFAULT_HACKABLE_DISTANCE 	GetDvarFloat("scr_hacker_default_distance")
#define DEFAULT_HACKABLE_ANGLEDOT 	GetDvarFloat("scr_hacker_default_angledot")
#define DEFAULT_HACKABLE_TIMEOUT  	GetDvarFloat("scr_hacker_default_timeout")
#define DEFAULT_HACKABLE_COST_MULT 	1.0 	
#define DEFAULT_HACKABLE_PROMPT   	&"WEAPON_HACKING"

#define DEFAULT_HACKING_BASE_SPEED 	GetDvarFloat("scr_hacker_default_base_speed")
	

function init()
{
	DEFAULT( level.hackable_items, []);
}

function add_hackable_object( obj, test_callback, start_callback, fail_callback, complete_callback )
{
	cleanup_hackable_objects();
	ARRAY_ADD( level.hackable_items, obj );
	DEFAULT(obj.hackable_distance_sq,DEFAULT_HACKABLE_DISTANCE*DEFAULT_HACKABLE_DISTANCE);
	DEFAULT(obj.hackable_angledot,DEFAULT_HACKABLE_ANGLEDOT);
	DEFAULT(obj.hackable_timeout,DEFAULT_HACKABLE_TIMEOUT);
	DEFAULT(obj.hackable_progress_prompt, DEFAULT_HACKABLE_PROMPT);
	DEFAULT(obj.hackable_cost_mult, DEFAULT_HACKABLE_COST_MULT);
	DEFAULT(obj.hackable_hack_time, DEFAULT_HACKABLE_HACK_TIME);

	obj.hackable_test_callback = test_callback;
	obj.hackable_start_callback = start_callback;
	obj.hackable_fail_callback = fail_callback;
	obj.hackable_hacked_callback = complete_callback;
}

function remove_hackable_object( obj )
{
	ArrayRemoveValue( level.hackable_items, obj );
	cleanup_hackable_objects();
}

function cleanup_hackable_objects()
{
	level.hackable_items = array::filter( level.hackable_items, false, &filter_deleted );
}

function filter_deleted( val )
{
	return IsDefined( val );
}


function find_hackable_object()
{
	cleanup_hackable_objects();
	candidates = [];
	origin = self.origin;
	forward = AnglesToForward( self.angles );
	foreach( obj in level.hackable_items )
	{
		if ( self is_object_hackable( obj, origin, forward ) )
		{
			ARRAY_ADD(candidates,obj);
		}
	}
	if ( candidates.size > 0 )
	{
		return ArrayGetClosest( self.origin, candidates );
	}
	return undefined;
}

function is_object_hackable( obj, origin, forward )
{
	if ( DistanceSquared( origin, obj.origin ) < obj.hackable_distance_sq )
	{
		to_obj = obj.origin-origin;
		to_obj = ( to_obj[0], to_obj[1], 0 );
		to_obj = VectorNormalize( to_obj );
		dot = VectorDot( to_obj, forward ); 
		if ( dot >= obj.hackable_angledot )
		{
			if ( IsDefined(obj.hackable_test_callback) )
			{
				return obj [[obj.hackable_test_callback]](self);
			}
			return true;
		}
		else
		{
			/#
				//Println( "Not hackable dot = "+dot+" targ = "+obj.hackable_angledot+" fwd = "+forward+" to obj = "+to_obj+"\n" );
			#/
			
		}
	}
	return false;
}



function start_hacking_object( obj )
{
	obj.hackable_being_hacked = true;
	obj.hackable_hacked_amount = 0.0;
	if ( IsDefined(obj.hackable_start_callback) )
	{
		obj thread [[obj.hackable_start_callback]](self);
	}
}

function fail_hacking_object( obj )
{
	if ( IsDefined(obj.hackable_fail_callback) )
	{
		obj thread [[obj.hackable_fail_callback]](self);
	}
	obj.hackable_hacked_amount = 0.0;
	obj.hackable_being_hacked = false;
	obj notify("hackable_watch_timeout");
}

function complete_hacking_object( obj )
{
	obj notify("hackable_watch_timeout");
	if ( IsDefined(obj.hackable_hacked_callback) )
	{
		obj thread [[obj.hackable_hacked_callback]](self);
	}
	obj.hackable_hacked_amount = 0.0;
	obj.hackable_being_hacked = false;
}

function watch_timeout( obj, time )
{
	obj notify("hackable_watch_timeout");
	obj endon("hackable_watch_timeout");
	wait time;
	if ( IsDefined(obj) )
		fail_hacking_object( obj );
}

function continue_hacking_object( obj )
{
	origin = self.origin;
	forward = AnglesToForward( self.angles );
	if ( self is_object_hackable( obj, origin, forward ) )
	{
		if (!IS_TRUE(obj.hackable_being_hacked))
		{
			self start_hacking_object( obj ); 
		}
		if (IsDefined(obj.hackable_timeout) && obj.hackable_timeout > 0 )
		{
			self thread watch_timeout( obj, obj.hackable_timeout ); 
		}
	
		amt = 1.0 / ( 20 * obj.hackable_hack_time );
		
		obj.hackable_hacked_amount += amt; //( DEFAULT_HACKING_BASE_SPEED * obj.hackable_speed_mult);
		
		if ( obj.hackable_hacked_amount > 1.0 )
		{
			self complete_hacking_object( obj );
		}
		
		if (IS_TRUE(obj.hackable_being_hacked))
			return obj.hackable_hacked_amount;
	}
	if (IS_TRUE(obj.hackable_being_hacked))
	{
		// this made the hacking feel too touchy
		// it may feel better if we just let the timeout handle it
		//fail_hacking_object( obj );
	}
	return -1;
}


