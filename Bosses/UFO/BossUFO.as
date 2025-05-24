#include "LWBRobotCommon.as"

// skills

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.SetGravityScale(0.0f);
	shape.SetRotationsAllowed(false);
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;

	this.Tag("boss");
	this.set_u16("laser_time", 0);
	this.set_u16("attack_time", 0);

	this.addCommandID("shoot_laser");
	this.addCommandID("summon_drones");

	CSprite@ sprite = this.getSprite();

	sprite.RemoveSpriteLayer("beam");
	CSpriteLayer@ beam = sprite.addSpriteLayer("beam", "LWBOrbitalStrike.png" , 32, 16);

	if (beam !is null)
	{
		Animation@ anim = beam.addAnimation("default", 0, false);
		anim.AddFrame(0);
		beam.SetAnimation("default");
		beam.SetRelativeZ(-1.5f);
		beam.SetVisible(false);
	}

	for (u8 i = 0; i < 5; i++)
	{
		sprite.RemoveSpriteLayer("beamCharge" + i);
		CSpriteLayer@ beamCharge = sprite.addSpriteLayer("beamCharge" + i, "LWBOrbitalStrikeCharging.png" , 32, 1);

		if (beamCharge !is null)
		{
			Animation@ anim = beamCharge.addAnimation("default", 0, false);
			anim.AddFrame(0);
			beamCharge.SetAnimation("default");
			beamCharge.SetRelativeZ(-1.5f);
			beamCharge.SetVisible(false);
		}
	}
}

void onTick(CBlob@ this)
{
	CSprite @sprite = this.getSprite();

	if (sprite !is null)
	{
		Animation @destruction_anim = sprite.getAnimation("default");
		Animation @attack_anim = sprite.getAnimation("attack");

		if (destruction_anim !is null && attack_anim !is null)
		{
			if (this.getHealth() < this.getInitialHealth())
			{
				sprite.SetAnimation((this.get_u16("laser_time") > 0 || this.get_u16("attack_time") > 0) ? attack_anim : destruction_anim);
				f32 ratio = this.getHealth() / this.getInitialHealth();

				if (ratio <= 0.0f)
				{
					sprite.animation.frame = sprite.animation.getFramesCount() - 1;
				}
				else
				{
					sprite.animation.frame = (1.0f - ratio) * (sprite.animation.getFramesCount());
				}
			}
		}
	}

	// reset sprites
	string beamName = "beam";
	CSpriteLayer@ beam = this.getSprite().getSpriteLayer(beamName);
	if (beam !is null)
	{
		beam.SetVisible(false);
	}

	for (u8 i = 0; i < 5; i++)
	{
		string chargeName = "beamCharge" + i;
		CSpriteLayer@ charge = this.getSprite().getSpriteLayer(chargeName);

		if (charge !is null)
		{
			charge.SetVisible(false);
		}
	}

	if (this.get_u16("attack_time") > 0) this.sub_u16("attack_time", 1);
	u16 laserTime = this.get_u16("laser_time");
	if (laserTime > 0)
	{ 
		this.sub_u16("laser_time", 1);
		bool shootState =  laserTime <= 150;
		bool hitTick = laserTime % 3 == 0;
		bool isServer = getNet().isServer();

		if (laserTime == 150)
		{
			this.getSprite().PlaySound("maou_se_battle_explosion08.ogg");
		}

		Vec2f pos = this.getPosition();

		// offset
		Vec2f normVel = Vec2f(0.0f, 1.0f);
		Vec2f beamOff = normVel * 4.0f;
		beamOff.RotateBy(90.0f);

		CMap@ map = this.getMap();
		f32 finalHit = 0.0f;
		
		for (u8 i = 0; i < 5; i++)
		{
			Vec2f beamPos = pos + (beamOff * ((i + 1) / 2) * (i % 2 == 1 ? -1.0f : 1.0f));

			HitInfo@[] rayInfos;
			map.getHitInfosFromRay(beamPos, -(normVel).getAngleDegrees(), 1000.0f, this, rayInfos);
			f32 tempFinal = 1000.0f;

			for (int j = 0; j < rayInfos.size(); j++)
			{
				CBlob@ rayb = rayInfos[j].blob;
				
				if (rayb is null) // map hit
				{
					tempFinal = (rayInfos[j].hitpos - beamPos).getLength();
					
					if (isServer && hitTick && shootState && map.getSectorAtPosition(rayInfos[j].hitpos, "no build") is null)
					{
						for (int k = 0; k < 1; k++)
						{
							map.server_DestroyTile(rayInfos[j].hitpos, 0.1f, this);
							if (map.isTileBedrock(map.getTile(rayInfos[j].hitpos).type)) map.server_SetTile(rayInfos[j].hitpos, CMap::tile_thickstone);
						}
					}
					
					break;
				}
				if (rayb.hasTag("ignore sword")) continue;
				if (!canHit(this, rayb)) continue;
			
				bool large = (rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable()); // || (rayb.getName() == "lwbturretshield" && this.getTeamNum() != rayb.getTeamNum()); // usually doors, but can also be boats/some mechanisms
				
				Vec2f velocity = rayb.getPosition() - beamPos;
				velocity.Normalize();
				velocity *= 4; // knockback force is same regardless of distance
			
				if (isServer && hitTick && shootState && this.getTeamNum() != rayb.getTeamNum())
				{
					this.server_Hit(rayb, rayInfos[j].hitpos, velocity, 4.0f, LWBRobotHitters::energy, true);
				}
			
				if (large)
				{
					tempFinal = (rayInfos[j].hitpos - beamPos).getLength();
					break; // don't raycast past the door after we do damage to it
				}
			}

			if (!shootState)
			{
				string chargeName = "beamCharge" + i;
				CSpriteLayer@ charge = this.getSprite().getSpriteLayer(chargeName);

				if (charge !is null)
				{
					f32 beamlen = Maths::Max(0.1f, tempFinal / 32.0f);

					charge.ResetTransform();
					charge.SetIgnoreParentFacing(true);
					charge.SetFacingLeft(true);
					charge.SetOffset(beamOff * ((i + 1) / 2) * (i % 2 == 1 ? -1.0f : 1.0f));
					charge.ScaleBy(Vec2f(beamlen, 1.0f));

					charge.TranslateBy(Vec2f(beamlen * 16.0f, 0.0f));

					charge.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

					charge.SetVisible(true);
				}
			}

			// particles

			if (getNet().isClient())
			{
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
					CParticle@ p = ParticlePixelUnlimited(beamPos + Vec2f(tempFinal * XORRandom(256) / 255.0f, 0.0f).RotateBy(90.0f), Vec2f(0.1f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 256.0f), color, true);
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
			}

			finalHit = Maths::Max(tempFinal, finalHit);
		}

		//effect check
		if (shootState && beam !is null)
		{
			f32 beamlen = Maths::Max(0.1f, finalHit / 32.0f);

			beam.ResetTransform();
			beam.SetIgnoreParentFacing(true);
			beam.SetFacingLeft(false);
			beam.ScaleBy(Vec2f(beamlen, 1.0f));

			beam.TranslateBy(Vec2f(beamlen * 16.0f, 0.0f));

			beam.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

			beam.SetVisible(true);
		}
	}
}

// Blame Fuzzle.
bool canHit(CBlob@ this, CBlob@ b)
{
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();
	Vec2f pos;
	if (!params.saferead_Vec2f(pos)) pos = this.getPosition();
	Vec2f offsetPos = pos;// + Vec2f(this.isFacingLeft() ? 2 : -2, -2);// from archer logic
	Vec2f aimPos;
	if (!params.saferead_Vec2f(aimPos)) aimPos = this.getAimPos();
	Vec2f normVel = aimPos - offsetPos;
	normVel.Normalize();

	if (cmd == this.getCommandID("shoot_laser"))
	{
		this.getSprite().PlaySound("PowerUp.ogg");
		this.set_u16("laser_time", 210);
	}
	else if (cmd == this.getCommandID("summon_drones"))
	{
		this.getSprite().PlaySound("maou_se_sound_machine08.ogg");

		if (isServer)
		{
			for (int i = 0; i < 5; i++)
			{
				CBlob@ bullet = server_CreateBlob("boss_ufo_drone");//boss_ufo_minion
				if (bullet !is null)
				{
					bullet.IgnoreCollisionWhileOverlapped(this);
					bullet.server_setTeamNum(this.getTeamNum());
					bullet.setPosition(pos);
					bullet.setVelocity(Vec2f((1.0f + XORRandom(10)) * 0.1f, 0.0f).RotateBy(XORRandom(360)));
				}
			}
		}
		this.set_u16("attack_time", 30);
	}
}

void onDie(CBlob@ this)
{
	CBlob@ landed = server_CreateBlob("boss_ufo_landed");
	if (landed !is null)
	{
		landed.setPosition(this.getPosition());
		landed.server_setTeamNum(this.getTeamNum());
	}
}