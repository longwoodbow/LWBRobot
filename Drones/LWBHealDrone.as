#include "LWBRobotCommon.as";

const u8 cooldown = 30;

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);
	this.set_u8("cooldown", cooldown);
	this.set_u8("beamTime", 0);
	this.addCommandID("heal");
	this.server_SetTimeToDie(10);

	CSpriteLayer@ beam = this.getSprite().addSpriteLayer("beam", "LWBDroneHealBeam.png" , 32, 7);

	if (beam !is null)
	{
		Animation@ anim = beam.addAnimation("default", 0, false);
		anim.AddFrame(0);
		beam.SetRelativeZ(1.5f);
		beam.SetVisible(false);
	}
}

void onTick(CBlob@ this)
{
	// trail effect
	if (this.get_u8("beamTime") > 0)
	{
		this.sub_u8("beamTime", 1);

		CBlob@ ally;
		if (this.get("target", @ally))
		{
			Vec2f pos = this.getPosition();
			Vec2f targetPos = ally.getPosition();
			Vec2f beamVec = targetPos - pos;
	
			CSpriteLayer@ beam = this.getSprite().getSpriteLayer("beam");
	
			if (beam !is null)
			{
				beam.SetVisible(true);
				f32 beamlen = Maths::Max(0.1f, beamVec.Length() / 32.0f);
	
				beam.ResetTransform();
				beam.SetIgnoreParentFacing(true);
				beam.SetFacingLeft(false);
				beam.ScaleBy(Vec2f(beamlen, 1.0f));
	
				beam.TranslateBy(Vec2f(beamlen * 16.0f, 0.0f));
	
				beam.RotateBy(-(beamVec).getAngleDegrees() , Vec2f());
			}
		}
	}
	else
	{
		CSpriteLayer@ beam = this.getSprite().getSpriteLayer("beam");
	
		if (beam !is null)
		{
			beam.SetVisible(false);
		}
	}

	if (!getNet().isServer()) return;

	if (this.get_u8("cooldown") > 0) this.sub_u8("cooldown", 1);
	else
	{
		Vec2f pos = this.getPosition();

		CMap@ map = this.getMap();
		HitInfo@[] hitInfos;
		CBlob@ target;
		if (map.getHitInfosFromArc(pos, 0.0f, 360.0f, 50.0f, this, @hitInfos))
		{
			for (int i = 0; i < hitInfos.size(); i++)
			{
				CBlob@ b = hitInfos[i].blob;
				if (b is null) continue;

				if (b.getName() == "lwbrobot" && this.getTeamNum() == b.getTeamNum() && getActualDamage(b) > 0.0f)
				{
					if (target is null || getActualHealth(target) > getActualHealth(b))
					{
						@target = @b;
					}
				}
			}

			if (target !is null)
			{
				HealRobot(target, 1.0f);
				CBitStream params;
				params.write_netid(target.getNetworkID());
				this.SendCommand(this.getCommandID("heal"), params);
				this.set_u8("cooldown", cooldown);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("heal") && getNet().isClient())
	{
		u16 allyID;
		if(params is null || !params.saferead_netid(allyID)) return;
		CBlob@ ally = getBlobByNetworkID(allyID);
		if (ally is null) return;

		this.getSprite().PlaySound("Heart.ogg");

		this.set_u8("beamTime", 15);
		this.set("target", @ally);
	}
}