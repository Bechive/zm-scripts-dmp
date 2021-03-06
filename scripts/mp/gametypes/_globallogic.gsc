#using scripts\shared\bb_shared;
#using scripts\codescripts\struct;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\challenges_shared;
#using scripts\shared\damagefeedback_shared;
#using scripts\shared\demo_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\hostmigration_shared;
#using scripts\shared\hud_shared;//DO NOT REMOVE - needed for system registration
#using scripts\shared\hud_message_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\math_shared;
#using scripts\shared\music_shared;
#using scripts\shared\objpoints_shared;
#using scripts\shared\persistence_shared;
#using scripts\shared\rank_shared;
#using scripts\shared\util_shared;
#using scripts\shared\simple_hostmigration;
#using scripts\shared\system_shared;
#using scripts\shared\tweakables_shared;
#using scripts\shared\visionset_mgr_shared;
#using scripts\shared\lui_shared;
#using scripts\shared\weapons\_hive_gun;
#using scripts\shared\weapons\_weapon_utils;
#using scripts\shared\weapons\_weapons;
#using scripts\mp\gametypes\_dogtags;

#using scripts\shared\bots\_bot;

#using scripts\mp\gametypes\_battlechatter;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_clientids;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_deathicons;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_dev;
#using scripts\mp\gametypes\_friendicons;
#using scripts\mp\gametypes\_globallogic_audio;
#using scripts\mp\gametypes\_globallogic_defaults;
#using scripts\mp\gametypes\_globallogic_player;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_globallogic_spawn;
#using scripts\mp\gametypes\_globallogic_ui;
#using scripts\mp\gametypes\_globallogic_utils;
#using scripts\mp\gametypes\_healthoverlay;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_hostmigration;
#using scripts\mp\gametypes\_hud_message;
#using scripts\mp\gametypes\_killcam;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_loadout;
#using scripts\mp\gametypes\_menus;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_scoreboard;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_serversettings;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_shellshock;
#using scripts\mp\gametypes\_spawning;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_spawnlogic;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_spectating;//DO NOT REMOVE - needed for system registration
#using scripts\mp\gametypes\_weapon_utils;
#using scripts\mp\gametypes\_weapons;//DO NOT REMOVE - needed for system registration

#using scripts\mp\_arena;
#using scripts\mp\_behavior_tracker;
#using scripts\mp\_challenges;
#using scripts\mp\_gameadvertisement;
#using scripts\mp\_gamerep;
#using scripts\mp\_rat;
#using scripts\mp\_teamops;
#using scripts\mp\_util;
#using scripts\mp\bots\_bot;//DO NOT REMOVE - needed for system registration
#using scripts\mp\killstreaks\_dogs;
#using scripts\mp\killstreaks\_killstreaks;//DO NOT REMOVE - needed for system registration
#using scripts\mp\teams\_teams;//DO NOT REMOVE - needed for system registration

#insert scripts\mp\gametypes\_globallogic.gsh;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

// must match the stats.ddl quitTypes_e enum
#define MATCH_KICKED 2
#define MATCH_QUIT 3
#define MATCH_FINISHED 4

#define TAUNT_TYPE_FIRST_PLACE	0
	
#define GESTURE_TYPE_GOOD_GAME	0
#define GESTURE_TYPE_THREATEN	1
#define GESTURE_TYPE_BOAST		2
#define GESTURE_TYPE_MAX		7
	
#define OTHER_LOOTXP_UPLOADSTAT_WAITTIME	1.0
#define WAIT_TIME_BEFORE_AWARDING_LOOT_XP	3.0

#namespace globallogic;

#precache( "model", "tag_origin" );

#precache( "statusicon", "hud_status_dead" );
#precache( "statusicon", "hud_status_connecting" );

#precache( "material", "white" );
#precache( "material", "black" );

#precache( "string", "PLATFORM_PRESS_TO_SPAWN" );
#precache( "string", "MP_WAITING_FOR_TEAMS" );
#precache( "string", "MP_OPPONENT_FORFEITING_IN" );
#precache( "string", "MP_WAITING_FOR_PLAYERS" );
#precache( "string", "MP_OPPONENT_FORFEITING_IN" );
#precache( "string", "MP_MATCH_STARTING_IN" );
#precache( "string", "MP_SPAWN_NEXT_ROUND" );
#precache( "string", "MP_WAITING_TO_SPAWN" );
#precache( "string", "MP_WAITING_TO_SPAWN_SS" );
#precache( "string", "MP_YOU_WILL_RESPAWN" );
#precache( "string", "MP_MATCH_STARTING" );
#precache( "string", "MP_CHANGE_CLASS_NEXT_SPAWN" );
#precache( "string", "MPUI_LAST_STAND" );
#precache( "string", "PLATFORM_COWARDS_WAY_OUT" );
#precache( "string", "MP_MATCH_TIE" );
#precache( "string", "MP_ROUND_DRAW" );
#precache( "string", "MP_ENEMIES_ELIMINATED" );
#precache( "string", "MP_SCORE_LIMIT_REACHED" );
#precache( "string", "MP_ROUND_LIMIT_REACHED" );
#precache( "string", "MP_TIME_LIMIT_REACHED" );
#precache( "string", "MP_PLAYERS_FORFEITED" );
#precache( "string", "MP_OTHER_TEAMS_FORFEITED" );

#precache( "eventstring", "prematch_waiting_for_players" );
#precache( "eventstring", "create_prematch_timer" );
#precache( "eventstring", "prematch_timer_ended" );
#precache( "eventstring", "force_scoreboard" );

#precache( "menu", "T7Hud_MP" );

REGISTER_SYSTEM( "globallogic", &__init__, "visionset_mgr" )

function __init__()
{	
	DEFAULT( level.vsmgr_prio_visionset_mpintro, MPINTRO_VISIONSET_PRIORITY );
	visionset_mgr::register_info( "visionset", MPINTRO_VISIONSET_ALIAS, VERSION_SHIP, level.vsmgr_prio_visionset_mpintro, MPINTRO_VISIONSET_STEPS, false, &visionset_mgr::ramp_in_out_thread, false );
	level.host_migration_activate_visionset_func = &mpintro_visionset_activate_func;
	level.host_migration_deactivate_visionset_func = &mpintro_visionset_deactivate_func;
}

function init()
{	
	level.splitscreen = isSplitScreen();
	level.xenon = (GetDvarString( "xenonGame") == "true");
	level.ps3 = (GetDvarString( "ps3Game") == "true");
	level.wiiu = (GetDvarString( "wiiuGame") == "true");
	level.orbis = (GetDvarString( "orbisGame") == "true");
	level.durango = (GetDvarString( "durangoGame") == "true");

	level.onlineGame = SessionModeIsOnlineGame();
	level.systemLink = SessionModeIsSystemlink(); 
	level.console = (level.xenon || level.ps3 || level.wiiu || level.orbis || level.durango);
	
	level.rankedMatch = ( GameModeIsUsingXP() );
	level.leagueMatch = false;
	level.customMatch = ( GameModeIsMode( GAMEMODE_PRIVATE_MATCH ) );
	level.arenaMatch = GameModeIsArena();
	
	level.mpCustomMatch = level.customMatch;
	
	level.contractsEnabled = !GetGametypeSetting( "disableContracts" );
		
	level.contractsEnabled = false;
	
	level.disableVehicleBurnDamage = true;
		
	level.script = toLower( GetDvarString( "mapname" ) );
	level.gametype = toLower( GetDvarString( "g_gametype" ) );

	level.teamBased = false;
	level.teamCount = GetGametypeSetting( "teamCount" );
	level.multiTeam = ( level.teamCount > 2 );
	
	// used to loop through all valid playing teams ( not spectator )
	// can also be used to check if a team is valid ( isdefined( level.teams[team] ) )
	// NOTE: added in the same order they are defined in code
	level.teams = [];
	level.teamIndex = [];
	
	teamCount = level.teamCount;
	
	if ( level.teamCount == 1 )
	{
		teamCount = 18;
		level.teams[ "free" ] = "free";
	}

	level.teams[ "allies" ] = "allies";
	level.teams[ "axis" ] = "axis";

	level.teamIndex[ "neutral" ] = 0; // Neutral team set to 0 so that it can be used by objectives
	level.teamIndex[ "allies" ] = 1;
	level.teamIndex[ "axis" ] = 2;
	
	for( teamIndex = 3; teamIndex <= teamCount; teamIndex++ )
	{
		level.teams[ "team" + teamIndex ] = "team" + teamIndex;
		level.teamIndex[ "team" + teamIndex ] = teamIndex;
	}
	
	level.overrideTeamScore = false;
	level.overridePlayerScore = false;
	level.displayHalftimeText = false;
	level.displayRoundEndText = true;
	
	level.clampScoreLimit = true;
	level.endGameOnScoreLimit = true;
	level.endGameOnTimeLimit = true;
	level.scoreRoundWinBased = false;
	level.resetPlayerScoreEveryRound = false;
	level.doEndgameScoreboard = true;
	
	level.gameForfeited= false;
	level.forceAutoAssign = false;
	
	level.halftimeType = "halftime";
	level.halftimeSubCaption = &"MP_SWITCHING_SIDES_CAPS";
	
	level.lastStatusTime = 0;
	level.wasWinning = [];
	
	level.lastSlowProcessFrame = 0;
	
	level.placement = [];
	foreach( team in level.teams )
	{
		level.placement[team] = [];
	}
	level.placement["all"] = [];
	
	level.postRoundTime = 7.0;//Kevin Sherwood changed to 9 to have enough time for music stingers
	
	level.inOvertime = false;
	
	level.defaultOffenseRadius = 560;
	level.defaultOffenseRadiusSQ = level.defaultOffenseRadius * level.defaultOffenseRadius;

	level.dropTeam = GetDvarint( "sv_maxclients" );
	
	level.inFinalKillcam = false;

	globallogic_ui::init();

	registerDvars();
	loadout::initPerkDvars();
	
	level.oldschool = GetGametypeSetting( "oldschoolMode" );

	precache_mp_leaderboards();
	
	if ( !isdefined( game["tiebreaker"] ) )
		game["tiebreaker"] = false;
	
	thread gameadvertisement::init();
	thread gamerep::init();
	thread teamops::init();
	
	level.disableChallenges = false;
	
	if ( level.leagueMatch || ( GetDvarInt( "scr_disableChallenges" ) > 0 ) )
	{
		level.disableChallenges = true;
	}
	
	level.disableStatTracking = ( GetDvarInt( "scr_disableStatTracking" ) > 0 );
	
	setup_callbacks();
	
	//handles both actor and player corpse cases
	clientfield::register( "playercorpse", "firefly_effect", VERSION_SHIP, 2, "int" );
	clientfield::register( "playercorpse", "annihilate_effect", VERSION_SHIP, 1, "int" );
	clientfield::register( "playercorpse", "pineapplegun_effect", VERSION_SHIP, 1, "int" );
	clientfield::register( "actor", "annihilate_effect", VERSION_SHIP, 1, "int" );
	clientfield::register( "actor", "pineapplegun_effect", VERSION_SHIP, 1, "int" );
	clientfield::register( "world", "game_ended", VERSION_SHIP, 1, "int" );
	clientfield::register( "world", "post_game", VERSION_SHIP, 1, "int" );
	clientfield::register( "world", "displayTop3Players", VERSION_SHIP, 1, "int" );
	clientfield::register( "world", "triggerScoreboardCamera", VERSION_SHIP, 1, "int" );
	clientfield::register( "clientuimodel", "hudItems.hideOutcomeUI", VERSION_SHIP, 1, "int" );
	clientfield::register( "clientuimodel", "hudItems.remoteKillstreakActivated", VERSION_SHIP, 1, "int" );
	clientfield::register( "world", "playTop0Gesture", VERSION_TU1, 3, "int" );
	clientfield::register( "world", "playTop1Gesture", VERSION_TU1, 3, "int" );
	clientfield::register( "world", "playTop2Gesture", VERSION_TU1, 3, "int" );
	clientfield::register( "clientuimodel", "hudItems.captureCrateState", VERSION_TU5, 2, "int" );
	clientfield::register( "clientuimodel", "hudItems.captureCrateTotalTime", VERSION_TU5, 13, "int" );

	level.playersDrivingVehiclesBecomeInvulnerable = false;
	
	// for use in shared scripts that do not know which version of figure_out_attacker to use
	level.figure_out_attacker = &globallogic_player::figure_out_attacker;
	level.figure_out_friendly_fire = &globallogic_player::figure_out_friendly_fire;
	level.get_base_weapon_param = &weapon_utils::getBaseWeaponParam; // used to figure out the weapon to as the parameter to GetBaseWeaponItemIndex()
}

function registerDvars()
{
	if ( GetDvarString( "ui_guncycle" ) == "" )
		SetDvar( "ui_guncycle", 0 );
		
	//makeDvarServerInfo( "ui_guncycle" );

	if ( GetDvarString( "ui_weapon_tiers" ) == "" )
		SetDvar( "ui_weapon_tiers", 0 );
	//makeDvarServerInfo( "ui_weapon_tiers" );

	SetDvar( "ui_text_endreason", "");
	//makeDvarServerInfo( "ui_text_endreason", "" );

	setMatchFlag( "bomb_timer", 0 );
	
	if ( GetDvarString( "scr_vehicle_damage_scalar" ) == "" )
		SetDvar( "scr_vehicle_damage_scalar", "1" );
		
	level.vehicleDamageScalar = GetDvarfloat( "scr_vehicle_damage_scalar");

	level.fire_audio_repeat_duration = GetDvarint( "fire_audio_repeat_duration" );
	level.fire_audio_random_max_duration = GetDvarint( "fire_audio_random_max_duration" );

	teamName = getcustomteamname( level.teamIndex[ "allies" ] );
	if( isdefined( teamName ) )
		SetDvar( "g_customTeamName_Allies", teamName );
	else
		SetDvar( "g_customTeamName_Allies", "" );

	teamName = getcustomteamname( level.teamIndex[ "axis" ] );
	if( isdefined( teamName ) )
		SetDvar( "g_customTeamName_Axis", teamName );
	else
		SetDvar( "g_customTeamName_Axis", "" );

}

function blank( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 )
{
}

function setup_callbacks()
{
	level.spawnPlayer = &globallogic_spawn::spawnPlayer;
	level.spawnPlayerPrediction = &globallogic_spawn::spawnPlayerPrediction;
	level.spawnClient = &globallogic_spawn::spawnClient;
	level.spawnSpectator = &globallogic_spawn::spawnSpectator;
	level.spawnIntermission = &globallogic_spawn::spawnIntermission;
	level.scoreOnGivePlayerScore = &globallogic_score::givePlayerScore;
	level.onPlayerScore = &globallogic_score::default_onPlayerScore;
	level.onTeamScore = &globallogic_score::default_onTeamScore;
	
	level.waveSpawnTimer =&waveSpawnTimer;
	level.spawnMessage =	&globallogic_spawn::default_spawnMessage;
	
	level.onSpawnPlayer =&blank;
	level.onSpawnPlayer = &spawning::onSpawnPlayer;
	level.onSpawnSpectator = &globallogic_defaults::default_onSpawnSpectator;
	level.onSpawnIntermission = &globallogic_defaults::default_onSpawnIntermission;
	level.onRespawnDelay =&blank;

	level.onForfeit = &globallogic_defaults::default_onForfeit;
	level.onTimeLimit = &globallogic_defaults::default_onTimeLimit;
	level.onScoreLimit = &globallogic_defaults::default_onScoreLimit;
	level.onRoundScoreLimit = &globallogic_defaults::default_onRoundScoreLimit;
	level.onAliveCountChange = &globallogic_defaults::default_onAliveCountChange;
	level.onDeadEvent = undefined;
	level.onOneLeftEvent = &globallogic_defaults::default_onOneLeftEvent;
	level.giveTeamScore = &globallogic_score::giveTeamScore;
	level.onLastTeamAliveEvent = &globallogic_defaults::default_onLastTeamAliveEvent;

	level.getTimePassed = &globallogic_utils::getTimePassed;
	level.getTimeLimit = &globallogic_defaults::default_getTimeLimit;
	level.getTeamKillPenalty = &globallogic_defaults::default_getTeamKillPenalty;
	level.getTeamKillScore = &globallogic_defaults::default_getTeamKillScore;

	level.isKillBoosting = &globallogic_score::default_isKillBoosting;

	level._setTeamScore = &globallogic_score::_setTeamScore;
	level._setPlayerScore = &globallogic_score::_setPlayerScore;

	level._getTeamScore = &globallogic_score::_getTeamScore;
	level._getPlayerScore = &globallogic_score::_getPlayerScore;
	
	level.resetPlayerScorestreaks = &globallogic_score::resetPlayerScoreChainAndMomentum;
	
	level.onPrecacheGametype =&blank;
	level.onStartGameType =&blank;
	level.onPlayerConnect =&blank;
	level.onPlayerDisconnect =&blank;
	level.onPlayerDamage =&blank;
	level.onPlayerKilled =&blank;
	level.onPlayerKilledExtraUnthreadedCBs = []; ///< Array of other CB function pointers

	level.onTeamOutcomeNotify = &hud_message::teamOutcomeNotify;
	level.onOutcomeNotify = &hud_message::outcomeNotify;
	level.setMatchScoreHUDElemForTeam = &hud_message::setMatchScoreHUDElemForTeam;
	level.onEndGame =&blank;
	level.onRoundEndGame = &globallogic_defaults::default_onRoundEndGame;
	level.determineWinner = &globallogic_defaults::default_determineWinner;
	level.onMedalAwarded =&blank;
	level.dogManagerOnGetDogs = &dogs::dog_manager_get_dogs;
	
	callback::on_joined_team( &globallogic_player::on_joined_team );

	globallogic_ui::SetupCallbacks();
}

function precache_mp_friend_leaderboards()
{

	hardcoreMode = GetGametypeSetting( "hardcoreMode" ); 
	if( !isdefined( hardcoreMode ) )
	{
		hardcoreMode = false;
	}

	arenaMode = IsArenaMode();

	/////////////////////////////////////////////////////////

	postfix = "";			// normal

	if( hardcoreMode )	    // hardcore
	{
		postfix = "_HC";
	}
	else if( arenaMode )	// arena
	{
		postfix = "_ARENA";
	}

	friendLeaderboardA = "LB_MP_FRIEND_A" + postfix;	
	friendLeaderboardB = " LB_MP_FRIEND_B" + postfix;

	precacheLeaderboards( friendLeaderboardA + friendLeaderboardB );	
}

//Note not all game modes have anticheat so these may not always be found
function precache_mp_anticheat_leaderboards()
{

	hardcoreMode = GetGametypeSetting( "hardcoreMode" ); 
	if( !isdefined( hardcoreMode ) )
	{
		hardcoreMode = false;
	}

	arenaMode = IsArenaMode();

	/////////////////////////////////////////////////////////

	postfix = "";			// normal

	if( hardcoreMode )	    // hardcore
	{
		postfix = "_HC";
	}
	else if( arenaMode )	// arena
	{
		postfix = "_ARENA";
	}

	anticheatLeaderboard = "LB_MP_ANTICHEAT_" + level.gametype + postfix;	

	if( level.gametype != "fr" )
	{
		anticheatLeaderboard = anticheatLeaderboard + " LB_MP_ANTICHEAT_GLOBAL";
	}

	precacheLeaderboards( anticheatLeaderboard );	
}

function precache_mp_public_leaderboards()
{
	mapname = GetDvarString( "mapname" );

	hardcoreMode = GetGametypeSetting( "hardcoreMode" ); 
	if( !isdefined( hardcoreMode ) )
	{
		hardcoreMode = false;
	}

	arenaMode = IsArenaMode();
	freerunMode = ( level.gametype == "fr" );

	/////////////////////////////////////////////////////////

	postfix = "";			// normal

	if( freerunMode )		// freerun
	{
		// strip the MP_ from the map name
		frLeaderboard = " LB_MP_GM_FR_" + getsubstr( mapname, 3, mapname.size ); 
		
		precacheLeaderboards( frLeaderboard );
		return;
	}
	else if( hardcoreMode )	// hardcore
	{
		postfix = "_HC";
	}
	else if( arenaMode )	// arena
	{
		postfix = "_ARENA";
	}

	careerLeaderboard = " LB_MP_GB_SCORE" + postfix;
	prestigeLB = " LB_MP_GB_XPPRESTIGE";
	gamemodeLeaderboard = "LB_MP_GM_" + level.gametype + postfix;

	arenaLeaderboard = "";
	if( GameModeIsMode( GAMEMODE_LEAGUE_MATCH ) )
	{
		arenaSlot = ArenaGetSlot();
		arenaLeaderboard = " LB_MP_ARENA_MASTERS_0" + arenaSlot;
	}	
	
	precacheLeaderboards( gamemodeLeaderboard + careerLeaderboard + prestigeLB + arenaLeaderboard );
}

function precache_mp_custom_leaderboards()
{
	customLeaderboards = "LB_MP_CG_" + level.gametype;
	
	precacheLeaderboards( "LB_MP_CG_GENERAL " + customLeaderboards );
	
	return;
}

function precache_mp_leaderboards()
{
	if( bot::is_bot_ranked_match() ) 
	{
		return;
	}

	if( level.rankedMatch || level.gametype == "fr" )
	{
		precache_mp_public_leaderboards();
		precache_mp_friend_leaderboards();
		precache_mp_anticheat_leaderboards();
	}
	else
	{
		precache_mp_custom_leaderboards();
	}
}

function setvisiblescoreboardcolumns( col1, col2, col3, col4, col5 )
{
	if ( !level.rankedMatch )
	{
		setscoreboardcolumns( col1, col2, col3, col4, col5, "sbtimeplayed", "shotshit", "shotsmissed", "victory" );
	}
	else
	{
		setscoreboardcolumns( col1, col2, col3, col4, col5 );
	}
}

function compareTeamByGameStat( gameStat, teamA, teamB, previous_winner_score )
{
	winner = undefined;
	
	if ( teamA == "tie" )
	{
		winner = "tie";
		
		if ( previous_winner_score < game[gameStat][teamB] )
			winner = teamB;
	}
	else if ( game[gameStat][teamA] == game[gameStat][teamB] )
		winner = "tie";
	else if ( game[gameStat][teamB] > game[gameStat][teamA] )
		winner = teamB;
	else
		winner = teamA;
	
	return winner;
}

function determineTeamWinnerByGameStat( gameStat )
{
	teamKeys = GetArrayKeys(level.teams);
	winner = teamKeys[0];
	previous_winner_score = game[gameStat][winner];
	
	for ( teamIndex = 1; teamIndex < teamKeys.size; teamIndex++ )
	{
		winner = compareTeamByGameStat( gameStat, winner, teamKeys[teamIndex], previous_winner_score);
		
		if ( winner != "tie" )
		{
			previous_winner_score = game[gameStat][winner];
		}	
	}
	
	return winner;
}

function compareTeamByTeamScore( teamA, teamB, previous_winner_score )
{
	winner = undefined;
  teamBScore = [[level._getTeamScore]]( teamB );

	if ( teamA == "tie" )
	{
		winner = "tie";
		
		if ( previous_winner_score < teamBScore )
			winner = teamB;
			
		return winner;
	}
	
  teamAScore = [[level._getTeamScore]]( teamA );

	if ( teamBScore == teamAScore )
		winner = "tie";
	else if ( teamBScore > teamAScore )
		winner = teamB;
	else
		winner = teamA;
		
	return winner;
}

function determineTeamWinnerByTeamScore( )
{
	teamKeys = GetArrayKeys(level.teams);
	winner = teamKeys[0];
	previous_winner_score = [[level._getTeamScore]]( winner );
	
	for ( teamIndex = 1; teamIndex < teamKeys.size; teamIndex++ )
	{
		winner = compareTeamByTeamScore( winner, teamKeys[teamIndex], previous_winner_score);
		
		if ( winner != "tie" )
		{
			previous_winner_score = [[level._getTeamScore]]( winner );
		}	
	}
	
	return winner;
}

function forceEnd(hostsucks)
{
	if (!isdefined(hostsucks))
		hostsucks = false;

	if ( level.hostForcedEnd || level.forcedEnd )
		return;

	winner = undefined;
	
	if ( level.teamBased )
	{
		winner = determineTeamWinnerByGameStat("teamScores");
		globallogic_utils::logTeamWinString( "host ended game", winner );
	}
	else
	{
		winner = globallogic_score::getHighestScoringPlayer();
		/#
		if ( isdefined( winner ) )
			print( "host ended game, win: " + winner.name );
		else
			print( "host ended game, tie" );
		#/
	}
	
	level.forcedEnd = true;
	level.hostForcedEnd = true;
	
	if (hostsucks)
	{
		endString = &"MP_HOST_SUCKS";
	}
	else
	{
		if ( level.splitscreen )
			endString = &"MP_ENDED_GAME";
		else
			endString = &"MP_HOST_ENDED_GAME";
	}
	
	setMatchFlag( "disableIngameMenu", 1 );
	//makeDvarServerInfo( "ui_text_endreason", endString );
	SetDvar( "ui_text_endreason", endString );
	thread endGame( winner, endString );
}

function killserverPc()
{
	if ( level.hostForcedEnd || level.forcedEnd )
		return;
		
	winner = undefined;
	
	if ( level.teamBased )
	{
		winner = determineTeamWinnerByGameStat("teamScores");
		globallogic_utils::logTeamWinString( "host ended game", winner );
	}
	else
	{
		winner = globallogic_score::getHighestScoringPlayer();
		/#
		if ( isdefined( winner ) )
			print( "host ended game, win: " + winner.name );
		else
			print( "host ended game, tie" );
		#/
	}
	
	level.forcedEnd = true;
	level.hostForcedEnd = true;
	
	level.killserver = true;
	
	endString = &"MP_HOST_ENDED_GAME";
	
	
/#
		PrintLn("kill server; ending game\n");
#/

	thread endGame( winner, endString );
}

function atLeastTwoTeams()
{
	valid_count = 0;
	
	foreach ( team in level.teams )
	{ 
		if ( level.playerCount[team] != 0 )
		{
			valid_count++;
		}
	}
	
	if ( valid_count < 2 )
	{
		return false;
	}
	
	return true;
}

function checkIfTeamForfeits( team )
{
	if ( !game["everExisted"][team] )
		return false;
		
	if ( level.playerCount[team] < 1 && util::totalPlayerCount() > 0 )
	{
		return true;
	}
	
	return false;
}

function checkForForfeit()
{
	forfeit_count = 0;
	valid_team = undefined;
	
	foreach( team in level.teams )
	{
		if ( checkIfTeamForfeits( team ) )
		{
			forfeit_count++;
			
			if ( !level.multiTeam )
			{
				thread [[level.onForfeit]]( team );
				return true;
			}
		}
		else
		{
			valid_team = team;
		}
	}
	
	if ( level.multiTeam && ( forfeit_count == ( level.teams.size - 1 ) ) )
	{
			thread [[level.onForfeit]]( valid_team );
			return true;		
	}
	
	return false;
}

function doSpawnQueueUpdates()
{
	foreach( team in level.teams )
	{
		if ( level.spawnQueueModified[team] ) 
		{
			[[level.onAliveCountChange]]( team );
		}
	}
}

function isTeamAllDead( team )
{
	return  (level.everExisted[team] && !level.aliveCount[team] && !level.playerLives[team] ); 
}

function areAllTeamsDead( )
{
	foreach( team in level.teams )
	{
		// if team was alive and now they are not
		if ( !isTeamAllDead( team ) )
		{	
			return false;
		}
	}
	
	return true;
}

function getLastTeamAlive()
{
	count = 0;
	everExistedCount = 0;
	aliveTeam = undefined;
	foreach( team in level.teams )
	{
		// if team was alive and now they are not
		if ( level.everExisted[team] )
		{
			if ( !isTeamAllDead( team ) )
			{
				aliveTeam = team;
				count++;
			}
			everExistedCount++;
		}
	}
	
	if ( ( everExistedCount > 1 ) && ( count == 1 ) )
	{
		return aliveTeam;
	}
	
	return undefined;
}

function doDeadEventUpdates()
{
	if ( level.teamBased )
	{
		// if all teams were alive and now they are all dead in the same instance
		if ( areAllTeamsDead( ) )
		{
			[[level.onDeadEvent]]( "all" );
			return true;
		}

		if ( !isdefined( level.onDeadEvent ) )
		{
			lastTeamAlive = getLastTeamAlive();
			if ( isdefined( lastTeamAlive ) )
			{
				[[level.onLastTeamAliveEvent]]( lastTeamAlive );
				return true;
			}
		}
		else
		{
			foreach( team in level.teams )
			{
				// if team was alive and now they are not
				if ( isTeamAllDead( team ) )
				{	
					[[level.onDeadEvent]]( team );
					return true;
				}
			}
		}
	}
	else
	{
		// everyone is dead
		if ( (totalAliveCount() == 0) && (totalPlayerLives() == 0) && level.maxPlayerCount > 1 )
		{
			[[level.onDeadEvent]]( "all" );
			return true;;
		}
	}
	
	return false;
}

function isOnlyOneLeftAliveOnTeam( team )
{
	return  (level.lastAliveCount[team] > 1 && level.aliveCount[team] == 1 && level.playerLives[team] == 1 ); 
}


function doOneLeftEventUpdates()
{
	if ( level.teamBased )
	{
		foreach( team in level.teams )
		{
			// one "team" left
			if ( isOnlyOneLeftAliveOnTeam( team ) )
			{	
				[[level.onOneLeftEvent]]( team );
				return true;;
			}
		}
	}
	else
	{
		// last man standing
		if ( (totalAliveCount() == 1) && (totalPlayerLives() == 1) && level.maxPlayerCount > 1 )
		{
			[[level.onOneLeftEvent]]( "all" );
			return true;;
		}
	}
	
	return false;
}

function updateGameEvents()
{
	if ( ( level.rankedMatch || level.wagerMatch || level.leagueMatch ) && !level.inGracePeriod )
	{
		if ( level.teamBased )
		{
			if (!level.gameForfeited )
			{
				if( game["state"] == "playing" && checkForForfeit() )
				{
					return;
				}
			}
			else // level.gameForfeited==true
			{
				if ( atLeastTwoTeams() )
				{
					level.gameForfeited = false;
					level notify( "abort forfeit" );
				}
			}
		}
		else
		{
			if (!level.gameForfeited)
			{
				if ( util::totalPlayerCount() == 1 && level.maxPlayerCount > 1 )
				{
					thread [[level.onForfeit]]();
					return;
				}
			}
			else // level.gameForfeited==true
			{
				if ( util::totalPlayerCount() > 1 )
				{
					level.gameForfeited = false;
					level notify( "abort forfeit" );
				}
			}
		}
	}
		
	if ( !level.playerQueuedRespawn && !level.numLives && !level.inOverTime )
		return;
		
	if ( level.inGracePeriod )
		return;

	if ( level.playerQueuedRespawn )
	{
		doSpawnQueueUpdates();
	}
	
	if ( doDeadEventUpdates() )
		return;
		
	if ( doOneLeftEventUpdates() )
		return;
}

function mpintro_visionset_ramp_hold_func()
{
	level endon( MPINTRO_VISIONSET_RAMP_NOTIFY );

	while ( true )
	{
		for ( player_index = 0; player_index < level.players.size; player_index++ )
		{
			self visionset_mgr::set_state_active( level.players[player_index], 1 );
		}

		WAIT_SERVER_FRAME;
	}
}

function mpintro_visionset_activate_func()
{
	visionset_mgr::activate( "visionset", MPINTRO_VISIONSET_ALIAS, undefined, MPINTRO_VISIONSET_RAMP_IN, &mpintro_visionset_ramp_hold_func, MPINTRO_VISIONSET_RAMP_OUT );
}

function mpintro_visionset_deactivate_func()
{
	level notify( MPINTRO_VISIONSET_RAMP_NOTIFY );
}

function matchStartTimer()
{
	mpintro_visionset_activate_func();
	level thread sndSetMatchSnapshot( 1 );
	waitForPlayers();
	
	countTime = int( level.prematchPeriod );
	
	if ( countTime >= 2 )
	{
		while ( countTime > 0 && !level.gameEnded )
		{
			LUINotifyEvent( &"create_prematch_timer", 1, GetTime() + ( countTime * 1000 ) );
			
			if ( countTime == 2 )
			{
				mpintro_visionset_deactivate_func();
			}
			
			if( countTime == 3 )
			{
				level thread sndSetMatchSnapshot( 0 );
				foreach ( player in level.players )
				{
					if ( player.hasSpawned || player.pers["team"] == "spectator" )
					{
						player globallogic_audio::set_music_on_player( "spawnPreRise" );
					}
				}
			}
			
			countTime--;

			foreach ( player in level.players )
			{
				player PlayLocalSound( "uin_start_count_down" );
			}
			
			wait ( 1.0 );
		}
		
		LUINotifyEvent( &"prematch_timer_ended", 0 );
	}
	else
	{
		mpintro_visionset_deactivate_func();
	}	
}

function notifyEndOfGameplay()
{
	level waittill( "game_ended" );
	level clientfield::set("gameplay_started", 0);
}

function matchStartTimerSkip()
{
	visionSetNaked( GetDvarString( "mapname" ), 0 );
}

function sndSetMatchSnapshot( num )
{
	wait(.05);
	level clientfield::set( "sndMatchSnapshot", num );
}

function notifyTeamWaveSpawn( team, time )
{
	if ( time - level.lastWave[team] > (level.waveDelay[team] * 1000) )
	{
		level notify ( "wave_respawn_" + team );
		level.lastWave[team] = time;
		level.wavePlayerSpawnIndex[team] = 0;
	}
}

function waveSpawnTimer()
{
	level endon( "game_ended" );

	while ( game["state"] == "playing" )
	{
		time = getTime();
		
		foreach( team in level.teams )
		{
			notifyTeamWaveSpawn( team, time );
		}
		WAIT_SERVER_FRAME;
	}
}


function hostIdledOut()
{
	hostPlayer = util::getHostPlayer();
	
	// host never spawned
	if ( isdefined( hostPlayer ) && !hostPlayer.hasSpawned && !isdefined( hostPlayer.selectedClass ) )
		return true;

	return false;
}

function IncrementMatchCompletionStat( gameMode, playedOrHosted, stat )
{
	self AddDStat( "gameHistory", gameMode, "modeHistory", playedOrHosted, stat, 1 );
}

function SetMatchCompletionStat( gameMode, playedOrHosted, stat )
{
	self SetDStat( "gameHistory", gameMode, "modeHistory", playedOrHosted, stat, 1 );
}

function getTeamScoreRatio()
{
	playerTeam = self.pers["team"];
	
	score = getTeamScore( playerTeam );
	
	otherTeamScore = 0;
	
	foreach ( team in level.teams )
	{
		if ( team == playerTeam )
			continue;
			
		otherTeamScore += getTeamScore( team );
	}
	
	if ( level.teams.size > 1 )
	{
		otherTeamScore = otherTeamScore / ( level.teams.size - 1 );
	}
	
	if ( otherTeamScore != 0 )
		return ( float( score ) / float( otherTeamScore ) );
		
	// should we just return the flat score here or some other indication of win?
	return score;
}

function getHighestScore()
{
	highestScore = -999999999;
	for ( index = 0; index < level.players.size; index++ )
	{
		player = level.players[index];
		
		if ( player.score > highestScore )
			highestScore = player.score;
	}
	
	return highestScore;
}

function getNextHighestScore( score )
{
	highestScore = -999999999;
	for ( index = 0; index < level.players.size; index++ )
	{
		player = level.players[index];
		
		if ( player.score >= score )
			continue;
			
		if ( player.score > highestScore )
			highestScore = player.score;
	}
	
	return highestScore;
}

function RecordPlayStyleInformation()
{
	// Record information for determining play styles
	avgKillDistance = 0;
	percentTimeMoving = 0;
	avgSpeedOfPlayerWhenMoving = 0;
	totalKillDistances = float( self.pers["kill_distances"] );
	numKillDistanceEntries = float( self.pers["num_kill_distance_entries"] );
	timePlayedMoving = float( self.pers["time_played_moving"] );
	timePlayedAlive = float( self.pers["time_played_alive"] );
	totalSpeedsWhenMoving = float( self.pers["total_speeds_when_moving"] );
	numSpeedsWhenMovingEntries = float( self.pers["num_speeds_when_moving_entries"] );
	totalDistanceTravelled = float( self.pers["total_distance_travelled"] );
	movementUpdateCount = float(self.pers["movement_Update_Count"]);
	if ( numKillDistanceEntries > 0 ) 
		avgKillDistance = totalKillDistances / numKillDistanceEntries;

	movementUpdateDenom = int(movementUpdateCount/5);
	if ( movementUpdateDenom > 0 )
		percentTimeMoving = ( numSpeedsWhenMovingEntries / movementUpdateDenom ) * 100.0;
	
	if ( numSpeedsWhenMovingEntries > 0 )
		avgSpeedOfPlayerWhenMoving = totalSpeedsWhenMoving / numSpeedsWhenMovingEntries;

	recordPlayerStats( self, "totalKillDistances", totalKillDistances );
	recordPlayerStats( self, "numKillDistanceEntries", numKillDistanceEntries );
	recordPlayerStats( self, "timePlayedMoving", timePlayedMoving );
	recordPlayerStats( self, "timePlayedAlive", timePlayedAlive );
	recordPlayerStats( self, "totalSpeedsWhenMoving", totalSpeedsWhenMoving );
	recordPlayerStats( self, "numSpeedsWhenMovingEntries", numSpeedsWhenMovingEntries );
	recordPlayerStats( self, "averageKillDistance", avgKillDistance );
	recordPlayerStats( self, "percentageOfTimeMoving", percentTimeMoving );
	recordPlayerStats( self, "averageSpeedDuringMatch", avgSpeedOfPlayerWhenMoving );
	recordPlayerStats( self, "totalDistanceTravelled", totalDistanceTravelled );
}

function getPlayerByName( name )
{
	for ( index = 0; index < level.players.size; index++ )
	{
		player = level.players[index];

		if ( player util::is_bot() )
		{
			continue;
		}

		if ( player.name == name )
		{
			return player;
		}
	}
}

function sendAfterActionReport()
{
	//Send After Action Report information to the client
	for ( index = 0; index < level.players.size; index++ )
	{
		player = level.players[index];

		if ( player util::is_bot() )
		{
			continue;
		}
		
		//Find the Nemesis for each player
		nemesis = player.pers["nemesis_name"];

		if( !isdefined( player.pers["killed_players"][nemesis] ) )
			player.pers["killed_players"][nemesis] = 0;
		if( !isdefined( player.pers["killed_by"][nemesis] ) )
			player.pers["killed_by"][nemesis] = 0;

		//Get the kill to death spread of the player
		spread = player.kills - player.deaths;
		
		if( player.pers["cur_kill_streak"] > player.pers["best_kill_streak"] )
			player.pers["best_kill_streak"] = player.pers["cur_kill_streak"];	
	
		if ( ( level.rankedMatch || level.leagueMatch ) )	
			player persistence::set_after_action_report_stat( "privateMatch", 0 );
		else
			player persistence::set_after_action_report_stat( "privateMatch", 1 );

		player setNemesisXuid( player.pers["nemesis_xuid"] );
		player persistence::set_after_action_report_stat( "nemesisName", nemesis );
		player persistence::set_after_action_report_stat( "nemesisRank", player.pers["nemesis_rank"] );
		player persistence::set_after_action_report_stat( "nemesisRankIcon", player.pers["nemesis_rankIcon"] );
		player persistence::set_after_action_report_stat( "nemesisKills", player.pers["killed_players"][nemesis] );
		player persistence::set_after_action_report_stat( "nemesisKilledBy", player.pers["killed_by"][nemesis] );
		nemesisPlayerEnt = getPlayerByName( nemesis );

		if ( isDefined( nemesisPlayerEnt ) )
		{
			player persistence::set_after_action_report_stat( "nemesisHeroIndex", nemesisPlayerEnt GetCharacterBodyType() );
		}

		player persistence::set_after_action_report_stat( "bestKillstreak", player.pers["best_kill_streak"] );
		player persistence::set_after_action_report_stat( "kills", player.kills );
		player persistence::set_after_action_report_stat( "deaths", player.deaths );
		player persistence::set_after_action_report_stat( "headshots", player.headshots );
		player persistence::set_after_action_report_stat( "score", player.score );
		
		player persistence::set_after_action_report_stat( "xpEarned", int( player.pers["summary"]["xp"] ) );
		player persistence::set_after_action_report_stat( "cpEarned", int( player.pers["summary"]["codpoints"] ) );
		player persistence::set_after_action_report_stat( "miscBonus", int( player.pers["summary"]["challenge"] + player.pers["summary"]["misc"] ) );
		player persistence::set_after_action_report_stat( "matchBonus", int( player.pers["summary"]["match"] ) );
		player persistence::set_after_action_report_stat( "demoFileID", getDemoFileID() );
		player persistence::set_after_action_report_stat( "leagueTeamID", player getLeagueTeamID() );
	
		player persistence::set_after_action_report_stat( "team", teams::getTeamIndex( player.team ) );
		
		alliesScore = globallogic_score::_getteamscore( "allies" );
		if( isdefined( alliesScore ) )
		{
			player persistence::set_after_action_report_stat( "alliesScore", alliesScore );	
		}
		
		axisScore = globallogic_score::_getteamscore( "axis" );
		if( isdefined( axisScore ) )
		{
			player persistence::set_after_action_report_stat( "axisScore", axisScore );	
		}
		
		player persistence::set_after_action_report_stat( "gameTypeRef", level.gametype );
		player persistence::set_after_action_report_stat( "mapname", GetDvarString( "ui_mapname" ) );
	}
}

function UpdateAndFinalizeMatchRecord()
{
	for ( index = 0; index < level.players.size; index++ )
	{
		player = level.players[index];

		player  globallogic_player::record_special_move_data_for_life( undefined );

		if ( player util::is_bot() )
		{
			continue;
		}
		
		player globallogic_player::record_global_mp_stats_for_player_at_match_end();
		
		//Find the Nemesis for each player
		nemesis = player.pers["nemesis_name"];

		if( !isdefined( player.pers["killed_players"][nemesis] ) )
			player.pers["killed_players"][nemesis] = 0;
		if( !isdefined( player.pers["killed_by"][nemesis] ) )
			player.pers["killed_by"][nemesis] = 0;

		//Get the kill to death spread of the player
		spread = player.kills - player.deaths;
		
		if( player.pers["cur_kill_streak"] > player.pers["best_kill_streak"] )
			player.pers["best_kill_streak"] = player.pers["cur_kill_streak"];	
	
		if ( level.onlineGame )
		{
			teamScoreRatio = player getTeamScoreRatio();
			scoreboardPosition = getPlacementForPlayer( player );
			if ( scoreboardPosition < 0 )
			 scoreboardPosition = level.players.size;
			 
			player GameHistoryFinishMatch( MATCH_FINISHED, player.kills, player.deaths, player.score, scoreboardPosition, teamScoreRatio );
			
			placement = level.placement["all"];			
			for ( otherPlayerIndex = 0; otherPlayerIndex < placement.size; otherPlayerIndex++ )
			{
				if ( level.placement["all"][otherPlayerIndex] == player )
				{
					recordPlayerStats( player, "position", otherPlayerIndex );				
				}				
			}
			
			if ( isdefined( player.pers["matchesPlayedStatsTracked"] ) )
			{
				gameMode = util::GetCurrentGameMode();
				player IncrementMatchCompletionStat( gameMode, "played", "completed" );
					
				if ( isdefined( player.pers["matchesHostedStatsTracked"] ) )
				{
					player IncrementMatchCompletionStat( gameMode, "hosted", "completed" );
					player.pers["matchesHostedStatsTracked"] = undefined;
				}
				
				player.pers["matchesPlayedStatsTracked"] = undefined;
			}
	
			recordPlayerStats( player, "highestKillStreak", player.pers["best_kill_streak"] );
			recordPlayerStats( player, "numUavCalled", player killstreaks::get_killstreak_usage("uav_used") );
			recordPlayerStats( player, "numDogsCalleD", player killstreaks::get_killstreak_usage("dogs_used") );
			recordPlayerStats( player, "numDogsKills", player.pers["dog_kills"] );

			player RecordPlayStyleInformation();

			recordPlayerMatchEnd( player );
			RecordPlayerStats(player, "presentAtEnd", 1 );			
		}
	}

	finalizeMatchRecord();
}

function gameHistoryPlayerKicked()
{
	teamScoreRatio = self getTeamScoreRatio();
	scoreboardPosition = getPlacementForPlayer( self );
	if ( scoreboardPosition < 0 )
		 scoreboardPosition = level.players.size;

	assert( isdefined( self.kills ) );
	assert( isdefined( self.deaths ) );
	assert( isdefined( self.score ) );
	assert( isdefined( scoreboardPosition ) );
	assert( isdefined( teamScoreRatio ) );

	self GameHistoryFinishMatch( MATCH_KICKED, self.kills, self.deaths, self.score, scoreboardPosition, teamScoreRatio );

	if ( isdefined( self.pers["matchesPlayedStatsTracked"] ) )
	{
		gameMode = util::GetCurrentGameMode();
		self IncrementMatchCompletionStat( gameMode, "played", "kicked" );
				
		self.pers["matchesPlayedStatsTracked"] = undefined;
	}

	UploadStats( self );
	
	// wait until the player recieves the new stats
  wait(1);
}

function gameHistoryPlayerQuit()
{
	teamScoreRatio = self getTeamScoreRatio();
	scoreboardPosition = getPlacementForPlayer( self );
	if ( scoreboardPosition < 0 )
		 scoreboardPosition = level.players.size;

	self GameHistoryFinishMatch( MATCH_QUIT, self.kills, self.deaths, self.score, scoreboardPosition, teamScoreRatio );

 	if ( isdefined( self.pers["matchesPlayedStatsTracked"] ) )
	{
		gameMode = util::GetCurrentGameMode();
		self IncrementMatchCompletionStat( gameMode, "played", "quit" );
			
		if ( isdefined( self.pers["matchesHostedStatsTracked"] ) )
		{
			self IncrementMatchCompletionStat( gameMode, "hosted", "quit" );
			self.pers["matchesHostedStatsTracked"] = undefined;
		}
		
		self.pers["matchesPlayedStatsTracked"] = undefined;
	}
	
	UploadStats( self );
 	
	if ( !self IsHost() )
	{
		// wait until the player recieves the new stats
		wait(1);
	}
}

function displayRoundEnd( winner, endReasonText )
{
	if ( level.displayRoundEndText )
	{
		if ( level.teamBased )
		{
			if ( winner == "tie" )
			{
				demo::gameResultBookmark( "round_result", level.teamIndex[ "neutral" ], level.teamIndex[ "neutral" ] );
			}
			else
			{
				demo::gameResultBookmark( "round_result", level.teamIndex[ winner ], level.teamIndex[ "neutral" ] );
			}
		}

		setmatchflag( "cg_drawSpectatorMessages", 0 );
		players = level.players;
		for ( index = 0; index < players.size; index++ )
		{
			player = players[index];
			
			if( !util::wasLastRound() )
			{
				player notify( "round_ended" );
			}
			if ( !isdefined( player.pers["team"] ) )
			{
				player [[level.spawnIntermission]]( true );
				continue;
			}
			
			if ( level.teamBased )
			{
				player thread [[level.onTeamOutcomeNotify]]( winner, "roundend", endReasonText );
				player globallogic_audio::set_music_on_player( "roundEnd" );		
			}
			else
			{
				player thread [[level.onOutcomeNotify]]( winner, true, endReasonText );
				player globallogic_audio::set_music_on_player( "roundEnd" );
			}
	
     	player setClientUIVisibilityFlag( "hud_visible", 0 );
			player setClientUIVisibilityFlag( "g_compassShowEnemies", 0 );
		}
	}

	if ( util::wasLastRound() )
	{
		roundEndWait( level.roundEndDelay, false );
	}
	else
	{
		thread globallogic_audio::announce_round_winner( winner, level.roundEndDelay / 4 );
		roundEndWait( level.roundEndDelay, true );
	}
}

function displayRoundSwitch( winner, endReasonText )
{
	switchType = level.halftimeType;
	level thread globallogic_audio::set_music_global( "roundSwitch" );
	if ( switchType == "halftime" )
	{
		if ( isdefined( level.nextRoundIsOvertime ) && level.nextRoundIsOvertime )
		{
			switchType = "overtime";
		}
		else
		{
			if ( level.roundLimit )
			{
				if ( (game["roundsplayed"] * 2) == level.roundLimit )
					switchType = "halftime";
				else
					switchType = "intermission";
			}
			else if ( level.scoreLimit )
			{
				if ( isdefined( level.roundswitch ) && level.roundSwitch == 1 )
				{
					switchtype = "intermission";
				}
				else if ( game["roundsplayed"] == (level.scoreLimit - 1) )
				{
					switchType = "halftime";
				}
				else
				{
					switchType = "intermission";
				}
			}
			else
			{
				switchType = "intermission";
			}
		}
	
	}
	
	leaderdialog = globallogic_audio::get_round_switch_dialog( switchType );
	
	SetMatchTalkFlag( "EveryoneHearsEveryone", 1 );

	players = level.players;
	for ( index = 0; index < players.size; index++ )
	{
		player = players[index];
		
		if ( !isdefined( player.pers["team"] ) )
		{
			player [[level.spawnIntermission]]( true );
			continue;
		}
		
		player globallogic_audio::leader_dialog_on_player( leaderdialog );
		
		player thread [[level.onTeamOutcomeNotify]]( winner, switchType, level.halftimeSubCaption );
        player setClientUIVisibilityFlag( "hud_visible", 0 );
	}

	roundEndWait( level.halftimeRoundEndDelay, false );
}

function displayGameEnd( winner, endReasonText )
{
	SetMatchTalkFlag( "EveryoneHearsEveryone", 1 );
	setmatchflag( "cg_drawSpectatorMessages", 0 );
	
	level thread sndSetMatchSnapshot( 2 );
	
	util::setClientSysState("levelNotify", "streamFKsl" );

	if ( level.teambased )
	{
		if ( winner == "tie" )
		{
			demo::gameResultBookmark( "game_result", level.teamIndex[ "neutral" ], level.teamIndex[ "neutral" ] );
		}
		else
		{ 
			demo::gameResultBookmark( "game_result", level.teamIndex[ winner ], level.teamIndex[ "neutral" ] );
		}
	}
	// catching gametype, since DM forceEnd sends winner as player entity, instead of string
	players = level.players;
	for ( index = 0; index < players.size; index++ )
	{
		player = players[index];
	
		if ( !isdefined( player.pers["team"] ) )
		{
			player [[level.spawnIntermission]]( true );
			continue;
		}
		
		if ( level.teamBased )
		{
			player thread [[level.onTeamOutcomeNotify]]( winner, "gameend", endReasonText );
		}
		else
		{
			if ( !IS_TRUE( level.freerun ) )
			{
				player thread [[level.onOutcomeNotify]]( winner, false, endReasonText );
			}
			
			if( IS_TRUE( level.freerun ) )
			{
				player globallogic_audio::set_music_on_player( "mp_freerun_gameover" );
			}
			else if ( isdefined( winner ) && player == winner )
			{
				player globallogic_audio::set_music_on_player( "matchWin" );
			}
			else if ( !level.splitScreen )
			{
				player globallogic_audio::set_music_on_player( "matchLose" );
			}
		}
		
    	player setClientUIVisibilityFlag( "hud_visible", 0 );
		player setClientUIVisibilityFlag( "g_compassShowEnemies", 0 );
	}
	
	thread globallogic_audio::announce_game_winner( winner );
	
	if ( level.teamBased )
	{		
		players = level.players;
		for ( index = 0; index < players.size; index++ )
		{
			player = players[index];
			team = player.pers["team"];
			
			if ( level.splitscreen )
			{
				if( IS_TRUE( level.freerun ) )
				{
					player globallogic_audio::set_music_on_player( "mp_freerun_gameover" );
				}
				else if ( winner == "tie" )
				{
					player globallogic_audio::set_music_on_player( "matchDraw" );
				}						
				else if ( winner == team )
				{	
					player globallogic_audio::set_music_on_player( "matchWin" );			
				}
				else
				{
					player globallogic_audio::set_music_on_player( "matchLose" );	
				}	
			}
			else
			{
				if( IS_TRUE( level.freerun ) )
				{
					player globallogic_audio::set_music_on_player( "mp_freerun_gameover" );
				}
					else if ( winner == "tie" )
				{
					player globallogic_audio::set_music_on_player( "matchDraw" );
				}						
					else if ( winner == team )
				{	
					player globallogic_audio::set_music_on_player( "matchWin" );			
				}
				else
				{
					player globallogic_audio::set_music_on_player( "matchLose" );	
				}	
			}
		}
	}
	
	roundEndWait( level.postRoundTime, true );
}

function recordEndGameComScoreEvent( result )
{
	players = level.players;
	for ( index = 0; index < players.size; index++ )
	{
		globallogic_player::recordEndGameComScoreEventForPlayer( players[index], result );
	}
}

function getEndReasonText()
{
	if ( isdefined( level.endReasonText ) )
	{
		return level.endReasonText;
	}
	
	if ( util::hitRoundLimit() || util::hitRoundWinLimit() )
		return  game["strings"]["round_limit_reached"];
	else if ( util::hitScoreLimit() )
		return  game["strings"]["score_limit_reached"];
	else if ( util::hitRoundScoreLimit() )
		return  game["strings"]["round_score_limit_reached"];

	if ( level.forcedEnd )
	{
		if ( level.hostForcedEnd )
			return &"MP_HOST_ENDED_GAME";
		else
			return &"MP_ENDED_GAME";
	}
	return game["strings"]["time_limit_reached"];
}

function resetOutcomeForAllPlayers()
{
	players = level.players;
	for ( index = 0; index < players.size; index++ )
	{
		player = players[index];
		player notify ( "reset_outcome" );
	}
}

function hideOutcomeUIForAllPlayers()
{
	players = level.players;
	for ( index = 0; index < players.size; index++ )
	{
		player = players[index];
		player clientfield::set_player_uimodel( "hudItems.hideOutcomeUI", 1 );	
	}
}

function startNextRound( winner,	endReasonText )
{
	if ( !util::isOneRound() )
	{
		displayRoundEnd( winner, endReasonText );

		globallogic_utils::executePostRoundEvents();
		
		if ( !util::wasLastRound() )
		{
			if ( checkRoundSwitch() )
			{
				if ( level.scoreRoundWinBased ) 
				{
					foreach( team in level.teams )
					{
						[[level._setTeamScore]]( team, game["roundswon"][team] );
					}
				}
				
				displayRoundSwitch( winner, endReasonText );
			}
			
			if ( isdefined( level.nextRoundIsOvertime ) && level.nextRoundIsOvertime )
			{
				if ( !isdefined( game["overtime_round"] ) )
				{
					game["overtime_round"] = 1;
				}
				else
				{
					game["overtime_round"]++;
				}
			}

			SetMatchTalkFlag( "DeadChatWithDead", level.voip.deadChatWithDead );
			SetMatchTalkFlag( "DeadChatWithTeam", level.voip.deadChatWithTeam );
			SetMatchTalkFlag( "DeadHearTeamLiving", level.voip.deadHearTeamLiving );
			SetMatchTalkFlag( "DeadHearAllLiving", level.voip.deadHearAllLiving );
			SetMatchTalkFlag( "EveryoneHearsEveryone", level.voip.everyoneHearsEveryone );
			SetMatchTalkFlag( "DeadHearKiller", level.voip.deadHearKiller );
			SetMatchTalkFlag( "KillersHearVictim", level.voip.killersHearVictim );
				
			game["state"] = "playing";
			map_restart( true );
			hideOutcomeUIForAllPlayers();
			return true;
		}
	}
	return false;
}

	
function setTopPlayerStats( )
{
	if( level.rankedMatch )
	{
		placement = level.placement["all"];
		topThreePlayers = min( 3, placement.size );
			
		for ( index = 0; index < topThreePlayers; index++ )
		{
			if ( level.placement["all"][index].score )
			{
				if ( !index )
				{
					level.placement["all"][index] AddPlayerStatWithGameType( "TOPPLAYER", 1 );
					level.placement["all"][index] notify( "topplayer" );
				}
				else
					level.placement["all"][index] notify( "nottopplayer" );
				
				level.placement["all"][index] AddPlayerStatWithGameType( "TOP3", 1 );
				level.placement["all"][index]  AddPlayerStat( "TOP3ANY", 1 );
				if ( level.hardcoreMode )
				{
					level.placement["all"][index]  AddPlayerStat( "TOP3ANY_HC", 1 );
				}
				if ( level.multiTeam )
				{
					level.placement["all"][index]  AddPlayerStat( "TOP3ANY_MULTITEAM", 1 );
				}
				level.placement["all"][index] notify( "top3" );
			}
		}
		
		for ( index = 3 ; index < placement.size ; index++ )
		{
			level.placement["all"][index] notify( "nottop3" );
			level.placement["all"][index] notify( "nottopplayer" );
		}

		if ( level.teambased ) 
		{		
			foreach ( team in level.teams )
			{
				setTopTeamStats(team);
			}
		}
	}
}

function setTopTeamStats(team)
{
	placementTeam = level.placement[team];
	topThreeTeamPlayers = min( 3, placementTeam.size );
	// should have at least 5 players on the team
	if ( placementTeam.size < 5 )
		return;
		
	for ( index = 0; index < topThreeTeamPlayers; index++ )
	{
		if ( placementTeam[index].score )
		{
			placementTeam[index] AddPlayerStat( "TOP3TEAM", 1 );
			placementTeam[index] AddPlayerStat( "TOP3ANY", 1 );
			if ( level.hardcoreMode )
			{
				placementTeam[index] AddPlayerStat( "TOP3ANY_HC", 1 );
			}
			if ( level.multiTeam )
			{
				placementTeam[index] AddPlayerStat( "TOP3ANY_MULTITEAM", 1 );
			}
			placementTeam[index] AddPlayerStatWithGameType( "TOP3TEAM", 1 );
		}
	}
}

function figureOutWinningTeam( winner )
{
	if ( !isdefined( winner ) )
	    return "tie";
	    
	if ( IsEntity( winner ) )
		return ( isdefined( winner.team ) ? winner.team : "none" );

	return winner;
}

function getRoundLength()
{
	if ( !level.timeLimit || level.forcedEnd )
	{
		gameLength = globallogic_utils::getTimePassed() / 1000;		
		// cap it at 20 minutes to avoid exploiting
		gameLength = min( gameLength, 1200 );
	}
	else
	{
		gameLength = level.timeLimit * 60;
	}
	
	return gameLength;
}

function awardLootXP( ) // self == player
{
	if( !GetDvarInt( "loot_enabled" ) )
	{
		return;
	}
	
	maxPlayableGameTime = game["playabletimepassed"] / 1000;	
	timePlayed = self getTotalTimePlayed( maxPlayableGameTime );
	lootXPAwarded = 0;		
	
	if ( self.pers["participation"] >= 1 )
	{
		lootXPPerKey = int( GetDvarInt( "loot_cryptokeyCost", 100 ) );
		avgGameLen = int( GetDvarInt( "loot_earnTime", 267 ) );
		minPlayTime = int( GetDvarInt( "loot_earnPlayThreshold", 10 ) );
		maxLootXp = int( GetDvarInt( "loot_earnMax", 10000 ) );
		minLootXp = int( GetDvarInt( "loot_earnMin", 0 ) );
		winMultiplier = int( GetDvarInt( "loot_winBonusPercent", 30 ) );
				
		if( maxPlayableGameTime > 0 && timePlayed > minPlayTime )
		{
			// account for time spent in arena ban/protect
			if( level.arenaMatch )
			{
				draftEnabled = ( GetGametypeSetting( "pregameDraftEnabled" ) == 1 );
				voteEnabled = ( GetGametypeSetting( "pregameItemVoteEnabled" ) == 1 );

				if( draftEnabled && voteEnabled )
				{
					arenaMin = GetDvarInt( "arena_minPregameCryptoSeconds", 0 );
					arenaMax = GetDvarInt( "arena_maxPregameCryptoSeconds", 0 );
					
					if( arenaMax > 0 && arenaMin >= 0 && arenaMin <= arenaMax )
					{
						bonusTime = RandomIntRange( arenaMin, arenaMax );
						timePlayed += bonusTime;
					}
				}
			} 
			
			// award enough lootxp for 1 cryptokey for each 'avgGameLen' seconds of time played
			lootXpScale = timePlayed / avgGameLen;
			lootXPAwarded = lootXPPerKey * lootXpScale;
			
			// bonus for winner
			if( isDefined( self.lootXpMultiplier ) && self.lootXpMultiplier == true )
			{
				lootXPAwarded = lootXPAwarded + ( lootXPAwarded * ( winMultiplier / 100 ) );
			}
			 
			// scale for double lootxp
			lootXPAwarded *= math::clamp( GetDvarFloat( "lootxp_multiplier", 1.0 ), 0.0, 4.0 );
			
			lootXPAwarded = int( lootXPAwarded );
			
			// sanity
			if( lootXPAwarded > maxLootXp )
			{
				lootXPAwarded = maxLootXp;
			}
			else if( lootXPAwarded < minLootXp )
			{
				lootXPAwarded = minLootXp;
			}
			
			otherLootXPAwarded = self awardOtherLootXP();
			lootXPAwarded += otherLootXPAwarded;
			
			if( lootXPAwarded > 0 )
			{
				self ReportLootReward( 1, lootXPAwarded );
			}
			
			// if other loot xp was awarded, let client receive stats before requesting an upload
			if ( otherLootXPAwarded > 0 )
			{
				level thread WaitAndUploadStats( self, GetDvarFloat( "src_other_lootxp_uploadstat_waittime", OTHER_LOOTXP_UPLOADSTAT_WAITTIME ) );
			}
		}
	}
	
	self setAARStat( "lootXpEarned", lootXPAwarded ); 
	recordPlayerStats( self, "lootXpEarned", lootXPAwarded );
	recordPlayerStats( self, "lootTimePlayed", timePlayed );
}

function WaitAndUploadStats( player, waitTime )
{
	wait waitTime;
	
	if ( isPlayer( player ) )
	{
		UploadStats( player );
	}
}

function registerOtherLootXPAwards( func )
{
	if ( !isdefined( level.awardOtherLootXPfunctions )  )
		level.awardOtherLootXPfunctions = [];
	
	ARRAY_ADD( level.awardOtherLootXPfunctions, func );
}

function awardOtherLootXP()
{
	player = self;
	
	if ( !isdefined( level.awardOtherLootXPfunctions ) )
		return 0;
		
	if ( !isPlayer( player ) )
		return 0;

	lootXP = 0;
	
	foreach( func in level.awardOtherLootXPfunctions )
	{
		if ( !isdefined( func ) )
			continue;
		
		lootXP += player [[ func ]]();
	}

	return lootXP;
}

function endGame( winner, endReasonText )
{
	// return if already ending via host quit or victory
	if ( game["state"] == "postgame" || level.gameEnded )
		return;

	if ( isdefined( level.onEndGame ) )
		[[level.onEndGame]]( winner );

	if ( !isdefined( level.disableOutroVisionSet ) || level.disableOutroVisionSet == false )
	{
		visionSetNaked( "mpOutro", 2.0 );
	}
	
	setmatchflag( "cg_drawSpectatorMessages", 0 );
	setmatchflag( "game_ended", 1 );

	game["state"] = "postgame";
	level.gameEndTime = getTime();
	level.gameEnded = true;
	SetDvar( "g_gameEnded", 1 );
	level.inGracePeriod = false;
	level notify ( "game_ended" );
	level clientfield::set( "game_ended", 1 );
	globallogic_audio::flush_dialog();

	foreach( team in level.teams )
	{
		game["lastroundscore"][team] = getTeamScore( team );
	}

	if( util::isRoundBased() )
	{
		matchRecordRoundEnd();
	}
	
	winning_team = figureOutWinningTeam( winner );
	
	if ( isdefined( game["overtime_round"] ) && isdefined( game["overtimeroundswon"][winning_team] ) )
	{
		game["overtimeroundswon"][winning_team]++;
	}
	
	if ( !isdefined( game["overtime_round"] ) || util::wasLastRound() ) // Want to treat all overtime rounds as a single round
	{
		game["roundsplayed"]++;
		game["roundwinner"][game["roundsplayed"]] = winner;
		
		if ( isdefined( game["roundswon"][winning_team] ) )
			game["roundswon"][winning_team]++;
	}

	if ( isdefined( winner ) && isdefined( level.teams[ winning_team ] ) )
	{
		level.finalKillCam_winner = winner;
	}
	else
	{
		level.finalKillCam_winner = "none";
	}

	level.finalKillCam_winnerPicked = true; // consider "none" as picked too
	
	setGameEndTime( 0 ); // stop/hide the timers
	
	updatePlacement();

	updateRankedMatch( winner );
	
	// freeze players
	players = level.players;
	
	newTime = getTime();
	roundLength = getRoundLength();

	SetMatchTalkFlag( "EveryoneHearsEveryone", 1 );

	bbGameOver = 0;
	if ( util::isOneRound() || util::wasLastRound() )
	{
		bbGameOver = 1;
	}
	
	surveyId = 0;
	if( RandomFloat(1) <= GetDvarFloat("survey_chance") )
		surveyId = RandomIntRange(1, GetDvarInt( "survey_count" ) + 1 );

	for ( index = 0; index < players.size; index++ )
	{
		player = players[index];
		player globallogic_player::freezePlayerForRoundEnd();
		player thread roundEndDoF( 4.0 );

		player globallogic_ui::freeGameplayHudElems();

		player.pers["lastroundscore"] = player.pointstowin;
		
		// Update weapon usage stats
		player weapons::update_timings( newTime );

		if ( bbGameOver )
			player behaviorTracker::Finalize();
		
		player bbPlayerMatchEnd( roundLength, endReasonText, bbGameOver );

		player.pers["totalTimePlayed"] += player.timePlayed["total"];
		
		if ( bbGameOver )
		{
			if ( level.leagueMatch )
			{
				player setAARStat( "lobbyPopup", "leaguesummary" );
			}
			else
			{
				player setAARStat( "lobbyPopup", "summary" );
			}
		}

		player setAARStat( "surveyId", surveyId );
		player setAARStat( "hardcore", level.hardcoreMode );
	}

//	music::setmusicstate( "silent" );

// temporarily disabling round end sound call to prevent the final killcam from not having sound
	if ( !level.inFinalKillcam )
	{
//		util::clientNotify( "snd_end_rnd" );
	}

	gamerep::gameRepUpdateInformationForRound();
	thread challenges::roundEnd( winner );

	// update now
	game_winner = winner;
	if ( !util::isOneRound() )
	{
		game_winner = [[level.determineWinner]]( winner );		
	}
	update_top_scorers(game_winner);
	
	if ( startNextRound( winner, endReasonText ) )
	{
		return;
	}
	
	///////////////////////////////////////////
	// After this the match is really ending //
	///////////////////////////////////////////

	if ( !util::isOneRound() )
	{
		if ( isdefined( level.onRoundEndGame ) )
			winner = [[level.onRoundEndGame]]( winner );
		
		endReasonText = getEndReasonText();
	}
	
	globallogic_score::updateWinLossStats( winner );
	
	// this needs to happen after updateWinLossStats to award winner multipliers correctly
	if( level.rankedmatch || level.arenaMatch )
	{
		thread awardLootXPToPlayers( WAIT_TIME_BEFORE_AWARDING_LOOT_XP, players );
	}

	if( level.arenaMatch )
	{
		arena::match_end( winner );
	}
	
	result = "";
	
	if ( level.teambased )
	{
		if ( winner == "tie" )
		{
			result = "draw";
		}
		else
		{
			result = winner;
		}
	}
	else
	{
		if ( !isDefined( winner ) )
		{
			result = "draw";
		}
		else
		{
			result = winner.team;
		}
	}
	
	recordGameResult( result );

	// we want the end time for each player the moment the match is done, not post-final-killcam-presentation
	players = level.players;
	for ( index = 0; index < players.size; index++ )
	{
		player = players[index];
		player globallogic_player::record_misc_player_stats();								   
	}

	skillUpdate( winner, level.teamBased );
	recordLeagueWinner( winner );
	
	setTopPlayerStats();
	thread challenges::gameEnd( winner );

	UpdateAndFinalizeMatchRecord();

	recordEndGameComScoreEvent( result );
	
	level.finalGameEnd = true;
	
	if ( !isdefined( level.skipGameEnd ) || !level.skipGameEnd )
		displayGameEnd( winner, endReasonText );
	
	level.finalGameEnd = undefined;
	
	if ( util::isOneRound() )
	{
		globallogic_utils::executePostRoundEvents();
	}
		
	level.intermission = true;
	
	gamerep::gameRepAnalyzeAndReport();
	
	util::setClientSysState("levelNotify", "fkcs" );
	
	// update again
//	update_top_scorers(winner);
	
	if( persistence::can_set_aar_stat() )
	{
		thread sendAfterActionReport();
	}
	
	stopdemorecording();

	SetMatchTalkFlag( "EveryoneHearsEveryone", 1 );

	//regain players array since some might've disconnected during the wait above
	players = level.players;
	for ( index = 0; index < players.size; index++ )
	{
		player = players[index];
		
		player notify ( "reset_outcome" );
		player thread [[level.spawnIntermission]]( false, level.useXCamsForEndGame );		
        player setClientUIVisibilityFlag( "hud_visible", 1 );
	}

	level clientfield::set( "post_game", 1 );
	
	doEndGameSequence();
	
	if ( isdefined ( level.endGameFunction ) )
	{
		level thread [[level.endGameFunction]]();
	}
	//Eckert - Fading out sound
	level notify ( "sfade");
	/#print( "game ended" );#/
	
	if ( !isdefined( level.skipGameEnd ) || !level.skipGameEnd )
		wait 5.0;
	
	if( isDefined( level.end_game_video ) )
	{
		level thread lui::play_movie( level.end_game_video.name, "fullscreen", true );
		wait( level.end_game_video.duration + 4.5 );
	}
	
	exit_level();
}

function awardLootXPToPlayers( delay, players )
{
	wait delay;
	
	foreach( player in players )
	{
		if ( !isdefined( player ) )
			continue;
		
		player awardLootXP();
	}
}

function exit_level()
{
	if ( level.exitLevel )
		return;
	
	level.exitLevel = true;
	exitLevel( false );
}

function update_top_scorers(winner)
{
	topscorers = [];

	winning_team = figureOutWinningTeam( winner );

	if ( level.teambased && isdefined(winner) && isdefined( level.placement[winning_team] ) )
	{
		topscorers = level.placement[winning_team];
	}
	else
	{
		topscorers = level.placement["all"];
	}
	
	if ( topscorers.size )
	{
		level.doTopScorers = true;
	}
	else
	{
		level.doTopScorers = false;
	}
	
	ClearTopScorers();
	
	for ( i = 0; i < 3 && i < topscorers.size; i++ )
	{
		player = topscorers[i];
		
		player thread checkForGestures( i );
		
		showcase_weapon = player weapons::showcaseweapon_get();
		tauntIndex = player GetPlayerSelectedTaunt( TAUNT_TYPE_FIRST_PLACE );
		gesture0Index = player GetPlayerSelectedGesture( GESTURE_TYPE_GOOD_GAME );
		gesture1Index = player GetPlayerSelectedGesture( GESTURE_TYPE_THREATEN );
		gesture2Index = player GetPlayerSelectedGesture( GESTURE_TYPE_BOAST );	
		// if they dont have a weapon then they never spawned in
		if ( !isDefined( showcase_weapon ) )
		{
			SetTopScorer( i, player, tauntIndex, gesture0Index, gesture1Index, gesture2Index, GetWeapon("ar_standard") );
			continue;
		}
		
		SetTopScorer( i, player, tauntIndex, gesture0Index, gesture1Index, gesture2Index, showcase_weapon["weapon"], showcase_weapon["options"], showcase_weapon["acvi"] );
	}
}

// self = player
function checkForGestures( topPlayerIndex )
{
	self endon( "disconnect" );
	
	fieldName = "playTop" + topPlayerIndex + "Gesture";
	
	// Initialize the field
	level clientfield::set( fieldName, GESTURE_TYPE_MAX );
	WAIT_SERVER_FRAME;
	
	while(true)
	{
		if ( self actionSlotOneButtonPressed() )
		{
			// Up - Good Game
			self setGestureClientField( fieldName, GESTURE_TYPE_GOOD_GAME );
		}
		else if ( self actionSlotThreeButtonPressed() )
		{
			// Left - Threaten
			self setGestureClientField( fieldName, GESTURE_TYPE_THREATEN );
		}
		else if ( self actionSlotFourButtonPressed() )
		{
			// Right - Boast
			self setGestureClientField( fieldName, GESTURE_TYPE_BOAST );
		}
/*		
		else if ( self actionSlotTwoButtonPressed() )
		{
			Down - Unused
			self setGestureClientField( topPlayerIndex, 3 );
		}
*/
		WAIT_SERVER_FRAME;
	}
}

function setGestureClientField( fieldName, gestureType )
{
	self notify ( "setGestureClientField" );
	self endon ( "setGestureClientField" );
	
	level clientfield::set( fieldName, gestureType );
	
	WAIT_SERVER_FRAME;
	
	// Reset the field
	level clientfield::set( fieldName, GESTURE_TYPE_MAX );
}

function doEndGameSequence()
{
	// This should be done only if the end game flow prefab is in the map.
	level notify ( "endgame_sequence" );
	
	preloadingEnabled = GetDvarInt( "sv_mapSwitchPreloadFrontend", 0 );
	if ( level.doTopScorers && isDefined( struct::get( "endgame_top_players_struct", "targetname" ) ) )
	{
		//setMatchFlag( "full_screen", 1 );
		setMatchFlag( "enable_popups", 1 );  // replace full_screen when new exes come in

		// get rid of the corpses so they dont show up in the top scorers screen
		ClearPlayerCorpses();

		level thread sndSetMatchSnapshot( 3 );
		level thread globallogic_audio::set_music_global("endmatch");
		level clientfield::set( "displayTop3Players", 1 );
		
		if( preloadingEnabled )
			SwitchMap_Preload( "core_frontend" );
		
		wait 15.0;
		level clientfield::set( "triggerScoreboardCamera", 1 );
		wait 5.0;
		//setMatchFlag( "full_screen", 0 );
		setMatchFlag( "enable_popups", 0 ); // replace full_screen when new exes come in
	}
	else if ( level.doEndgameScoreboard )
	{
		if( preloadingEnabled )
			SwitchMap_Preload( "core_frontend" );
		LUINotifyEvent( &"force_scoreboard", 0 );
	}
}

function getTotalTimePlayed( maxLength ) // self == player
{
	totalTimePlayed = 0;
	if ( isdefined( self.pers["totalTimePlayed"] ) )
	{
		totalTimePlayed = self.pers["totalTimePlayed"];
		if ( totalTimePlayed > maxLength )
		{
			totalTimePlayed = maxLength;
		}
	}
	return totalTimePlayed;
}

function getRoundTimePlayed( roundLength ) // self == player
{
	totalTimePlayed = 0;
	if ( isdefined( self.timePlayed ) && isdefined( self.timePlayed["total"] ) )
	{
		totalTimePlayed = self.timePlayed["total"];
		if ( totalTimePlayed > roundLength )
		{
			totalTimePlayed = roundLength;
		}
	}
	return totalTimePlayed;
}

function bbPlayerMatchEnd( gameLength, endReasonString, gameOver ) // self == player
{		 
}

function roundEndWait( defaultDelay, matchBonus )
{
	notifiesDone = false;
	while ( !notifiesDone )
	{
		players = level.players;
		notifiesDone = true;
		for ( index = 0; index < players.size; index++ )
		{
			if ( !isdefined( players[index].doingNotify ) || !players[index].doingNotify )
				continue;
				
			notifiesDone = false;
		}
		wait ( 0.5 );
	}

	if ( !matchBonus )
	{
		wait ( defaultDelay );
		level notify ( "round_end_done" );
		return;
	}

  	wait ( defaultDelay / 2 );
	level notify ( "give_match_bonus" );
	wait ( defaultDelay / 2 );

	notifiesDone = false;
	while ( !notifiesDone )
	{
		players = level.players;
		notifiesDone = true;
		for ( index = 0; index < players.size; index++ )
		{
			if ( !isdefined( players[index].doingNotify ) || !players[index].doingNotify )
				continue;
				
			notifiesDone = false;
		}
		wait ( 0.5 );
	}
	
	level notify ( "round_end_done" );
}


function roundEndDOF( time )
{
	self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
}


function checkTimeLimit()
{
	if ( isdefined( level.timeLimitOverride ) && level.timeLimitOverride )
		return;
	
	if ( game["state"] != "playing" )
	{
		setGameEndTime( 0 );
		return;
	}
		
	if ( level.timeLimit <= 0 )
	{
		setGameEndTime( 0 );
		return;
	}
		
	if ( level.inPrematchPeriod )
	{
		setGameEndTime( 0 );
		return;
	}
	
	if( IS_TRUE( level.timerPaused ) )
	{
		timeRemaining = globallogic_utils::getTimeRemaining();
		if ( timeRemaining > 30000 )
		{
			// round down to the nearest number so it doesn't jump back and forth
			setGameEndTime( -int(timeRemaining - 999) );
		}
		else
		{
			// we show tenths of a second under 30
			setGameEndTime( -int(timeRemaining - 99) );
		}
		return;
	}
	
	if ( level.timerStopped )
	{
		setGameEndTime( 0 );
		return;
	}
	
	if ( !isdefined( level.startTime ) )
		return;
	
	timeLeft = globallogic_utils::getTimeRemaining();
	
	// want this accurate to the millisecond
	setGameEndTime( getTime() + int(timeLeft) );
	
	if ( timeLeft > 0 )
		return;
	
	[[level.onTimeLimit]]();
}

function checkScoreLimit()
{
	if ( game["state"] != "playing" )
		return false;

	if ( level.scoreLimit <= 0 )
		return false;

	if ( level.teamBased )
	{
		if( !util::any_team_hit_score_limit() )
			return false;
	}
	else
	{
		if ( !isPlayer( self ) )
			return false;

		if ( self.pointstowin < level.scoreLimit )
			return false;
	}

	[[level.onScoreLimit]]();
}

function checkSuddenDeathScoreLimit( team )
{
	if ( game["state"] != "playing" )
		return false;

	if ( level.roundScoreLimit <= 0 )
		return false;

	if ( level.teamBased )
	{
		if( !game["teamSuddenDeath"][team] )
			return false;
	}
	else
	{
		return false;
	}

	[[level.onScoreLimit]]();
}

function checkRoundScoreLimit()
{
	if ( game["state"] != "playing" )
		return false;

	if ( level.roundScoreLimit <= 0 )
		return false;

	if ( level.teamBased )
	{
		if( !util::any_team_hit_round_score_limit() )
			return false;
	}
	else
	{
		if ( !isPlayer( self ) )
			return false;

		roundScoreLimit = util::get_current_round_score_limit();
	
		if ( self.pointstowin < roundScoreLimit )
			return false;
	}

	[[level.onRoundScoreLimit]]();
}

function updateGameTypeDvars()
{
	level endon ( "game_ended" );
	
	while ( game["state"] == "playing" )
	{
		roundlimit = math::clamp( GetGametypeSetting( "roundLimit" ), level.roundLimitMin, level.roundLimitMax );
		if ( roundlimit != level.roundlimit )
		{
			level.roundlimit = roundlimit;
			level notify ( "update_roundlimit" );
		}

		timeLimit = [[level.getTimeLimit]]();
		if ( timeLimit != level.timeLimit )
		{
			level.timeLimit = timeLimit;
			SetDvar( "ui_timelimit", level.timeLimit );
			level notify ( "update_timelimit" );
		}
		thread checkTimeLimit();

		scoreLimit = math::clamp( GetGametypeSetting( "scoreLimit" ), level.scoreLimitMin, level.scoreLimitMax );
		if ( scoreLimit != level.scoreLimit )
		{
			level.scoreLimit = scoreLimit;
			SetDvar( "ui_scorelimit", level.scoreLimit );
			level notify ( "update_scorelimit" );
		}
		thread checkScoreLimit();
		
		roundScoreLimit = math::clamp( GetGametypeSetting( "roundScoreLimit" ), level.roundScoreLimitMin, level.roundScoreLimitMax );
		if ( roundScoreLimit != level.roundScoreLimit )
		{
			level.roundScoreLimit = roundScoreLimit;
			level notify ( "update_roundScoreLimit" );
		}
		thread checkRoundScoreLimit();
		
		// make sure we check time limit right when game ends
		if ( isdefined( level.startTime ) )
		{
			if ( globallogic_utils::getTimeRemaining() < 3000 )
			{
				wait .1;
				continue;
			}
		}
		wait 1;
	}
}


function removeDisconnectedPlayerFromPlacement()
{
	offset = 0;
	numPlayers = level.placement["all"].size;
	found = false;
	for ( i = 0; i < numPlayers; i++ )
	{
		if ( level.placement["all"][i] == self )
			found = true;
		
		if ( found )
			level.placement["all"][i] = level.placement["all"][ i + 1 ];
	}
	if ( !found )
		return;
	
	level.placement["all"][ numPlayers - 1 ] = undefined;
	assert( level.placement["all"].size == numPlayers - 1 );

	updateTeamPlacement();
	
	if ( level.teamBased )
		return;
		
	numPlayers = level.placement["all"].size;
	for ( i = 0; i < numPlayers; i++ )
	{
		player = level.placement["all"][i];
		player notify( "update_outcome" );
	}
	
}

function updatePlacement()
{
	
	if ( !level.players.size )
		return;

	level.placement["all"] = [];
	foreach ( player in level.players )
	{
		if ( !level.teambased || isdefined( level.teams[ player.team ] ) )
			level.placement["all"][level.placement["all"].size] = player;
	}
		
	placementAll = level.placement["all"];
	
	if ( level.teamBased )
	{
		for ( i = 1; i < placementAll.size; i++ )
		{
			player = placementAll[i];
			playerScore = player.score;
			for ( j = i - 1; j >= 0 && (playerScore > placementAll[j].score || (playerScore == placementAll[j].score && player.deaths < placementAll[j].deaths)); j-- )
				placementAll[j + 1] = placementAll[j];
			placementAll[j + 1] = player;
		}
	}
	else
	{
		for ( i = 1; i < placementAll.size; i++ )
		{
			player = placementAll[i];
			playerScore = player.pointstowin;
			for ( j = i - 1; j >= 0 && (playerScore > placementAll[j].pointstowin || (playerScore == placementAll[j].pointstowin && player.deaths < placementAll[j].deaths) || (playerScore == placementAll[j].pointstowin && player.deaths == placementAll[j].deaths && player.lastKillTime > placementAll[j].lastKillTime)); j-- )
				placementAll[j + 1] = placementAll[j];
			placementAll[j + 1] = player;
		}
	}
	
	level.placement["all"] = placementAll;
	
	updateTeamPlacement();

}	


function updateTeamPlacement()
{
	foreach( team in level.teams )
	{
		placement[team]    = [];
	}
	placement["spectator"] = [];
	
	if ( !level.teamBased )
		return;
	
	placementAll = level.placement["all"];
	placementAllSize = placementAll.size;
	
	for ( i = 0; i < placementAllSize; i++ )
	{
		player = placementAll[i];
		team = player.pers["team"];
		
		placement[team][ placement[team].size ] = player;
	}
	
	foreach( team in level.teams )
	{
		level.placement[team] = placement[team];
	}
}

function getPlacementForPlayer( player )
{
	updatePlacement();

	playerRank = -1;
	placement = level.placement["all"];
	for ( placementIndex = 0; placementIndex < placement.size; placementIndex++ )
	{
		if ( level.placement["all"][placementIndex] == player )
		{
			playerRank = (placementIndex + 1);
			break;
		}				
	}

	return playerRank;
}

function isTopScoringPlayer( player )
{
	topScoringPlayer = false;
	updatePlacement();

	assert( level.placement["all"].size > 0 );
	if ( level.placement["all"].size == 0 )
	{
		return false;
	}
	
	if ( level.teambased ) 
	{
		topScore = level.placement["all"][0].score;
		for ( index = 0; index < level.placement["all"].size; index++ )
		{
			if ( level.placement["all"][index].score == 0 )
			{
				break;
			}
			if ( topScore > level.placement["all"][index].score )
			{
				break;
			}
			if ( player == level.placement["all"][index] )
			{
				topScoringPlayer = true;
				break;
			}
		}
	}
	else
	{
		topScore = level.placement["all"][0].pointsToWin;
		for ( index = 0; index < level.placement["all"].size; index++ )
		{
			if ( level.placement["all"][index].pointsToWin == 0 )
			{
				break;
			}
			if ( topScore > level.placement["all"][index].pointsToWin )
			{
				break;
			}
			if ( player == level.placement["all"][index] )
			{
				topScoringPlayer = true;
				break;
			}
		}
	}
	return topScoringPlayer;
}

function sortDeadPlayers( team )
{
	// only need to sort if we are running queued respawn
	if ( !level.playerQueuedRespawn )
		return;
		
	// sort by death time
	for ( i = 1; i < level.deadPlayers[team].size; i++ )
	{
		player = level.deadPlayers[team][i];
		for ( j = i - 1; j >= 0 && player.deathTime < level.deadPlayers[team][j].deathTime; j-- )
			level.deadPlayers[team][j + 1] = level.deadPlayers[team][j];
		level.deadPlayers[team][j + 1] = player;
	}
	
	for ( i = 0; i < level.deadPlayers[team].size; i++ )
	{
		if ( level.deadPlayers[team][i].spawnQueueIndex != i )
		{
			level.spawnQueueModified[team] = true;
		}
		level.deadPlayers[team][i].spawnQueueIndex = i;
	}
}

function totalAliveCount()
{
	count = 0;
	foreach( team in level.teams )
	{
		count += level.aliveCount[team];
	}
	return count; 
}

function totalPlayerLives()
{
	count = 0;
	foreach( team in level.teams )
	{
		count += level.playerLives[team];
	}
	return count; 
}

function initTeamVariables( team )
{
	
	if ( !isdefined( level.aliveCount ) )
		level.aliveCount = [];
	
	level.aliveCount[team] = 0;
	level.lastAliveCount[team] = 0;
	
	if ( !isdefined( game["everExisted"] ) )
	{
		game["everExisted"] = [];
	}
	if ( !isdefined( game["everExisted"][team] ) )
	{
		game["everExisted"][team] = false;
	}	
	level.everExisted[team] = false;
	level.waveDelay[team] = 0;
	level.lastWave[team] = 0;
	level.wavePlayerSpawnIndex[team] = 0;

	resetTeamVariables( team );}

function resetTeamVariables( team )
{
	level.playerCount[team] = 0;
	level.botsCount[team] = 0;
	level.lastAliveCount[team] = level.aliveCount[team];
	level.aliveCount[team] = 0;
	level.playerLives[team] = 0;
	level.alivePlayers[team] = [];
	level.spawningPlayers[team] = [];
	level.deadPlayers[team] = [];
	level.squads[team] = [];
	level.spawnQueueModified[team] = false;
}

function updateTeamStatus()
{
	// run only once per frame, at the end of the frame.
	level notify("updating_team_status");
	level endon("updating_team_status");
	level endon ( "game_ended" );
	waittillframeend;
	
	wait 0;	// Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute

	if ( game["state"] == "postgame" )
		return;

	resetTimeout();
	
	foreach( team in level.teams )
	{
		resetTeamVariables( team );
	}

	if ( !level.teambased )
	{
		resetTeamVariables( "free" );
	}
	
	level.activePlayers = [];

	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		
		if ( !isdefined( player ) && level.splitscreen )
			continue;

		if ( level.teambased || player.team == "spectator" )
		{
			team = player.team;
		}
		else
		{
			team = "free";
		}
		
		playerclass = player.curClass;
		
		if ( team != "spectator" && (isdefined( playerclass ) && playerclass != "") )
		{
			level.playerCount[team]++;
			
			if( isdefined( player.pers["isBot"] ) )
				level.botsCount[team]++;
			
			not_quite_dead = false;
			
			// used by the resurrect gadget to keep players that could self-resurrect from appearing dead
			if ( isdefined(	player.overridePlayerDeadStatus ) )
			{
				not_quite_dead = player [[ player.overridePlayerDeadStatus ]]();
			}
			
			if ( player.sessionstate == "playing" )
			{
				level.aliveCount[team]++;
				level.playerLives[team]++;
				player.spawnQueueIndex = -1;
				
				if ( isAlive( player ) )
				{
					level.alivePlayers[team][level.alivePlayers[team].size] = player;
					level.activeplayers[ level.activeplayers.size ] = player;
				}
				else
				{
					level.deadPlayers[team][level.deadPlayers[team].size] = player;
				}
			}
			else if ( not_quite_dead )
			{
				level.aliveCount[team]++;
				level.playerLives[team]++;
				level.alivePlayers[team][level.alivePlayers[team].size] = player;
			}
			else
			{
				level.deadPlayers[team][level.deadPlayers[team].size] = player;
				if ( player globallogic_spawn::maySpawn() )
					level.playerLives[team]++;
			}
		}
	}
	
	totalAlive = totalAliveCount();
	
	if ( totalAlive > level.maxPlayerCount )
		level.maxPlayerCount = totalAlive;
	
	foreach( team in level.teams )
	{
		if ( level.aliveCount[team] )
		{
			game["everExisted"][team] = true;
			level.everExisted[team] = true;
		}
	
		sortDeadPlayers( team );
	}

	level updateGameEvents();
}

function updateAliveTimes(team)
{
	level.aliveTimesAverage[team] = 0;

	if ( game["state"] == "postgame" )
		return;

	total_player_count = 0;
	average_player_spawn_time = 0;
	total_value_count = 0;
	
	foreach( player in level.alivePlayers[team] )
	{
		average_time = 0;
		count = 0;
		foreach( time in player.aliveTimes )
		{
			if ( time != 0 )
			{
				average_time += time;
				count++;
			}
		}
		
		if ( count )
		{
			total_value_count += count;
			average_player_spawn_time += average_time / count;
			total_player_count++;
		}
	}
	
	foreach( player in level.deadPlayers[team] )
	{
		average_time = 0;
		count = 0;
		foreach( time in player.aliveTimes )
		{
			if ( time != 0 )
			{
				average_time += time;
				count++;
			}
		}
		
		if ( count )
		{
			total_value_count += count;
			average_player_spawn_time += average_time / count;
			total_player_count++;
		}
	}
	
	// if we dont have player or dont have enough data dont bother
	if ( total_player_count == 0 || total_value_count < 3 )
	{
		level.aliveTimesAverage[team] = 0;
		return;
	}
		
	level.aliveTimesAverage[team] = average_player_spawn_time / total_player_count;
}

function updateAllAliveTimes()
{
	foreach( team in level.teams )
	{
		updateAliveTimes(team);
	}
}

function checkTeamScoreLimitSoon( team )
{
	assert( isdefined( team ) );
	
	if ( level.scoreLimit <= 0 )
		return;
		
	if ( !level.teamBased )
		return;
		
	// Give the data a minute to converge/settle
	if ( globallogic_utils::getTimePassed() < ( 60 * 1000 ) )
		return;
	
	timeLeft = globallogic_utils::getEstimatedTimeUntilScoreLimit( team );
	
	if ( timeLeft < 1 )
	{
		level notify( "match_ending_soon", "score" );
	}
}

function checkPlayerScoreLimitSoon()
{
	assert( IsPlayer( self ) );
	
	if ( level.scoreLimit <= 0 )
		return;
	
	if ( level.teamBased )
		return;
		
	// Give the data a minute to converge/settle
	if ( globallogic_utils::getTimePassed() < ( 60 * 1000 ) )
		return;
		
	timeLeft = globallogic_utils::getEstimatedTimeUntilScoreLimit( undefined );
	
	if ( timeLeft < 1 )
	{
		level notify( "match_ending_soon", "score" );
	}
}

function timeLimitClock()
{
	level endon ( "game_ended" );
	
	wait .05;
	
	clockObject = spawn( "script_origin", (0,0,0) );
	
	while ( game["state"] == "playing" )
	{
		if ( !level.timerStopped && level.timeLimit )
		{
			timeLeft = globallogic_utils::getTimeRemaining() / 1000;
			timeLeftInt = int(timeLeft + 0.5); // adding .5 and flooring rounds it.
			
			if ( timeLeftInt == 601  )
				util::clientNotify( "notify_10" );
			
			if ( timeLeftInt == 301  )
				util::clientNotify( "notify_5" );
				
			if ( timeLeftInt == 60  )
				util::clientNotify( "notify_1" );
				
			if ( timeLeftInt == 12 )
				util::clientNotify( "notify_count" );
			
			if ( timeLeftInt >= 40 && timeLeftInt <= 60 )
				level notify ( "match_ending_soon", "time" );

			if ( timeLeftInt >= 30 && timeLeftInt <= 40 )
				level notify ( "match_ending_pretty_soon", "time" );
				
			if( timeLeftInt <= 32 )
			    level notify ( "match_ending_vox" );	

			if ( timeLeftInt <= 10 || (timeLeftInt <= 30 && timeLeftInt % 2 == 0) )
			{
				level notify ( "match_ending_very_soon", "time" );
				// don't play a tick at exactly 0 seconds, that's when something should be happening!
				if ( timeLeftInt == 0 )
					break;
				
				clockObject playSound( "mpl_ui_timer_countdown" );
			}
			
			// synchronize to be exactly on the second
			if ( timeLeft - floor(timeLeft) >= .05 )
				wait timeLeft - floor(timeLeft);
		}

		wait ( 1.0 );
	}
}

function timeLimitClock_Intermission( waitTime )
{
	setGameEndTime( getTime() + int(waitTime*1000) );
	clockObject = spawn( "script_origin", (0,0,0) );
	
	if ( waitTime >= 10.0 )
		wait ( waitTime - 10.0 );
		
	for ( ;; )
	{
		clockObject playSound( "mpl_ui_timer_countdown" );
		wait ( 1.0 );
	}	
}
function recordBreadcrumbData()
{
	level endon ( "game_ended" );

	while(1)
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if( isAlive( player ) )
			{		
				RecordBreadcrumbDataForPlayer( player, player.lastShotBy );			
			}
		}

		wait( 2.0 );	// make sure #define BREADCRUMBDATA_INTERVAL_SECONDS in code matches this!
	}

}

function startGame()
{
	thread globallogic_utils::gameTimer();
	level.timerStopped = false;
	level.playableTimerStopped = false;
	// RF, disabled this, as it is not required anymore.
	//thread spawnlogic::spawn_per_frame_update();

	SetMatchTalkFlag( "DeadChatWithDead", level.voip.deadChatWithDead );
	SetMatchTalkFlag( "DeadChatWithTeam", level.voip.deadChatWithTeam );
	SetMatchTalkFlag( "DeadHearTeamLiving", level.voip.deadHearTeamLiving );
	SetMatchTalkFlag( "DeadHearAllLiving", level.voip.deadHearAllLiving );
	SetMatchTalkFlag( "EveryoneHearsEveryone", level.voip.everyoneHearsEveryone );
	SetMatchTalkFlag( "DeadHearKiller", level.voip.deadHearKiller );
	SetMatchTalkFlag( "KillersHearVictim", level.voip.killersHearVictim );
	
	ClearTopScorers();

	if(IsDefined(level.custom_prematch_period))
	{
		[[level.custom_prematch_period]]();
	}	
	else
	{
		prematchPeriod();
	}
	
	level notify("prematch_over");
	level.prematch_over = true;

	level clientfield::set("gameplay_started", 1);

	thread notifyEndOfGameplay();

	thread timeLimitClock();
	thread gracePeriod();
	thread watchMatchEndingSoon();

	thread globallogic_audio::announcerController();
	thread globallogic_audio::sndMusicFunctions();
	thread recordBreadcrumbData();

	if( util::isRoundBased() )
	{
		if( util::getRoundsPlayed() == 0 )
		{
			// true beginning of a round-based game
			recordMatchBegin();
		}
		matchRecordRoundStart();
		
		if ( isdefined( game["overtime_round"] ) )
		{
			matchRecordOvertimeRound();
		}
	}
	else
	{
		// not round based
		recordMatchBegin();
	}
}

function isPrematchRequirementConditionMet(activeTeamCount)
{
	if ( level.prematchRequirement == 0 )
		return true;
		
	if ( level.teamBased )
	{
		if ( activeTeamCount.size <= 1 )
			return false;
			
		foreach( teamCount in activeTeamCount )
		{
			if ( teamCount != level.prematchRequirement )
				return false;
		}
	}
	else
	{
		if ( activeTeamCount["free"] != level.prematchRequirement )
			return false;
	}
	return true;
}

function waitForPlayers()
{
	level endon( "game_ended" );
	startTime = getTime();
		
	playerReady = false;
	activePlayerCount = 0;
	acceptTestClient = false;

	activeTeamCount = [];
	player_ready = [];
	
	while ( !playerReady || activePlayerCount == 0 || !isprematchRequirementConditionMet(activeTeamCount) )
	{
		activePlayerCount = 0;

		if ( level.teamBased )
		{
			foreach( team in level.teams )
			{
				activeTeamCount[team] = 0;
			}
		}
		else
		{
			activeTeamCount["free"] = 0;
		}
		
		temp_player_ready = [];

		foreach( player in level.players )
		{
			// only consider real players
			if ( player istestclient() && acceptTestClient == false ) 
				continue;
			
			if ( player.team != "spectator" )
			{
				activePlayerCount++;
				
				player_num = player GetEntityNumber();
				if ( isDefined( player_ready[player_num] ) )
				{
					temp_player_ready[player_num] = player_ready[player_num];
				}
				else
				{
					temp_player_ready[player_num] = GetTime();
				}
				
				// streamer gets marked ready well before the player is done "loading"
				// we want to wait until the player is done loading but will have a five second failsafe
				// this mechanic should probably be a core system as we have several places that we want to know
				// when the player is done loading
				if ( ((temp_player_ready[player_num] + 5000) < GetTime()) || player isStreamerReady( -1, true ) )
				{
					if ( level.teamBased )
					{
						activeTeamCount[player.team]++;
					}
					else
					{
						activeTeamCount["free"]++;
					}
				}
			}

			if( player isStreamerReady( -1, true ) )
			{
				if ( playerReady == false )
				{
					level notify("first_player_ready", player );
				}
				playerReady = true;
			}
		}

		// this causes any players that no longer exist in the list to flush
		player_read = temp_player_ready;
		
		WAIT_SERVER_FRAME;
		if( getTime() - startTime > ( 20 * 1000 ) )
		{
			if ( level.rankedmatch == false && level.arenamatch == false )
			{
				acceptTestClient = true;	
			}
		}
		
		if( level.rankedMatch && ((getTime() - startTime) > ( 120 * 1000 )) )
		{
			//EOughton: if we've been sitting here for 2 minutes without anyone making it in, it's time to call it a night
			exit_level();		
			
			while(1)
			{
				// dont do anything just let the level exit
				wait(10);
			}
		}
	}
}	

function prematchWaitingForPlayers() 
{
		if ( level.prematchRequirement != 0 )
		{
			level waittill ("first_player_ready", player );
			LUINotifyEvent( &"prematch_waiting_for_players" );
		}
}

function prematchPeriod()
{
	setMatchFlag( "hud_hardcore", level.hardcoreMode );

	level endon( "game_ended" );
	
	globallogic_audio::sndMusicSetRandomizer();
	
	if ( level.prematchPeriod > 0 )
	{
		thread matchStartTimer();
		thread prematchWaitingForPlayers();
			
		waitForPlayers();

		wait ( level.prematchPeriod );
	}
	else
	{
		matchStartTimerSkip();
		
		WAIT_SERVER_FRAME;
	}
	
	level.inPrematchPeriod = false;
	level thread sndSetMatchSnapshot( 0 );
	
	for ( index = 0; index < level.players.size; index++ )
	{		
		level.players[index] util::freeze_player_controls( false );
		level.players[index] enableWeapons();
	}
	
	if ( game["state"] != "playing" )
		return;
}
	
function gracePeriod()
{
	level endon("game_ended");
	
	if ( isdefined( level.gracePeriodFunc ) )
	{
		[[ level.gracePeriodFunc ]]();
	}
	else
	{
		wait ( level.gracePeriod );
	}
	
	level notify ( "grace_period_ending" );
	WAIT_SERVER_FRAME;
	
	level.inGracePeriod = false;
	
	if ( game["state"] != "playing" )
		return;
	
	if ( level.numLives )
	{
		// Players on a team but without a weapon show as dead since they can not get in this round
		players = level.players;
		
		for ( i = 0; i < players.size; i++ )
		{
			player = players[i];
			
			if ( !player.hasSpawned && player.sessionteam != "spectator" && !isAlive( player ) )
				player.statusicon = "hud_status_dead";
		}
	}
	
	level thread updateTeamStatus();
	level thread updateAllAliveTimes();
}

function watchMatchEndingSoon()
{
	SetDvar( "xblive_matchEndingSoon", 0 );
	level waittill( "match_ending_soon", reason );
	SetDvar( "xblive_matchEndingSoon", 1 );
}

function assertTeamVariables( )
{
	// these are defined in the teamset file
	foreach ( team in level.teams ) 
	{
		Assert( isdefined( game["strings"][ team + "_win"] ), "game[\"strings\"][\"" + team + "_win\"] does not exist"  );
		Assert( isdefined( game["strings"][ team + "_win_round"] ), "game[\"strings\"][\"" + team + "_win_round\"] does not exist"  );
		Assert( isdefined( game["strings"][ team + "_mission_accomplished"] ), "game[\"strings\"][\"" + team + "_mission_accomplished\"] does not exist"  );
		Assert( isdefined( game["strings"][ team + "_eliminated"] ), "game[\"strings\"][\"" + team + "_eliminated\"] does not exist"  );
		Assert( isdefined( game["strings"][ team + "_forfeited"] ), "game[\"strings\"][\"" + team + "_forfeited\"] does not exist"  );
		Assert( isdefined( game["strings"][ team + "_name"] ), "game[\"strings\"][\"" + team + "_name\"] does not exist"  );
		Assert( isdefined( game["music"]["spawn_" + team] ), "game[\"music\"][\"spawn_" + team + "\"] does not exist"  );
		Assert( isdefined( game["music"]["victory_" + team] ), "game[\"music\"][\"victory_" + team + "\"] does not exist"  );
		Assert( isdefined( game["icons"][team] ), "game[\"icons\"][\"" + team + "\"] does not exist"  );
		Assert( isdefined( game["voice"][team] ), "game[\"voice\"][\"" + team + "\"] does not exist"  );
	}
}

function anyTeamHasWaveDelay()
{
	foreach ( team in level.teams )
	{
		if ( level.waveDelay[team] )
			return true;
	}
	
	return false;
}

function Callback_StartGameType()
{
	level.prematchRequirement = 0;
	level.prematchPeriod = 0;
	level.intermission = false;

	setmatchflag( "cg_drawSpectatorMessages", 1 );
	setmatchflag( "game_ended", 0 );
	
	if ( !isdefined( game["gamestarted"] ) )
	{
		// defaults if not defined in level script
		if ( !isdefined( game["allies"] ) )
			game["allies"] = "seals";
		if ( !isdefined( game["axis"] ) )
			game["axis"] = "pmc";
		if ( !isdefined( game["attackers"] ) )
			game["attackers"] = "allies";
		if (  !isdefined( game["defenders"] ) )
			game["defenders"] = "axis";

		// if this hits the teams are not setup right
		assert( game["attackers"] != game["defenders"] );
		
		// TODO MTEAM - need to update this valid team
		foreach( team in level.teams )
		{
			if ( !isdefined( game[team] ) )
				game[team] = "pmc";
		}

		if ( !isdefined( game["state"] ) )
			game["state"] = "playing";
	
		//makeDvarServerInfo( "cg_thirdPersonAngle", 354 );

		SetDvar( "cg_thirdPersonAngle", 354 );

		game["strings"]["press_to_spawn"] = &"PLATFORM_PRESS_TO_SPAWN";
		if ( level.teamBased )
		{
			game["strings"]["waiting_for_teams"] = &"MP_WAITING_FOR_TEAMS";
			game["strings"]["opponent_forfeiting_in"] = &"MP_OPPONENT_FORFEITING_IN";
		}
		else
		{
			game["strings"]["waiting_for_teams"] = &"MP_WAITING_FOR_PLAYERS";
			game["strings"]["opponent_forfeiting_in"] = &"MP_OPPONENT_FORFEITING_IN";
		}
		game["strings"]["match_starting_in"] = &"MP_MATCH_STARTING_IN";
		game["strings"]["spawn_next_round"] = &"MP_SPAWN_NEXT_ROUND";
		game["strings"]["waiting_to_spawn"] = &"MP_WAITING_TO_SPAWN";
		game["strings"]["waiting_to_spawn_ss"] = &"MP_WAITING_TO_SPAWN_SS";
		//game["strings"]["waiting_to_safespawn"] = &"MP_WAITING_TO_SAFESPAWN";
		game["strings"]["you_will_spawn"] = &"MP_YOU_WILL_RESPAWN";
		game["strings"]["match_starting"] = &"MP_MATCH_STARTING";
		game["strings"]["change_class"] = &"MP_CHANGE_CLASS_NEXT_SPAWN";
		game["strings"]["last_stand"] = &"MPUI_LAST_STAND";
		
		game["strings"]["cowards_way"] = &"PLATFORM_COWARDS_WAY_OUT";
		
		game["strings"]["tie"] = &"MP_MATCH_TIE";
		game["strings"]["round_draw"] = &"MP_ROUND_DRAW";

		game["strings"]["enemies_eliminated"] = &"MP_ENEMIES_ELIMINATED";
		game["strings"]["score_limit_reached"] = &"MP_SCORE_LIMIT_REACHED";
		game["strings"]["round_score_limit_reached"] = &"MP_SCORE_LIMIT_REACHED";
		game["strings"]["round_limit_reached"] = &"MP_ROUND_LIMIT_REACHED";
		game["strings"]["time_limit_reached"] = &"MP_TIME_LIMIT_REACHED";
		game["strings"]["players_forfeited"] = &"MP_PLAYERS_FORFEITED";
		game["strings"]["other_teams_forfeited"] = &"MP_OTHER_TEAMS_FORFEITED";

		assertTeamVariables();

		[[level.onPrecacheGameType]]();

		game["gamestarted"] = true;
		
		game["totalKills"] = 0;

		foreach( team in level.teams )
		{
			if ( !isdefined( game["migratedHost"] ) )
				game["teamScores"][team] = 0;

			game["teamSuddenDeath"][team] = false;
			
			game["totalKillsTeam"][team] = 0;
		}

		level.prematchRequirement = GetGametypeSetting( "prematchRequirement" );
		level.prematchPeriod = GetGametypeSetting( "prematchperiod" );

		if ( GetDvarint( "xblive_clanmatch" ) != 0 )
		{
			// TODO MTEAM is this code used anymore?
			foreach( team in level.teams )
			{
				game["icons"][team] = "composite_emblem_team_axis";
			}
			
			game["icons"]["allies"] = "composite_emblem_team_allies";
			game["icons"]["axis"] = "composite_emblem_team_axis";
		}
	}
	else
	{
			if ( !level.splitscreen )
				level.prematchPeriod = GetGametypeSetting( "preroundperiod" );
	}

	DEFAULT( game["timepassed"], 0 );
	DEFAULT( game["playabletimepassed"], 0 );
	DEFAULT( game["roundsplayed"], 0 );
	
	SetRoundsPlayed( game["roundsplayed"] );
	
	if ( isdefined( game["overtime_round"] ) )
	{
		SetRoundsPlayed( game["roundsplayed"] + game["overtime_round"] - 1 );
		SetMatchFlag( "overtime", 1 );
	}
	else
	{
		SetMatchFlag( "overtime", 0 );
	}
	
	if(!isdefined(game["roundwinner"] ))
		game["roundwinner"] = [];

	if(!isdefined(game["lastroundscore"] ))
		game["lastroundscore"] = [];

	if(!isdefined(game["roundswon"] ))
		game["roundswon"] = [];

	if(!isdefined(game["roundswon"]["tie"] ))
		game["roundswon"]["tie"] = 0;

	if(!isdefined(game["overtimeroundswon"] ))
		game["overtimeroundswon"] = [];

	if(!isdefined(game["overtimeroundswon"]["tie"] ))
		game["overtimeroundswon"]["tie"] = 0;

	foreach ( team in level.teams )
	{
		if(!isdefined(game["roundswon"][team] ))
			game["roundswon"][team] = 0;
		if(!isdefined(game["overtimeroundswon"][team] ))
			game["overtimeroundswon"][team] = 0;

		level.teamSpawnPoints[team] = [];
		level.spawn_point_team_class_names[team] = [];
	}

	level.skipVote = false;
	level.gameEnded = false;
	level.exitLevel = false;
	//level clientfield::set( "game_ended", 0 );
	SetDvar( "g_gameEnded", 0 );

	level.objIDStart = 0;
	level.forcedEnd = false;
	level.hostForcedEnd = false;

	level.hardcoreMode = GetGametypeSetting( "hardcoreMode" );
	if ( level.hardcoreMode )
	{
		/#print( "game mode: hardcore" );#/
		
		//set up friendly fire delay for hardcore
		if( !isdefined(level.friendlyFireDelayTime) )
			level.friendlyFireDelayTime = 0;
	}

	if ( GetDvarString( "scr_max_rank" ) == "" )
			SetDvar( "scr_max_rank", "0" );
	level.rankCap = GetDvarint( "scr_max_rank" );
	
	if ( GetDvarString( "scr_min_prestige" ) == "" )
	{
		SetDvar( "scr_min_prestige", "0" );
	}
	level.minPrestige = GetDvarint( "scr_min_prestige" );

	// this gets set to false when someone takes damage or a gametype-specific event happens.
	level.useStartSpawns = true;
	level.alwaysUseStartSpawns = false;
	level.useXCamsForEndGame = true;
	
	level.cumulativeRoundScores = GetGametypeSetting( "cumulativeRoundScores" );

	level.allowHitMarkers = GetGametypeSetting( "allowhitmarkers" );
	level.playerQueuedRespawn = GetGametypeSetting( "playerQueuedRespawn" );
	level.playerForceRespawn = GetGametypeSetting( "playerForceRespawn" );

	level.roundStartExplosiveDelay = GetGametypeSetting( "roundStartExplosiveDelay" );
	level.roundStartKillstreakDelay = GetGametypeSetting( "roundStartKillstreakDelay" );
	
	level.perksEnabled = GetGametypeSetting( "perksEnabled" );
	level.disableAttachments = GetGametypeSetting( "disableAttachments" );
	level.disableTacInsert = GetGametypeSetting( "disableTacInsert" );
	level.disableCAC = GetGametypeSetting( "disableCAC" );
	level.disableClassSelection = GetGametypeSetting( "disableClassSelection" );
	level.disableWeaponDrop = GetGametypeSetting( "disableweapondrop" );
	level.onlyHeadShots = GetGametypeSetting( "onlyHeadshots" );
	
	// set to 0 to disable
	level.minimumAllowedTeamKills = GetGametypeSetting( "teamKillPunishCount" ) - 1;
	level.teamKillReducedPenalty = GetGametypeSetting( "teamKillReducedPenalty" );
	level.teamKillPointLoss = GetGametypeSetting( "teamKillPointLoss" );
	level.teamKillSpawnDelay = GetGametypeSetting( "teamKillSpawnDelay" );
	
	level.deathPointLoss = GetGametypeSetting( "deathPointLoss" );
	level.leaderBonus = GetGametypeSetting( "leaderBonus" );
	level.forceRadar = GetGametypeSetting( "forceRadar" );
	level.playerSprintTime = GetGametypeSetting( "playerSprintTime" );
	level.bulletDamageScalar = GetGametypeSetting( "bulletDamageScalar" );
	
	level.playerMaxHealth = GetGametypeSetting( "playerMaxHealth" );
	level.playerHealthRegenTime = GetGametypeSetting( "playerHealthRegenTime" );
	level.scoreResetOnDeath = GetGametypeSetting( "scoreResetOnDeath" );
	
	level.playerRespawnDelay = GetGametypeSetting( "playerRespawnDelay" );
	level.playerIncrementalRespawnDelay = GetGametypeSetting( "incrementalSpawnDelay" );
		
	level.playerObjectiveHeldRespawnDelay = GetGametypeSetting( "playerObjectiveHeldRespawnDelay" );
	level.waveRespawnDelay = GetGametypeSetting( "waveRespawnDelay" );
	level.suicideSpawnDelay = GetGametypeSetting( "spawnsuicidepenalty" );
	level.teamKilledSpawnDelay = GetGametypeSetting( "spawnteamkilledpenalty" );
	level.maxSuicidesBeforeKick = GetGametypeSetting( "maxsuicidesbeforekick" );
	
	level.spectateType = GetGametypeSetting( "spectateType" );
	
	level.voip = SpawnStruct();
	level.voip.deadChatWithDead = GetGametypeSetting( "voipDeadChatWithDead" );
	level.voip.deadChatWithTeam = GetGametypeSetting( "voipDeadChatWithTeam" );
	level.voip.deadHearAllLiving = GetGametypeSetting( "voipDeadHearAllLiving" );
	level.voip.deadHearTeamLiving = GetGametypeSetting( "voipDeadHearTeamLiving" );
	level.voip.everyoneHearsEveryone = GetGametypeSetting( "voipEveryoneHearsEveryone" );
	level.voip.deadHearKiller = GetGametypeSetting( "voipDeadHearKiller" );
	level.voip.killersHearVictim = GetGametypeSetting( "voipKillersHearVictim" );
	
	level.droppedTagRespawn = GetGametypeSetting( "droppedTagRespawn" );

	if( IS_TRUE( level.droppedTagRespawn ) )
		dogtags::init();

	// this will clear out any non game mode entities before the gametype callbacks happen
	gameobjects::main();

	callback::callback( #"on_start_gametype" );
		
	thread hud_message::init();

	foreach( team in level.teams )
	{
		initTeamVariables( team );
	}
	
	if ( !level.teambased )
	{
		initTeamVariables( "free" );
	}
	
	level.maxPlayerCount = 0;
	level.activePlayers = [];

	level.aliveTimeMaxCount = 3;
	level.aliveTimesAverage = [];
	foreach( team in level.teams )
	{
		level.aliveTimesAverage[team] = 0;
	}
	
	if( !isdefined( level.livesDoNotReset ) || !level.livesDoNotReset )
	{
		foreach( team in level.teams )
		{
			game[team+"_lives"] = level.numTeamLives;
		}
	}	

	level.allowAnnouncer = GetGametypeSetting( "allowAnnouncer" );

	if ( !isdefined( level.timeLimit ) )
		util::registerTimeLimit( 1, 1440 );
		
	if ( !isdefined( level.scoreLimit ) )
		util::registerScoreLimit( 1, 500 );

	if ( !isdefined( level.roundScoreLimit ) )
		util::registerRoundScoreLimit( 0, 500 );

	if ( !isdefined( level.roundLimit ) )
		util::registerRoundLimit( 0, 10 );

	if ( !isdefined( level.roundWinLimit ) )
		util::registerRoundWinLimit( 0, 10 );
	
	// The order the following functions are registered in are the order they will get called
	globallogic_utils::registerPostRoundEvent( &killcam::post_round_final_killcam );	

	//makeDvarServerInfo( "ui_scorelimit" );
	//makeDvarServerInfo( "ui_timelimit" );
	//makeDvarServerInfo( "ui_allow_classchange", GetDvarString( "ui_allow_classchange" ) );

	waveDelay = level.waveRespawnDelay;
	if ( waveDelay )
	{
		foreach ( team in level.teams )
		{
			level.waveDelay[team] = waveDelay;
			level.lastWave[team] = 0;
		}
		
		level thread [[level.waveSpawnTimer]]();
	}
	
	level.inPrematchPeriod = true;
	
	if ( level.prematchPeriod > 2.0 && level.rankedMatch )
		level.prematchPeriod = level.prematchPeriod + (randomFloat( 4 ) - 2); // live host obfuscation

	if ( level.numLives || anyTeamHasWaveDelay() || level.playerQueuedRespawn )
		level.gracePeriod = 15;
	else
		level.gracePeriod = 5;
		
	level.inGracePeriod = true;
	
	level.roundEndDelay = 5;
	level.halftimeRoundEndDelay = 3;
	
	globallogic_score::updateAllTeamScores();
	
	level.killstreaksenabled = 1;
	level.missileLockPlaySpaceCheckEnabled = true;
	level.missileLockPlaySpaceCheckExtraRadius = 5000;

	if ( GetDvarString( "scr_game_rankenabled" ) == "" )
		SetDvar( "scr_game_rankenabled", true );
	level.rankEnabled = GetDvarint( "scr_game_rankenabled" );
	
	if ( GetDvarString( "scr_game_medalsenabled" ) == "" )
		SetDvar( "scr_game_medalsenabled", true );
	level.medalsEnabled = GetDvarint( "scr_game_medalsenabled" );

	if( level.hardcoreMode && level.rankedMatch && GetDvarString( "scr_game_friendlyFireDelay" ) == "" )
		SetDvar( "scr_game_friendlyFireDelay", true );
	level.friendlyFireDelay = GetDvarint( "scr_game_friendlyFireDelay" );

	// level gametype and features globals should be defaulted before this, and level.onstartgametype should reset them if desired
	[[level.onStartGameType]]();

	// disable killstreaks for custom game modes
	if( GetDvarInt( "custom_killstreak_mode" ) == 1 )
	{
		level.killstreaksenabled = 0;
	}

	level thread killcam::do_final_killcam();

	thread startGame();
	level thread updateGameTypeDvars();
	level thread simple_hostmigration::UpdateHostMigrationData();
}

function registerFriendlyFireDelay( dvarString, defaultValue, minValue, maxValue )
{
	dvarString = ("scr_" + dvarString + "_friendlyFireDelayTime");
	if ( GetDvarString( dvarString ) == "" )
		SetDvar( dvarString, defaultValue );
		
	if ( getDvarInt( dvarString ) > maxValue )
		SetDvar( dvarString, maxValue );
	else if ( getDvarInt( dvarString ) < minValue )
		SetDvar( dvarString, minValue );

	level.friendlyFireDelayTime = getDvarInt( dvarString );
}

function checkRoundSwitch()
{
	if ( !isdefined( level.roundSwitch ) || !level.roundSwitch )
		return false;
	if ( !isdefined( level.onRoundSwitch ) )
		return false;
	
	assert( game["roundsplayed"] > 0 );
	
	if ( game["roundsplayed"] % level.roundswitch == 0 )
	{
		[[level.onRoundSwitch]]();
		return true;
	}
		
	return false;
}


function listenForGameEnd()
{
	self waittill( "host_sucks_end_game" );
	//if ( level.console )
	//	endparty();
	level.skipVote = true;

	if ( !level.gameEnded )
		level thread globallogic::forceEnd(true);
}


function getKillStreaks( player )
{
	for ( killstreakNum = 0; killstreakNum < level.maxKillstreaks; killstreakNum++ )
	{
		killstreak[ killstreakNum ] = "killstreak_null";
	}
	
	if ( isPlayer( player ) &&
		 level.disableClassSelection != 1 &&
		 !isdefined( player.pers["isBot"] ) &&
		 isdefined( player.killstreak) )
	{
		currentKillstreak = 0;
		for ( killstreakNum = 0; killstreakNum < level.maxKillstreaks; killstreakNum++ )
		{
				if ( isdefined( player.killstreak[ killstreakNum ] ) )
				{
					killstreak[ currentKillstreak ] = player.killstreak[ killstreakNum ];
					currentKillstreak++;
				}
		}
	}
	
	return killstreak;
}

function updateRankedMatch(winner)
{
	if ( level.rankedMatch )
	{
		if ( hostIdledOut() )
		{
			level.hostForcedEnd = true;
			/#print( "host idled out" );#/
			endLobby();
		}
	}
	globallogic_score::updateMatchBonusScores( winner );
}


function annihilatorGunPlayerKillEffect( attacker, weapon )
{
	if ( weapon.fusetime != 0 )
		wait( weapon.fusetime * 0.001 );
	else
	 	wait(0.45);
	
	if ( !isdefined( self ) )
	{
		return;
	}
	
	self playsoundtoplayer( "evt_annihilation", attacker );
	self playsoundtoallbutplayer( "evt_annihilation_npc", attacker );
	
	CodeSetClientField(self, "annihilate_effect", 1);
	self shake_and_rumble(0, 0.3, 0.75, 1);
	
	wait 0.1;
	
	if ( !isdefined( self ) )
	{
		return;
	}
	
	self NotSolid();
	self Ghost();
}

function annihilatorGunActorKillEffect( attacker, weapon )
{
	self waittill("actor_corpse",body); //now a corpse!
	
	if ( weapon.fusetime != 0 )
		wait( weapon.fusetime * 0.001 );
	else
	 	wait(0.45);
	
	if ( !isdefined( self ) )
	{
		return;
	}
	
	self playsoundtoplayer( "evt_annihilation", attacker );
	self playsoundtoallbutplayer( "evt_annihilation_npc", attacker );
	
	if ( !isdefined( body ) )
	{
		return;
	}
	
	CodeSetClientField(body, "annihilate_effect", 1);
	body shake_and_rumble(0, 0.6, 0.2, 1);
	body NotSolid();
	body Ghost();
}

function pineappleGunPlayerKillEffect( attacker )
{
	wait 0.1;
	
	if ( !isdefined( self ) )
	{
		return;
	}
	
	playsoundatposition ("evt_annihilation_npc", (self.origin));
	CodeSetClientField(self, "pineapplegun_effect", 1);
	self shake_and_rumble(0, 0.3, 0.35, 1);
	wait 0.1;
	
	if ( !isdefined( self ) )
	{
		return;
	}
	
	self NotSolid();
	self Ghost();
}

function BowPlayerKillEffect()
{
	wait 0.05;
	if ( !isdefined( self ) )
	{
		return;
	}
	
	playsoundatposition ("evt_annihilation_npc", (self.origin));
	CodeSetClientField(self, "annihilate_effect", 1);
	self shake_and_rumble(0, 0.3, 0.35, 1);

	if ( !isdefined( self ) )
	{
		return;
	}
	
	self NotSolid();
	self Ghost();
}

function pineappleGunActorKillEffect()
{
	self waittill("actor_corpse",body); //now a corpse!
	wait(0.75);
	
	if ( !isdefined( self ) )
	{
		return;
	}
	
	playsoundatposition ("evt_annihilation_npc", (self.origin));
	
	if ( !isdefined( body ) )
	{
		return;
	}
	
	CodeSetClientField(body, "pineapplegun_effect", 1);
	body shake_and_rumble(0, 0.3, 0.75, 1);
	body NotSolid();
	body Ghost();
}

// ============================================================================
// self = player
function shake_and_rumble( n_delay, shake_size, shake_time, rumble_num )
{
	if( IsDefined(n_delay) && (n_delay > 0) )
	{
		wait( n_delay );
	}

	// Earthquake
	nMagnitude = shake_size;
	nduration = shake_time;
	nRadius = 500;
	v_pos = self.origin;
	Earthquake( nMagnitude, nDuration, v_pos, nRadius );

	// Pad Rumble
	for( i=0; i<rumble_num; i++ )
	{
		self PlayRumbleOnEntity( "damage_heavy" );
		wait( 0.1 );
	}
}

function DoWeaponSpecificKillEffects(eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime)
{
	if( weapon.name=="hero_pineapplegun" && isPlayer( attacker ) && sMeansOfDeath == "MOD_GRENADE" ) 
	{
		attacker playLocalSound( "wpn_pineapple_grenade_explode_flesh_2D" );
	}
}

#define ANNIHILATE_PUSH_SCALE 	100
#define ANNIHILATE_UPPUSH_SCALE	25
function DoWeaponSpecificCorpseEffects(body, eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime)
{
	if ( weapon.doannihilate&& isPlayer( attacker ) && ( sMeansOfDeath == "MOD_IMPACT" || sMeansOfDeath == "MOD_GRENADE" ) ) //this does the annihilation effect and launches ragdoll
	{
		if (IsActor(body))
		{
			body thread annihilatorGunActorKillEffect( attacker, weapon );
		}
		else
		{
			body thread annihilatorGunPlayerKillEffect( attacker, weapon );
		}
	}
	else if( sMeansOfDeath == "MOD_BURNED" )
	{
		if( !IsActor(body) )
		{
			body thread BurnCorpse();
		}
	}
	else if( weapon.isheroweapon == 1  && isPlayer( attacker ) )
	{
		/*if (weapon.name == "hero_pineapplegun" && sMeansOfDeath == "MOD_GRENADE") //this does an annilhation effect and launches ragdoll
		{
			//modify the launch direction to give it some up vector - John Woo style
			newVector = ((0,0,1)*ANNIHILATE_UPPUSH_SCALE) + (vDir * ANNIHILATE_PUSH_SCALE);
			body LaunchRagdoll( newVector, sHitLoc);
			if (IsActor(body))
			{
				body thread pineappleGunActorKillEffect();
			}
			else
			{
				body thread pineappleGunPlayerKillEffect();
			}
		}
		*/
		if ( weapon.name == "hero_firefly_swarm" )
		{
			value = RandomInt(2) + 1;
			if( !IsActor(body) )
			{
				CodeSetClientField(body, "firefly_effect", value);
			}
		}
	}
}

#define CORPSE_BURN_DURATION 3
function BurnCorpse()
{
	self endon( "death" );
	CodeSetClientField( self, "burned_effect", 1 );
	wait( CORPSE_BURN_DURATION );
	CodeSetClientField( self, "burned_effect", 0 );
}
