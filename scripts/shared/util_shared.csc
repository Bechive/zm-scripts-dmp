#using scripts\shared\flagsys_shared;
#using scripts\shared\trigger_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

#define MAX_CLIENT_OBJECTIVE_IDS 32

/*
	util.gsc
		
	This is a utility script common to all game modes. Don't add anything with calls to game type
	specific script API calls.
*/

#namespace util;

/@
"Name: empty( <a>, <b>, <c>, <d>, <e> )"
"Summary: Empty function mainly used as a place holder or default function pointer in a system."
"Module: Utility"
"CallOn: "
"OptionalArg: <a> : option arg"
"OptionalArg: <b> : option arg"
"OptionalArg: <c> : option arg"
"OptionalArg: <d> : option arg"
"OptionalArg: <e> : option arg"
"Example: default_callback = &empty;"
"SPMP: both"
@/
function empty( a, b, c, d, e )
{
}

function waitforallclients()
{
	localClient = 0;
	
	if(!isdefined(level.localPlayers))
	{
		while(!isdefined(level.localPlayers))
		{
			WAIT_CLIENT_FRAME;
		}
	}
	
	while( level.localPlayers.size <= 0 )
	{
		WAIT_CLIENT_FRAME;
	}

	while (localClient < level.localPlayers.size)
	{
		waitforclient(localClient);
		localClient++;
	}
}

function waitforclient(client)
{
	while(!clienthassnapshot(client))
	{
		WAIT_CLIENT_FRAME;
	}
	//syncsystemstates(client);	
}

function get_dvar_float_default( str_dvar, default_val )
{
	value = GetDvarString( str_dvar );
	return ( value != "" ? Float( value ) : default_val );
}	

function get_dvar_int_default( str_dvar, default_val )
{
	value = GetDvarString( str_dvar );
	return ( value != "" ? Int( value ) : default_val );
}

/@
"Name: spawn_model(<model_name>, [origin], [angles])"
"Summary: Spawns a model at an origin and angles."
"Module: Utility"
"MandatoryArg: <model_name> the model name."
"OptionalArg: [origin] the origin to spawn the model at."
"OptionalArg: [angles] the angles to spawn the model at."
"Example: fx_model = spawn_model("tag_origin", org, ang);"
"SPMP: SP"
@/
function spawn_model( n_client, str_model, origin = ( 0, 0, 0 ), angles = ( 0, 0, 0 ) )
{
	model = Spawn( n_client, origin, "script_model" );
	model SetModel( str_model );
	model.angles = angles;
	return model;
}

// ----------------------------------------------------------------------------------------------------
// -- Arrays ------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------

function waittill_string( msg, ent )
{
	if ( msg != "entityshutdown" )
	{
		self endon ("entityshutdown");
	}
		
	ent endon( "die" );
	self waittill( msg );
	ent notify( "returned", msg );
}

/@
"Name: waittill_multiple( <string1>, <string2>, <string3>, <string4>, <string5> )"
"Summary: Waits for all of the the specified notifies."
"MandatoryArg:	The notifies to wait on."
"Example: guy waittill_multiple( "goal", "pain", "near_goal", "bulletwhizby" );"
@/
function waittill_multiple( ... )
{
	s_tracker = SpawnStruct();
	s_tracker._wait_count = 0;
	
	for ( i = 0; i < vararg.size; i++ )
	{
		self thread _waitlogic( s_tracker, vararg[ i ] );
	}
	
	if ( s_tracker._wait_count > 0 )
	{
		s_tracker waittill( "waitlogic_finished" );
	}
}

/@
"Name: waittill_multiple_ents( ... )"
"Summary: Waits for all of the the specified notifies on their associated entities."
"MandatoryArg:	List of ents and the notifies to wait on."
"Example: waittill_multiple_ents( guy, "goal", guy, "pain", guy, "near_goal", player, "weapon_change" );"
@/
function waittill_multiple_ents( ... )
{
	a_ents = [];
	a_notifies = [];
	
	for ( i = 0; i < vararg.size; i++ )
	{
		if ( i % 2 )
		{
			ARRAY_ADD( a_notifies, vararg[ i ] );
		}
		else
		{
			ARRAY_ADD( a_ents, vararg[ i ] );
		}
	}
	
	s_tracker = SpawnStruct();
	s_tracker._wait_count = 0;
	
	for ( i = 0; i < a_ents.size; i++ )
	{
		ent = a_ents[ i ];
		
		if ( isdefined( ent ) )
		{
			ent thread _waitlogic( s_tracker, a_notifies[ i ] );
		}
	}
	
	if ( s_tracker._wait_count > 0 )
	{
		s_tracker waittill( "waitlogic_finished" );
	}
}

function _waitlogic( s_tracker, notifies )
{
	s_tracker._wait_count++;
	
	ARRAY_ADD( notifies, "entityshutdown" );	
	waittill_any_array( notifies );
	
	s_tracker._wait_count--;
	if ( s_tracker._wait_count == 0 )
	{
		s_tracker notify( "waitlogic_finished" );
	}
}

/@
"Name: waittill_any_return( <string1>, <string2>, <string3>, <string4>, <string5> )"
"Summary: Waits for any of the the specified notifies and return which one it got."
"Module: Utility"
"CallOn: Entity"
"MandatoryArg:	<string1> name of a notify to wait on"
"OptionalArg:	<string2> name of a notify to wait on"
"OptionalArg:	<string3> name of a notify to wait on"
"OptionalArg:	<string4> name of a notify to wait on"
"OptionalArg:	<string4> name of a notify to wait on"
"OptionalArg:	<string6> name of a notify to wait on"
"OptionalArg:	<string7> name of a notify to wait on"
"Example: which_notify = guy waittill_any( "goal", "pain", "near_goal", "bulletwhizby" );"
"SPMP: both"
@/
function waittill_any_return( string1, string2, string3, string4, string5, string6, string7 )
{
	if ((!isdefined (string1) || string1 != "entityshutdown") &&
	    (!isdefined (string2) || string2 != "entityshutdown") &&
	    (!isdefined (string3) || string3 != "entityshutdown") &&
	    (!isdefined (string4) || string4 != "entityshutdown") &&
	    (!isdefined (string5) || string5 != "entityshutdown") &&
	    (!isdefined (string6) || string6 != "entityshutdown") &&
	    (!isdefined (string7) || string7 != "entityshutdown"))
		self endon ("entityshutdown");
		
	ent = SpawnStruct();

	if (isdefined (string1))
		self thread waittill_string (string1, ent);

	if (isdefined (string2))
		self thread waittill_string (string2, ent);

	if (isdefined (string3))
		self thread waittill_string (string3, ent);

	if (isdefined (string4))
		self thread waittill_string (string4, ent);

	if (isdefined (string5))
		self thread waittill_string (string5, ent);

	if (isdefined (string6))
		self thread waittill_string (string6, ent);

	if (isdefined (string7))
		self thread waittill_string (string7, ent);

	ent waittill ("returned", msg);
	ent notify ("die");
	return msg;
}

/@
"Name: waittill_any_array_return( <a_notifies> )"
"Summary: Waits for any of the the specified notifies and return which one it got."
"Module: Utility"
"CallOn: Entity"
"MandatoryArg:	<a_notifies> array of notifies to wait on"
"Example: str_which_notify = guy waittill_any_array_return( array( "goal", "pain", "near_goal", "bulletwhizby" ) );"
"SPMP: both"
@/
function waittill_any_array_return( a_notifies )
{
	if ( IsInArray( a_notifies, "entityshutdown" ) )
	{
		self endon("entityshutdown");
	}
		
	s_tracker = SpawnStruct();
	
	foreach ( str_notify in a_notifies )
	{
		if ( isdefined( str_notify ) )
		{
			self thread waittill_string( str_notify, s_tracker );
		}
	}

	s_tracker waittill( "returned", msg );
	s_tracker notify( "die" );
	return msg;
}

/@
"Name: waittill_any( <str_notify1>, <str_notify2>, <str_notify3>, <str_notify4>, <str_notify5> )"
"Summary: Waits for any of the the specified notifies."
"Module: Utility"
"CallOn: Entity"
"MandatoryArg:	<str_notify1> name of a notify to wait on"
"OptionalArg:	<str_notify2> name of a notify to wait on"
"OptionalArg:	<str_notify3> name of a notify to wait on"
"OptionalArg:	<str_notify4> name of a notify to wait on"
"OptionalArg:	<str_notify5> name of a notify to wait on"
"Example: guy waittill_any( "goal", "pain", "near_goal", "bulletwhizby" );"
"SPMP: both"
@/
function waittill_any( str_notify1, str_notify2, str_notify3, str_notify4, str_notify5 )
{
	Assert( isdefined( str_notify1 ) );
	
	waittill_any_array( array( str_notify1, str_notify2, str_notify3, str_notify4, str_notify5 ) );
}

/@
"Name: waittill_any_array( <a_notifies> )"
"Summary: Waits for any of the the specified notifies in the array."
"Module: Utility"
"CallOn: Entity"
"MandatoryArg:	<a_notifies> array of notifies to wait on"
"Example: guy waittill_any_array( array( "goal", "pain", "near_goal", "bulletwhizby" ) );"
"SPMP: both"
@/
function waittill_any_array( a_notifies )
{
	assert( isdefined( a_notifies[0] ),
		"At least the first element has to be defined for waittill_any_array." );
	
	for ( i = 1; i < a_notifies.size; i++ )
	{
		if ( isdefined( a_notifies[i] ) )
		{
			self endon( a_notifies[i] );
		}
	}
	
	self waittill( a_notifies[0] );
}

/@
"Name: waittill_any_timeout( <n_timeout>, <str_notify1>, [str_notify2], [str_notify3], [str_notify4], [str_notify5] )"
"Summary: Waits for any of the the specified notifies or times out."
"Module: Utility"
"CallOn: Entity"
"MandatoryArg:	<n_timeout> timeout in seconds"
"MandatoryArg:	<str_notify1> name of a notify to wait on"
"OptionalArg:	<str_notify2> name of a notify to wait on"
"OptionalArg:	<str_notify3> name of a notify to wait on"
"OptionalArg:	<str_notify4> name of a notify to wait on"
"OptionalArg:	<str_notify5> name of a notify to wait on"
"Example: guy waittill_any_timeout( 2, "goal", "pain", "near_goal", "bulletwhizby" );"
"SPMP: both"
@/
function waittill_any_timeout( n_timeout, string1, string2, string3, string4, string5 )
{
	if ( ( !isdefined( string1 ) || string1 != "entityshutdown" ) &&
	( !isdefined( string2 ) || string2 != "entityshutdown" ) &&
	( !isdefined( string3 ) || string3 != "entityshutdown" ) &&
	( !isdefined( string4 ) || string4 != "entityshutdown" ) &&
	( !isdefined( string5 ) || string5 != "entityshutdown" ) )
		self endon( "entityshutdown" );

	ent = spawnstruct();

	if ( isdefined( string1 ) )
		self thread waittill_string( string1, ent );

	if ( isdefined( string2 ) )
		self thread waittill_string( string2, ent );

	if ( isdefined( string3 ) )
		self thread waittill_string( string3, ent );

	if ( isdefined( string4 ) )
		self thread waittill_string( string4, ent );

	if ( isdefined( string5 ) )
		self thread waittill_string( string5, ent );

	ent thread _timeout( n_timeout );

	ent waittill( "returned", msg );
	ent notify( "die" );
	return msg;
}

function _timeout( delay )
{
	self endon( "die" );

	wait( delay );
	self notify( "returned", "timeout" );
}

/@
"Name: waittill_notify_or_timeout( <msg>, <timer> )"
"Summary: Waits until the owner receives the specified notify message or the specified time runs out. Do not thread this!"
"CallOn: an entity"
"Example: tank waittill_notify_or_timeout( "turret_on_target", 10 ); "
"MandatoryArg: <msg> : The notify to wait for."
"MandatoryArg: <timer> : The amount of time to wait until overriding the wait statement."
@/
function waittill_notify_or_timeout( msg, timer )
{
	self endon( msg );
	wait( timer );
}

/@
"Name: waittill_any_ents( ent1, string1, ent2, string2, ent3, string3, ent4, string4 )"
"Summary: Waits for any of the the specified notifies on their associated entities."
"Module: Utility"
"CallOn: Entity"
"MandatoryArg:	<ent1> entity to wait for <string1> on"
"MandatoryArg:	<string1> notify to wait for on <ent1>"
"OptionalArg:	<ent2> entity to wait for <string2> on"
"OptionalArg:	<string2> notify to wait for on <ent2>"
"OptionalArg:	<ent3> entity to wait for <string3> on"
"OptionalArg:	<string3> notify to wait for on <ent3>"
"OptionalArg:	<ent4> entity to wait for <string4> on"
"OptionalArg:	<string4> notify to wait for on <ent4>"
"Example: guy waittill_any_ents( guy, "goal", guy, "pain", guy, "near_goal", player, "weapon_change" );"
"SPMP: both"
@/
function waittill_any_ents( ent1, string1, ent2, string2, ent3, string3, ent4, string4, ent5, string5, ent6, string6,ent7, string7 )
{
	assert( isdefined( ent1 ) );
	assert( isdefined( string1 ) );
	
	if ( ( isdefined( ent2 ) ) && ( isdefined( string2 ) ) )
		ent2 endon( string2 );

	if ( ( isdefined( ent3 ) ) && ( isdefined( string3 ) ) )
		ent3 endon( string3 );
	
	if ( ( isdefined( ent4 ) ) && ( isdefined( string4 ) ) )
		ent4 endon( string4 );
	
	if ( ( isdefined( ent5 ) ) && ( isdefined( string5 ) ) )
		ent5 endon( string5 );
	
	if ( ( isdefined( ent6 ) ) && ( isdefined( string6 ) ) )
		ent6 endon( string6 );
	
	if ( ( isdefined( ent7 ) ) && ( isdefined( string7 ) ) )
		ent7 endon( string7 );
	
	ent1 waittill( string1 );
}

/@
"Name: waittill_any_ents_two( ent1, string1, ent2, string2)"
"Summary: Waits for any of the the specified notifies on their associated entities [MAX TWO]."
"Module: Utility"
"CallOn: Entity"
"MandatoryArg:	<ent1> entity to wait for <string1> on"
"MandatoryArg:	<string1> notify to wait for on <ent1>"
"OptionalArg:	<ent2> entity to wait for <string2> on"
"OptionalArg:	<string2> notify to wait for on <ent2>"
"Example: guy waittill_any_ents_two( guy, "goal", guy, "pain");"
"SPMP: both"
@/
function waittill_any_ents_two( ent1, string1, ent2, string2 )
{
	assert( isdefined( ent1 ) );
	assert( isdefined( string1 ) );
	
	if ( ( isdefined( ent2 ) ) && ( isdefined( string2 ) ) )
		ent2 endon( string2 );

	ent1 waittill( string1 );
}

/@
"Name: single_func( <entity>, <func>, [arg1], [arg2], [arg3], [arg4], [arg5], [arg6] )"
"Summary: Runs the < func > function on the entity. The entity will become "self" in the specified function."
"Module: Utility"
"CallOn: NA"
"MandatoryArg: entity : the entity to run through <func>"
"MandatoryArg: func> : pointer to a script function"
"OptionalArg: arg1 : parameter 1 to pass to the func"
"OptionalArg: arg2 : parameter 2 to pass to the func"
"OptionalArg: arg3 : parameter 3 to pass to the func"
"OptionalArg: arg4 : parameter 4 to pass to the func"
"OptionalArg: arg5 : parameter 5 to pass to the func"
"OptionalArg: arg6 : parameter 6 to pass to the func"
"Example: single_func( guy,&set_ignoreme, false );"
"SPMP: both"
@/
function single_func( entity, func, arg1, arg2, arg3, arg4, arg5, arg6 )
{
	if ( !isdefined( entity ) )
	{
		entity = level;
	}

	if ( isdefined( arg6 ) )
	{
		return entity [[ func ]]( arg1, arg2, arg3, arg4, arg5, arg6 );
	}
	else if ( isdefined( arg5 ) )
	{
		return entity [[ func ]]( arg1, arg2, arg3, arg4, arg5 );
	}
	else if ( isdefined( arg4 ) )
	{
		return entity [[ func ]]( arg1, arg2, arg3, arg4 );
	}
	else if ( isdefined( arg3 ) )
	{
		return entity [[ func ]]( arg1, arg2, arg3 );
	}
	else if ( isdefined( arg2 ) )
	{
		return entity [[ func ]]( arg1, arg2 );
	}
	else if ( isdefined( arg1 ) )
	{
		return entity [[ func ]]( arg1 );
	}
	else
	{
		return entity [[ func ]]();
	}
}

/@
"Name: new_func( <func>, [arg1], [arg2], [arg3], [arg4], [arg5], [arg6] )"
"Summary: Creates a new func with the args stored on a struct that can be called with call_func."
"Module: Utility"
"CallOn: NA"
"MandatoryArg: func> : pointer to a script function"
"OptionalArg: arg1 : parameter 1 to pass to the func"
"OptionalArg: arg2 : parameter 2 to pass to the func"
"OptionalArg: arg3 : parameter 3 to pass to the func"
"OptionalArg: arg4 : parameter 4 to pass to the func"
"OptionalArg: arg5 : parameter 5 to pass to the func"
"OptionalArg: arg6 : parameter 6 to pass to the func"
"Example: s_callback = new_func(&set_ignoreme, false );"
"SPMP: both"
@/
function new_func( func, arg1, arg2, arg3, arg4, arg5, arg6 )
{
	s_func = SpawnStruct();
	s_func.func = func;
	s_func.arg1 = arg1;
	s_func.arg2 = arg2;
	s_func.arg3 = arg3;
	s_func.arg4 = arg4;
	s_func.arg5 = arg5;
	s_func.arg6 = arg6;
	return s_func;
}

/@
"Name: call_func( <func_struct> )"
"Summary: Runs the func and args stored on a struct created with new_func."
"Module: Utility"
"CallOn: NA"
"MandatoryArg: func_struct> : struct return by new_func"
"Example: self call_func( s_callback );"
"SPMP: both"
@/
function call_func( s_func )
{
	return single_func( self, s_func.func, s_func.arg1, s_func.arg2, s_func.arg3, s_func.arg4, s_func.arg5, s_func.arg6 );
}

/@
"Name: array_ent_thread( <entities>, <func>, [arg1], [arg2], [arg3], [arg4], [arg5] )"
"Summary: Threads the <func> function on self for every entity in the <entities> array, passing the entity has the first argument."
"Module: Array"
"CallOn: NA"
"MandatoryArg: entities : array of entities to thread the process"
"MandatoryArg: func : pointer to a script function"
"OptionalArg: arg1 : parameter 1 to pass to the func (after the entity)"
"OptionalArg: arg2 : parameter 2 to pass to the func (after the entity)"
"OptionalArg: arg3 : parameter 3 to pass to the func (after the entity)"
"OptionalArg: arg4 : parameter 4 to pass to the func (after the entity)"
"OptionalArg: arg5 : parameter 5 to pass to the func (after the entity)"
"Example: array_ent_thread( GetAITeamArray("allies"),&do_something, false );"
"SPMP: both"
@/
function array_ent_thread( entities, func, arg1, arg2, arg3, arg4, arg5 )
{
	Assert( isdefined( entities ), "Undefined entity array passed to util::array_ent_thread" );
	Assert( isdefined( func ), "Undefined function passed to util::array_ent_thread" );
	
	if ( IsArray( entities ) )
	{
		if ( entities.size )
		{
			keys = GetArrayKeys( entities );
			for ( i = 0; i < keys.size; i++ )
			{
				single_thread( self, func, entities[keys[i]], arg1, arg2, arg3, arg4, arg5 );
			}
		}
	}
	else
	{
		single_thread( self, func, entities, arg1, arg2, arg3, arg4, arg5 );
	}
}

/@
"Name: single_thread( <entity>, <func>, [arg1], [arg2], [arg3], [arg4], [arg5], [arg6] )"
"Summary: Threads the < func > function on the entity. The entity will become "self" in the specified function."
"Module: Utility"
"CallOn: "
"MandatoryArg: <entity> : the entity to thread <func> on"
"MandatoryArg: <func> : pointer to a script function"
"OptionalArg: [arg1] : parameter 1 to pass to the func"
"OptionalArg: [arg2] : parameter 2 to pass to the func"
"OptionalArg: [arg3] : parameter 3 to pass to the func"
"OptionalArg: [arg4] : parameter 4 to pass to the func"
"OptionalArg: [arg5] : parameter 5 to pass to the func"
"OptionalArg: [arg6] : parameter 6 to pass to the func"
"Example: single_func( guy,&special_ai_think, "some_string", 345 );"
"SPMP: both"
@/
function single_thread(entity, func, arg1, arg2, arg3, arg4, arg5, arg6 )
{
	Assert( isdefined( entity ), "Undefined entity passed to util::single_thread()" );

	if ( isdefined( arg6 ) )
	{
		entity thread [[ func ]]( arg1, arg2, arg3, arg4, arg5, arg6 );
	}
	else if ( isdefined( arg5 ) )
	{
		entity thread [[ func ]](arg1, arg2, arg3, arg4, arg5);
	}
	else if ( isdefined( arg4 ) )
	{
		entity thread [[ func ]]( arg1, arg2, arg3, arg4 );
	}
	else if ( isdefined( arg3 ) )
	{
		entity thread [[ func ]]( arg1, arg2, arg3 );
	}
	else if ( isdefined( arg2 ) )
	{
		entity thread [[ func ]]( arg1, arg2 );
	}
	else if ( isdefined( arg1 ) )
	{
		entity thread [[ func ]]( arg1 );
	}
	else
	{
		entity thread [[ func ]]();
	}
}

function add_listen_thread( wait_till, func, param1, param2, param3, param4, param5 )
{
	level thread add_listen_thread_internal( wait_till, func, param1, param2, param3, param4, param5 );
}

function add_listen_thread_internal( wait_till, func, param1, param2, param3, param4, param5 )
{
	for( ;; )
	{
		level waittill( wait_till );
		single_thread(level, func, param1, param2, param3, param4, param5);
	}
}

/@
"Name: timeout( <n_time>, <func>, [arg1], [arg2], [arg3], [arg4], [arg5], [arg6] )"
"Summary: Run any function with a timeout.  The function will exit when the timeout is reached."
"CallOn: any"
"MandatoryArg: <n_time> : the timeout"
"MandatoryArg: <func> : the function"
"OptionalArg: [arg1] : parameter 1 to pass to the func"
"OptionalArg: [arg2] : parameter 2 to pass to the func"
"OptionalArg: [arg3] : parameter 3 to pass to the func"
"OptionalArg: [arg4] : parameter 4 to pass to the func"
"OptionalArg: [arg5] : parameter 5 to pass to the func"
"OptionalArg: [arg6] : parameter 6 to pass to the func"
"Example: ent timeout( 10, &my_function, 12, "hi" );"
@/
function timeout( n_time, func, arg1, arg2, arg3, arg4, arg5, arg6 )
{
	self endon( "entityshutdown" );
	TIMEOUT( n_time );
	
	single_func( self, func, arg1, arg2, arg3, arg4, arg5, arg6 );
}

/@
"Name: delay(<time_or_notify>, [str_endon], <function>, [arg1], [arg2], [arg3], [arg4], [arg5])"
"Summary: Delay the execution of a thread."
"MandatoryArg: <time_or_notify> : Time to wait( in seconds ) or notify to wait for before sending the notify."
"OptionalArg: [str_endon] : endon to cancel the function call"
"MandatoryArg: <function> : The function to run."
"OptionalArg: [arg1] : parameter 1 to pass to the process"
"OptionalArg: [arg2] : parameter 2 to pass to the process"
"OptionalArg: [arg3] : parameter 3 to pass to the process"
"OptionalArg: [arg4] : parameter 4 to pass to the process"
"OptionalArg: [arg5] : parameter 5 to pass to the process"
"Example: delay( &flag::set, "player_can_rappel", 3 );"
@/
function delay( time_or_notify, str_endon, func, arg1, arg2, arg3, arg4, arg5, arg6 )
{
	self thread _delay( time_or_notify, str_endon, func, arg1, arg2, arg3, arg4, arg5, arg6 );
}

function _delay( time_or_notify, str_endon, func, arg1, arg2, arg3, arg4, arg5, arg6 )
{
	self endon( "entityshutdown" );
	
	if ( isdefined( str_endon ) )
	{
		self endon( str_endon );
	}
	
	if ( IsString( time_or_notify ) )
	{
		self waittill( time_or_notify );
	}
	else
	{
		wait time_or_notify;
	}
	
	single_func( self, func, arg1, arg2, arg3, arg4, arg5, arg6 );
}

/@
"Name: delay_notify( <n_delay>, <str_notify>, [str_endon] )"
"Summary: Notifies self the string after waiting the specified delay time"
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <time_or_notify> : Time to wait( in seconds ) or notify to wait for before sending the notify."
"MandatoryArg: <str_notify> : The string to notify"
"OptionalArg: <str_endon> : Endon to cancel the notify"
"Example: vehicle delay_notify( 3.5, "start_to_smoke" );"
"SPMP: singleplayer"
@/
function delay_notify( time_or_notify, str_notify, str_endon )
{
	self thread _delay_notify( time_or_notify, str_notify, str_endon );
}

function _delay_notify( time_or_notify, str_notify, str_endon )
{
	self endon( "entityshutdown" );
	
	if ( isdefined( str_endon ) )
	{
		self endon( str_endon );
	}
	
	if ( IsString( time_or_notify ) )
	{
		self waittill( time_or_notify );
	}
	else
	{
		wait time_or_notify;
	}
	
	self notify( str_notify );
}

// Time

function new_timer( n_timer_length )
{
	s_timer = SpawnStruct();
	s_timer.n_time_created = GetTime();
	s_timer.n_length = n_timer_length;
	return s_timer;
}

function get_time()
{
	t_now = GetTime();
	return t_now - self.n_time_created;
}

function get_time_in_seconds()
{
	return get_time() / 1000;
}

function get_time_frac( n_end_time )
{
	DEFAULT( n_end_time, self.n_length );	
	return ( LerpFloat( 0, 1, get_time_in_seconds() / n_end_time ) );
}

function get_time_left()
{
	if ( isdefined( self.n_length ) )
	{
		n_current_time = get_time_in_seconds();
		return ( Max( self.n_length - n_current_time, 0 ) );
	}

	return -1;
}

function is_time_left()
{
	return ( get_time_left() != 0 );
}

function timer_wait( n_wait )
{
	if ( isdefined( self.n_length ) )
	{
		n_wait = Min( n_wait, get_time_left() );
	}
	
	wait n_wait;
	
	n_current_time = get_time_in_seconds();
	
	return n_current_time;
}

function add_remove_list( &a, on_off )
{
	DEFAULT(a,[]);
	if ( on_off )
	{
		if ( !IsInArray( a, self ) )
		{
			ArrayInsert(a,self,a.size);
		}
	}
	else
	{
		ArrayRemoveValue( a, self, false );
	}
}

function clean_deleted( &array )
{
	done = false; 
	while ( !done && array.size > 0 )
	{
		done = true;
		foreach( key, val in array )
		{
			if (!IsDefined(val))
			{
				ArrayRemoveIndex(array,key,false);
				done = false; 
				break;
			}
		}
	}
}

/@
"Name: get_eye()"
"Summary: Get eye position accurately even on a player when linked to an entity."
"Module: Utility"
"CallOn: Player or AI"
"Example: eye_pos = player get_eye();"
"SPMP: both"
@/
function get_eye()
{
	if( SessionModeIsCampaignGame() )
	{
		if (self IsPlayer())
		{
			linked_ent = self GetLinkedEnt();
			if (isdefined(linked_ent) && (GetDvarInt("cg_cameraUseTagCamera") > 0))
			{
				camera = linked_ent GetTagOrigin("tag_camera");
				if (isdefined(camera))
				{
					return camera;
				}
			}
		}
	}

	pos = self GetEye();
	return pos;
}

function spawn_player_arms()
{
	arms = spawn(self GetLocalClientNumber(), self.origin + ( 0, 0, -1000 ), "script_model");

	if (isdefined(level.player_viewmodel))
	{
		// level specific viewarms
		arms SetModel(level.player_viewmodel);
	}
	else
	{
		// default viewarms
		arms SetModel("c_usa_cia_masonjr_viewhands");  // updated default viewarms to match _loadout.gsc - TravisJ 12/13/2011
	}

	return arms;
}

function lerp_dvar( str_dvar, n_start_val, n_end_val, n_lerp_time, b_saved_dvar, b_client_dvar, n_client = 0 )
{
	DEFAULT( n_start_val, GetDvarFloat( str_dvar ) );
	
	s_timer = new_timer();
	
	do
	{
		n_time_delta = s_timer timer_wait( .01666 );
		n_curr_val = LerpFloat( n_start_val, n_end_val, n_time_delta / n_lerp_time );
		
		if ( IS_TRUE( b_saved_dvar ) )
		{
			SetSavedDvar( str_dvar, n_curr_val );
		}
		/*else if ( IS_TRUE( b_client_dvar ) )//TODO T7 - not supported in MP
		{
				SetClientDvar( str_dvar, n_curr_val );
		}	*/
		else
		{
			SetDvar( str_dvar, n_curr_val );
		}
	}
	while ( n_time_delta < n_lerp_time );
}



function is_valid_type_for_callback(type)
{
	switch(type)
	{
		case "actor":
		case "vehicle":
		case "player":
		case "NA":
		case "general":
		case "trigger":
		case "missile":
		case "scriptmover":
		case "turret":
		case "plane":
		case "helicopter":
		{
			return true;
		}
		default:
		{
			return false;
		}
	}
}

/@
"Name: wait_till_not_touching( <ent> )"
"Summary: Blocking function. Returns when entity one is no longer touching entity two or either entity dies."
"Module: Util"
"MandatoryArg: <e_to_check>: The entity you want to check"
"MandatoryArg: <e_to_touch>: The entity you want to touch"	
"Example: util::wait_till_not_touching( player, t_player_safe )"
"SPMP: singleplayer"
@/
function wait_till_not_touching( e_to_check, e_to_touch )
{
	Assert( isdefined( e_to_check ), "Undefined check entity passed to util::wait_till_not_touching" );
	Assert( isdefined( e_to_touch ), "Undefined touch entity passed to util::wait_till_not_touching" );
	
	e_to_check endon( "entityshutdown" );
	e_to_touch endon( "entityshutdown" );	
	
	while( e_to_check IsTouching( e_to_touch ) )
	{
		wait( 0.05 );
	}
}

/#
function error( message )
{
	println( "^c * ERROR * ", message );
	wait 0.05;
 }
#/

function register_system(sSysName, cbFunc)
{
	if(!isdefined(level._systemStates))
	{
		level._systemStates = [];
	}
	
	if(level._systemStates.size >= 32)	
	{
		/#error("Max num client systems exceeded.");#/
		return;
	}
	
	if(isdefined(level._systemStates[sSysName]))
	{
		/#error("Attempt to re-register client system : " + sSysName);#/
		return;
	}
	else
	{
		level._systemStates[sSysName] = spawnstruct();
		level._systemStates[sSysName].callback = cbFunc;
	}
}

function field_set_lighting_ent( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	level.light_entity = self;
}

function field_use_lighting_ent( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	//TODO T7 - SetLightingEntity not on MP
	/*if ( newVal )
	{
		self SetLightingEntity( level.light_entity );
	}
	else
	{
		self SetLightingEntity( self );
	}*/
}

function waittill_dobj(localClientNum)
{
	while( isdefined( self ) && !(self hasdobj(localClientNum)) )
	{
		WAIT_CLIENT_FRAME;
	}
}

function server_wait( localClientNum, seconds, waitBetweenChecks, level_endon )//serverwait
{
	if ( isdefined( level_endon ) )
	{
		level endon( level_endon );
	}
	
	if ( level.isDemoPlaying && seconds != 0 )
	{
		if ( !isdefined( waitBetweenChecks ) )
		{
			waitBetweenChecks = 0.2;
		}

		waitCompletedSuccessfully = false;
		startTime = level.serverTime;
		lastTime = startTime;
		endTime = startTime + (seconds * 1000);

		while( level.serverTime < endTime && level.serverTime >= lastTime )
		{
			lastTime = level.serverTime;
			wait( waitBetweenChecks );
		}

		if ( lastTime < level.serverTime )
		{
			waitCompletedSuccessfully = true;
		}
	}
	else
	{
		waitrealtime( seconds );
		waitCompletedSuccessfully = true;
	}
	
	return waitCompletedSuccessfully;
}

function friend_not_foe( localClientIndex, predicted )//friendnotfoe
{
	player = GetNonPredictedLocalPlayer( localClientIndex ); // Get the local client player not the predicted player

	// use the predicted local player when we want to see what they saw
	if ( IS_TRUE( predicted ) || isdefined( player ) && isdefined( player.team ) && ( player.team == "spectator" ))
	{
		player = GetLocalPlayer( localClientIndex ); // if spectating use the team info from the predicted/spectated client
	}

	if ( isdefined( player ) && isdefined( player.team ))
	{
		team = player.team;

		// using the player team to determine team base games
		if ( team == "free" )
		{
			owner = self GetOwner( localClientIndex );

			if ( isdefined( owner ) && owner == player )
			{
				return true;
			}
		}
		else if ( self.team == team )
		{
			return true;
		}
	}
	
	return false;
}


function friend_not_foe_team( localClientIndex, team, predicted )//friendnotfoe
{
	player = GetNonPredictedLocalPlayer( localClientIndex ); // Get the local client player not the predicted player

	// use the predicted local player when we want to see what they saw
	if ( IS_TRUE( predicted ) || isdefined( player ) && isdefined( player.team ) && ( player.team == "spectator" ))
	{
		player = GetLocalPlayer( localClientIndex ); // if spectating use the team info from the predicted/spectated client
	}

	if ( isdefined( player ) && isdefined( player.team ))
	{
	 	if ( player.team == team )
		{
			return true;
		}
	}
	
	return false;
}


function IsEnemyPlayer( player )
{
	assert( isdefined( player ) );

	if( !player IsPlayer() )
		return false;

	if( player.team != "free" )
	{
		if ( player.team == self.team ) 
		{
			return false;
		}
	}
	else
	{
		if ( player == self )
		{
			return false;	
		}
	}
	return true;
}

function is_player_view_linked_to_entity(localClientNum)//isplayerviewlinkedtoentity
{
	if ( self IsDriving( localClientNum ) )
	{
		return true;
	}
		
	if ( self IsLocalPlayerWeaponViewOnlyLinked( ) )
	{
		return true;
	}

	return false;
}

function init_utility()
{
	level.IsDemoPlaying = IsDemoPlaying();
	level.localPlayers = [];
	level.numGametypeReservedObjectives = [];
	level.releasedObjectives = [];

	maxLocalClients = GetMaxLocalClients();
	for( localClientNum = 0; localClientNum < maxLocalClients; localClientNum++ )
	{
		level.releasedObjectives[localClientNum] = [];
		level.numGametypeReservedObjectives[localClientNum] = 0;
	}


	util::WaitForClient( 0 );
	level.localPlayers = GetLocalPlayers();
}

/@
"Name: within_fov( <start_origin> , <start_angles> , <end_origin> , <fov> )"
"Summary: Returns true if < end_origin > is within the players field of view, otherwise returns false."
"Module: Vector"
"CallOn: "
"MandatoryArg: <start_origin> : starting origin for FOV check( usually the players origin )"
"MandatoryArg: <start_angles> : angles to specify facing direction( usually the players angles )"
"MandatoryArg: <end_origin> : origin to check if it is in the FOV"
"MandatoryArg: <fov> : cosine of the FOV angle to use"
"Example: qBool = within_fov( level.player.origin, level.player.angles, target1.origin, cos( 45 ) );"
"SPMP: multiplayer"
@/ 
function within_fov( start_origin, start_angles, end_origin, fov )
{
	normal = VectorNormalize( end_origin - start_origin ); 
	forward = AnglesToForward( start_angles ); 
	dot = VectorDot( forward, normal ); 

	return dot >= fov; 
}

function is_mature()
{
	return IsMatureContentEnabled();
}

function is_gib_restricted_build()
{
	if( !(IsMatureContentEnabled() && IsShowGibsEnabled() ))
	{
		return true;
	}

	return false;
}

// fancy quicker struct array handling, assumes array elements are objects with which an index can be asigned to( IE: can't do 5.struct_array_index ) 
// also have to be sure that objects can't be a part of another structarray setup as the index position is asigned to the object

function registerSystem(sSysName, cbFunc)
{
	if(!isdefined(level._systemStates))
	{
		level._systemStates = [];
	}
	
	if(level._systemStates.size >= 32)	
	{
		/#error("Max num client systems exceeded.");#/
		return;
	}
	
	if(isdefined(level._systemStates[sSysName]))
	{
		/#error("Attempt to re-register client system : " + sSysName);#/
		return;
	}
	else
	{
		level._systemStates[sSysName] = spawnstruct();
		level._systemStates[sSysName].callback = cbFunc;
	}	
}

function getStatsTableName()
{
	if ( SessionModeIsCampaignGame() )
	{
		return STATS_TABLE_CP;
	}
	else if ( SessionModeIsZombiesGame() )
	{
		return STATS_TABLE_ZM;
	}
	else
	{
		return STATS_TABLE_MP;
	}
}

/*setFootstepEffect(name, fx)
{
	assert(isdefined(name), "Need to define the footstep surface type.");
	assert(isdefined(fx), "Need to define the " + name + " effect.");
	if (!isdefined(level._optionalStepEffects))
		level._optionalStepEffects = [];
	level._optionalStepEffects[level._optionalStepEffects.size] = name;
	level._effect["step_" + name] = fx;
}*/

function add_trigger_to_ent(ent, trig)
{
	if(!isdefined(ent._triggers))
	{
		ent._triggers = [];
	}
	
	ent._triggers[trig getentitynumber()] = 1;
}

function remove_trigger_from_ent(ent, trig)
{
	if(!isdefined(ent._triggers))
		return;
		
	if(!isdefined(ent._triggers[trig getentitynumber()]))
		return;
		
	ent._triggers[trig getentitynumber()] = 0;
}

function ent_already_in_trigger(trig)
{
	if(!isdefined(self._triggers))
		return false;
		
	if(!isdefined(self._triggers[trig getentitynumber()]))
		return false;
		
	if(!self._triggers[trig getentitynumber()])
		return false;
		
	return true;	// We're already in this trigger volume.
}

function trigger_thread(ent, on_enter_payload, on_exit_payload)
{
	ent endon("entityshutdown");
	
	if(ent ent_already_in_trigger(self))
		return;
		
	add_trigger_to_ent(ent, self);

//	iprintlnbold("Trigger " + self.targetname + " hit by ent " + ent getentitynumber());
	
	if(isdefined(on_enter_payload))
	{
		[[on_enter_payload]](ent);
	}
	
	while(isdefined(ent) && ent istouching(self))
	{
		WAIT_CLIENT_FRAME;
	}

//	iprintlnbold(ent getentitynumber() + " leaves trigger " + self.targetname + ".");

	if(isdefined(ent) && isdefined(on_exit_payload))
	{
		[[on_exit_payload]](ent);
	}

	if(isdefined(ent))
	{
		remove_trigger_from_ent(ent, self);
	}
}

// This function differs from trigger_thread in that it does not end on entityshutdown
// and it will always call the on_exit_payload even if the ent is not defined.
// Use cases are on players where you want the exit to be called even if the player goes into killcam
function local_player_trigger_thread_always_exit( ent, on_enter_payload, on_exit_payload)
{
	if(ent ent_already_in_trigger(self))
		return;
		
	add_trigger_to_ent(ent, self);

	if(isdefined(on_enter_payload))
	{
		[[on_enter_payload]](ent);
	}
	
	while(isdefined(ent) && ent istouching(self) && ent issplitscreenhost() )
	{
		WAIT_CLIENT_FRAME;
	}

	if(isdefined(on_exit_payload))
	{
		[[on_exit_payload]](ent);
	}

	if(isdefined(ent))
	{
		remove_trigger_from_ent(ent, self);
	}
}

function local_player_entity_thread( localClientNum, entity, func, arg1, arg2, arg3, arg4 )
{
	entity endon("entityshutdown");
	
	entity waittill_dobj( localClientNum );
	
	single_thread(entity, func, localClientNum, arg1, arg2, arg3, arg4);
}

/@
"Name: local_players_entity_thread( <entity> , <func> , <arg1> , <arg2> , <arg3>, <arg4> )"
"Summary: Threads the < func > function on entity on all local players when the dobj becomes valid. The entity will become "self" in the specified function."
"Module: Array"
"CallOn: "
"MandatoryArg: <entity> : entity to thread the process"
"MandatoryArg: <func> : pointer to a script function.  Function must have the first parameter of localCientNum"
"OptionalArg: <arg1> : parameter 1 to pass to the func"
"OptionalArg: <arg2> : parameter 2 to pass to the func"
"OptionalArg: <arg3> : parameter 3 to pass to the func"
"OptionalArg: <arg4> : parameter 4 to pass to the func"
"Example: local_players_entity_thread( chopper,&spawn_fx );"
"SPMP: mp"
@/ 
function local_players_entity_thread( entity, func, arg1, arg2, arg3, arg4 )
{
	players = level.localPlayers;
	for (i = 0; i < players.size; i++)
	{
		players[i] thread local_player_entity_thread( i, entity, func, arg1, arg2, arg3, arg4 );
	}
}	

function debug_line( from, to, color, time )
{
}

function debug_star( origin, color, time )
{
}


function serverTime()
{
	for (;;)
	{
		level.serverTime = getServerTime( 0 );
		WAIT_CLIENT_FRAME;
	}
}

function getNextObjID( localClientNum )
{
	nextID = 0;
	
	if (  level.releasedObjectives[localClientNum].size > 0 )
	{
		nextID = level.releasedObjectives[localClientNum][ level.releasedObjectives[localClientNum].size - 1 ];
		level.releasedObjectives[localClientNum][ level.releasedObjectives[localClientNum].size - 1 ] = undefined;
	}
	else
	{
		nextID = level.numGametypeReservedObjectives[localClientNum];
		level.numGametypeReservedObjectives[localClientNum]++;
	}

/#
	//No longer an assert, but still print a warning so we know when it happens.
	if( nextId > MAX_CLIENT_OBJECTIVE_IDS - 1 )
	{
		println("^3SCRIPT WARNING: Ran out of objective IDs");
	}
	assert( nextId < MAX_CLIENT_OBJECTIVE_IDS );
#/
	
	// if for some reason we ever overrun the objective array then just going
	// to keep using the last objective id.  This should only happen in extreme
	// situations (ie. trying to make this happen).
	if ( nextId > MAX_CLIENT_OBJECTIVE_IDS - 1 )
		nextId = MAX_CLIENT_OBJECTIVE_IDS - 1;
	
	return nextID;
}

function releaseObjID( localClientNum, objID )
{
	assert( objID < level.numGametypeReservedObjectives[localClientNum] );
	for( i = 0; i < level.releasedObjectives[localClientNum].size; i++ )
	{
		if( objID == level.releasedObjectives[localClientNum][i] )
			return;
	}
	level.releasedObjectives[localClientNum][level.releasedObjectives[localClientNum].size] = objID;		
}

function get_next_safehouse( str_next_map )
{
	switch( str_next_map )
	{
		case "cp_mi_sing_blackstation":
		case "cp_mi_sing_biodomes":
		case "cp_mi_sing_sgen":
			
			return "cp_sh_singapore";
			
		case "cp_mi_cairo_infection":
		case "cp_mi_cairo_aquifer":
		case "cp_mi_cairo_lotus":
			
			return "cp_sh_cairo";
		
		default:
			
			return "cp_sh_mobile";
	}
}

function is_safehouse( str_next_map )
{
	DEFAULT( str_next_map, ToLower( GetDvarString( "mapname" ) ) );
	
	switch ( str_next_map )
	{
		case "cp_sh_cairo":
		case "cp_sh_mobile":
		case "cp_sh_singapore":
			
			return true;
			
		default:
			
			return false;
	}
}


