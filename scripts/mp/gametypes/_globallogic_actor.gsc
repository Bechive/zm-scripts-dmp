#using scripts\codescripts\struct;

#using scripts\shared\clientfield_shared;
#using scripts\shared\challenges_shared;
#using scripts\shared\damagefeedback_shared;
#using scripts\shared\scoreevents_shared;
#using scripts\shared\spawner_shared;
#using scripts\shared\weapons\_weapon_utils;
#using scripts\shared\ai\systems\destructible_character;
#using scripts\shared\ai\systems\gib;
#using scripts\shared\abilities\gadgets\_gadget_clone;
	
#using scripts\mp\gametypes\_globallogic;
#using scripts\mp\gametypes\_globallogic_player;
#using scripts\mp\gametypes\_globallogic_utils;

#using scripts\shared\_burnplayer;
#using scripts\mp\_challenges;


#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#namespace globallogic_actor;

function autoexec init()
{
}

function Callback_ActorSpawned( spawner )
{
	self thread spawner::spawn_think( spawner );
}

function Callback_ActorDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, vDamageOrigin, psOffsetTime, boneIndex, modelIndex, surfaceType, vSurfaceNormal )
{
	if ( game["state"] == "postgame" )
		return;
	
	if ( self.team == "spectator" )
		return;
	
	if ( isdefined( eAttacker ) && isPlayer( eAttacker ) && isdefined( eAttacker.canDoCombat ) && !eAttacker.canDoCombat )
		return;

	self.iDFlags = iDFlags;
	self.iDFlagsTime = getTime();

	eAttacker = globallogic_player::figure_out_attacker( eAttacker );
	
	// Don't do knockback if the damage direction was not specified
	if( !isdefined( vDir ) )
		iDFlags |= IDFLAGS_NO_KNOCKBACK;
	
	friendly = false;

	if ( ((self.health == self.maxhealth)) || !isdefined( self.attackers ) )
	{
		self.attackers = [];
		self.attackerData = [];
		self.attackerDamage = [];
		self.attackersThisSpawn = [];
	}

	if ( globallogic_utils::isHeadShot( weapon, sHitLoc, sMeansOfDeath, eInflictor ) && !weapon_utils::ismeleemod( sMeansOfDeath ) )
	{
		sMeansOfDeath = "MOD_HEAD_SHOT";
	}
	
	if ( level.onlyHeadShots )
	{
		if ( sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET" )
			return;
		else if ( sMeansOfDeath == "MOD_HEAD_SHOT" )
			iDamage = 150;
	}

	if ( isdefined( self.overrideActorDamage ) )
	{
		iDamage = self [[self.overrideActorDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime, boneIndex, modelIndex );
	}
	
	friendlyfire = [[ level.figure_out_friendly_fire ]]( self );
	if( ( friendlyfire == 0 ) && ( self.archetype === "robot" ) && isdefined( eAttacker ) && ( eAttacker.team === self.team ) )
		return;
	
	// This is the AI system's override damage callback, it must come last!
	if ( IsDefined( self.aiOverrideDamage ) )
	{
		for ( index = 0; index < self.aiOverrideDamage.size; index++ )
		{
			damageCallback = self.aiOverrideDamage[index];
			iDamage = self [[damageCallback]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime, boneIndex, modelIndex );
		}
		if ( iDamage < 1 )
			return;
		
		iDamage = int( iDamage + 0.5 );
	}

	// explosive barrel/car detection
	if ( weapon == level.weaponNone && isdefined( eInflictor ) )
	{
		if ( isdefined( eInflictor.targetname ) && eInflictor.targetname == "explodable_barrel" )
			weapon = GetWeapon( "explodable_barrel" );
		else if ( isdefined( eInflictor.destructible_type ) && isSubStr( eInflictor.destructible_type, "vehicle_" ) )
			weapon = GetWeapon( "destructible_car" );
	}

	// check for completely getting out of the damage
	if( !(iDFlags & IDFLAGS_NO_PROTECTION) )
	{
		if ( isPlayer( eAttacker ) )
			eAttacker.pers["participation"]++;
		
		prevHealthRatio = self.health / self.maxhealth;
		
		isShootingOwnClone = false;
		if( isDefined( self.isaiclone ) && self.isaiclone && isPlayer( eAttacker ) && ( self.owner == eAttacker ) )
		{
			isShootingOwnClone = true;
		}
		
		if ( level.teamBased && isPlayer( eAttacker ) && (self != eAttacker) && (self.team == eAttacker.pers["team"]) && !isShootingOwnClone )
		{
			friendlyfire = [[ level.figure_out_friendly_fire ]]( self );
			
			if ( friendlyfire == 0 ) // no one takes damage
			{
				return;
			}
			else if ( friendlyfire == 1 ) // the friendly takes damage
			{
				// Make sure at least one point of damage is done
				if ( iDamage < 1 )
					iDamage = 1;
				
				self.lastDamageWasFromEnemy = false;
				
				self globallogic_player::giveAttackerAndInflictorOwnerAssist( eAttacker, eInflictor, iDamage, sMeansOfDeath, weapon );

				self finishActorDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, vDamageOrigin, psOffsetTime, boneIndex, surfaceType, vSurfaceNormal);
			}
			else if ( friendlyfire == 2 ) // no one takes damage
			{
				return;
			}
			else if ( friendlyfire == 3 ) // both friendly and attacker take damage
			{
				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if ( iDamage < 1 )
					iDamage = 1;
				
				self.lastDamageWasFromEnemy = false;
				
				self globallogic_player::giveAttackerAndInflictorOwnerAssist( eAttacker, eInflictor, iDamage, sMeansOfDeath, weapon );
			
				self finishActorDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, vDamageOrigin, psOffsetTime, boneIndex, surfaceType, vSurfaceNormal);
			}
			
			friendly = true;
		}
		else
		{
			// no damage from the dogs owner unless in hardcore
			if ( isdefined( eAttacker ) && isdefined( self.script_owner ) && eAttacker == self.script_owner && !level.hardcoreMode && !isShootingOwnClone )
			{
				return;
			}
			
			// dogs with the same owner can not damage each other
			if ( isdefined( eAttacker ) && isdefined( self.script_owner ) && isdefined( eAttacker.script_owner ) && eAttacker.script_owner == self.script_owner )
			{
				return;
			}
			
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;
		
			if ( issubstr( sMeansOfDeath, "MOD_GRENADE" ) && isdefined( eInflictor ) && isdefined( eInflictor.isCooked ) )
				self.wasCooked = getTime();
			else
				self.wasCooked = undefined;
			
			self.lastDamageWasFromEnemy = (isdefined( eAttacker ) && (eAttacker != self));
			
			self globallogic_player::giveAttackerAndInflictorOwnerAssist( eAttacker, eInflictor, iDamage, sMeansOfDeath, weapon );
			
			self finishActorDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, vDamageOrigin, psOffsetTime, boneIndex, surfaceType, vSurfaceNormal);
		}

		if ( isdefined(eAttacker) && eAttacker != self )
		{
			if ( weapon.name != "artillery" && ( !isdefined( eInflictor ) || !isai( eInflictor ) || !isdefined( eInflictor.controlled ) || eInflictor.controlled ) )
			{
				if ( iDamage > 0 && shitloc !== "riotshield" )
				{
					eAttacker thread damagefeedback::update( sMeansOfDeath, eInflictor, undefined, weapon, self );
				}
			}
		}
	}

	if(1) // self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfteam = self.team;
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		/#logPrint("AD;" + lpselfnum + ";" + lpselfteam + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + weapon.name + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + ";" + boneIndex + "\n");#/
	}
	
}

function Callback_ActorKilled(eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime)
{
	if ( game["state"] == "postgame" )
		return;	
	
	if( isai(attacker) && isdefined( attacker.script_owner ) )
	{
		// if the person who called the dogs in switched teams make sure they don't
		// get penalized for the kill
		if ( attacker.script_owner.team != self.team )
			attacker = attacker.script_owner;
	}
		
	if( attacker.classname == "script_vehicle" && isdefined( attacker.owner ) )
		attacker = attacker.owner;

	_gadget_clone::ProcessCloneScoreEvent( self, attacker, weapon );

	globallogic::DoWeaponSpecificKillEffects(eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime);
	globallogic::DoWeaponSpecificCorpseEffects(self, eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime);

	
}

function Callback_ActorCloned( original )
{
	DestructServerUtils::CopyDestructState( original, self );
	GibServerUtils::CopyGibState( original, self );
}
