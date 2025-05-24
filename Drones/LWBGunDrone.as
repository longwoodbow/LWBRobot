#include "LWBRobotCommon.as";

const u8 cooldown = 10;

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(10);
	this.getShape().SetRotationsAllowed(false);

	this.set_u8("cooldown", cooldown);
	this.addCommandID("shoot");

	CSpriteLayer@ hand = this.getSprite().addSpriteLayer("hand", "LWBShooterDrones.png" , 16, 16);

	if (hand !is null)
	{
		Animation@ anim = hand.addAnimation("default", 0, false);
		anim.AddFrame(2);
		hand.SetRelativeZ(1.5f);
	}
}

void onTick(CBlob@ this)
{
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

				if ((b.hasTag("player") || b.hasTag("boss")) && this.getTeamNum() != b.getTeamNum())
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

					if (this.get_u8("cooldown") == 0 && getNet().isServer())
					{
						hitvec.Normalize();

						CBlob@ bullet = server_CreateBlobNoInit("lwbgundronebullet");
						if (bullet !is null)
						{
							bullet.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
							bullet.Init();
						
							bullet.IgnoreCollisionWhileOverlapped(this);
							bullet.server_setTeamNum(this.getTeamNum());
							bullet.setPosition(this.getPosition());
							bullet.setVelocity(hitvec * 25.0f);
						}

						this.SendCommand(this.getCommandID("shoot"));
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
		this.getSprite().PlaySound("M16Fire.ogg");
	}
}