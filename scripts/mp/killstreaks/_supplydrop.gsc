#using scripts\codescripts\struct;
#using scripts\shared\callbacks_shared;
#using scripts\shared\challenges_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\entityheadicons_shared;
#using scripts\shared\gameobjects_shared;
#using scripts\shared\hostmigration_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\killstreaks_shared;
#using scripts\shared\popups_shared;
#using scripts\shared\scoreevents_shared;
#using scripts\shared\sound_shared;
#using scripts\shared\util_shared;
#using scripts\shared\weapons\_hacker_tool;
#using scripts\shared\weapons\_smokegrenade;
#using scripts\shared\weapons\_tacticalinsertion;
#using scripts\shared\weapons\_weapons;
#using scripts\shared\weapons\_heatseekingmissile;
#using scripts\shared\weapons\_weaponobjects;
#using scripts\shared\vehicleriders_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\flagsys_shared;
#using scripts\mp\_challenges;
#using scripts\mp\_util;
#using scripts\mp\gametypes\_battlechatter;
#using scripts\mp\gametypes\_hostmigration;
#using scripts\mp\killstreaks\_ai_tank;
#using scripts\mp\killstreaks\_airsupport;
#using scripts\mp\killstreaks\_emp;
#using scripts\mp\killstreaks\_helicopter;
#using scripts\mp\killstreaks\_killstreak_bundles;
#using scripts\mp\killstreaks\_killstreak_detect;
#using scripts\mp\killstreaks\_killstreak_hacking;
#using scripts\mp\killstreaks\_killstreak_weapons;
#using scripts\mp\killstreaks\_killstreakrules;
#using scripts\mp\killstreaks\_killstreaks;
#using scripts\mp\killstreaks\_supplydrop;
#using scripts\mp\killstreaks\_combat_robot;

#insert scripts\mp\_hacker_tool.gsh;
#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;
#insert scripts\mp\killstreaks\_killstreaks.gsh;

#define SUPPLY_DROP_NAME "supply_drop"
#define SUPPLY_DROP_AI_TANK_NAME "supply_drop_ai_tank"
#define SUPPLY_DROP_COMBAT_ROBOT_NAME "supply_drop_combat_robot"

#define SUPPY_DROP_ON_TARGET_DISTANCE					3.7
#define SUPPY_DROP_NAV_MESH_VALID_LOCATION_BOUNDARY		12
#define SUPPY_DROP_NAV_MESH_VALID_LOCATION_TOLERANCE	4

#define SUPPLY_DROP_CRATE_STATE_NONE		0
#define SUPPLY_DROP_CRATE_STATE_CAPTURE		1
#define SUPPLY_DROP_CRATE_STATE_HACK		2
#define SUPPLY_DROP_CRATE_STATE_DISARM		3


#precache( "material", "compass_supply_drop_black" );
#precache( "material", "compass_supply_drop_green" );
#precache( "material", "compass_supply_drop_red" );
#precache( "material", "compass_supply_drop_white" );
#precache( "material", "waypoint_recon_artillery_strike" );
#precache( "material", "t7_hud_ks_wpn_turret_drop" );
#precache( "material", "t7_hud_ks_rolling_thunder_drop" );
#precache( "material", "t7_hud_ks_drone_amws_drop" );


// TODO: this is a placeholder head icon for when a supply drop is hacked and a booby trap is made
#precache( "material","headicon_dead");
#precache( "string", "KILLSTREAK_CAPTURING_CRATE" );
#precache( "string", "KILLSTREAK_HACKING_CRATE" );
#precache( "string", "KILLSTREAK_SUPPLY_DROP_DISARM_HINT" );
#precache( "triggerstring", "KILLSTREAK_SUPPLY_DROP_DISARM_HINT" );
#precache( "string", "KILLSTREAK_SUPPLY_DROP_DISARMING_CRATE" );
#precache( "string", "KILLSTREAK_SUPPLY_DROP_HACKED" );

#precache( "triggerstring", "KILLSTREAK_AI_TANK_CRATE" );
#precache( "triggerstring", "KILLSTREAK_MINIGUN_CRATE" );
#precache( "triggerstring", "PLATFORM_MINIGUN_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_M32_CRATE" );
#precache( "triggerstring", "PLATFORM_M32_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_AMMO_CRATE" );
#precache( "triggerstring", "PLATFORM_AMMO_CRATE_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_RADAR_CRATE" );
#precache( "triggerstring", "PLATFORM_RADAR_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_RCBOMB_CRATE" );
#precache( "triggerstring", "PLATFORM_RCBOMB_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_MISSILE_DRONE_CRATE" );
#precache( "triggerstring", "PLATFORM_MISSILE_DRONE_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_COUNTERU2_CRATE" );
#precache( "triggerstring", "PLATFORM_COUNTERU2_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_REMOTE_MISSILE_CRATE" );
#precache( "triggerstring", "PLATFORM_REMOTE_MISSILE_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_PLANE_MORTAR_CRATE");
#precache( "triggerstring", "PLATFORM_PLANE_MORTAR_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_AUTO_TURRET_CRATE" );
#precache( "triggerstring", "PLATFORM_AUTO_TURRET_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_MICROWAVE_TURRET_CRATE" );
#precache( "triggerstring", "PLATFORM_MICROWAVE_TURRET_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_MINIGUN_CRATE" );
#precache( "triggerstring", "PLATFORM_MINIGUN_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_M32_CRATE" );
#precache( "triggerstring", "PLATFORM_M32_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_HELICOPTER_GUARD_CRATE" );
#precache( "triggerstring", "PLATFORM_HELICOPTER_GUARD_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_SATELLITE_CRATE" );
#precache( "triggerstring", "PLATFORM_SATELLITE_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_QRDRONE_CRATE" );
#precache( "triggerstring", "PLATFORM_QRDRONE_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_AI_TANK_CRATE" );
#precache( "triggerstring", "PLATFORM_AI_TANK_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_HELICOPTER_CRATE" );
#precache( "triggerstring", "PLATFORM_HELICOPTER_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_EMP_CRATE" );
#precache( "triggerstring", "PLATFORM_EMP_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_RAPS_CRATE" );
#precache( "triggerstring", "PLATFORM_RAPS_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_DART_CRATE" );
#precache( "triggerstring", "PLATFORM_DART_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_SENTINEL_CRATE" );
#precache( "triggerstring", "PLATFORM_SENTINEL_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_COMBAT_ROBOT_CRATE" );
#precache( "triggerstring", "PLATFORM_COMBAT_ROBOT_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_REMOTE_MORTAR_CRATE" );
#precache( "triggerstring", "PLATFORM_REMOTE_MORTAR_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_HELICOPTER_GUNNER_CRATE" );
#precache( "triggerstring", "PLATFORM_HELICOPTER_GUNNER_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_DOGS_CRATE" );
#precache( "triggerstring", "PLATFORM_DOGS_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_MISSILE_SWARM_CRATE" );
#precache( "triggerstring", "PLATFORM_MISSILE_SWARM_GAMBLER" );
#precache( "triggerstring", "KILLSTREAK_EARNED_SUPPLY_DROP" );
#precache( "triggerstring", "KILLSTREAK_DRONE_STRIKE_CRATE" );
#precache( "triggerstring", "PLATFORM_DRONE_STRIKE_GAMBLER" );
#precache( "triggerstring", "PLATFORM_AI_TANK_CRATE_GAMBLER" ); 

#precache( "string", "KILLSTREAK_AIRSPACE_FULL" );
#precache( "string", "KILLSTREAK_SUPPLY_DROP_INBOUND" );
#precache( "string", "FriendlyBlue" );
#precache( "string", "EnemyOrange" );
#precache( "eventstring", "mpl_killstreak_supply" );
#precache( "fx", "killstreaks/fx_supply_drop_smoke" );
#precache( "fx", "explosions/fx_exp_grenade_default" );

#using_animtree ( "mp_vehicles" );

#namespace supplydrop;

function init()
{
	level.crateModelFriendly = "wpn_t7_care_package_world";
	level.crateModelEnemy = "wpn_t7_care_package_world";	
	level.crateModelTank = "wpn_t7_drop_box";
	level.crateModelBoobyTrapped = "wpn_t7_care_package_world";
	level.vtolDropHelicopterVehicleInfo = "vtol_supplydrop_mp";
	
	level.crateOwnerUseTime = 500;
	level.crateNonOwnerUseTime = GetGametypeSetting("crateCaptureTime") * 1000;
	level.crate_headicon_offset = (0, 0, 15);
	level.supplyDropDisarmCrate = &"KILLSTREAK_SUPPLY_DROP_DISARM_HINT";
	level.disarmingCrate = &"KILLSTREAK_SUPPLY_DROP_DISARMING_CRATE";
	
	level.supplydropCarePackageIdleAnim = %o_drone_supply_care_idle;
	level.supplydropCarePackageDropAnim = %o_drone_supply_care_drop;
	level.supplydropAiTankIdleAnim = %o_drone_supply_agr_idle;
	level.supplydropAiTankDropAnim = %o_drone_supply_agr_drop;
		
	clientfield::register( "helicopter", "supplydrop_care_package_state", VERSION_SHIP, 1, "int" );
	clientfield::register( "helicopter", "supplydrop_ai_tank_state", VERSION_SHIP, 1, "int" );

	clientfield::register( "vehicle", "supplydrop_care_package_state", VERSION_SHIP, 1, "int" );
	clientfield::register( "vehicle", "supplydrop_ai_tank_state", VERSION_SHIP, 1, "int" );
	
	clientfield::register( "scriptmover", "supplydrop_thrusters_state", VERSION_SHIP, 1, "int" );	
	clientfield::register( "scriptmover", "aitank_thrusters_state", VERSION_SHIP, 1, "int" );	
	
	clientfield::register( "toplayer", "marker_state", VERSION_SHIP, 2, "int" );
	
	level._supply_drop_smoke_fx = "killstreaks/fx_supply_drop_smoke";
	level._supply_drop_explosion_fx = "explosions/fx_exp_grenade_default";

	killstreaks::register( SUPPLY_DROP_NAME, "supplydrop_marker", "killstreak_supply_drop", "supply_drop_used",&useKillstreakSupplyDrop, undefined, true );
	killstreaks::register_strings(SUPPLY_DROP_NAME, &"KILLSTREAK_EARNED_SUPPLY_DROP", &"KILLSTREAK_AIRSPACE_FULL", &"KILLSTREAK_SUPPLY_DROP_INBOUND", undefined, &"KILLSTREAK_SUPPLY_DROP_HACKED" );
	killstreaks::register_dialog(SUPPLY_DROP_NAME, "mpl_killstreak_supply", "supplyDropDialogBundle", "supplyDropPilotDialogBundle", "friendlySupplyDrop", "enemySupplyDrop", "enemySupplyDropMultiple", "friendlySupplyDropHacked", "enemySupplyDropHacked", "requestSupplyDrop", "threatSupplyDrop" );
	killstreaks::register_alt_weapon(SUPPLY_DROP_NAME, "mp40_blinged" );
	killstreaks::register_alt_weapon(SUPPLY_DROP_NAME, "supplydrop" );
	killstreaks::allow_assists(SUPPLY_DROP_NAME, true);
	
	killstreak_bundles::register_killstreak_bundle( "supply_drop_ai_tank" ); // only registering for damage processing only, to limit scope of change
	killstreak_bundles::register_killstreak_bundle( "supply_drop_combat_robot" ); // only registering for damage processing only, to limit scope of change

	level.crateTypes = [];
	level.categoryTypeWeight = [];

	// percentage of drop explanation:
	//		add all of the numbers up: 15 + 2 + 3 + etc. = 80 for example
	//		now if you want to know the percentage of the minigun_mp drop, you'd do (minigun_mp number / total) or 2/80 = 2.5% chance of dropping
	// right now this is at a perfect 1000, so the percentages are easy to understand
	//registerCrateType( "supplydrop", "ammo", "ammo", 0, &"KILLSTREAK_AMMO_CRATE", &"PLATFORM_AMMO_CRATE_GAMBLER",&giveCrateAmmo );
	registerCrateType( "supplydrop", "killstreak", "uav", 125, &"KILLSTREAK_RADAR_CRATE", &"PLATFORM_RADAR_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "rcbomb", 105, &"KILLSTREAK_RCBOMB_CRATE", &"PLATFORM_RCBOMB_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "counteruav", 115, &"KILLSTREAK_COUNTERU2_CRATE", &"PLATFORM_COUNTERU2_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "remote_missile", 90, &"KILLSTREAK_REMOTE_MISSILE_CRATE", &"PLATFORM_REMOTE_MISSILE_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "planemortar", 80, &"KILLSTREAK_PLANE_MORTAR_CRATE", &"PLATFORM_PLANE_MORTAR_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "autoturret", 90, &"KILLSTREAK_AUTO_TURRET_CRATE", &"PLATFORM_AUTO_TURRET_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "microwave_turret", 120, &"KILLSTREAK_MICROWAVE_TURRET_CRATE", &"PLATFORM_MICROWAVE_TURRET_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "satellite", 20, &"KILLSTREAK_SATELLITE_CRATE", &"PLATFORM_SATELLITE_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "drone_strike", 75, &"KILLSTREAK_DRONE_STRIKE_CRATE", &"PLATFORM_DRONE_STRIKE_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "helicopter_comlink", 30, &"KILLSTREAK_HELICOPTER_CRATE", &"PLATFORM_HELICOPTER_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "emp", 5, &"KILLSTREAK_EMP_CRATE", &"PLATFORM_EMP_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "raps", 20, &"KILLSTREAK_RAPS_CRATE", &"PLATFORM_RAPS_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "dart", 75, &"KILLSTREAK_DART_CRATE", &"PLATFORM_DART_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "sentinel", 20, &"KILLSTREAK_SENTINEL_CRATE", &"PLATFORM_SENTINEL_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "combat_robot", 5, &"KILLSTREAK_COMBAT_ROBOT_CRATE", &"PLATFORM_COMBAT_ROBOT_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "supplydrop", "killstreak", "ai_tank_drop", 25, &"KILLSTREAK_AI_TANK_CRATE", &"PLATFORM_AI_TANK_CRATE_GAMBLER", &giveCrateKillstreak );
	
	registerCrateType( "inventory_supplydrop", "killstreak", "uav", 125, &"KILLSTREAK_RADAR_CRATE", &"PLATFORM_RADAR_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "counteruav", 115, &"KILLSTREAK_COUNTERU2_CRATE", &"PLATFORM_COUNTERU2_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "rcbomb", 105, &"KILLSTREAK_RCBOMB_CRATE", &"PLATFORM_RCBOMB_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "remote_missile", 90, &"KILLSTREAK_REMOTE_MISSILE_CRATE", &"PLATFORM_REMOTE_MISSILE_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "planemortar", 80, &"KILLSTREAK_PLANE_MORTAR_CRATE", &"PLATFORM_PLANE_MORTAR_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "autoturret", 90, &"KILLSTREAK_AUTO_TURRET_CRATE", &"PLATFORM_AUTO_TURRET_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "microwave_turret", 120, &"KILLSTREAK_MICROWAVE_TURRET_CRATE", &"PLATFORM_MICROWAVE_TURRET_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "satellite", 20, &"KILLSTREAK_SATELLITE_CRATE", &"PLATFORM_SATELLITE_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "helicopter_comlink", 30, &"KILLSTREAK_HELICOPTER_CRATE", &"PLATFORM_HELICOPTER_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "emp", 5, &"KILLSTREAK_EMP_CRATE", &"PLATFORM_EMP_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "raps", 20, &"KILLSTREAK_RAPS_CRATE", &"PLATFORM_RAPS_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "dart", 75, &"KILLSTREAK_DART_CRATE", &"PLATFORM_DART_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "sentinel", 20, &"KILLSTREAK_SENTINEL_CRATE", &"PLATFORM_SENTINEL_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "combat_robot", 5, &"KILLSTREAK_COMBAT_ROBOT_CRATE", &"PLATFORM_COMBAT_ROBOT_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "ai_tank_drop", 25, &"KILLSTREAK_AI_TANK_CRATE", &"PLATFORM_AI_TANK_CRATE_GAMBLER", &giveCrateKillstreak );
	registerCrateType( "inventory_supplydrop", "killstreak", "drone_strike", 75, &"KILLSTREAK_DRONE_STRIKE_CRATE", &"PLATFORM_DRONE_STRIKE_GAMBLER", &giveCrateKillstreak );

	registerCrateType( "inventory_ai_tank_drop", "killstreak", "ai_tank_drop", 75, &"KILLSTREAK_AI_TANK_CRATE", undefined, undefined, &ai_tank::crateLand );
	registerCrateType( "ai_tank_drop", "killstreak", "ai_tank_drop", 75, &"KILLSTREAK_AI_TANK_CRATE", undefined, undefined, &ai_tank::crateLand );
	
	// for the gambler perk, have its own crate types with a greater chance to get good stuff
	// right now this is at a perfect 1000, so the percentages are easy to understand
	//registerCrateType( "gambler", "ammo", "ammo", 0, &"KILLSTREAK_AMMO_CRATE", undefined, &giveCrateAmmo );
	registerCrateType( "gambler", "killstreak", "uav", 95, &"KILLSTREAK_RADAR_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "counteruav", 85, &"KILLSTREAK_COUNTERU2_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "rcbomb", 75, &"KILLSTREAK_RCBOMB_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "microwave_turret", 110, &"KILLSTREAK_MICROWAVE_TURRET_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "remote_missile", 100, &"KILLSTREAK_REMOTE_MISSILE_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "planemortar", 80, &"KILLSTREAK_PLANE_MORTAR_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "autoturret", 100, &"KILLSTREAK_AUTO_TURRET_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "satellite", 30, &"KILLSTREAK_SATELLITE_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "ai_tank_drop", 40, &"KILLSTREAK_AI_TANK_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "helicopter_comlink", 45, &"KILLSTREAK_HELICOPTER_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "emp", 10, &"KILLSTREAK_EMP_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "raps", 35, &"KILLSTREAK_RAPS_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "dart", 75, &"KILLSTREAK_DART_CRATE", undefined, &giveCrateKillstreak );		
	registerCrateType( "gambler", "killstreak", "sentinel", 35, &"KILLSTREAK_SENTINEL_CRATE", undefined, &giveCrateKillstreak );		
	registerCrateType( "gambler", "killstreak", "combat_robot", 10, &"KILLSTREAK_COMBAT_ROBOT_CRATE", undefined, &giveCrateKillstreak );
	registerCrateType( "gambler", "killstreak", "drone_strike", 75, &"KILLSTREAK_DRONE_STRIKE_CRATE", undefined, &giveCrateKillstreak );			
	
	level.crateCategoryWeights = [];
	level.crateCategoryTypeWeights = [];
	
	foreach( categoryKey, category in level.crateTypes )
	{
		finalizeCrateCategory( categoryKey );
	}
}

function finalizeCrateCategory( category )
{
	level.crateCategoryWeights[category] = 0;

	crateTypeKeys = getarraykeys( level.crateTypes[category] );
	
	// must leave this as a for loop not a foreach loop
	// it must match the loop in getRandomCrateType
	for ( crateType = 0; crateType < crateTypeKeys.size; crateType++ )
	{
		typeKey = crateTypeKeys[crateType];
		level.crateTypes[category][typeKey].previousWeight = level.crateCategoryWeights[category];
		level.crateCategoryWeights[category] += level.crateTypes[category][typeKey].weight;
		level.crateTypes[category][typeKey].weight = level.crateCategoryWeights[category];
	}
}

function advancedFinalizeCrateCategory( category )
{
	level.crateCategoryTypeWeights[category] = 0;
	crateTypeKeys = getarraykeys( level.categoryTypeWeight[category] );
	
	// must leave this as a for loop not a foreach loop
	// it must match the loop in getRandomCrateType
	for ( crateType = 0; crateType < crateTypeKeys.size; crateType++ )
	{
		typeKey = crateTypeKeys[crateType];
		level.crateCategoryTypeWeights[category] += level.categoryTypeWeight[category][typeKey].weight;
		level.categoryTypeWeight[category][typeKey].weight = level.crateCategoryTypeWeights[category];
	}
	
	finalizeCrateCategory( category );
}

function setCategoryTypeWeight( category, type, weight )
{
	if ( !isdefined(level.categoryTypeWeight[category]) )
	{
		level.categoryTypeWeight[category] = [];
	}
	
	level.categoryTypeWeight[category][type] = SpawnStruct();
	
	level.categoryTypeWeight[category][type].weight = weight;
	
	count = 0;
	totalWeight = 0;
	startIndex = undefined;
	finalIndex = undefined;
	
	crateNameKeys = getarraykeys( level.crateTypes[category] );
	
	// must leave this as a for loop not a foreach loop
	// it must match the loop in getRandomCrateType
	for ( crateName = 0; crateName < crateNameKeys.size; crateName++ )
	{
		nameKey = crateNameKeys[crateName];

		if ( level.crateTypes[category][nameKey].type == type )
		{
			count++;
			totalWeight = totalWeight + level.crateTypes[category][nameKey].weight;
			
			if ( !isdefined( startIndex ) )
			{
				startIndex = crateName;
			}
			
			if ( isdefined( finalIndex ) && (( finalIndex + 1 ) != crateName ) )
			{
				/#println("Crate type declaration must be contiguous");#/
				callback::abort_level();
				
				return;
			}
			
			finalIndex = crateName;
		} 
	}
	
	level.categoryTypeWeight[category][type].totalCrateWeight = totalWeight; 
	level.categoryTypeWeight[category][type].crateCount = count;
	level.categoryTypeWeight[category][type].startIndex = startIndex;
	level.categoryTypeWeight[category][type].finalIndex = finalIndex;
}

function registerCrateType( category, type, name, weight, hint, hint_gambler, giveFunction, landFunctionOverride )
{
	itemName = level.killstreaks[name].menuName;
		
	if( IsItemRestricted( itemName ) )
		return;
		
	if ( !isdefined(level.crateTypes[category]) )
	{
		level.crateTypes[category] = [];
	}
	
	crateType = SpawnStruct();
	crateType.type = type;
	crateType.name = name;
	crateType.weight = weight;
	crateType.hint = hint;
	crateType.hint_gambler = hint_gambler;
	crateType.giveFunction = giveFunction;
	crateWeapon = killstreaks::get_killstreak_weapon( name );
	if( isdefined(crateWeapon) )
	{
		crateType.objective = GetCrateHeadObjective( crateWeapon );
	}
	if ( isdefined( landFunctionOverride ) )
	{
		crateType.landFunctionOverride = landFunctionOverride;
	}
	
	level.crateTypes[category][name] = crateType;
	
	game["strings"][name + "_hint"] = hint;
}

function getRandomCrateType( category, gambler_crate_name )
{
	if( !isdefined(level.crateTypes) || !isdefined(level.crateTypes[category]) ) 
		return;
	
	Assert( isdefined(level.crateTypes) );
	Assert( isdefined(level.crateTypes[category]) );
	Assert( isdefined(level.crateCategoryWeights[category]) );

	typeKey = undefined;
	crateTypeStart = 0;	
	randomWeightEnd = RandomIntRange( 1, level.crateCategoryWeights[category] + 1 );
	find_another = false;

	crateNameKeys = getarraykeys( level.crateTypes[category] );

	if ( isdefined( level.categoryTypeWeight[category] ) )
	{
		randomWeightEnd = RandomInt(level.crateCategoryTypeWeights[category] ) + 1;
		crateTypeKeys = getarraykeys( level.categoryTypeWeight[category] );
		
		for ( crateType = 0; crateType < crateTypeKeys.size; crateType++ )
		{
			typeKey = crateTypeKeys[crateType];
			
			if ( level.categoryTypeWeight[category][typeKey].weight < randomWeightEnd )
				continue;
				
			crateTypeStart = level.categoryTypeWeight[category][typeKey].startIndex;
			randomWeightEnd = RandomInt( level.categoryTypeWeight[category][typeKey].totalCrateWeight) + 1;
			randomWeightEnd += level.crateTypes[category][crateNameKeys[crateTypeStart]].previousWeight;
			break;
		}
	}
	
	for ( crateType = crateTypeStart; crateType < crateNameKeys.size; crateType++ )
	{
		typeKey = crateNameKeys[crateType];
		
		if ( level.crateTypes[category][typeKey].weight < randomWeightEnd )
			continue;
		
		// if we have the gambler perk then make sure we aren't getting the same thing again
		if( isdefined( gambler_crate_name ) && level.crateTypes[category][typeKey].name == gambler_crate_name )
		{
			find_another = true;
		}

		// go find another crate
		if( find_another )
		{
			if( crateType < crateNameKeys.size - 1 )
			{
				crateType++;
			}
			else if( crateType > 0 )
			{
				crateType--;
			}
			typeKey = crateNameKeys[crateType];
		}

		break;
	}

	return level.crateTypes[category][typeKey];
}

function giveCrateItem( crate )
{
	if ( !IsAlive( self ) || !isdefined( crate.crateType ) )
		return;
		
	Assert( isdefined(crate.crateType.giveFunction), "no give function defined for " + crate.crateType.name );
	
	return [[crate.crateType.giveFunction]]( "inventory_" + crate.crateType.name );
}

function giveCrateKillstreakWaiter( event, removeCrate, extraEndon )
{
	self endon( "give_crate_killstreak_done" );
	if ( isdefined( extraEndon ) )
	{
		self endon( extraEndon );
	}
	self waittill( event );
	self notify( "give_crate_killstreak_done", removeCrate );
}

function giveCrateKillstreak( killstreak )
{
	self killstreaks::give( killstreak );
}

function giveSpecializedCrateWeapon( weapon )
{
	switch ( weapon.name )
	{
	case "minigun":
		level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_MINIGUN_INBOUND", self );
		level weapons::add_limited_weapon( weapon, self, 3 );
		break;
	case "m32":
		level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_M32_INBOUND", self );
		level weapons::add_limited_weapon( weapon, self, 3 );
		break;
	case "m202_flash":
		level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_M202_FLASH_INBOUND", self );
		level weapons::add_limited_weapon( weapon, self, 3 );
		break;
	case "m220_tow":
		level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_M220_TOW_INBOUND", self );
		level weapons::add_limited_weapon( weapon, self, 3 );
		break;
	case "mp40_blinged":
		level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_MP40_INBOUND", self );
		level weapons::add_limited_weapon( weapon, self, 3 );
		break;

	default:
		break;
	}
	
}

function giveCrateWeapon( weapon_name )
{
	weapon = GetWeapon(weapon_name);
	if ( weapon == level.weaponNone )
		return;
		
	currentWeapon = self GetCurrentWeapon();

	if ( currentWeapon == weapon || self HasWeapon( weapon ) ) 
	{
		self GiveMaxAmmo( weapon );
		return true;
	}
	
	// if the player is holding anything other than primary or secondary weapons, 
	// take away the last primary or secondary weapon the player was holding before giving the crate weapon. 
	if ( currentWeapon.isSupplyDropWeapon || isdefined( level.grenade_array[currentWeapon] )|| isdefined( level.inventory_array[currentWeapon] ) ) 
	{
		self TakeWeapon( self.lastdroppableweapon );
		self GiveWeapon( weapon );
		self switchToWeapon( weapon );
		return true;
	}
	
	self AddWeaponStat( weapon, "used", 1 );

	giveSpecializedCrateWeapon( weapon );	
	
	self GiveWeapon( weapon );
	self switchToWeapon( weapon );

	self waittill( "weapon_change", newWeapon );
	
	self killstreak_weapons::useKillstreakWeaponFromCrate( weapon );
	
	return true;
}

function useSupplyDropMarker( package_contents_id, context )
{
	player = self;
	//self endon("death"); // never endon death in for this thread
	self endon("disconnect");
	self endon("spawned_player");
	
	supplyDropWeapon = level.weaponNone;
	currentWeapon = self GetCurrentWeapon();
	prevWeapon = currentWeapon;
	if ( currentWeapon.isSupplyDropWeapon )
	{
		supplyDropWeapon = currentWeapon;
	}
	
	if( supplyDropWeapon.isGrenadeWeapon )
		trigger_event = "grenade_fire";
	else
		trigger_event = "weapon_fired";	
	
	self thread supplyDropWatcher( package_contents_id, trigger_event, supplyDropWeapon, context );

	self.supplyGrenadeDeathDrop = false;
	
	while( true )
	{
		player AllowMelee( false );
		notifyString = self util::waittill_any_return( "weapon_change", trigger_event );
		player AllowMelee( true );

		if ( !isdefined( notifyString ) || ( notifyString != trigger_event ) ) 
		{
			cleanup( context, player );
			return false; 
		}
		
		
		if( isdefined( player.markerPosition ) )
		{
			break;
		}
	}
	
	self notify ( "trigger_weapon_shutdown" );
	
	// for some reason we never had the supply drop weapon
	if ( supplyDropWeapon == level.weaponNone )
	{
		cleanup( context, player );
		return false;
	}
	
	if ( isdefined( self ) )
	{
		// don't take the supplyDropWeapon until the throwing (firing) state is completed
		notifyString = self util::waittill_any_return( "weapon_change", "death" );
		
		self TakeWeapon( supplyDropWeapon );
	
		// if we no longer have the supply drop weapon in our inventory then 
		// it must have been successful
		if ( self HasWeapon( supplyDropWeapon ) || self GetAmmoCount( supplyDropWeapon ) )
		{
			cleanup( context, player );
			return false;
		}
	}
	
	return true;
}

function isSupplyDropGrenadeAllowed( killstreak )
{
	if ( !self killstreakrules::isKillstreakAllowed( killstreak, self.team ) )
	{
		self killstreaks::switch_to_last_non_killstreak_weapon();
	
		return false;
	}

	return true;
}

function AddDropLocation( killstreak_id, location )
{
	level.droplocations[killstreak_id] = location;
}

function DelDropLocation( killstreak_id )
{
	level.droplocations[killstreak_id] = undefined;
}

function IsLocationGood( location, context )
{
	//check no zones	
	foreach( dropLocation in level.dropLocations )
	{
		if( Distance2DSquared( dropLocation, location ) < 60 * 60 )
			return false;
	}
	
	if ( context.perform_physics_trace === true )
	{
		mask = PHYSICS_TRACE_MASK_PHYSICS;
		if( isdefined( context.tracemask ) ) 
			mask = context.tracemask;
		
		radius = context.radius;
		//trace = physicstrace( location + ( 0,0, 5000 ), location + ( 0, 0, 10 ), ( -radius, -radius, 0 ), ( radius, radius, radius ), undefined, mask );
		trace = physicstrace( location + ( 0,0, 5000 ), location + ( 0, 0, 10 ), ( -radius, -radius, 0 ), ( radius, radius, 2 * radius ), undefined, mask );
	
	
		if( trace["fraction"] < 1 )
		{
			return false;
		}
		else
		{
		}
	}
	
	// check for a valid start node	
	closestPoint = GetClosestPointOnNavMesh( location, max( context.max_dist_from_location, 24 ), context.dist_from_boundary );

	isValidPoint = isdefined( closestPoint );
	
	// make sure the selected point is roughly on the same floor
	if ( isValidPoint && context.check_same_floor === true && Abs( location[2] - closestPoint[2] ) > 96 )
		isValidPoint = false;
	
	if ( isValidPoint && Distance2DSquared( location, closestPoint ) > SQR( context.max_dist_from_location ) )
		isValidPoint = false;


	return isValidPoint;
}
	
function useKillstreakSupplyDrop( killstreak )
{
	player = self;
	
	if ( !player isSupplyDropGrenadeAllowed( killstreak ) )
		return false;
	
	context = SpawnStruct();
	context.radius = level.killstreakCoreBundle.ksAirdropSupplydropRadius;
	context.dist_from_boundary = SUPPY_DROP_NAV_MESH_VALID_LOCATION_BOUNDARY;
	context.max_dist_from_location = SUPPY_DROP_NAV_MESH_VALID_LOCATION_TOLERANCE;
	context.perform_physics_trace = true;
	context.isLocationGood = &IsLocationGood;
	context.objective = &"airdrop_supplydrop";	
	context.validLocationSound = level.killstreakCoreBundle.ksValidCarepackageLocationSound;
	context.tracemask = PHYSICS_TRACE_MASK_PHYSICS | PHYSICS_TRACE_MASK_WATER;
	context.dropTag = "tag_attach";
	context.dropTagOffset = ( -32, 0, 23 );
	context.killstreakType = killstreak;

	result = player useSupplyDropMarker( undefined, context );
	
	player notify( "supply_drop_marker_done" );

	if ( !isdefined( result ) || !result )
		return false;

	return result;
}

function use_killstreak_death_machine( killstreak )
{
	if ( !self killstreakrules::isKillstreakAllowed( killstreak, self.team ) )
		return false;

	weapon = GetWeapon( "minigun" );
	currentWeapon = self GetCurrentWeapon();

	// if the player is holding anything other than primary or secondary weapons, 
	// take away the last primary or secondary weapon the player was holding before giving the crate weapon. 
	if ( currentWeapon.isSupplyDropWeapon || isdefined( level.grenade_array[currentWeapon] ) || isdefined( level.inventory_array[currentWeapon] ) ) 
	{
		self TakeWeapon( self.lastdroppableweapon );
		self GiveWeapon( weapon );
		self SwitchToWeapon( weapon );

		//This will make it so the player cannot pick up weapons while using this weapon for the first time.
		self setBlockWeaponPickup( weapon, true );
		return true;
	}

	level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_MINIGUN_INBOUND", self );
	level weapons::add_limited_weapon( weapon, self, 3 );

	self TakeWeapon( currentWeapon );
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	//This will make it so the player cannot pick up weapons while using this weapon for the first time.
	self setBlockWeaponPickup( weapon, true );
	return true;
}

function use_killstreak_grim_reaper( killstreak )
{
	if ( !self killstreakrules::isKillstreakAllowed( killstreak, self.team ) )
		return false;

	weapon = GetWeapon( "m202_flash" );
	currentWeapon = self GetCurrentWeapon();

	// if the player is holding anything other than primary or secondary weapons, 
	// take away the last primary or secondary weapon the player was holding before giving the crate weapon. 
	if ( currentWeapon.isSupplyDropWeapon || isdefined( level.grenade_array[currentWeapon] ) || isdefined( level.inventory_array[currentWeapon] ) ) 
	{
		self TakeWeapon( self.lastdroppableweapon );
		self GiveWeapon( weapon );
		self SwitchToWeapon( weapon );

		//This will make it so the player cannot pick up weapons while using this weapon for the first time.
		self setBlockWeaponPickup( weapon, true );
		return true;
	}

	level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_M202_FLASH_INBOUND", self );
	level weapons::add_limited_weapon( weapon, self, 3 );

	self TakeWeapon( currentWeapon );
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );
	
	//This will make it so the player cannot pick up weapons while using this weapon for the first time.
	self setBlockWeaponPickup( weapon, true );
	return true;
}

function use_killstreak_tv_guided_missile( killstreak )
{
	if ( !killstreakrules::isKillstreakAllowed( killstreak, self.team ) )
	{
		self iPrintLnBold( level.killstreaks[ killstreak].notAvailableText );

		return false;
	}

	weapon = GetWeapon( "m220_tow" );
	currentWeapon = self GetCurrentWeapon();

	// if the player is holding anything other than primary or secondary weapons, 
	// take away the last primary or secondary weapon the player was holding before giving the crate weapon. 
	if ( currentWeapon.isSupplyDropWeapon || isdefined( level.grenade_array[currentWeapon] ) || isdefined( level.inventory_array[currentWeapon] ) ) 
	{
		self TakeWeapon( self.lastdroppableweapon );
		self GiveWeapon( weapon );
		self SwitchToWeapon( weapon );

		//This will make it so the player cannot pick up weapons while using this weapon for the first time.
		self setBlockWeaponPickup( weapon, true );
		return true;
	}

	level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_M220_TOW_INBOUND", self );
	level weapons::add_limited_weapon( weapon, self, 3 );

	self TakeWeapon( currentWeapon );
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );
	
	//This will make it so the player cannot pick up weapons while using this weapon for the first time.
	self setBlockWeaponPickup( weapon, true );
	return true;
}

function use_killstreak_mp40( killstreak )
{
	if ( !killstreakrules::isKillstreakAllowed( killstreak, self.team ) )
	{
		self iPrintLnBold( level.killstreaks[killstreak].notAvailableText );

		return false;
	}

	weapon = GetWeapon( "mp40_blinged" );
	currentWeapon = self GetCurrentWeapon();

	// if the player is holding anything other than primary or secondary weapons, 
	// take away the last primary or secondary weapon the player was holding before giving the crate weapon. 
	if ( currentWeapon.isSupplyDropWeapon || isdefined( level.grenade_array[currentWeapon] ) || isdefined( level.inventory_array[currentWeapon] ) ) 
	{
		self TakeWeapon( self.lastdroppableweapon );
		self GiveWeapon( weapon );
		self SwitchToWeapon( weapon );
		
		//This will make it so the player cannot pick up weapons while using this weapon for the first time.
		self setBlockWeaponPickup( weapon, true );
		return true;
	}

	level thread popups::DisplayTeamMessageToAll( &"KILLSTREAK_MP40_INBOUND", self );
	level weapons::add_limited_weapon( weapon, self, 3 );

	self TakeWeapon( currentWeapon );
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );
	
	//This will make it so the player cannot pick up weapons while using this weapon for the first time.
	self setBlockWeaponPickup( weapon, true );
	return true;
}

function cleanUpWatcherOnDeath( team, killstreak_id )
{
	player = self;
	self endon( "disconnect" );
	self endon( "supplyDropWatcher" );
	self endon( "trigger_weapon_shutdown" );
	self endon( "spawned_player" );
	self endon( "weapon_change" );
	
	self util::waittill_any( "death", "joined_team", "joined_spectators" );
	
	killstreakrules::killstreakStop( SUPPLY_DROP_NAME, team, killstreak_id );
	self notify( "cleanup_marker" );
}

function cleanup( context, player )
{
	if( isdefined( context ) && isdefined( context.marker ) )
	{
		context.marker delete();
		context.marker = undefined;
		if( isdefined( context.markerFXHandle ) )
		{
			context.markerFXHandle delete();
			context.markerFXHandle = undefined;
		}
		
		if ( isdefined( player ) )
		{
			player clientfield::set_to_player( "marker_state", 0 ); // off
		}
		
		DelDropLocation( context.killstreak_id );
	}	
}

function MarkerUpdateThread( context )
{
	player = self;
	player endon( "supplyDropWatcher" );
	player endon( "spawned_player" );
	player endon( "disconnect" );
	player endon( "weapon_change" );
	player endon( "death" );	
	
	markerModel = spawn( "script_model", ( 0, 0, 0 ) );
	context.marker = markerModel;
	
	player thread MarkerCleanupThread( context );	
	
	while( true )
	{		
		if( player flagsys::get( "marking_done" ) )
			break; // we dont delete the marker yet, just stop moving it around.
		
		minRange = level.killstreakCoreBundle.ksMinAirdropTargetRange;
		maxRange = level.killstreakCoreBundle.ksMaxAirdropTargetRange;
		
		forwardVector = VectorScale( AnglesToForward( player GetPlayerAngles() ), maxRange );
		//results = BulletTrace( player GetEye(), player GetEye() + forwardVector, false, player );
		
		mask = PHYSICS_TRACE_MASK_PHYSICS;
		if( isdefined( context.tracemask ) ) 
			mask = context.tracemask;
		
		radius = 2;
		results = physicstrace( player GetEye(), player GetEye() + forwardVector, ( -radius, -radius, 0 ), ( radius, radius, 2 * radius ), player, mask );
		
		
		markerModel.origin = results["position"];
		
		tooClose = DistanceSquared( markerModel.origin, player.origin ) < minRange * minRange;
		
		if( ( results["normal"][2] > 0.7 ) && !tooClose && isdefined( context.isLocationGood ) && [[context.isLocationGood]]( markerModel.origin, context ) )
		{
			player.markerPosition = markerModel.origin;
			player clientfield::set_to_player( "marker_state", 1 ); // good
		}
		else
		{
			player.markerPosition = undefined;
			player clientfield::set_to_player( "marker_state", 2 ); // bad
		}
		
		WAIT_SERVER_FRAME;
	}
}

function supplyDropWatcher( package_contents_id, trigger_event, supplyDropWeapon, context )
{
	player = self;
	self notify( "supplyDropWatcher" );
	
	self endon( "supplyDropWatcher" );
	self endon( "spawned_player" );
	self endon( "disconnect" );
	self endon( "weapon_change" );
	
	team = self.team;

	killstreak_id = killstreakrules::killstreakStart( SUPPLY_DROP_NAME, team, false, false );
	if ( killstreak_id == -1 )
		return;
	
	context.killstreak_id = killstreak_id;
	
	player flagsys::clear( "marking_done" );

	if( !supplyDropWeapon.isGrenadeWeapon )
		self thread MarkerUpdateThread( context );
	
	self thread checkForEmp();
	
	self thread checkWeaponChange( team, killstreak_id );

	self thread cleanUpWatcherOnDeath( team, killstreak_id ); 
	
	while( true )
	{
		self waittill( trigger_event, weapon_instance, weapon );
		
		isSupplyDropWeapon = true;
		if( trigger_event == "grenade_fire" )
			isSupplyDropWeapon = weapon.isSupplyDropWeapon;
			
		if ( isdefined( self ) && isSupplyDropWeapon )
		{
			if( isdefined( context ) )
			{
				if( !isdefined( player.markerPosition ) || !supplydrop::islocationgood( player.markerPosition, context ) )
				{
					if( isdefined( level.killstreakCoreBundle.ksInvalidLocationSound ) )
						player playsoundtoplayer( level.killstreakCoreBundle.ksInvalidLocationSound, player );
					
					if( isdefined( level.killstreakCoreBundle.ksInvalidLocationString ) )
						player iPrintLnBold( Istring( level.killstreakCoreBundle.ksInvalidLocationString ) );
					
					continue;
				}
				
				if( isdefined( context.validLocationSound ) )
					player playsoundtoplayer( context.validLocationSound, player );
				
				self thread heliDeliverCrate( player.markerPosition, weapon_instance, self, team, killstreak_id, package_contents_id, context );
			}
			else
			{
				self thread doSupplyDrop( weapon_instance, weapon, self, killstreak_id, package_contents_id );
				weapon_instance thread do_supply_drop_detonation( weapon, self );
				weapon_instance thread supplyDropGrenadeTimeout( team, killstreak_id, weapon );
			}
			self killstreaks::switch_to_last_non_killstreak_weapon();
		}
		else
		{
			killstreakrules::killstreakStop( SUPPLY_DROP_NAME, team, killstreak_id );
			self notify( "cleanup_marker" );
		}
		
		break;
	}
	
	player flagsys::set( "marking_done" );
	player clientfield::set_to_player( "marker_state", 0 );
}

function checkForEmp()
{
	self endon( "supplyDropWatcher" );
	self endon( "spawned_player" );
	self endon( "disconnect" );
	self endon( "weapon_change" );
	self endon( "death" );
	self endon( "trigger_weapon_shutdown" );
	
	self waittill( "emp_jammed" );
	
	self killstreaks::switch_to_last_non_killstreak_weapon();
}

function supplyDropGrenadeTimeout( team, killstreak_id, weapon )
{
	self endon( "death" );
	self endon("stationary");
	
	GRENADE_LIFETIME = 10;

	//If the grenade hasn't stopped moving after a certain time delete it.
	wait( GRENADE_LIFETIME );
	
	if( !isdefined( self ) )
		return;

	self notify( "grenade_timeout" );
	
	killstreakrules::killstreakStop( SUPPLY_DROP_NAME, team, killstreak_id );

	if ( weapon.name == "ai_tank_drop" )
	{
		killstreakrules::killstreakStop( "ai_tank_drop", team, killstreak_id );
		self notify( "cleanup_marker" );
	}
	else if ( weapon.name == "inventory_ai_tank_drop" )
	{
		killstreakrules::killstreakStop( "inventory_ai_tank_drop", team, killstreak_id );
		self notify( "cleanup_marker" );
	}	
	else if ( weapon.name == "combat_robot_drop" )
	{
		killstreakrules::killstreakStop( "combat_robot_drop", team, killstreak_id );
		self notify( "cleanup_marker" );
	}
	else if ( weapon.name == "inventory_combat_robot_drop" )
	{
		killstreakrules::killstreakStop( "inventory_combat_robot_drop", team, killstreak_id );
		self notify( "cleanup_marker" );
	}	

	self delete();
}

function checkWeaponChange( team, killstreak_id )
{
	self endon( "supplyDropWatcher" );
	self endon( "spawned_player" );
	self endon( "disconnect" );
	self endon( "trigger_weapon_shutdown" );
	self endon( "death" );
	
	self waittill( "weapon_change" );
	killstreakrules::killstreakStop( SUPPLY_DROP_NAME, team, killstreak_id );	
	self notify( "cleanup_marker" );
}

function supplyDropGrenadePullWatcher( killstreak_id )
{
	self endon( "disconnect" );
	self endon( "weapon_change" );

	self waittill ( "grenade_pullback", weapon );

	self util::_disableUsability();

	self thread watchForGrenadePutDown();
	
	self waittill ( "death" );
	
	killstreak = SUPPLY_DROP_NAME;
	self.supplyGrenadeDeathDrop = true;

	if( weapon.isSupplyDropWeapon )
	{
		killstreak = killstreaks::get_killstreak_for_weapon( weapon );
	}

	if ( !IS_TRUE( self.usingKillstreakFromInventory ) ) 
	{
		self killstreaks::change_killstreak_quantity( weapon, -1 );
	}
	else
	{
		killstreaks::remove_used_killstreak( killstreak, killstreak_id );
	}
}

function watchForGrenadePutDown()
{
	self notify( "watchForGrenadePutDown" );
	self endon( "watchForGrenadePutDown" );
	self endon( "death" );
	self endon( "disconnect" );

	self util::waittill_any( "grenade_fire", "weapon_change" );
	
	self notify ( "trigger_weapon_shutdown" );
	
	self util::_enableUsability();
}

function playerChangeWeaponWaiter()
{
	self endon( "supply_drop_marker_done" );

	self endon( "disconnect" );
	self endon( "spawned_player" );

	currentWeapon = self GetCurrentWeapon();
	
	while ( currentWeapon.isSupplyDropWeapon )
	{
		self waittill( "weapon_change", currentWeapon );
	}

	// if the killstreak ended because of a weapon change
	// give a frame to allow the weapon_change to trigger in other scripts
	waittillframeend;

	self notify( "supply_drop_marker_done" );
}

function getIconForCrate()
{
	icon = undefined;
	
	switch ( self.crateType.type )
	{
		case "killstreak":
			{
				if( isDefined(self.crateType.objective) )
				{
					return self.crateType.objective;
				}
				else if (self.crateType.name == "inventory_ai_tank_drop" )
				{
					icon = "t7_hud_ks_drone_amws";
				}
				else
				{
					killstreak = killstreaks::get_menu_name( self.crateType.name );
					icon = level.killStreakIcons[killstreak];
				}
			}
			break;
		
		case "weapon":
			{
				switch( self.crateType.name )
				{
				case "minigun":
					icon = "hud_ks_minigun";
					break;
				case "m32":
					icon = "hud_ks_m32";
					break;
				case "m202_flash":
					icon = "hud_ks_m202";
					break;
				case "m220_tow":
					icon = "hud_ks_tv_guided_missile";
					break;
				case "mp40_drop":
					icon = "hud_mp40";
						break;
				default:
					icon = "waypoint_recon_artillery_strike";
					break;
				}
			}
			break;
		
		case "ammo":
			{
				icon = "hud_ammo_refill";
			}
			break;

		default:
				return undefined;
			break;
	}
	
	return icon + "_drop";
}

function crateActivate( hacker )
{
	self MakeUsable();
	self SetCursorHint("HINT_NOICON");
	
	if( !isdefined( self.crateType ) )
		return;

	self setHintString( self.crateType.hint );	
	if ( isdefined( self.crateType.hint_gambler ) )
	{
		self setHintStringForPerk( "specialty_showenemyequipment", self.crateType.hint_gambler );
	}

	crateObjID = gameobjects::get_next_obj_id();	
	objective_add( crateObjID, "invisible", self.origin );
	//blue/friendly
	objective_icon( crateObjID, "compass_supply_drop_white" );
	objective_setcolor( crateObjID, &"FriendlyBlue" );
	objective_state( crateObjID, "active" );
	self.friendlyObjID = crateObjID;
	self.enemyObjID = [];
	
	icon = self getIconForCrate();
	
	if (isdefined( hacker ))
	{
		// hacked crate stops appearing as enemy equipment
		self clientfield::set( "enemyequip", 0 );
	}
	
	if ( level.teambased )
	{
		objective_team( crateObjID, self.team );

		foreach( team in level.teams )
		{
			if ( self.team == team )
				continue;
				
			crateObjID = gameobjects::get_next_obj_id();	
			objective_add( crateObjID, "invisible", self.origin );
			if( isdefined( self.hacker ) )
			{
				//black/hacked
				objective_icon( crateObjID, "compass_supply_drop_black" );
			}
			else
			{
				//orange/enemy
				objective_icon( crateObjID, "compass_supply_drop_white" );
				objective_setcolor( crateObjID, &"EnemyOrange" );
			}
			objective_team( crateObjID, team );
			objective_state( crateObjID, "active" );
			self.enemyObjID[self.enemyObjID.size] = crateObjID;	
		}
	}
	else
	{
		if ( !self.visibleToAll )
		{
			Objective_SetInvisibleToAll( crateObjID );
	
			enemyCrateObjID = gameobjects::get_next_obj_id();	
			objective_add( enemyCrateObjID, "invisible", self.origin );
			objective_icon( enemyCrateObjID, "compass_supply_drop_white" );
			objective_setcolor( enemyCrateObjID, &"EnemyOrange" );
			objective_state( enemyCrateObjID, "active" );
			
			if ( isplayer( self.owner ) )
			{
				Objective_SetInvisibleToPlayer( enemyCrateObjID, self.owner );
			}
			
			self.enemyObjID[self.enemyObjID.size] = enemyCrateObjID;
		}
		
		if ( isplayer( self.owner ) )
		{
			Objective_SetVisibleToPlayer( crateObjID, self.owner );
		}
		
		if( isdefined( self.hacker ) )
		{
			Objective_SetInvisibleToPlayer( crateObjID, self.hacker );
			
			crateObjID = gameobjects::get_next_obj_id();	
			objective_add( crateObjID, "invisible", self.origin );
			//black/hacked
			objective_icon( crateObjID, "compass_supply_drop_black" );
			objective_state( crateObjID, "active" );
			Objective_SetInvisibleToAll( crateObjID );
			Objective_SetVisibleToPlayer( crateObjID, self.hacker );
			self.hackerObjID = crateObjID;
		}
	}
	
	if( !self.visibleToAll && isdefined( icon ) )
	{
		self entityheadIcons::setEntityHeadIcon( self.team, self, level.crate_headicon_offset, icon, true );	
		if( self.entityHeadObjectives.size > 0 )
		{
			objectiveID = self.entityHeadObjectives[self.entityHeadObjectives.size - 1];
			if( isdefined( objectiveID ) )
			{
				Objective_SetInvisibleToAll( objectiveID );
				Objective_SetVisibleToPlayer( objectiveID, self.owner );
			}
		}
	}
	
	if ( isdefined( self.owner ) && IsPlayer(self.owner) && self.owner util::is_bot() )
	{
		self.owner notify( "bot_crate_landed", self );
	}

	if ( isdefined( self.owner ) )
	{
		self.owner notify( "crate_landed", self );
		
		setRicochetProtectionEndTime( SUPPLY_DROP_NAME, self.killstreak_id, self.owner );
	}
}

function setRicochetProtectionEndTime( killstreak, killstreak_id, owner )
{
	ksBundle = level.killstreakBundle[ killstreak ];
	if ( isdefined( ksBundle ) && isdefined( ksBundle.ksRicochetPostLandDuration ) && ksBundle.ksRicochetPostLandDuration > 0  )
	{
		endtime = GetTime() + ( ksBundle.ksRicochetPostLandDuration * 1000 );
		killstreaks::set_ricochet_protection_endtime( killstreak_id, owner, endtime );
	}
}

function crateDeactivate( )
{
	self makeunusable();

	if ( isdefined(self.friendlyObjID) )
	{
		Objective_Delete( self.friendlyObjID );
		gameobjects::release_obj_id(self.friendlyObjID);
		self.friendlyObjID = undefined;
	}
	
	if ( isdefined(self.enemyObjID) )
	{
		foreach( objId in self.enemyObjID )
		{
			Objective_Delete( objId );
			gameobjects::release_obj_id(objId);
		}
		self.enemyObjID = [];
	}
	
	if ( isdefined(self.hackerObjID) )
	{
		Objective_Delete( self.hackerObjID );
		gameobjects::release_obj_id(self.hackerObjID);
		self.hackerObjID = undefined;
	}
}


function ownerTeamChangeWatcher()
{
	self notify( "ownerTeamChangeWatcher_singleton" );
	self endon ("ownerTeamChangeWatcher_singleton");
	
	self endon("death");

	if ( !level.teamBased || !isdefined( self.owner ) )
		return;

	self.owner waittill("joined_team");

	self.owner = undefined;
}

function dropAllToGround( origin, radius, stickyObjectRadius )
{
	PhysicsExplosionSphere( origin, radius, radius, 0 );
	WAIT_SERVER_FRAME;
	weapons::drop_all_to_ground( origin, radius );

	supplydrop::dropCratesToGround( origin, radius );
	level notify( "drop_objects_to_ground", origin, stickyObjectRadius );
}

function dropEverythingTouchingCrate( origin )
{
	// a sphere with a radius of 44 covers the current supply drop exactly
	dropAllToGround( origin, 70, 70 );
}

function dropAllToGroundAfterCrateDelete( crate, crate_origin )
{
	crate waittill("death");
	wait( 0.1 );
	
	crate dropEverythingTouchingCrate( crate_origin );
}

function dropCratesToGround( origin, radius )
{
	crate_ents = GetEntArray( "care_package", "script_noteworthy" );
	radius_sq = radius * radius;
	for ( i = 0 ; i < crate_ents.size ; i++ )
	{
		if ( DistanceSquared( origin, crate_ents[i].origin ) < radius_sq )
		{
			crate_ents[i] thread dropCrateToGround();
		}
	}
}

function dropCrateToGround()
{
	self endon("death");
	
	if ( isdefined( self.droppingToGround ) )
		return;
		
	self.droppingToGround = true;
	
	// we need to recursively have this crate trigger a drop to ground as well
	dropEverythingTouchingCrate( self.origin );
	
	self crateDeactivate();
	self thread crateDropToGroundKill();
	self crateRedoPhysics();
	self crateActivate();
		
	self.droppingToGround = undefined;
}

function ConfigureTeamPost( owner )
{
	crate = self;
	
	crate thread ownerTeamChangeWatcher();	
}

function crateSpawn( killstreak, killstreakId, owner, team, drop_origin, drop_angle )
{
	crate = spawn( "script_model", drop_origin, 1 );
	crate killstreaks::configure_team( killstreak, killstreakId, owner, undefined, undefined, &ConfigureTeamPost );
	
	crate.angles = drop_angle;
	crate.visibleToAll = false;
	crate.script_noteworthy = "care_package";
	crate clientfield::set( "enemyequip", 1 );
	
	if ( killstreak == "ai_tank_drop" || killstreak == "inventory_ai_tank_drop" )
	{
		crate setModel( level.crateModelTank );
		crate setEnemyModel( level.crateModelTank );
	}
	else
	{
		crate setModel( level.crateModelFriendly );
		crate setEnemyModel( level.crateModelEnemy );
	}
	
	// Care Packages will cut the navmesh causing AI's to walk around them.
	crate DisconnectPaths();
	
	switch( killstreak )
	{
	case "turret_drop":
		crate.crateType = level.crateTypes[ killstreak ][ "autoturret" ];
		break;
	case "tow_turret_drop":
		crate.crateType = level.crateTypes[ killstreak ][ "auto_tow" ];
		break;
	case "m220_tow_drop":
		crate.crateType = level.crateTypes[ killstreak ][ "m220_tow" ];
		break;
	case "ai_tank_drop":
	case "inventory_ai_tank_drop":
		crate.crateType = level.crateTypes[ killstreak ][ "ai_tank_drop" ];
		break;	
	case "minigun_drop":
	case "inventory_minigun_drop":
		crate.crateType = level.crateTypes[ killstreak ][ "minigun" ];
		break;	
	case "m32_drop":
	case "inventory_m32_drop":
		crate.crateType = level.crateTypes[ killstreak ][ "m32" ];
		break;	
	default:
		crate.crateType = getRandomCrateType( "supplydrop" );
		break;
	}
	
	return crate;
}

function crateDelete( drop_all_to_ground )
{
	if( !isdefined( self ) )
		return;
	
	killstreaks::remove_ricochet_protection( self.killstreak_id, self.originalowner );

	if( !isdefined( drop_all_to_ground ) )
	{
		drop_all_to_ground = true;
	}
	
	if ( isdefined(self.friendlyObjID) )
	{
		Objective_Delete( self.friendlyObjID );
		gameobjects::release_obj_id(self.friendlyObjID);
		self.friendlyObjID = undefined;
	}
	
	if ( isdefined(self.enemyObjID) )
	{
		foreach( objId in self.enemyObjID )
		{
			Objective_Delete( objId );
			gameobjects::release_obj_id(objId);
		}
		self.enemyObjID = undefined;
	}
	
	if ( isdefined(self.hackerObjID) )
	{
		Objective_Delete( self.hackerObjID );
		gameobjects::release_obj_id(self.hackerObjID);
		self.hackerObjID = undefined;
	}
	
	if( drop_all_to_ground )
	{
		level thread dropAllToGroundAfterCrateDelete( self, self.origin );
	}
	
	if ( isdefined ( self.killcament ) )
	{
		self.killcament thread util::deleteAfterTime( 5 );	
	}

	self Delete();
}

function stationaryCrateOverride()
{
	self endon("death");
	self endon("stationary");
	
	wait( 3 ); // give some time for the physics to settle
	
	// if not turn it off and fire the notify
	
	self.angles = self.angles;
	self.origin = self.origin; // this should turn off the physics
	
	self notify( "stationary" );
}

function timeoutCrateWaiter()
{
	self endon("death");
	self endon("stationary");
	
	// if the crate has not stopped moving for some time just get rid of it
	wait( 20 );
	
	self crateDelete( true );
}

function cratePhysics()
{
	//forcePointVariance = 200.0;
	//vertVelocityMin = -100.0;
	//vertVelocityMax = 100.0;
	
	//forcePointX = RandomFloatRange( 0-forcePointVariance, forcePointVariance );
	//forcePointY = RandomFloatRange( 0-forcePointVariance, forcePointVariance );
	//forcePoint = ( forcePointX, forcePointY, 0 );
	//initialVelocityZ = RandomFloatRange( vertVelocityMin, vertVelocityMax );
	//forcePoint += self.origin;
	
	forcePoint = self.origin;
	params = level.killstreakBundle[SUPPLY_DROP_NAME];
	DEFAULT( params.ksLandingVelocity, 100 );
	initialVelocity = ( 0, 0, -params.ksLandingVelocity / 40 );

	self PhysicsLaunch( forcePoint, initialVelocity );
	
	self thread timeoutCrateWaiter();
	self thread stationaryCrateOverride();

	self thread update_crate_velocity();
	self thread play_impact_sound();

	self waittill("stationary");
}

function get_height( e_ignore )
{
	DEFAULT( e_ignore, self );
	
	const height_diff = 10;
	trace = GroundTrace( self.origin + (0,0,height_diff), self.origin + ( 0, 0, -10000 ), false, e_ignore, false );
	

	return Distance( self.origin, trace[ "position" ] );
}

function crateControlledDrop( killstreak, v_target_location )
{
	crate = self;
	
	supplydrop = true;
	if( killstreak == AI_TANK_AGR_NAME ) 
		supplydrop = false;
	
	if( supplydrop ) 
		params = level.killstreakBundle[SUPPLY_DROP_NAME];
	else
		params = level.killstreakBundle[AI_TANK_AGR_NAME];
	
	DEFAULT( params.ksThrustersOffHeight, 100 );
	DEFAULT( params.ksTotalDropTime, 4 );
	DEFAULT( params.ksAccelTimePercentage, 0.65 );
	
	accelTime = params.ksTotalDropTime * params.ksAccelTimePercentage;
	decelTime = params.ksTotalDropTime - accelTime;
	
	target = ( v_target_location[0], v_target_location[1], v_target_location[2] + params.ksThrustersOffHeight );
	
	hostmigration::waitTillHostMigrationDone();
	crate moveto( target, params.ksTotalDropTime, accelTime, decelTime ) ;

	crate thread WatchForCrateKill( v_target_location[2] + VAL( params.ksStartCrateKillHeightFromGround, 200 ) );
	
	wait( accelTime - 0.05 );

	if( supplydrop )
		crate clientfield::set( "supplydrop_thrusters_state", 1 );
	else
		crate clientfield::set( "aitank_thrusters_state", 1 );
	
	crate waittill( "movedone" );
	
	hostmigration::waitTillHostMigrationDone();
	
	if( supplydrop )
		crate clientfield::set( "supplydrop_thrusters_state", 0 );
	else
		crate clientfield::set( "aitank_thrusters_state", 0 );

	crate cratePhysics();
}

function play_impact_sound() //self == crate
{
	self endon( "entityshutdown" );
	self endon( "stationary" );
	self endon( "death" );

	wait( 0.5 ); //this wait is to delay the fall speed check

	while( abs( self.velocity[2] ) > 5 ) //this is not 0 since the crate will sometimes rock a bit before it stops moving
	{
		wait( 0.1 );
	}

	self PlaySound( "phy_impact_supply" );
}

function update_crate_velocity() //self == crate
{
	self endon( "entityshutdown" );
	self endon( "stationary" );

	self.velocity = ( 0,0,0 );
	self.old_origin = self.origin;

	while( isdefined( self ) )
	{
		self.velocity = ( self.origin - self.old_origin );
		self.old_origin = self.origin;

		WAIT_SERVER_FRAME;
	}
}


function crateRedoPhysics()
{
	forcePoint = self.origin;
	
	initialVelocity = ( 0, 0, 0 );

	self PhysicsLaunch(forcePoint,initialVelocity);
	
	self thread timeoutCrateWaiter();
	self thread stationaryCrateOverride();
	
	self waittill("stationary");
}

function do_supply_drop_detonation( weapon, owner ) // self == weapon_instance
{
	self notify( "supplyDropWatcher" );

	self endon( "supplyDropWatcher" );
	self endon( "spawned_player" );
	self endon( "disconnect" );
	self endon( "death" );
	self endon ( "grenade_timeout" );

	// control the explosion events to circumvent the code cleanup
	self util::waitTillNotMoving();
	self.angles = ( 0, self.angles[1], 90 );
	fuse_time = weapon.fuseTime / 1000; // fuse time comes back in milliseconds
	wait( fuse_time );
	
	if ( !isdefined( owner ) || !owner EMP::EnemyEMPActive() )
	{
		thread smokegrenade::playSmokeSound( self.origin, 6, level.sound_smoke_start, level.sound_smoke_stop, level.sound_smoke_loop );
		PlayFXOnTag( level._supply_drop_smoke_fx, self, "tag_fx" );
		proj_explosion_sound = weapon.projExplosionSound;
		sound::play_in_space( proj_explosion_sound, self.origin );
	}
	
	// need to clean up the canisters
	wait( 3 );
	self delete();
}

function doSupplyDrop( weapon_instance, weapon, owner, killstreak_id, package_contents_id, context )
{
	weapon endon ( "explode" );
	weapon endon ( "grenade_timeout" );
	self endon( "disconnect" );
	team = owner.team;
	weapon_instance thread watchExplode( weapon, owner, killstreak_id, package_contents_id );
	weapon_instance util::waitTillNotMoving();
	weapon_instance notify( "stoppedMoving" );
	
	self thread heliDeliverCrate( weapon_instance.origin, weapon, owner, team, killstreak_id, package_contents_id, context );
}

function watchExplode( weapon, owner, killstreak_id, package_contents_id )
{
	self endon( "stoppedMoving" );
	team = owner.team;
	self waittill( "explode", position ); 
	
	owner thread heliDeliverCrate( position, weapon, owner, team, killstreak_id, package_contents_id );
}

function crateTimeOutThreader()
{
	crate = self;
	crateTimeOut( 90 );
	crate thread deleteOnOwnerLeave();
}
function crateTimeOut( time )
{
	crate = self;
	self thread killstreaks::WaitForTimeout( "inventory_supply_drop", 90 * 1000, &crateDelete, "death" );
}

function deleteOnOwnerleave()
{
	crate = self;
	crate endon( "death" );
	crate.owner util::waittill_any( "joined_team", "joined_spectators", "disconnect" );
	crate crateDelete( true );
}

function WaitAndDelete( time )
{
	self endon( "death" );
	wait( time );
	self delete();
}

function dropCrate( origin, angle, killstreak, owner, team, killcamEnt, killstreak_id, package_contents_id, crate_, context )
{
	angle = ( angle[0] * 0.5, angle[1] * 0.5, angle[2] * 0.5 );
	
	if ( isdefined( crate_ ) )
	{
		origin = crate_.origin;
		angle = crate_.angles;
		crate_ thread WaitAndDelete( 0.1 );
	}
	crate = crateSpawn( killstreak, killstreak_id, owner, team, origin, angle );
	killCamEnt unlink();
	killCamEnt linkto( crate );
	crate.killcamEnt = killcamEnt;
	crate.killstreak_id = killstreak_id;
	crate.package_contents_id = package_contents_id;
	killCamEnt thread util::deleteAfterTime( 15 );
	killCamEnt thread unlinkOnRotation( crate );
	
	crate endon("death");
	
	crate crateTimeOutThreader();

	trace = GroundTrace( crate.origin + ( 0, 0, -100 ), crate.origin + ( 0, 0, -10000 ), false, crate, false );
	v_target_location = trace["position"];	

	crate crateControlledDrop(killstreak, v_target_location );	
	
	crate thread hacker_tool::registerWithHackerTool( level.carePackageHackerToolRadius, level.carePackageHackerToolTimeMs );
	
	cleanup( context, owner ) ;
	
	if ( isdefined( crate.crateType ) && isdefined( crate.crateType.landFunctionOverride ) )
	{
		[[crate.crateType.landFunctionOverride]]( crate, killstreak, owner, team, context );
	}
	else
	{
		crate crateActivate();
	
		crate thread crateUseThink();
		crate thread crateUseThinkOwner();
		
		if( isdefined( crate.crateType ) && isdefined( crate.crateType.hint_gambler )) 
		{
			crate thread crateGamblerThink();
		}

		default_land_function( crate, killstreak, owner, team );
	}
	

}

function unlinkOnRotation( crate )
{
	self endon( "delete" );
	crate endon( "death" );
	crate endon( "entityshutdown" );
	crate endon( "stationary" );
	
	waitBeforeRotationCheck = GetDvarFloat( "scr_supplydrop_killcam_rot_wait", 0.5 );
	wait( waitBeforeRotationCheck ); //this wait is to delay the fall speed check

	minCos = GetDvarFloat( "scr_supplydrop_killcam_max_rot", 0.999 );
		
	cosine = 1;

	currentDirection = VectorNormalize( AnglesToForward( crate.angles ) );

	while( cosine > minCos  ) 
	{
		oldDirection = currentDirection;
		WAIT_SERVER_FRAME;
		currentDirection = VectorNormalize( AnglesToForward( crate.angles ) );
		cosine = vectordot( oldDirection, currentDirection );
	}
	self unlink();
}


function default_land_function( crate, category, owner, team ) 
{
	while ( 1 )
	{
		crate waittill("captured", player, remote_hack );

		player challenges::capturedCrate( owner );
		deleteCrate = player giveCrateItem( crate );
		if ( isdefined( deleteCrate ) && !deleteCrate )
		{
			continue;
		}
		
		playerHasEngineerPerk = player HasPerk( "specialty_showenemyequipment" );
		
		// added functionality to specialty_showenemyequipment to create a booby trapped supply crate once this is captured
		if( ( playerHasEngineerPerk || remote_hack==true ) &&
			owner != player &&
			((level.teambased && team != player.team) || !level.teambased) )
		{
			// spawn an explosive crate right before we delete the other
			spawn_explosive_crate( crate.origin, crate.angles, category, owner, team, player, playerHasEngineerPerk );
			crate MakeUnusable();
			util::wait_network_frame(); // to avoid crate blinking
			crate crateDelete( false );
		}
		else
		{
			crate crateDelete( true );
		}
		return;
	}
}

function spawn_explosive_crate( origin, angle, killstreak, owner, team, hacker, playerHasEngineerPerk ) // self == crate
{
	// No killstreakId needed since there's currently no dialog to attach to an exploding crate
	crate = crateSpawn( killstreak, undefined, owner, team, origin, angle );
	crate SetOwner( owner );
	crate SetTeam( team );

	if ( level.teambased )
	{
		crate setEnemyModel( level.crateModelBoobyTrapped );
		crate MakeUsable( team );
	}
	else
	{
		crate setEnemyModel( level.crateModelEnemy );
	}
	
	crate.hacker = hacker;
	crate.visibleToAll = false;
	crate crateActivate( hacker );
	crate setHintStringForPerk( "specialty_showenemyequipment", level.supplyDropDisarmCrate );
	crate thread crateUseThink();
	crate thread crateUseThinkOwner();
	crate thread watch_explosive_crate();
	crate crateTimeOutThreader();
	crate.playerHasEngineerPerk = playerHasEngineerPerk;
}

function watch_explosive_crate() // self == crate
{
	killCamEnt = spawn( "script_model", self.origin + (0,0,60) );
	self.killcament = killcament;
	self waittill( "captured", player, remote_hack );
	
	// give warning and then explode if the capturer didnt have hacker perk
	if ( !player HasPerk( "specialty_showenemyequipment" ) && !remote_hack )
	{
		self thread entityheadIcons::setEntityHeadIcon( player.team, player, level.crate_headicon_offset, "headicon_dead", true );	
		self loop_sound( "wpn_semtex_alert", 0.15 );
	
		if( !isdefined( self.hacker ) )
		{
			self.hacker = self;
		}
		self RadiusDamage( self.origin, 256, 300, 75, self.hacker, "MOD_EXPLOSIVE", GetWeapon( "supplydrop" ) );
		PlayFX( level._supply_drop_explosion_fx, self.origin );
		PlaySoundAtPosition( "wpn_grenade_explode", self.origin );
	}
	else
	{
		PlaySoundAtPosition ( "mpl_turret_alert", self.origin );
		scoreevents::processScoreEvent( "disarm_hacked_care_package", player );
		player challenges::disarmedHackedCarepackage();
	}
	wait ( 0.1 );
	self crateDelete();
	killcament thread util::deleteAfterTime( 5 );	
}

function loop_sound( alias, interval ) // self == crate
{
	self endon( "death" );
	while( 1 )
	{
		PlaySoundAtPosition( alias, self.origin );

		wait interval;
		interval = (interval / 1.2);

		if (interval < .08)
		{
			break;
		}	
	}
}

function WatchForCrateKill( start_kill_watch_z_threshold )
{
	crate = self;
	crate endon( "death" );
	crate endon( "stationary" );

	while ( crate.origin[2] > start_kill_watch_z_threshold )
	{
		WAIT_SERVER_FRAME;
	}
	
	stationaryThreshold = 2;
	killThreshold = 15;
	maxFramesTillStationary = 20;
	numFramesStationary = 0;	
	
	while( true )
	{	
		vel = 0;
		if( isdefined( self.velocity ) )
			vel = abs( self.velocity[2] );
		
		if( vel > killThreshold )
		{
			crate is_touching_crate();
			crate is_clone_touching_crate();
		}
		
		if( vel < stationaryThreshold )
			numFramesStationary++;
		else
			numFramesStationary = 0;

		if( numFramesStationary >= maxFramesTillStationary )
			break;
		
		WAIT_SERVER_FRAME;
	}
}

function crateKill() // self == crate
{
	self endon( "death" );

	// kill anyone under it
	stationaryThreshold = 2;
	killThreshold = 15;
	maxFramesTillStationary = 20;
	numFramesStationary = 0;
	while( true )
	{	
		vel = 0;
		if ( isdefined( self.velocity ) )
			vel = abs( self.velocity[2] );
		
		if ( vel > killThreshold )
		{
			self is_touching_crate();
			self is_clone_touching_crate();
		}

		if ( vel < stationaryThreshold )
			numFramesStationary++;
		else
			numFramesStationary = 0;

		if ( numFramesStationary >= maxFramesTillStationary )
			break;
		
		wait 0.01;
	}
}

function crateDropToGroundKill()
{
	self endon( "death" );
	self endon( "stationary" );

	for ( ;; )
	{
		players = GetPlayers();
		doTrace = false;

		for ( i = 0; i < players.size; i++ )
		{
			if ( players[i].sessionstate != "playing" )
				continue;

			if ( players[i].team == "spectator" )
				continue;

			//Check if any equipment gets landed on
			self is_equipment_touching_crate( players[i] );

			if ( !IsAlive( players[i] ) )
				continue;
			
			flattenedSelfOrigin = (self.origin[0], self.origin[1], 0 );
			flattenedPlayerOrigin = (players[i].origin[0], players[i].origin[1], 0 );
			
			if ( DistanceSquared( flattenedSelfOrigin, flattenedPlayerOrigin ) > 64 * 64 )
				continue;

			doTrace = true;
			break;
		}

		// do the trace
		if ( doTrace )
		{
			start = self.origin;
			crateDropToGroundTrace( start );

			start = self GetPointInBounds( 1.0, 0.0, 0.0 );
			crateDropToGroundTrace( start );

			start = self GetPointInBounds( -1.0, 0.0, 0.0 );
			crateDropToGroundTrace( start );

			start = self GetPointInBounds( 0.0, -1.0, 0.0 );
			crateDropToGroundTrace( start );

			start = self GetPointInBounds( 0.0, 1.0, 0.0 );
			crateDropToGroundTrace( start );

			start = self GetPointInBounds( 1.0, 1.0, 0.0 );
			crateDropToGroundTrace( start );

			start = self GetPointInBounds( -1.0, 1.0, 0.0 );
			crateDropToGroundTrace( start );

			start = self GetPointInBounds( 1.0, -1.0, 0.0 );
			crateDropToGroundTrace( start );

			start = self GetPointInBounds( -1.0, -1.0, 0.0 );
			crateDropToGroundTrace( start );

			wait( 0.2 );
		}
		else
		{
			wait( 0.5 );
		}
	}
}

function crateDropToGroundTrace( start )
{
	end = start + ( 0, 0, -8000 );

	trace = BulletTrace( start, end, true, self, true, true );

	if ( isdefined( trace[ "entity" ] ) && IsPlayer( trace[ "entity" ] ) && IsAlive( trace[ "entity" ] ) )
	{
		player = trace[ "entity" ];

		if ( player.sessionstate != "playing" )
			return;

		if ( player.team == "spectator" )
			return;

		if ( DistanceSquared( start, trace[ "position" ] ) < 12 * 12 || self IsTouching( player ) )
		{
			player DoDamage( player.health + 1, player.origin, self.owner, self, "none", "MOD_HIT_BY_OBJECT", 0, GetWeapon( "supplydrop" ) );
			player playsound ( "mpl_supply_crush" );
			player playsound ( "phy_impact_supply" );			
		}
	}
}

function is_touching_crate() // self == crate
{
	if ( !isdefined( self ) )
		return;

	crate = self;
	extraBoundary = ( 10, 10, 10 );
	players = GetPlayers();
		
	//crate_bottom_point = self GetPointInBounds( 0.0, 0.0, -1.0 );
	crate_bottom_point = self.origin;
	
	foreach( player in level.players )
	{		
		if( isdefined( player ) && IsAlive( player ) )
		{
			stance = player GetStance();
			stance_z_offset = ( ( stance == "stand" ) ? 40 : ( ( stance == "crouch" ) ? 18 : 6 ) );
			player_test_point = player.origin + ( 0, 0, stance_z_offset );
			
			if (  ( player_test_point[2] < crate_bottom_point[2] ) && self IsTouching( player, extraBoundary ) )
			{
				attacker = ( isdefined( self.owner ) ? self.owner : self );
				
				player DoDamage( player.health + 1, player.origin, attacker, self, "none", "MOD_HIT_BY_OBJECT", 0, GetWeapon( "supplydrop" ) );
				player playsound ("mpl_supply_crush");
				player playsound ("phy_impact_supply");
			}
		}

		self is_equipment_touching_crate( player );
	}
	
	vehicles = GetEntArray( "script_vehicle", "classname" );
	foreach( vehicle in vehicles )
	{
		if( IsVehicle( vehicle ) )
		{
			if( isdefined( vehicle.archetype ) && ( vehicle.archetype == "wasp" ) )
			{
				if( crate IsTouching( vehicle, ( 2, 2, 2 ) ) )
				{
					vehicle notify( "sentinel_shutdown" );
				}
			}
		}
	}
}

function is_clone_touching_crate() // self == crate
{
	if ( !isdefined( self ) )
		return;
	
	extraBoundary = ( 10, 10, 10 );
	actors = GetActorArray();
	for( i = 0; i < actors.size; i++ )
	{
		if( isdefined( actors[i] ) && isdefined( actors[i].isAiClone ) && IsAlive( actors[i] ) && ( actors[i].origin[2] < self.origin[2] ) && self IsTouching( actors[i], extraBoundary ) )
		{
			attacker = ( isdefined( self.owner ) ? self.owner : self );
			
			actors[i] DoDamage( actors[i].health + 1, actors[i].origin, attacker, self, "none", "MOD_HIT_BY_OBJECT", 0, GetWeapon( "supplydrop" ) );
			actors[i] playsound ("mpl_supply_crush");
			actors[i] playsound ("phy_impact_supply");			
		}
	}
}

function is_equipment_touching_crate( player ) // self == crate, player is passed to access their equipment
{
	extraBoundary = ( 10, 10, 10 );
	if( isdefined( player ) && isdefined( player.weaponObjectWatcherArray ) )
	{
		for( watcher = 0; watcher < player.weaponObjectWatcherArray.size; watcher++ )
		{ 
			objectWatcher = player.weaponObjectWatcherArray[watcher];
			objectArray = objectWatcher.objectArray;
			
			if( isdefined( objectArray ) )
			{
				for( weaponObject = 0; weaponObject < objectArray.size; weaponObject++ )
				{
					if( isdefined(objectArray[weaponObject]) && self IsTouching( objectArray[weaponObject], extraBoundary ) )
					{
						if( isdefined(objectWatcher.onDetonateCallback) )
						{
							objectWatcher thread weaponobjects::waitAndDetonate( objectArray[weaponObject], 0 );
						}
						else
						{
							weaponobjects::removeWeaponObject( objectWatcher, objectArray[weaponObject] );
							
							// TODO-T8: this doesn't actually delete the weapon object; make a call to weaponobjects::deleteWeaponObjectInstance here after it is implemented

						}
					}
				}
			}
		}
	}

	//Check for tactical insertion
	extraBoundary = ( 15, 15, 15 );
	if( isdefined( player ) && isdefined( player.tacticalInsertion ) && self IsTouching( player.tacticalInsertion, extraBoundary ) )
	{
		player.tacticalInsertion thread tacticalinsertion::fizzle();
	}
}

function spawnUseEnt()
{
	useEnt = spawn( "script_origin", self.origin );
	useEnt.curProgress = 0;
	useEnt.inUse = false;
	useEnt.useRate = 0;
	useEnt.useTime = 0;
	useEnt.owner = self;
	
	useEnt thread useEntOwnerDeathWaiter( self );

	return useEnt;
}

function useEntOwnerDeathWaiter( owner )
{
	self endon ( "death" );
	owner waittill ( "death" );
	
	self delete();
}

// taken from _gameobject maybe we can just use the _gameobject code
function crateUseThink() // self == crate
{
	while( isdefined(self) )
	{
		self waittill("trigger", player );
		
		if ( !isAlive( player ) )
			continue;
			
		if ( !player isOnGround() )
			continue;
		
		if ( isdefined( self.owner ) && self.owner == player )
			continue;
			
		useEnt = self spawnUseEnt();
		result = false;
		
		// if the crate has been hacked then we'll need to know later on the useEnt
		if( isdefined( self.hacker ) )
		{
			useEnt.hacker = self.hacker;
		}
		
		self.useEnt = useEnt;

		result = useEnt useHoldThink( player, level.crateNonOwnerUseTime );
		
		if ( isdefined( useEnt ) )
		{
			useEnt Delete();
		}
		
		if ( result )
		{
			scoreevents::giveCrateCaptureMedal( self, player );
			self notify("captured", player, false );
		}
	}
}

function crateUseThinkOwner() // self == crate
{
	self endon("joined_team");

	while( isdefined(self) )
	{
		self waittill("trigger", player );
		
		if ( !isAlive( player ) )
			continue;
			
		//if ( !player isOnGround() )
			//continue;
		
		if ( !isdefined( self.owner ) )
			continue;

		if ( self.owner != player )
			continue;
			
		result = self useHoldThink( player, level.crateOwnerUseTime );

		if ( result )
		{
			self notify("captured", player, false );
		}
	}
}

function useHoldThink( player, useTime ) // self == a script origin (useEnt) or the crate
{
	player notify ( "use_hold" );
	player util::freeze_player_controls( true );

	player util::_disableWeapon();

	self.curProgress = 0;
	self.inUse = true;
	self.useRate = 0;
	self.useTime = useTime;
	
	player thread personalUseBar( self );

	result = useHoldThinkLoop( player );
	
	if ( isdefined( player ) )
	{
		player notify( "done_using" );
	}
	
	if ( isdefined( player ) )
	{
		
		if ( IsAlive(player) )
		{
			player util::_enableWeapon();
	
			player util::freeze_player_controls( false );
		}
	}
	
	if ( isdefined( self ) )
	{
		self.inUse = false;
	}

	// result may be undefined if useholdthinkloop hits an endon
	if ( isdefined( result ) && result )
		return true;
	
	return false;
}

function continueHoldThinkLoop( player )
{
	if ( !isdefined(self ) )
		return false;
		
	if ( self.curProgress >= self.useTime )
		return false;
		
	if ( !IsAlive( player ) )
		return false;

	if ( player.throwingGrenade )
		return false;

	if ( !(player useButtonPressed()) )
		return false;

	if ( player meleeButtonPressed() )
		return false;
		
	if ( player IsInVehicle() )
		return false;
	
	if ( player IsWeaponViewOnlyLinked() )
		return false;

	if ( player IsRemoteControlling() )
		return false;

	return true;
}

function useHoldThinkLoop( player )
{
	level endon ( "game_ended" );
	self endon("disabled");
	self.owner endon( "crate_use_interrupt" );
	
	timedOut = 0;
	
	while( self continueHoldThinkLoop( player ) )
	{
		timedOut += 0.05;

		self.curProgress += (50 * self.useRate);
		self.useRate = 1;

		if ( self.curProgress >= self.useTime )
		{
			self.inUse = false;
						
			wait .05;
			
			return isAlive( player );
		}
		
		WAIT_SERVER_FRAME;
		hostmigration::waitTillHostMigrationDone();
	}
	
	return false;
}

function crateGamblerThink()
{
	self endon( "death" );

	for ( ;; )
	{

		self waittill( "trigger_use_doubletap", player );

			
		if ( !player HasPerk( "specialty_showenemyequipment" ))
		{
			continue;
		}
		if( isdefined( self.useEnt ) && self.useEnt.inUse )
		{
			// TODO: get a fail sound for this
			if(  IsDefined( self.owner ) && self.owner != player )
				continue;
		}
		
		player playlocalsound ("uin_gamble_perk");
		
		self.crateType = getRandomCrateType( "gambler", self.crateType.name );
		self crateReactivate();
		self setHintStringForPerk( "specialty_showenemyequipment", self.crateType.hint );

		self notify( "crate_use_interrupt" );
		level notify( "use_interrupt", self );
		
		return;
	}
}

function crateReactivate()
{
	self setHintString( self.crateType.hint );

	icon = self getIconForCrate();
	
	self thread entityheadIcons::setEntityHeadIcon( self.team, self, level.crate_headicon_offset, icon, true );
}

function personalUseBar( object ) // self == player, object == a script origin (useEnt) or the crate
{
	self endon("disconnect");
	
	captureCrateState = SUPPLY_DROP_CRATE_STATE_NONE;
	
	if( self HasPerk( "specialty_showenemyequipment" ) && 
		object.owner != self && 
		!isdefined( object.hacker ) &&
		( ( level.teambased && object.owner.team != self.team ) || !level.teambased ) )
	{
		captureCrateState = SUPPLY_DROP_CRATE_STATE_HACK;
		self PlayLocalSound ( "evt_hacker_hacking" );
	}
	else if( self HasPerk( "specialty_showenemyequipment" ) &&
		isdefined( object.hacker ) &&
		(object.owner == self || 
		( level.teambased && object.owner.team == self.team ) ) )
	{
		captureCrateState = SUPPLY_DROP_CRATE_STATE_DISARM;
		self PlayLocalSound ( "evt_hacker_hacking" );
	}
	else
	{
		captureCrateState = SUPPLY_DROP_CRATE_STATE_CAPTURE;
		self.is_capturing_own_supply_drop = ( object.owner === self ) && ( !isdefined( object.originalOwner ) || object.originalOwner == self );
	}

	lastRate = -1;
	while ( isAlive( self ) && isdefined(object) && object.inUse && !level.gameEnded )
	{
		if ( lastRate != object.useRate )
		{
			if( object.curProgress > object.useTime)
				object.curProgress = object.useTime;

			if ( !object.useRate )
			{
				self clientfield::set_player_uimodel( "hudItems.captureCrateTotalTime", 0 );
				self clientfield::set_player_uimodel( "hudItems.captureCrateState", SUPPLY_DROP_CRATE_STATE_NONE );
			}
			else
			{
				barFrac = object.curProgress / object.useTime;
				rateOfChange = object.useRate / object.useTime;
				captureCrateTotalTime = 0;
				if ( rateOfChange > 0 )
				{
					captureCrateTotalTime = ( ( 1 - barFrac ) / rateOfChange );
				}
				
				self clientfield::set_player_uimodel( "hudItems.captureCrateTotalTime", Int( captureCrateTotalTime ) );
				self clientfield::set_player_uimodel( "hudItems.captureCrateState", captureCrateState );
			}
		}	
		lastRate = object.useRate;
		WAIT_SERVER_FRAME;
	}
	
	self.is_capturing_own_supply_drop = false;
	self clientfield::set_player_uimodel( "hudItems.captureCrateTotalTime", 0 );
	self clientfield::set_player_uimodel( "hudItems.captureCrateState", SUPPLY_DROP_CRATE_STATE_NONE );
}

function spawn_helicopter( owner, team, origin, angles, model, targetname, killstreak_id, context )
{
	chopper = spawnHelicopter( owner, origin, angles, model, targetname );
	if ( !isdefined( chopper ) )
	{
		if ( isplayer( owner ) )
		{
			killstreakrules::killstreakStop( SUPPLY_DROP_NAME, team, killstreak_id );
			self notify( "cleanup_marker" );
		}
		return undefined;
	}

	chopper killstreaks::configure_team( SUPPLY_DROP_NAME, killstreak_id, owner );
//	chopper killstreak_hacking::enable_hacking( SUPPLY_DROP_NAME );
//	if ( isdefined ( context.killstreakRef ) )
//	{
//		chopper killstreak_hacking::override_hacked_killstreak_reference( context.killstreakRef );
//	}
	
	chopper.maxhealth = level.heli_maxhealth;		// max health
	//chopper.health = 999999;								// we check against maxhealth in the damage monitor to see if this gets destroyed, so we don't want this to die prematurely			
	chopper.rocketDamageOneShot = chopper.maxhealth + 1;	// Make it so the heatseeker blows it up in one hit for now
	chopper.damageTaken = 0;
	
	hardpointTypeForDamage = SUPPLY_DROP_NAME;
	if ( context.killstreakref === "inventory_ai_tank_drop" || context.killstreakref === "ai_tank_drop" )
	{
		hardpointTypeForDamage = SUPPLY_DROP_AI_TANK_NAME;
	}
	else if ( context.killstreakref === "inventory_combat_robot" || context.killstreakref === "combat_robot" )
	{
		hardpointTypeForDamage = SUPPLY_DROP_COMBAT_ROBOT_NAME;
	}
		
	chopper thread helicopter::heli_damage_monitor( hardpointTypeForDamage );
	chopper thread heatseekingmissile::MissileTarget_ProximityDetonateIncomingMissile("crashing", "death");
	chopper.spawnTime = GetTime();
	chopper clientfield::set( "enemyvehicle", ENEMY_VEHICLE_ACTIVE );
	
	supplydropSpeed = GetDvarInt( "scr_supplydropSpeedStarting", 250 ); // 250);
	supplydropAccel = GetDvarInt( "scr_supplydropAccelStarting", 100 ); //175);
	chopper SetSpeed( supplydropSpeed, supplydropAccel );	

	maxPitch = GetDvarInt( "scr_supplydropMaxPitch", 25);
	maxRoll = GetDvarInt( "scr_supplydropMaxRoll", 45 ); // 85);
	chopper SetMaxPitchRoll( 0, maxRoll );	
	
	chopper SetDrawInfrared( true );
	
	Target_Set(chopper, ( 0, 0, -25 ));
	
	if ( isplayer( owner ) )
	{
		chopper thread refCountDecChopper(team, killstreak_id);
	}
	chopper thread heliDestroyed();

	return chopper;
}

function getDropHeight(origin)
{
	return airsupport::getMinimumFlyHeight();
}

function getDropDirection()
{
	return (0, RandomInt(360), 0);
}

function getNextDropDirection( drop_direction, degrees )
{
	drop_direction = (0, drop_direction[1] + degrees, 0 );

	if( drop_direction[1] >= 360 )
		drop_direction = (0, drop_direction[1] - 360, 0 );

	return drop_direction;
}

function getHeliStart( drop_origin, drop_direction )
{
	dist = -1 * GetDvarInt( "scr_supplydropIncomingDistance", 15000 ); // 15000);
	pathRandomness = 100;
	direction = drop_direction + (0, RandomIntRange( -2, 3 ), 0);
	
	start_origin = drop_origin + ( AnglesToForward( direction ) * dist );
	start_origin += ( (randomfloat(2) - 1)*pathRandomness, (randomfloat(2) - 1)*pathRandomness, 0 );
	return start_origin;
}

function getHeliEnd( drop_origin, drop_direction )
{
	pathRandomness = 150;
	dist = -1 * GetDvarInt( "scr_supplydropOutgoingDistance", 15000);
	
	// have the heli do a sharp turn when leaving
	if ( RandomIntRange(0,2) == 0 )
		turn = RandomIntRange( 60,121);
	else
		turn = -1 * RandomIntRange( 60,121);
		
	direction = drop_direction + (0, turn, 0);
	
	end_origin = drop_origin + ( AnglesToForward( direction ) * dist );
	end_origin += ( (randomfloat(2) - 1)*pathRandomness  , (randomfloat(2) - 1)*pathRandomness  , 0 );

	return end_origin;
}

function addOffsetOntoPoint( point, direction, offset )
{
	angles = VectorToAngles( (direction[0], direction[1], 0) );
	
	offset_world = RotatePoint( offset, angles );
	
	return (point + offset_world);			
}

function supplyDropHeliStartPath_v2_setup( goal, goal_offset )
{
	goalPath = SpawnStruct();

	goalPath.start = helicopter::getValidRandomStartNode( goal ).origin;
	
	return goalPath;
}

function supplyDropHeliStartPath_v2_part2_local( goal, goalPath, goal_local_offset )
{
	direction = ( goal - goalPath.start );

	goalPath.path = [];
	goalPath.path[0] = addOffsetOntoPoint( goal, direction, goal_local_offset );
}

function supplyDropHeliStartPath_v2_part2( goal, goalPath, goal_world_offset )
{
	goalPath.path = [];
	goalPath.path[0] = goal + goal_world_offset;
}

function supplyDropHeliStartPath(goal, goal_offset)
{
	total_tries = 12;
	tries = 0;
	
	goalPath = SpawnStruct();
	drop_direction = getDropDirection();
	
	
	while ( tries < total_tries )
	{
		goalPath.start = getHeliStart( goal, drop_direction );
		
		goalPath.path = airsupport::getHeliPath( goalPath.start, goal );
		
		startNoFlyZones = airsupport::insideNoFlyZones( goalPath.start, false );
		
		if ( IsDefined( goalPath.path ) && startNoFlyZones.size == 0 )
		{
			if ( goalPath.path.size > 1 )
			{
				direction = ( goalPath.path[goalPath.path.size - 1] - goalPath.path[goalPath.path.size - 2] );
			}
			else
			{
				direction = ( goalPath.path[goalPath.path.size - 1] - goalPath.start );
			}
			goalPath.path[goalPath.path.size - 1] = addOffsetOntoPoint(goalPath.path[goalPath.path.size - 1], direction, goal_offset);
			return goalPath;
		}
		
		//Couldn't find a path that didn't cross a no fly zone picking random directions, so try the last tried direction plus 30 degrees
		drop_direction = getNextDropDirection( drop_direction, 30 );
		
		tries++;
	}

	//Couldn't find a valid direction, so just bring it in even if it will fly through something
	drop_direction = getDropDirection();
	goalPath.start = getHeliStart( goal, drop_direction );
	
	direction = ( goal - goalPath.start );
	goalPath.path = [];
	goalPath.path[0] = addOffsetOntoPoint( goal, direction, goal_offset );
	
	return goalPath;
}

function supplyDropHeliEndPath_v2( start )
{
	goalPath = SpawnStruct();

	goalPath.start = start;
	
	goal = helicopter::getValidRandomLeaveNode( start ).origin;
	
	goalPath.path = [];
	goalPath.path[0] = goal;
	
	return goalPath;
}

function supplyDropHeliEndPath(origin, drop_direction)
{
	total_tries = 5;
	tries = 0;
	
	goalPath = SpawnStruct();
	
	while ( tries < total_tries )
	{
		goal = getHeliEnd( origin, drop_direction );
		
		goalPath.path = airsupport::getHeliPath( origin, goal );
		
		if ( isdefined( goalPath.path ) )
		{
			return goalPath;
		}
		
		tries++;
	}
	
	// could not locate a clear path try the leave nodes
	leave_nodes = getentarray( "heli_leave", "targetname" ); 		
	foreach ( node in leave_nodes )
	{
		goalPath.path = airsupport::getHeliPath( origin, node.origin );
		
		if ( isdefined( goalPath.path ) )
		{
			return goalPath;
		}
	}
	
	// points where the helicopter leaves to
	goalPath.path = [];
	goalPath.path[0] = getHeliEnd( origin, drop_direction );
	
	return goalPath;
}

function incCrateKillstreakUsageStat(weapon, killstreak_id)
{
	if ( weapon == level.weaponNone )
		return;

	switch ( weapon.name )
	{
	case "turret_drop":
		self killstreaks::play_killstreak_start_dialog( "turret_drop", self.pers["team"], killstreak_id );
		break;
	case "tow_turret_drop":
		self killstreaks::play_killstreak_start_dialog( "tow_turret_drop", self.pers["team"], killstreak_id );
		break;
	case "supplydrop_marker":
	case "inventory_supplydrop_marker":
		self killstreaks::play_killstreak_start_dialog( SUPPLY_DROP_NAME, self.pers["team"], killstreak_id );
		level thread popups::DisplayKillstreakTeamMessageToAll( SUPPLY_DROP_NAME, self );
		self challenges::calledInCarePackage();
		self AddWeaponStat( GetWeapon( "supplydrop" ), "used", 1 );
		break;
	case "ai_tank_drop":
	case "inventory_ai_tank_drop":
		self killstreaks::play_killstreak_start_dialog( "ai_tank_drop", self.pers["team"], killstreak_id );
		level thread popups::DisplayKillstreakTeamMessageToAll( "ai_tank_drop", self );
		self AddWeaponStat( GetWeapon( "ai_tank_drop" ), "used", 1 );
		break;
	case "inventory_minigun_drop":
	case "minigun_drop":
		self killstreaks::play_killstreak_start_dialog( "minigun", self.pers["team"], killstreak_id );
		break;
	case "m32_drop":
	case "inventory_m32_drop":
		self killstreaks::play_killstreak_start_dialog( "m32", self.pers["team"], killstreak_id );
		break;
	case "combat_robot_drop":
		level thread popups::DisplayKillstreakTeamMessageToAll( "combat_robot", self );
		break;
		
	}
}

function MarkerCleanupThread( context )
{
	player = self;
	player util::waittill_any( "death", "disconnect", "joined_team", "joined_spectators", "cleanup_marker" );
	cleanup( context, player );
}

// gets the world drop point from which a payload is dropped from (also the payload's origin while attached to the chopper)
function GetChopperDropPoint( context ) // self = chopper
{
	chopper = self;
	return ( isdefined( context.dropTag ) ? chopper GetTagOrigin( context.dropTag ) + RotatePoint( VAL( context.dropTagOffset, (0,0,0) ), chopper.angles ) : chopper.origin );
}

function heliDeliverCrate( origin, weapon, owner, team, killstreak_id, package_contents_id, context )
{
	if ( owner EMP::EnemyEMPActive() && !owner hasperk("specialty_immuneemp") )
	{
		killstreakrules::killstreakStop( SUPPLY_DROP_NAME, team, killstreak_id );
		self notify( "cleanup_marker" );
		return;
	}

	context.markerFXHandle = SpawnFx( level.killstreakCoreBundle.fxMarkedLocation, context.marker.origin + ( 0, 0, 5 ), ( 0, 0, 1 ), ( 1, 0, 0 ) );
	context.markerFXHandle.team = owner.team;
	TriggerFX( context.markerFXHandle );
	AddDropLocation( killstreak_id, context.marker.origin );
	killstreakBundle = ( isdefined( context.killstreakType ) ? level.killstreakbundle[ context.killstreakType ] : undefined );
	ricochetDistance = ( isdefined( killstreakBundle ) ? killstreakBundle.ksRicochetDistance : undefined );
	killstreaks::add_ricochet_protection( killstreak_id, owner, context.marker.origin, ricochetDistance );

	context.marker.team = owner.team;	
	context.marker entityheadicons::destroyEntityHeadIcons();
	
	// the offset for the icon can be controlled from the objective in APE
	context.marker entityheadicons::setEntityHeadIcon( owner.pers["team"], owner, undefined, context.objective );

	if( isdefined( weapon ) )
		incCrateKillstreakUsageStat( weapon, killstreak_id );

	rear_hatch_offset_local = GetDvarInt( "scr_supplydropOffset", 0);

	drop_origin = origin;
	drop_height = getDropHeight(drop_origin);
	drop_height += level.zOffsetCounter * 350;
	level.zOffsetCounter++;
	if( level.zOffsetCounter >= 5 )
		level.zOffsetCounter = 0;

	heli_drop_goal = ( drop_origin[0], drop_origin[1], drop_height ); //  + rear_hatch_offset_world;
	

	goalPath = undefined;
	
	if ( IsDefined( context.dropOffset ) )
	{
		goalPath = supplyDropHeliStartPath_v2_setup(heli_drop_goal, context.dropOffset );
		supplyDropHeliStartPath_v2_part2_local(heli_drop_goal, goalPath, context.dropOffset );
	}
	else
	{
		goalPath = supplyDropHeliStartPath_v2_setup(heli_drop_goal, (rear_hatch_offset_local, 0, 0 ));
		goal_path_setup_needs_finishing = true;
	}

	drop_direction = VectorToAngles( (heli_drop_goal[0], heli_drop_goal[1], 0) - (goalPath.start[0], goalPath.start[1], 0));
	
	if( isdefined( context.vehiclename ) )
		helicopterVehicleInfo = context.vehiclename;
	else
		helicopterVehicleInfo = level.vtolDropHelicopterVehicleInfo;
	
	chopper = spawn_helicopter(	owner, 
	                           	team, 
	                           	goalPath.start, 
	                           	drop_direction,
	                           	helicopterVehicleInfo, 	                           	
	                           	"",
	                           	killstreak_id, context );
	
	if ( goal_path_setup_needs_finishing === true )
	{
		goal_world_offset = chopper.origin - chopper GetChopperDropPoint( context );
		supplyDropHeliStartPath_v2_part2( heli_drop_goal, goalPath, goal_world_offset );
		goal_path_setup_needs_finishing = false;
	}

	// disable drop location wait until we have a more proper design-approved solution
	waitForOnlyOneDropLocation = false;

	while( level.dropLocations.size > 1 && waitForOnlyOneDropLocation) // wait for the older ongoing drops to finish
	{
		// remove old drop locations
		ArrayRemoveValue( level.dropLocations, undefined );

		wait_for_drop = false;
		foreach( id, dropLocation in level.dropLocations )	
		{ // check if older drop is still ongoing 
			if( id < killstreak_id )
			{
				wait_for_drop = true;
				break;
			}
		}
		if( wait_for_drop )
			wait 0.5;
		else
			break;
	}
	
	chopper.killstreakWeaponName = weapon.name;
	
	if( isdefined( context ) && isdefined( context.hasFlares ) ) 
	{
		chopper.numFlares = 3;
		chopper.flareOffset = ( 0, 0 ,0 );
		chopper thread helicopter::create_flare_ent( (0, 0, -50 ) );
	}	
	else
	{
		chopper.numFlares = 0;
	}
	
	killCamEnt = spawn( "script_model", chopper.origin + (0,0,800) );
	killCamEnt.angles = (100, chopper.angles[1], chopper.angles[2]);
	killCamEnt.startTime = gettime();
	killCamEnt linkTo( chopper );
	
	//Wait until the chopper is within the map bounds or within a certain distance of it's target before the SAM turret can target it
	if ( isplayer( owner ) )
	{
		Target_SetTurretAquire( self, false );
		chopper thread SAMTurretWatcher( drop_origin );
	}
	
	if ( !isdefined( chopper ) )
		return;

	if( isdefined( context ) && isdefined( context.prolog ) ) // we need callbacks for this
	{
		chopper [[context.prolog]]( context );
	}
	else
	{
		chopper thread heliDropCrate( level.killstreakWeapons[weapon], owner, rear_hatch_offset_local, killCamEnt, killstreak_id, package_contents_id, context );
		//chopper thread heliDropCrate( weapon.name, owner, rear_hatch_offset_local, killCamEnt, killstreak_id, package_contents_id, context );
	}
	
	chopper endon("death");
	
	chopper thread airsupport::followPath( goalPath.path, "drop_goal", true);

	chopper thread speedRegulator(heli_drop_goal);

	chopper waittill( "drop_goal" );
	
	if( isdefined( context ) && isdefined( context.epilog ) )
	{
		chopper [[context.epilog]]( context );
	}
	
/#
	PrintLn("Chopper Incoming Time: " + ( GetTime() - chopper.spawnTime ) );
#/

	// wait 0.1;
	
	on_target = false;
	last_distance_from_goal_squared = SQR( 9999999.0 );
	continue_waiting = true;
	remaining_tries = 30; // fail-safe, about one and a half seconds
	while ( continue_waiting && remaining_tries > 0 )
	{
		if ( isdefined( context.dropOffset ) )
		{
			chopper_drop_point = chopper.origin - RotatePoint( context.dropOffset, chopper.angles );
		}
		else
		{
			chopper_drop_point = chopper GetChopperDropPoint( context );
		}

		current_distance_from_goal_squared = Distance2DSquared( chopper_drop_point, heli_drop_goal );
		continue_waiting = ( ( current_distance_from_goal_squared < last_distance_from_goal_squared ) && ( current_distance_from_goal_squared > SQR( SUPPY_DROP_ON_TARGET_DISTANCE ) ) );
		last_distance_from_goal_squared = current_distance_from_goal_squared;

    
		if ( continue_waiting )
		{
	    	WAIT_SERVER_FRAME;
		}
		
		remaining_tries--;
	}
	
	chopper notify("drop_crate", chopper.origin, chopper.angles, chopper.owner);
	chopper.dropTime = GetTime();
	chopper playsound ("veh_supply_drop");
	
	wait ( 0.7 );
	
	if ( isdefined( level.killstreakWeapons[weapon] ) )
	{
		chopper killstreaks::play_pilot_dialog_on_owner( "waveStartFinal", level.killstreakWeapons[weapon], chopper.killstreak_id );
    }
	    
	supplydropSpeed = GetDvarInt( "scr_supplydropSpeedLeaving", 250 ); 
	supplydropAccel = GetDvarInt( "scr_supplydropAccelLeaving", 60 );
	chopper setspeed( supplydropSpeed, supplydropAccel );	

	goalPath = supplyDropHeliEndPath_v2( chopper.origin );
	
	chopper airsupport::followPath( goalPath.path, undefined, false );
/#
	PrintLn("Chopper Outgoing Time: " + ( GetTime() - chopper.dropTime ) );
#/
	chopper notify( "leaving" );
	chopper Delete();
	
}

function SAMTurretWatcher( destination )
{
	self endon( "leaving" );
	self endon( "helicopter_gone" );
	self endon( "death" );

	SAM_TURRET_AQUIRE_DIST = 1500;

	while(1)
	{
		if( Distance( destination, self.origin ) < SAM_TURRET_AQUIRE_DIST )
			break;

		if( self.origin[0] > level.spawnMins[0] && self.origin[0] < level.spawnMaxs[0] &&
			self.origin[1] > level.spawnMins[1] && self.origin[1] < level.spawnMaxs[1] )
			break;

		wait( 0.1 );
	}

	Target_SetTurretAquire( self, true );
}

function speedRegulator( goal )
{
	self endon("drop_goal");
	self endon("death");
	
	wait (3);

	supplydropSpeed = GetDvarInt( "scr_supplydropSpeed", 400);
	supplydropAccel = GetDvarInt( "scr_supplydropAccel", 60);
	self SetYawSpeed( 100, 60, 60 );
	self SetSpeed( supplydropSpeed, supplydropAccel );	

	wait (1);
	maxPitch = GetDvarInt( "scr_supplydropMaxPitch", 25);
	maxRoll = GetDvarInt( "scr_supplydropMaxRoll", 35 ); // 85);
	self SetMaxPitchRoll( maxPitch, maxRoll );	
}

function heliDropCrate( killstreak, originalOwner, offset, killCamEnt, killstreak_id, package_contents_id, context )
{
	helicopter = self;
	originalOwner endon ( "disconnect" );
	
	crate = crateSpawn( killstreak, killstreak_id, originalOwner, self.team, self.origin, self.angles );

    if ( killstreak == "inventory_supply_drop" || killstreak == "supply_drop" )
    {
    	crate LinkTo( helicopter, VAL( context.dropTag, "tag_origin" ), VAL( context.dropTagOffset, (0,0,0) ) );
    	helicopter clientfield::set( "supplydrop_care_package_state", 1 );
    }
    else if ( killstreak == "inventory_ai_tank_drop" || killstreak == "ai_tank_drop" || killstreak == "ai_tank_marker" )
    {
    	crate LinkTo( helicopter, VAL( context.dropTag, "tag_origin" ), VAL( context.dropTagOffset, (0,0,0) ) );
    	helicopter clientfield::set( "supplydrop_ai_tank_state", 1 );
    }

	team = self.team;
	
	helicopter waittill("drop_crate", origin, angles, chopperOwner );
	
	if ( isdefined( chopperOwner ) )
	{
		owner = chopperOwner;
		
		if ( owner != originalOwner ) // chopper has been hacked
		{
			crate killstreaks::configure_team( killstreak, owner );
			killstreaks::remove_ricochet_protection( killstreak_id, owner );
		}
	}
	else
	{
		owner = originalOwner;
	}
	
	if ( isdefined( self ) )
	{
		team = self.team;
	
		if ( killstreak == "inventory_supply_drop" || killstreak == "supply_drop" )
	    {
	    	helicopter clientfield::set( "supplydrop_care_package_state", 0 );
	    }
	    else if ( killstreak == "inventory_ai_tank_drop" || killstreak == "ai_tank_drop" )
	    {
	    	helicopter clientfield::set( "supplydrop_ai_tank_state", 0 );
	    }
	    
	    enemy = helicopter.owner battlechatter::get_closest_player_enemy( helicopter.origin, true );
		enemyRadius = battlechatter::mpdialog_value( "supplyDropRadius", 0 );
		
		if ( isdefined( enemy ) && Distance2DSquared( origin, enemy.origin ) < enemyRadius * enemyRadius )
		{
			enemy battlechatter::play_killstreak_threat( killstreak );
		}
	}
	
	if( team == owner.team ) // dont drop if the team changed //
	{
		//ideally we can not respawn a new crate, but unlink the old crate then zero out the velocity
		rear_hatch_offset_height = GetDvarInt( "scr_supplydropOffsetHeight", 200);
		rear_hatch_offset_world = RotatePoint( ( offset, 0, 0), angles );
		drop_origin = origin - (0,0,rear_hatch_offset_height) - rear_hatch_offset_world;
		thread dropCrate(drop_origin, angles, killstreak, owner, team, killCamEnt, killstreak_id, package_contents_id, crate, context );
	}
}

function heliDestroyed()
{
	self endon( "leaving" );
	self endon( "helicopter_gone" );
	self endon( "death" );
	
	while( true )
	{
		if( self.damageTaken > self.maxhealth )
			break;

		WAIT_SERVER_FRAME;
	}

	if (! isdefined(self) )
		return;

	
	self SetSpeed( 25, 5 );
	self thread lbSpin( RandomIntRange(180, 220) );
	
	wait( RandomFloatRange( .5, 1.5 ) );
	
	self notify( "drop_crate", self.origin, self.angles, self.owner );
	
	lbExplode();
}

// crash explosion
function lbExplode()
{
	forward = ( self.origin + ( 0, 0, 1 ) ) - self.origin;
	playfx ( level.chopper_fx["explode"]["death"], self.origin, forward );
	
	// play heli explosion sound
	self playSound( level.heli_sound["crash"] );
	self notify ( "explode" );

	if ( isdefined( self.delete_after_destruction_wait_time ) )
	{
		self Hide();
		self WaitAndDelete( self.delete_after_destruction_wait_time  );
	}
	else
	{
		self delete();
	}
}


function lbSpin( speed )
{
	self endon( "explode" );
	
	// tail explosion that caused the spinning
	playfxontag( level.chopper_fx["explode"]["large"], self, "tail_rotor_jnt" );
	playfxontag( level.chopper_fx["fire"]["trail"]["large"], self, "tail_rotor_jnt" );
	
	self setyawspeed( speed, speed, speed );
	while ( isdefined( self ) )
	{
		self settargetyaw( self.angles[1]+(speed*0.9) );
		wait ( 1 );
	}
}

function refCountDecChopper( team, killstreak_id )
{
	self waittill("death");
	killstreakrules::killstreakStop( SUPPLY_DROP_NAME, team, killstreak_id );
	self notify( "cleanup_marker" );
}

