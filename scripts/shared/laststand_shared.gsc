#using scripts\codescripts\struct;

#using scripts\shared\flag_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

// The number of laststands in type getup that the player starts with
#define LASTSTAND_GETUP_COUNT_START	0
// Percent of the bar removed by AI damage		
#define LASTSTAND_GETUP_BAR_DAMAGE	0.1


#namespace laststand;

//TODO T7 - once we decide what should/shouldn't be in here, do a pass on function names to fit better with the namespace
function player_is_in_laststand()
{
	if ( !IS_TRUE( self.no_revive_trigger ) )
	{
		return ( IsDefined( self.revivetrigger ) );
	}
	else
	{
		return ( IS_TRUE( self.laststand ) );
	}
}


function player_num_in_laststand()
{
	num = 0;
	players = GetPlayers();

	for ( i = 0; i < players.size; i++ )
	{	
		if ( players[i] player_is_in_laststand() )
		{
			num++;
		}
	}

	return num;
}

function player_all_players_in_laststand()
{
	return ( player_num_in_laststand() == GetPlayers().size );
}

function player_any_player_in_laststand()
{
	return ( player_num_in_laststand() > 0 );
}

function laststand_allowed( sWeapon, sMeansOfDeath, sHitLoc )
{
	if( level.laststandpistol == "none" )
	{
		return false;
	}
	
	return true;
}

function cleanup_suicide_hud()
{
	if( isdefined( self.suicidePrompt ) )
	{
		self.suicidePrompt destroy();
	}
	self.suicidePrompt = undefined;	
}

function clean_up_suicide_hud_on_end_game()
{
	self endon ( "disconnect" );
	self endon ( "stop_revive_trigger" );
	self endon ( "player_revived");
	self endon ( "bled_out"); 
	level util::waittill_any("game_ended","stop_suicide_trigger");
	self cleanup_suicide_hud();
	
	if ( IsDefined( self.suicideTextHud ) )
	{
		self.suicideTextHud Destroy();
	}
	
	if ( IsDefined( self.suicideProgressBar ) )
	{
		self.suicideProgressBar hud::destroyElem();
	}
	

}

function clean_up_suicide_hud_on_bled_out()
{
	self endon ( "disconnect" );
	self endon ( "stop_revive_trigger" );
	self util::waittill_any( "bled_out","player_revived","fake_death" ); 
	self cleanup_suicide_hud();
	
	if ( IsDefined( self.suicideProgressBar ) )
	{
		self.suicideProgressBar hud::destroyElem();
	}
	
	if ( IsDefined( self.suicideTextHud ) )
	{
		self.suicideTextHud Destroy();
	}
}

function is_facing( facee, requiredDot = 0.9 )
{
	orientation = self getPlayerAngles();
	forwardVec = anglesToForward( orientation );
	forwardVec2D = ( forwardVec[0], forwardVec[1], 0 );
	unitForwardVec2D = VectorNormalize( forwardVec2D );
	toFaceeVec = facee.origin - self.origin;
	toFaceeVec2D = ( toFaceeVec[0], toFaceeVec[1], 0 );
	unitToFaceeVec2D = VectorNormalize( toFaceeVec2D );
	
	dotProduct = VectorDot( unitForwardVec2D, unitToFaceeVec2D );
	return ( dotProduct > requiredDot ); // reviver is facing within a ~52-degree cone of the player
}


//*****************************************************************************
//*****************************************************************************

// the text that tells players that others are in need of a revive
function revive_hud_create()
{	
	self.revive_hud = newclientHudElem( self );
	self.revive_hud.alignX = "center";
	self.revive_hud.alignY = "middle";
	self.revive_hud.horzAlign = "center";
	self.revive_hud.vertAlign = "bottom";
	self.revive_hud.foreground = true;
	self.revive_hud.font = "default";
	self.revive_hud.fontScale = 1.5;
	self.revive_hud.alpha = 0;
	self.revive_hud.color = ( 1.0, 1.0, 1.0 );
	self.revive_hud.hidewheninmenu = true;
	self.revive_hud setText( "" );

	self.revive_hud.y = -148;
}

function revive_hud_show()
{
	assert( IsDefined( self ) );
	assert( IsDefined( self.revive_hud ) );

	self.revive_hud.alpha = 1;
}

//CODER_MOD: TOMMYK 07/13/2008
function revive_hud_show_n_fade(time)
{
	revive_hud_show();

	self.revive_hud fadeOverTime( time );
	self.revive_hud.alpha = 0;
}

function drawcylinder(pos, rad, height)
{
}

function get_lives_remaining()
{
	assert( level.lastStandGetupAllowed, "Lives only exist in the Laststand type GETUP." );

	if ( level.lastStandGetupAllowed && IsDefined( self.laststand_info ) && IsDefined( self.laststand_info.type_getup_lives ) )
	{
		return max( 0, self.laststand_info.type_getup_lives );
	}

	return 0;
}

function update_lives_remaining( increment )
{
	assert( level.lastStandGetupAllowed, "Lives only exist in the Laststand type GETUP." );
	assert( isdefined( increment ), "Must specify increment true or false" );

	// Increment / Decrement lives 
	increment = (isdefined( increment )?increment:false );
	self.laststand_info.type_getup_lives = max( 0, ( increment?self.laststand_info.type_getup_lives + 1:self.laststand_info.type_getup_lives - 1 ) );

	// Notify HUD that laststand life amount has changed
	self notify( "laststand_lives_updated" );
}

function player_getup_setup()
{
/#	println( "ZM >> player_getup_setup called" );	#/
	self.laststand_info = SpawnStruct();
	self.laststand_info.type_getup_lives = LASTSTAND_GETUP_COUNT_START;
}

function laststand_getup_damage_watcher()
{
	self endon ("player_revived");
	self endon ("disconnect");

	while(1)
	{
		self waittill( "damage" );

		self.laststand_info.getup_bar_value -= LASTSTAND_GETUP_BAR_DAMAGE;

		if( self.laststand_info.getup_bar_value < 0 )
		{
			self.laststand_info.getup_bar_value = 0;
		}
	}
}

function laststand_getup_hud()
{
	self endon ("player_revived");
	self endon ("disconnect");

	hudelem = NewClientHudElem( self );

	hudelem.alignX = "left";
	hudelem.alignY = "middle";
	hudelem.horzAlign = "left";
	hudelem.vertAlign = "middle";
	hudelem.x = 5;
	hudelem.y = 170;
	hudelem.font = "big";
	hudelem.fontScale = 1.5;
	hudelem.foreground = 1;
	hudelem.hidewheninmenu = true;
	hudelem.hidewhendead = true;
	hudelem.sort = 2;
	hudelem.label = &"SO_WAR_LASTSTAND_GETUP_BAR";

	self thread laststand_getup_hud_destroy( hudelem );

	while( 1 )
	{
		hudelem SetValue( self.laststand_info.getup_bar_value );
		WAIT_SERVER_FRAME;
	}
}

function laststand_getup_hud_destroy( hudelem )
{
	self util::waittill_either( "player_revived", "disconnect" );

	hudelem Destroy();
}

function cleanup_laststand_on_disconnect()
{
	self endon ("player_revived");
	self endon ("player_suicide");
	self endon ("bled_out");
	
	trig =  self.revivetrigger;
	
	self waittill ("disconnect");
	if(isDefined(trig))
	{
		trig delete();
	}
	
}	
