//common robot header
#include "Hitters.as";

// consts
const f32 armour_health_ratio = 0.5f;

namespace LWBRobotHitters
{
	enum Type
	{
		physical = 111,
		energy,

		// for damage deal info
		physical_left,
		physical_right,
		physical_module,
		energy_left,
		energy_right,
		energy_module
	}
}

// add new hitters here, if it's energy damage
u8 getDamageType(u8 type)
{
	if (type == LWBRobotHitters::energy ||
		type == LWBRobotHitters::energy_left ||
		type == LWBRobotHitters::energy_right ||
		type == LWBRobotHitters::energy_module ||
		type == Hitters::fire ||
		type == Hitters::burn ||
		type == Hitters::drown ||
		type == Hitters::suddengib)
	{
		return LWBRobotHitters::energy;
	}
	else
	{
		return LWBRobotHitters::physical;
	}
}

namespace LWBRobotWeapons
{
	enum Weapons
	{
		cannon = 0,
		gatling,
		railgun,
		rocket,
		homing,
		grenade,
		blade,
		buster,
		laser,
		beam,
		plasma,
		napalm,
		lightning,
		energyblade,
		shield,
		sawboomelang,
		diffuser,
		planet,
		energyball,
		count
	}
}

const u16[] weaponCooldown =
{
	30, // cannon
	4,   // gatling
	150, // railgun
	125, // rocket
	150, // homing
	60, // grenade
	24, // blade
	30, // buster
	3, // laser
	150, // beam
	120, // plasma
	120, // napalm
	120, // lightning
	18, // energyblade
	300, // shield
	100, // sawboomelang
	5, // diffuser
	150, // planet
	75 // energyball
};

const string[] weaponNames =
{
	"Cannon", // cannon
	"Gatling", // gatling
	"Railgun", // raingun
	"Rocket Launcher", // rocket
	"Homing Missile", // homing
	"Grenade Launcher", // grenade
	"Blade", // blade
	"Buster", // buster
	"Laser", // laser
	"Beam Cannon", //beam
	"Plasma Torpedo Launcher", // plasma
	"Napalm Bomb", // napalm
	"Lightning Shooter", // lightning
	"Energy Blade", // energyblade
	"Shield", // shield
	"Saw Thrower", // sawboomelang
	"Diffuser", // diffuser
	"Planet Shooter", //planet
	"Energy Ball Shooter" //energyball
};

const string[] weaponDescriptions =
{
	// cannon
	"Type:Physical\n\nBasic physical weapon.",
	// gatling
	"Type:Physical\n\nRapid fire weapon with low accuracy.",
	// railgun
	"Type:Physical\n\nHigh damage and velocity weapon. Useful for sniping.",
	// rocket
	"Type:Physical\n\nLaunch the rocket with high power explosive.",
	// homing
	"Type:Physical\n\nLauch the rocket that follows your cursor.",
	// grenade
	"Type:Physical\n\nShoot high power bomb with medium fire rate.",
	// blade
	"Type:Physical\n\nMelee weapon.",
	// buster
	"Type:Energy\n\nBasic energy weapon. Has a little slower velocity but no gravity.",
	// laser
	"Type:Energy\n\nLong range, high fire rate with low damage.",
	// beam
	"Type:Energy\n\nAfter charging, shoot high power beam. Has mid-long range and low fire rate.",
	// plasma
	"Type:Energy\n\nShoot the plasma that follows your cursor. Hits enemies while overlapping and explodes at the end.",
	// napalm
	"Type:Energy\n\nThrow the napalm bomb that makes flame lasts longer.",
	// lightning
	"Type:Energy\n\nShoot the lightning to short range. It causes stunning enemy.",
	// energyblade
	"Type:Energy\n\nEnergy version blade.",
	// shield
	"Takes over the damage with its energy. It also loses its energy while active.",
	// sawboomelang
	"Type:Physical\n\nThrow a sawblade like boomelang.",
	// diffuser
	"Type:Energy\n\nDiffuse energy like flamethrower.",
	// growingplasma
	"Type:Physical\nIdea by ban all sandwiches\n\nShoot the planet that fly and make child planet.",
	// energyball
	"Type:Energy\n\nShoot a bouncy deadly ball;"
};

namespace LWBRobotModules
{
	enum Modules
	{
		armour = 0,
		specialarmour,
		jetpack,
		movement,
		shield,
		nanohealer,
		healdrone,
		shieldturret,
		homingmissile,
		clustermissile,
		saw,
		sunbeam,
		orbit,
		emp,
		gundrone,
		beamdrone,
		antigravity,
		disperser,
		count
	}
}

const u16[] moduleCooldown =
{
	0, // armour
	0, // specialarmour
	150, // jetpack
	0, // movement
	120, // shield,
	0, // nanohealer
	360, // healdrone
	360, // shieldturret
	350, // homingmissile
	150, // clustermissile
	0, // saw
	400, // sunbeam
	400, // orbit
	240, // emp
	210, // gundrone
	210, // beamdrone
	270, // antigravity
	180 // disperser
};

const string[] moduleNames =
{
	"Additional Armour", // armour
	"Special Armour", // specialarmour
	"Jet Pack", // jetpack
	"Movement Reinforcement", // movement
	"Shield Generator", // shield
	"Healing Nanomachine Diffuser", // nanohealer
	"Healing Drone Factory", // healdrone
	"Shield Turret Factory", // shieldturret
	"Homing Missile Pod", // homingmissile
	"Cluster Missile Pod", // clustermissile
	"Sawblade Drones", // saw
	"Sun Beam Shooter", // sunbeam
	"Orbital Strike Relay", // orbit
	"EMP Shooter", // emp
	"Gun Drone Factory", // gundrone
	"Beam Drone Factory", // beamdrone
	"Antigravity Field Maker Factory", // antigravity
	"Energy ball disperser" // disperser
};

const string[] moduleDescriptions =
{
	// armour
	"Reinforce the body.\nGet 50% more health and 20% physical damage resistance.",
	// specialarmour
	"Specially processed armor.\nGet 50% energy damage resistance. Also reduces duarition of energy damage stun.",
	// jetpack
	"Allow you to fly using its energy.",
	// movement
	"Reinforce your legs.\nIncrease walk speed and jump height, also decrease fall damage.",
	// shield
	"Takes over the damage with its energy.",
	// nanohealer
	"Heal yourself and nearby allies.",
	// healdrone
	"Summon a drone that heal yourself or nearby ally.",
	// shieldturret
	"Summon a turret that deploys shield for protect you from projectiles.",
	// homingmissile
	"Type:Physical\n\nShoot 4 missiles to above. They targets enemies automatically.",
	// clustermissile
	"Type:Physical\n\nShoot a missile to above. It flies to aimed point and drop bombs to ground.",
	// saw
	"Type:Physical\n\nSawblade drones fly around you and hit collided enemies.",
	// sunbeam
	"Type:Energy\n\nAfter charging, shoot the deadly beam. Be careful that it kills everything.",
	// orbit
	"Type:Energy\n\nRequest the orbital strike of beam to aimed point.",
	// emp
	"After charging, shoot the EMP that stuns enemies.",
	// gundrone
	"Type:Physical\n\nBuild drones that follow you and shoot enemies.",
	// beamdrone
	"Type:Energy\n\nBuild drones that follow you and shoot enemies.\nShorter range but instant hit.",
	// antigravity
	"Summon a turret that deploys antigravity field for jamming enemy robots and projectiles.",
	//
};

bool isShootWeapon(u8 type)
{
	return type != LWBRobotWeapons::shield;
}

bool isShootModule(u8 type)
{
	return type != LWBRobotModules::armour &&
		   type != LWBRobotModules::specialarmour &&
		   type != LWBRobotModules::jetpack &&
		   type != LWBRobotModules::movement &&
		   type != LWBRobotModules::shield &&
		   type != LWBRobotModules::nanohealer &&
		   type != LWBRobotModules::saw;
}

shared class LWBRobotInfo
{
	//u8 lefthand = 0;// weapon id
	u16 lefthand_energy = 0;// cooldown or shield power
	u16 lefthand_special = 0;// blade hit time, etc

	//u8 righthand = 0;
	u16 righthand_energy = 0;
	u16 righthand_special = 0;

	//u8 module = 0;
	u16 module_energy = 0;
	u16 module_special = 0;

	WeaponEffectInfo[] effects;
};

// heal robot, add extra health if has armour module
void HealRobot(CBlob@ this, f32 amount)
{
	f32 oldHealth = this.getHealth();
	this.server_Heal(amount);
	if (this.get_u8("module") == LWBRobotModules::armour)
	{
		this.set_f32("extra_health", Maths::Min(this.getInitialHealth() * armour_health_ratio, this.get_f32("extra_health") + amount / 2.0f + oldHealth - this.getHealth()));
		this.Sync("extra_health", true);
	}
}

f32 getActualMaxHealth(CBlob@ this)
{
	bool isArmour = this.get_u8("module") == LWBRobotModules::armour;
	return this.getInitialHealth() * (isArmour ? (1.0f + armour_health_ratio) : 1.0f);
}

f32 getActualHealth(CBlob@ this)
{
	return this.getHealth() + this.get_f32("extra_health");
}

f32 getActualDamage(CBlob@ this)
{
	return getActualMaxHealth(this) - getActualHealth(this);
}

shared class WeaponEffectInfo
{
	u8 type;
	string name;
	uint endTime;
	Vec2f shootingPos;
	Vec2f offset;
}

// Blame Fuzzle.
bool canHit_robot(CBlob@ this, CBlob@ b)
{
	if (b.getName() == "lwbturretshield") // special hit
		return true;

	if (b.hasTag("invincible") || b.hasTag("temp blob"))
		return false;

	// don't hit picked up items
	CAttachment@ att = b.getAttachments();
	if (att !is null)
	{
		AttachmentPoint@ point = att.getAttachmentPointByName("PICKUP");
		if (point !is null && !point.socket &&
			b.isAttachedToPoint("PICKUP") && !b.hasTag("slash_while_in_hand")) return false;
	}

	if (b.hasTag("dead"))
		return true;

	return !b.hasTag("projectile");

}

void makeHealerParticles(Vec2f pos)
{
	if (!getNet().isClient()) return;

	for (int i = 0; i < 8; i++)
	{
		CParticle@ p = ParticlePixelUnlimited(pos + Vec2f(f32(XORRandom(256)) * 50.0f / 255.0f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 255.0f), Vec2f(0.1f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 256.0f), SColor(0x8000ff00), true);
		if(p !is null)
		{
		    p.collides = true;
		    p.gravity = Vec2f_zero;
		    p.bounce = 0;
		    p.Z = 7;
		    p.timeout = 10;
			p.setRenderStyle(RenderStyle::light);
		}
	}
	
	CParticle@ p = ParticleAnimated("HealParticle2.png", pos + Vec2f(f32(XORRandom(256)) * 50.0f / 255.0f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 255.0f), Vec2f(0,0),  0.0f, 1.0f, 1+XORRandom(5), -0.1f, false);
	if (p !is null)
	{
		p.diesoncollide = true;
		p.fastcollision = true;
		p.lighting = true; // required unless you want it so show up under ground
	}
}