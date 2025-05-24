#include "LWBRobotCommon.as";

const u8 cooldown = 15;

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.server_SetTimeToDie(10);
	this.getShape().SetRotationsAllowed(false);

	this.set_u8("cooldown", cooldown);
	this.set_u8("beamTime", 0);
	this.addCommandID("shoot");

	CSpriteLayer@ hand = this.getSprite().addSpriteLayer("hand", "LWBShooterDrones.png" , 16, 16, this.getTeamNum(), 0);

	if (hand !is null)
	{
		Animation@ anim = hand.addAnimation("default", 0, false);
		anim.AddFrame(3);
		hand.SetRelativeZ(1.5f);
	}

	CSpriteLayer@ beam = this.getSprite().addSpriteLayer("beam", "LWBBeamDroneBeam.png" , 32, 8, this.getTeamNum(), 0);

	if (beam !is null)
	{
		Animation@ anim = beam.addAnimation("default", 0, false);
		anim.AddFrame(0);
		beam.SetRelativeZ(1.4f);
		beam.SetVisible(false);
	}
}

void onTick(CBlob@ this)
{
	// trail effect
	if (this.get_u8("beamTime") > 0)
	{
		this.sub_u8("beamTime", 1);

		CBlob@ enemy;
		if (this.get("target", @enemy))
		{
			Vec2f pos = this.getPosition();
			Vec2f targetPos = enemy.getPosition();
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

	if (this.get_u8("cooldown") > 0) this.sub_u8("cooldown", 1);
	//else
	{
		Vec2f pos = this.getPosition();

		CMap@ map = this.getMap();
		HitInfo@[] hitInfos;
		CBlob@ target;
		if (map.getHitInfosFromArc(pos, 0.0f, 360.0f, 500.0f, this, @hitInfos))
		{
			for (int i = 0; i < hitInfos.size(); i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;

				if (b is null) continue;

				Vec2f hitvec = hi.hitpos - pos;

				if (b.hasTag("player") && this.getTeamNum() != b.getTeamNum())
				{
					HitInfo@[] rayInfos;
					map.getHitInfosFromRay(pos, -(hitvec).getAngleDegrees(), hitvec.Length() + 2.0f, this, rayInfos);

					for (int j = 0; j < rayInfos.size(); j++)
					{
						CBlob@ rayb = rayInfos[j].blob;
						if (rayb is b)
						{
							@target = @b;
							break;
						}
					}
				}

				if (target !is null)
				{
					CSpriteLayer@ hand = this.getSprite().getSpriteLayer("hand");

					if (hand !is null)
					{
						hand.SetIgnoreParentFacing(true);
						hand.SetFacingLeft(false);
						hand.ResetTransform();
						hand.SetRelativeZ(1.5f);
						hand.RotateBy(-(hitvec).getAngleDegrees(), Vec2f_zero);
					}

					Vec2f force = hitvec;
					force.Normalize();

					this.AddForce(force * 0.1f);

					if (this.get_u8("cooldown") == 0 && hitvec.Length() <= 100.0f && getNet().isServer())
					{
						CBitStream params;
						params.write_netid(target.getNetworkID());
						this.SendCommand(this.getCommandID("shoot"), params);
						this.set_u8("cooldown", cooldown);
					}
					
					break;
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shoot"))
	{
		u16 enemyID;
		if(params is null || !params.saferead_netid(enemyID)) return;
		CBlob@ enemy = getBlobByNetworkID(enemyID);
		if (enemy is null) return;

		Vec2f velocity = enemy.getPosition() - this.getPosition();
		velocity.Normalize();

		this.server_Hit(enemy, enemy.getPosition(), velocity, 0.5f, LWBRobotHitters::energy_module, true);
		this.getSprite().PlaySound("maou_se_battle_gun05.ogg");

		this.set_u8("beamTime", 5);
		this.set("target", @enemy);
	}
}