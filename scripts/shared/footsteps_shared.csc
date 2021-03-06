#using scripts\codescripts\struct;

#using scripts\shared\audio_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;

#namespace footsteps;

REGISTER_SYSTEM( "footsteps", &__init__, undefined )

function __init__()
{	
	surfaceArray = getSurfaceStrings();
//	footstepArray = getFootstepStrings();
	
	movementArray = [];

	// for playerJump() sound
	movementArray[movementArray.size] = "step_run";
	// for playerLand() sound
	movementArray[movementArray.size] = "land";
	
	// building array of all sounds
	level.playerFootSounds = [];
	for ( movementArrayIndex = 0; movementArrayIndex < movementArray.size; movementArrayIndex++ )
	{
		movementType = movementArray[movementArrayIndex];
		for ( surfaceArrayIndex = 0; surfaceArrayIndex < surfaceArray.size; surfaceArrayIndex++ )
		{
			surfaceType = surfaceArray[surfaceArrayIndex];
			for ( index = 0; index < 4; index++ )
			{
				if ( index < 2 ) 
				{
					firstPerson = false;
				}
				else
				{
					firstPerson = true;
				}
				
				if ( ( index % 2 ) == 0 )
				{
					isLouder = false;
				}
				else
				{
					isLouder = true;
				}
				
				snd = buildAndCacheSoundAlias( movementtype, surfaceType, firstperson, isLouder );
				
				//PrintLn(movementType + " " + surfaceType + " : " + snd);
			}
		}
	}
	
}

function playerJump(client_num, player, surfaceType, firstperson, quiet, isLouder)
{
	if ( isdefined( player.audioMaterialOverride ) )
	{
		surfaceType = player.audioMaterialOverride;
	}
	
	sound_alias = level.playerFootSounds["step_run"][surfaceType][firstperson][isLouder];
	
	player playsound( client_num, sound_alias );
}

function playerLand(client_num, player, surfaceType, firstperson, quiet, damagePlayer, isLouder)
{	
	if ( isdefined( player.audioMaterialOverride ) )
	{
		surfaceType = player.audioMaterialOverride;
	}
	
	sound_alias = level.playerFootSounds["land"][surfaceType][firstperson][isLouder];

	player playsound( client_num, sound_alias );
	// play step sound for landings if one exists
	if ( isdefined( player.step_sound ) && (!quiet) && (player.step_sound) != "none" )
	{
		volume = audio::get_vol_from_speed (player);

 		player playsound (client_num, player.step_sound, player.origin, volume);				
	}
	if ( damagePlayer )
	{
		if (isdefined(level.playerFallDamageSound))
			player [[level.playerFallDamageSound]](client_num, firstperson);
		else
		{
			sound_alias = "fly_land_damage_npc";
			if ( firstperson )
			{
				sound_alias = "fly_land_damage_plr";
				player playsound( client_num, sound_alias );
			}
		}
	}
}

function playerFoliage(client_num, player, firstperson, quiet)
{
	sound_alias = "fly_movement_foliage_npc";
	if ( firstperson )
	{
		sound_alias = "fly_movement_foliage_plr";
	}

	volume = audio::get_vol_from_speed (player);		
	player playsound( client_num, sound_alias, player.origin, volume );
}

function buildAndCacheSoundAlias( movementtype, surfaceType, firstperson, isLouder )
{
	sound_alias = "fly_" + movementtype;

	if ( firstperson )
	{
		sound_alias = sound_alias + "_plr_";
	}
	else
	{
		sound_alias = sound_alias + "_npc_";
	}
	
	sound_alias = sound_alias + surfaceType; 

	if ( !isdefined( level.playerFootSounds ) )
		level.playerFootSounds = [];

	if ( !isdefined( level.playerFootSounds[movementtype] ) )
		level.playerFootSounds[movementtype] = [];

	if ( !isdefined( level.playerFootSounds[movementtype][surfaceType] ) )
		level.playerFootSounds[movementtype][surfaceType] = [];

	if ( !isdefined( level.playerFootSounds[movementtype][surfaceType][firstperson] ) )
		level.playerFootSounds[movementtype][surfaceType][firstperson] = [];
	
	assert( isArray( level.playerFootSounds ) );
	assert( isArray( level.playerFootSounds[movementtype] ) );
	assert( isArray( level.playerFootSounds[movementtype][surfaceType] ) );
	assert( isArray( level.playerFootSounds[movementtype][surfaceType][firstperson] ) );
	
	level.playerFootSounds[movementtype][surfaceType][firstperson][isLouder] = sound_alias;
	
	return sound_alias;
}

function do_foot_effect(client_num, ground_type, foot_pos, on_fire)
{

	if(!isdefined(level._optionalStepEffects))
		return;

	if( on_fire )
	{
		ground_type = "fire";
	} 
	
	for(i = 0; i < level._optionalStepEffects.size; i ++)
	{
		if(level._optionalStepEffects[i] == ground_type)
		{
			effect = "fly_step_" + ground_type;
			
			if(isdefined(level._effect[effect]))
			{
				playfx(client_num, level._effect[effect], foot_pos, foot_pos + (0,0,100));
				return;				
			}
		}
	}
	
}

function missing_ai_footstep_callback()
{
}

function playAIFootstep(client_num, pos, surface, notetrack, bone)
{	
	if(!isdefined(self.archetype))
	{
	/#	PrintLn("*** Client script footstep callback on an entity that doesn't have an archetype defined.  Ignoring.");	#/
		FootstepDoEverything();		
		return;
	}
	
	if(!isdefined(level._footstepCBFuncs) || !isdefined(level._footstepCBFuncs[self.archetype]))
	{
		self missing_ai_footstep_callback();
		FootstepDoEverything();
		return;
	}
	
	[[level._footstepCBFuncs[self.archetype]]](client_num, pos, surface, notetrack, bone);

}