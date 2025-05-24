// Robot logic

#include "ThrowCommon.as"
#include "LWBRobotCommon.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "KnockedCommon.as";
#include "LWBRobotHands.as";
#include "LWBRobotModules.as";

void onInit(CBlob@ this)
{
	if (this.exists("lefthand")) this.set_u8("lefthand", 0);
	if (this.exists("righthand")) this.set_u8("righthand", 0);
	if (this.exists("module")) this.set_u8("module", 0);

	LWBRobotInfo robot;
	this.set("robotInfo", @robot);

	if (this.get_u8("module") == LWBRobotModules::armour) this.set_f32("extra_health", this.getInitialHealth() * armour_health_ratio);

	actorlimit_setup(this);

	this.set_f32("gib health", -2.5f);
	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	this.Tag("player");
	//this.Tag("flesh");

	this.addCommandID("shoot_left");
	this.addCommandID("shoot_right");
	this.addCommandID("shoot_module");

	this.addCommandID("shoot_left_client");
	this.addCommandID("shoot_right_client");
	this.addCommandID("shoot_module_client");

	// init damage deal
	this.set_f32("damagedeal_left", 0.0f);
	this.set_f32("damagedeal_right", 0.0f);
	this.set_f32("damagedeal_module", 0.0f);

	//centered on inventory
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 0.0f);
	this.set_u8("custom_hitter", Hitters::keg);
	this.set_string("custom_explosion_sound", "Entities/Items/Explosives/KegExplosion.ogg");
	this.set_f32("map_damage_radius", 72.0f);
	this.set_f32("map_damage_ratio", 0.2f);
	this.set_bool("map_damage_raycast", true);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 3, Vec2f(16, 16));
	}
}

void onTick(CBlob@ this)
{
	if (this.isInInventory())
	{
		return;
	}

	bool knocked = isKnocked(this);

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	LWBRobotInfo@ robot;
	if (!this.get("robotInfo", @robot))
	{
		return;
	}

	// load loadout from player
	CPlayer@ player = this.getPlayer();
	CRules@ rules = getRules();
	if (player !is null && !this.hasTag("loadouted"))
	{
		if (rules.exists(player.getUsername() + "_robot_left")) this.set_u8("lefthand", rules.get_u8(player.getUsername() + "_robot_left"));
		if (rules.exists(player.getUsername() + "_robot_right")) this.set_u8("righthand", rules.get_u8(player.getUsername() + "_robot_right"));
		if (rules.exists(player.getUsername() + "_robot_module")) this.set_u8("module", rules.get_u8(player.getUsername() + "_robot_module"));

		this.Tag("loadouted");

		if (this.get_u8("module") == LWBRobotModules::armour) this.set_f32("extra_health", this.getInitialHealth() * armour_health_ratio);
		else this.set_f32("extra_health", 0.0f);
	}

	if (getRules().isWarmup()) return;

	if (knocked)
	{
		robot.lefthand_special = 0;
		robot.righthand_special = 0;
		robot.module_special = 0;
	}
	else
	{
		if (this.hasTag("energy_stun")) this.getSprite().PlaySound("maou_se_system02.ogg");
		this.Untag("energy_stun");
		u8 cooling = 0;

		// weapon cooldown
		if (robot.lefthand_energy  < weaponCooldown[this.get_u8("lefthand")])
		{
			robot.lefthand_energy++;
			if (this.get_u8("lefthand") != LWBRobotWeapons::shield) cooling++;
			//else if (robot.lefthand_energy  < weaponCooldown[robot.lefthand]) robot.lefthand_energy++; // shield has double regen
		}
		if (robot.righthand_energy < weaponCooldown[this.get_u8("righthand")])
		{
			robot.righthand_energy++;
			if (this.get_u8("righthand") != LWBRobotWeapons::shield) cooling++;
			//else if (robot.righthand_energy < weaponCooldown[robot.righthand]) robot.righthand_energy++;
		}
		if (robot.module_energy    < moduleCooldown[this.get_u8("module")])
		{
			robot.module_energy++;
		}

		// special control
		cooling += SpecialWeaponControl(this, robot, true);
		cooling += SpecialWeaponControl(this, robot, false);
		SpecialModuleControl(this, robot);

		if ((this.get_u8("module") == LWBRobotModules::sunbeam || this.get_u8("module") == LWBRobotModules::emp) && robot.module_special > 0)
		{
			//moveVars.jumpFactor *= 0.0f;
			//moveVars.walkFactor *= 0.0f;
			return;
		}

		// slowing while weapon cooldown
		if (cooling >= 2)
		{
			moveVars.jumpFactor *= 0.5f;
			moveVars.walkFactor *= 0.5f;
		}
		else if (cooling >= 1)
		{
			moveVars.jumpFactor *= 0.7f;
			moveVars.walkFactor *= 0.7f;
		}

		if (this.get_u8("module") == LWBRobotModules::movement)
		{
			moveVars.jumpFactor *= 1.5f;
			moveVars.walkFactor *= 1.5f;
		}

		bool isMyPlayer = this.isMyPlayer();
		CHUD@ hud = getHUD();

		// shoot

		// left hand
		if (isShootWeapon(this.get_u8("lefthand")) && robot.lefthand_energy >= weaponCooldown[this.get_u8("lefthand")] && this.isKeyPressed(key_action1))
		{
			if (isMyPlayer && !hud.hasButtons())
			{
				CBitStream params;
				params.write_Vec2f(this.getPosition());
				params.write_Vec2f(this.getAimPos());
				this.SendCommand(this.getCommandID("shoot_left"), params);
			}
			robot.lefthand_energy = 0;
		}
		// right hand
		if (isShootWeapon(this.get_u8("righthand")) && robot.righthand_energy >= weaponCooldown[this.get_u8("righthand")] && this.isKeyPressed(key_action2))
		{
			if (isMyPlayer && !hud.hasButtons())
			{
				CBitStream params;
				params.write_Vec2f(this.getPosition());
				params.write_Vec2f(this.getAimPos());
				this.SendCommand(this.getCommandID("shoot_right"), params);
			}
			robot.righthand_energy = 0;
		}
		// module
		if (isShootModule(this.get_u8("module")) && robot.module_energy >= moduleCooldown[this.get_u8("module")] && this.isKeyPressed(key_action3))
		{
			if (isMyPlayer && !hud.hasButtons())
			{
				CBitStream params;
				params.write_Vec2f(this.getPosition());
				params.write_Vec2f(this.getAimPos());
				this.SendCommand(this.getCommandID("shoot_module"), params);
			}
			robot.module_energy = 0;
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	LWBRobotInfo@ robot;
	if (!this.get("robotInfo", @robot))
	{
		return;
	}

	if (cmd == this.getCommandID("shoot_left") && isServer())
	{
		weaponOperate_server(this, robot, true, @params);
	}
	else if (cmd == this.getCommandID("shoot_right") && isServer())
	{
		weaponOperate_server(this, robot, false, @params);
	}
	else if (cmd == this.getCommandID("shoot_module") && isServer())
	{
		moduleOperate_server(this, robot, @params);
	}
	else if (cmd == this.getCommandID("shoot_left_client") && isClient())
	{
		weaponOperate_client(this, robot, true, @params);
	}
	else if (cmd == this.getCommandID("shoot_right_client") && isClient())
	{
		weaponOperate_client(this, robot, false, @params);
	}
	else if (cmd == this.getCommandID("shoot_module_client") && isClient())
	{
		moduleOperate_client(this, robot, @params);
	}
}

// damage deal check, shield system and armour modules
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	LWBRobotInfo@ robot;
	if (!this.get("robotInfo", @robot))
	{
		return damage;
	}

	u8 damageType = getDamageType(customData);

	if (damageType == LWBRobotHitters::physical && this.get_u8("module") == LWBRobotModules::armour) damage *= 0.8f;
	if (damageType == LWBRobotHitters::energy && this.get_u8("module") == LWBRobotModules::specialarmour) damage *= 0.5f;

	CBlob@ attacker = @hitterBlob;
	CPlayer@ owner = hitterBlob.getDamageOwnerPlayer();

	if (hitterBlob.getName() != "lwbrobot" && owner !is null)
	{
		CBlob@ ownerBlob = owner.getBlob();

		if (ownerBlob !is null)
		{
			@attacker = @ownerBlob;
		}
	}

	f32 damagedeal = damage;

	bool shieldHit = false;

	// hand shield
	if (velocity != Vec2f_zero)
	{

		// check dif of angles
		f32 shieldAngle = (this.getAimPos() - this.getPosition()).getAngleDegrees() - 180.0f;
		f32 dif = velocity.getAngleDegrees() - shieldAngle;

		while (dif > 180.0f)
		{
			dif -= 360.0f;
		}
		while (dif < -180.0f)
		{
			dif += 360.0f;
		}

		if (dif < 75.0f && dif > -75.0f)
		{
			// take damage using shield energy
			// left hand
			if (this.get_u8("lefthand") == LWBRobotWeapons::shield && this.isKeyPressed(key_action1))
			{
				shieldHit = true;
				if (f32(robot.lefthand_energy) / 20.0f >= damage)
				{
					robot.lefthand_energy -= uint(damage * 20.0f);
					damage = 0;
				}
				else
				{
					damage -= robot.lefthand_energy / 20.0f;
					robot.lefthand_energy = 0;
				}
			}
			// right hand
			if (this.get_u8("righthand") == LWBRobotWeapons::shield && this.isKeyPressed(key_action2))
			{
				shieldHit = true;
				if (f32(robot.righthand_energy) / 20.0f >= damage)
				{
					robot.righthand_energy -= uint(damage * 20.0f);
					damage = 0;
				}
				else
				{
					damage -= robot.righthand_energy / 20.0f;
					robot.righthand_energy = 0;
				}
			}
		}
	}

	// module shield

	if (this.get_u8("module") == LWBRobotModules::shield)
	{
		shieldHit = true;
		if (f32(robot.module_energy) / 30.0f >= damage)
		{
			robot.module_energy -= uint(damage * 30.0f);
			damage = 0;
		}
		else
		{
			damage -= robot.module_energy / 30.0f;
			robot.module_energy = 0;
		}
	}

	// hit effect
	if (shieldHit)
	{
		this.getSprite().PlaySound("WaterBubble?.ogg");
	}
	
	// send damage deal
	if (attacker.getTeamNum() != this.getTeamNum())
	{
		if (damage > getActualHealth(this) * 2.0f) damagedeal = getActualHealth(this) * 2.0f;

		if (customData == LWBRobotHitters::physical_left || customData == LWBRobotHitters::energy_left) attacker.add_f32("damagedeal_left", damagedeal);
		else if (customData == LWBRobotHitters::physical_right || customData == LWBRobotHitters::energy_right) attacker.add_f32("damagedeal_right", damagedeal);
		else if (customData == LWBRobotHitters::physical_module || customData == LWBRobotHitters::energy_module) attacker.add_f32("damagedeal_module", damagedeal);
	}

	return damage;
}