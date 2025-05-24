// TDM Ruins logic
// added no destroy tiles, robot equipment changing system and heal

#include "LWBRobotCommon.as"
#include "StandardRespawnCommand.as"
#include "StandardControlsCommon.as"
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.CreateRespawnPoint("ruins", Vec2f(0.0f, 16.0f));
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;
	this.addCommandID("change_left");
	this.addCommandID("change_right");
	this.addCommandID("change_module");
	this.addCommandID("change_left_client");
	this.addCommandID("change_right_client");
	this.addCommandID("change_module_client");
	this.Tag("invincible");

	this.Tag("change class drop inventory");

	this.getSprite().SetZ(-50.0f);   // push to background
	// defaultnobuild
	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));
}

// shield and heal
void onTick(CBlob@ this)
{
	CBlob@[] temp;
	if (getBlobsByName("robot_spawn_shield", @temp))
	{
		bool hasShieldMaker = false;
		for (int i = 0; i < temp.length; i++)
		{
			CBlob@ maker = temp[i];
			u8 team = maker.getTeamNum();
			if (team == 255 || team == this.getTeamNum())
			{
				hasShieldMaker = true;
				break;
			}
		}

		if (hasShieldMaker)
		{
			this.Tag("invincible");

			Vec2f pos = this.getPosition();

			SColor color;
			switch (this.getTeamNum())
			{
				case 0:
				color = SColor(0xf01d85ab);
				break;

				case 1:
				color = SColor(0xf0b73333);
				break;
				
				case 2:
				color = SColor(0xf0649b0d);
				break;
				
				case 3:
				color = SColor(0xf09e3abb);
				break;
				
				case 4:
				color = SColor(0xf0cd6120);
				break;
				
				case 5:
				color = SColor(0xf04f9b7f);
				break;
				
				case 6:
				color = SColor(0xf04149f0);
				break;
				
				default:
				color = SColor(0xf097a792);
				break;
			}


			for (int i = 0; i < 4; i++)
			{
				CParticle@ p1 = ParticlePixelUnlimited(pos + Vec2f(50.0f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 256.0f), Vec2f_zero, color, true);
				if(p1 !is null)
				{
				    p1.collides = true;
				    p1.gravity = Vec2f_zero;
				    p1.bounce = 0;
				    p1.Z = 7;
				    p1.timeout = 10;
					p1.setRenderStyle(RenderStyle::light);
				}

				CParticle@ p2 = ParticlePixelUnlimited(pos + Vec2f(f32(XORRandom(256)) * 50.0f / 256.0f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 256.0f), Vec2f(0.1f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 256.0f), color, true);
				if(p2 !is null)
				{
				    p2.collides = true;
				    p2.gravity = Vec2f_zero;
				    p2.bounce = 0;
				    p2.Z = 7;
				    p2.timeout = 10;
					p2.setRenderStyle(RenderStyle::light);
				}
			}
		}
		else this.Untag("invincible");
	}

	Vec2f pos = this.getPosition();

	if (getNet().isServer() && getGameTime() % 20 == 0)
	{
		CBlob@[] blobs;
		this.getMap().getBlobsInRadius(pos, 50.0f, @blobs);
		for (int i = 0; i < blobs.size(); i++)
		{
			if (blobs[i].getName() == "lwbrobot" && blobs[i].getTeamNum() == this.getTeamNum())
			{
				HealRobot(blobs[i], 0.25f);
			}
		}
	}
	
	makeHealerParticles(pos);
}


void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	
	u16 callerID;
	if (!params.saferead_u16(callerID)) return;
	u8 selected;
	if (!params.saferead_u8(selected)) return;

	CBlob@ caller = getBlobByNetworkID(callerID);
	if (caller is null) return;

	CPlayer@ player = caller.getPlayer();
	bool hasPlayer = player !is null;

	CRules@ rules = getRules();

	if (caller !is null)
	{
		LWBRobotInfo@ robot;
		if (!caller.get("robotInfo", @robot))
		{
			return;
		}

		if (cmd == this.getCommandID("change_left") || cmd == this.getCommandID("change_left_client"))
		{
			caller.set_u8("lefthand", selected);
			robot.lefthand_energy = 0;
			robot.lefthand_special = 0;
			if (hasPlayer)
			{
				rules.set_u8(player.getUsername() + "_robot_left", selected);
			}

			if (!isClient() && cmd != this.getCommandID("change_left_client"))
			{
				CBitStream sendparams;
				sendparams.write_u16(callerID);
				sendparams.write_u8(selected);
				this.SendCommand(this.getCommandID("change_left_client"), sendparams);
			}
		}
		else if (cmd == this.getCommandID("change_right") || cmd == this.getCommandID("change_right_client"))
		{
			caller.set_u8("righthand", selected);
			robot.righthand_energy = 0;
			robot.righthand_special = 0;
			if (hasPlayer)
			{
				rules.set_u8(player.getUsername() + "_robot_right", selected);
			}

			if (!isClient() && cmd != this.getCommandID("change_right_client"))
			{
				CBitStream sendparams;
				sendparams.write_u16(callerID);
				sendparams.write_u8(selected);
				this.SendCommand(this.getCommandID("change_right_client"), sendparams);
			}
		}
		else if (cmd == this.getCommandID("change_module") || cmd == this.getCommandID("change_module_client"))
		{
			caller.set_u8("module", selected);
			robot.module_energy = 0;
			robot.module_special = 0;
			if (hasPlayer)
			{
				rules.set_u8(player.getUsername() + "_robot_module", selected);
			}

			if (!isClient() && cmd != this.getCommandID("change_module_client"))
			{
				CBitStream sendparams;
				sendparams.write_u16(callerID);
				sendparams.write_u8(selected);
				this.SendCommand(this.getCommandID("change_module_client"), sendparams);
			}

			// health check
			if (caller.get_u8("module") == LWBRobotModules::armour) caller.set_f32("extra_health", caller.getInitialHealth() * armour_health_ratio);
			else caller.set_f32("extra_health", 0.0f);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (canChangeClass(this, caller))
	{
		caller.CreateGenericButton("$change_class$", Vec2f(-6, 0), this, createLeftHandMenu, "Change Left Hand");
		caller.CreateGenericButton("$change_class$", Vec2f(6, 0), this, createRightHandMenu, "Change Right Hand");
		caller.CreateGenericButton("$change_class$", Vec2f(0, 6), this, createModuleMenu, "Change Module");
	}
}

void createLeftHandMenu(CBlob@ this, CBlob@ caller)
{
	// is this the robot?
	LWBRobotInfo@ robot;
	if (!caller.get("robotInfo", @robot))
	{
		return;
	}

	// load icons
	for (int i = 0; i < LWBRobotWeapons::count; i++)
	{
		AddIconToken("$lwbweapon" + i + "$", "LWBRobotHands.png", Vec2f(32, 16), i, caller.getTeamNum());
	}

	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos(), this, Vec2f(8, 5), "Weapons: Left Click");

	if (menu !is null)
	{
		menu.deleteAfterClick = true;
		for (u8 i = 0 ; i < LWBRobotWeapons::count; i++)
		{
			CBitStream params;

			params.write_u16(caller.getNetworkID());
			params.write_u8(i);

			CGridButton@ button = menu.AddButton("$lwbweapon" + i + "$", weaponNames[i], this.getCommandID("change_left"), Vec2f(2, 1), params);
			
			if (button !is null)
			{
				button.hoverText = weaponDescriptions[i];
				if (caller.get_u8("lefthand") == i) button.SetSelected(1);
			}
		}
	}
}

void createRightHandMenu(CBlob@ this, CBlob@ caller)
{
	// is this the robot?
	LWBRobotInfo@ robot;
	if (!caller.get("robotInfo", @robot))
	{
		return;
	}

	// load icons
	for (int i = 0; i < LWBRobotWeapons::count; i++)
	{
		AddIconToken("$lwbweapon" + i + "$", "LWBRobotHands.png", Vec2f(32, 16), i, caller.getTeamNum());
	}

	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos(), this, Vec2f(8, 5), "Weapons: Right Click");

	if (menu !is null)
	{
		menu.deleteAfterClick = true;
		for (u8 i = 0 ; i < LWBRobotWeapons::count; i++)
		{
			CBitStream params;

			params.write_u16(caller.getNetworkID());
			params.write_u8(i);

			CGridButton@ button = menu.AddButton("$lwbweapon" + i + "$", weaponNames[i], this.getCommandID("change_right"), Vec2f(2, 1), params);
			
			if (button !is null)
			{
				button.hoverText = weaponDescriptions[i];
				if (caller.get_u8("righthand") == i) button.SetSelected(1);
			}
		}
	}
}

void createModuleMenu(CBlob@ this, CBlob@ caller)
{
	// is this the robot?
	LWBRobotInfo@ robot;
	if (!caller.get("robotInfo", @robot))
	{
		return;
	}

	// load icons
	for (int i = 0; i < LWBRobotModules::count; i++)
	{
		AddIconToken("$lwbmodule" + i + "$", "LWBRobotModules.png", Vec2f(16, 16), i, caller.getTeamNum());
	}

	CGridMenu@ menu = CreateGridMenu(caller.getScreenPos(), this, Vec2f(4, 5), "Modules: Space Key");

	if (menu !is null)
	{
		menu.deleteAfterClick = true;
		for (u8 i = 0 ; i < LWBRobotModules::count; i++)
		{
			CBitStream params;

			params.write_u16(caller.getNetworkID());
			params.write_u8(i);

			CGridButton@ button = menu.AddButton("$lwbmodule" + i + "$", moduleNames[i], this.getCommandID("change_module"), Vec2f(1, 1), params);
			
			if (button !is null)
			{
				button.hoverText = moduleDescriptions[i];
				if (caller.get_u8("module") == i) button.SetSelected(1);
			}
		}
	}
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	return (this.getPosition() - caller.getPosition()).Length() < this.getRadius();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("invincible")) return 0.0f;
	else return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !this.hasTag("invincible") && this.getTeamNum() != blob.getTeamNum() && blob.hasTag("projectile");
}