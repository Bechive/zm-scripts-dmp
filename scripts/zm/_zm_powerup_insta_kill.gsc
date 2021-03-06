#using scripts\codescripts\struct;

#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\shared\ai\zombie_death;

#using scripts\zm\_zm_bgb;
#using scripts\zm\_zm_pers_upgrades_functions;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_spawner;
#using scripts\zm\_zm_utility;

#insert scripts\zm\_zm_powerups.gsh;
#insert scripts\zm\_zm_utility.gsh;

#precache( "material", "specialty_instakill_zombies" );
#precache( "string", "ZOMBIE_POWERUP_INSTA_KILL" );

#namespace zm_powerup_insta_kill;

REGISTER_SYSTEM( "zm_powerup_insta_kill", &__init__, undefined )


//-----------------------------------------------------------------------------------
// setup
//-----------------------------------------------------------------------------------
function __init__()
{
	zm_powerups::register_powerup( "insta_kill", &grab_insta_kill );
	if( ToLower( GetDvarString( "g_gametype" ) ) != "zcleansed" )
	{
		zm_powerups::add_zombie_powerup( "insta_kill", "p7_zm_power_up_insta_kill", &"ZOMBIE_POWERUP_INSTA_KILL",	&zm_powerups::func_should_always_drop, !POWERUP_ONLY_AFFECTS_GRABBER, !POWERUP_ANY_TEAM, !POWERUP_ZOMBIE_GRABBABLE, undefined, CLIENTFIELD_POWERUP_INSTANT_KILL, "zombie_powerup_insta_kill_time", "zombie_powerup_insta_kill_on" );	
	}
}

function grab_insta_kill( player )
{	
	level thread insta_kill_powerup( self,player );
	player thread zm_powerups::powerup_vo("insta_kill");
}

function insta_kill_powerup( drop_item, player )
{
	level notify( "powerup instakill_" + player.team );
	level endon( "powerup instakill_" + player.team );

	if(isDefined(level.insta_kill_powerup_override )) //race
	{
		level thread [[level.insta_kill_powerup_override]](drop_item,player);
		return;
	}

	// Only in classic mode - Update the "insta kill" persistent unlock
	if( zm_utility::is_Classic() )
	{
		player thread zm_pers_upgrades_functions::pers_upgrade_insta_kill_upgrade_check();
	}

	team = player.team;
	
	level thread zm_powerups::show_on_hud( team, "insta_kill" );

	level.zombie_vars[team]["zombie_insta_kill"] = 1;	
	n_wait_time = N_POWERUP_DEFAULT_TIME;
	wait n_wait_time;	
	level.zombie_vars[team]["zombie_insta_kill"] = 0;

	players = GetPlayers( team );
	for( i=0; i<players.size; i++ )
	{
		if( isdefined(players[i]) )
		{
			players[i] notify( "insta_kill_over" );
		}
	}
}
