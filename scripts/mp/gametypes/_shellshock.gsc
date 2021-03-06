#using scripts\codescripts\struct;

#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\util_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;

#using scripts\mp\_util;

#namespace shellshock;

REGISTER_SYSTEM( "shellshock", &__init__, undefined )
	
function __init__()
{
	callback::on_start_gametype( &init );
	
	level.shellshockOnPlayerDamage = &on_damage;
}

function init()
{
}

function on_damage( cause, damage, weapon )
{
	if ( self util::isFlashbanged() )
	{
		return; // don't interrupt flashbang shellshock

	}
	
	if( self.health <= 0 )
	{
		self clientfield::set_to_player("sndMelee", 0);
	}
	
	if ( cause == "MOD_EXPLOSIVE" ||
	     cause == "MOD_GRENADE" ||
	     cause == "MOD_GRENADE_SPLASH" ||
	     cause == "MOD_PROJECTILE" ||
	     cause == "MOD_PROJECTILE_SPLASH" )
	{
		// if we are using this as a impact damage only projectile then no shellshock
		// we should probably add a bool to the weapon to indicate that it spawn protects
		if ( weapon.explosionradius == 0 )
			return;
		
		time = 0;
		
		if(damage >= 90)
			time = 4;
		else if(damage >= 50)
			time = 3;
		else if(damage >= 25)
			time = 2;
		else if(damage > 10)
			time = 2;
		
		if ( time )
		{
			if ( self util::mayApplyScreenEffect() && self HasPerk( "specialty_flakjacket" ) == false )
			{
				self shellshock("frag_grenade_mp", 0.5);
			}
		}
	}
}

function end_on_death()
{
	self waittill( "death" );
	waittillframeend;
	self notify ( "end_explode" );
}

function end_on_timer( timer )
{
	self endon( "disconnect" );

	wait( timer );
	self notify( "end_on_timer" );
}

function rcbomb_earthquake(position)
{
	PlayRumbleOnPosition( "grenade_rumble", position );
	Earthquake( 0.5, 0.5, self.origin, 512 );
}
function reset_meleeSnd()
{
	self endon ("death");
		
	wait (6);
	self clientfield::set_to_player("sndMelee", 0);
	self notify ("snd_melee_end");
}