#include "LWBRobotCommon.as"

// skills

void actorlimit_setup(CBlob@ this)
{
	u16[] networkIDs;
	this.set("LimitedActors", networkIDs);
}

bool has_hit_actor(CBlob@ this, CBlob@ actor)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.find(actor.getNetworkID()) >= 0;
}

u32 hit_actor_count(CBlob@ this)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.length;
}

void add_actor_limit(CBlob@ this, CBlob@ actor)
{
	this.push("LimitedActors", actor.getNetworkID());
}

void clear_actor_limits(CBlob@ this)
{
	this.clear("LimitedActors");
}

void onInit(CBlob@ this)
{
	this.server_SetHealth(getRules().get_f32("boss_health"));

	this.getShape().SetRotationsAllowed(false);

	actorlimit_setup(this);
	
	this.Tag("boss");
	this.set_u16("buster_time", 0);
	this.set_u16("sword_time", 0);
	//this.set_bool("awaken", false);

	this.addCommandID("sword");
	this.addCommandID("buster");
	//this.addCommandID("awaken");

	CSprite@ sprite = this.getSprite();

	sprite.SetAnimation("awaken");

	sprite.RemoveSpriteLayer("edge");
	CSpriteLayer@ edge = sprite.addSpriteLayer("edge", "BossUFOEdge.png" , 64, 64);

	if (edge !is null)
	{
		Animation@ anim = edge.addAnimation("default", 1, false);
		anim.AddFrame(0);
		anim.AddFrame(1);
		anim.AddFrame(2);
		edge.SetRelativeZ(1000.0f);
		edge.SetVisible(false);
	}

}

void onTick(CBlob@ this)
{
	CSprite @sprite = this.getSprite();

	if (sprite.isAnimation("awaken") && sprite.isAnimationEnded())
	{
		sprite.SetAnimation("default");
	}

	Vec2f vec;
	this.getAimDirection(vec);

	u16 swordTime = this.get_u16("sword_time");
	if (swordTime > 0)
	{
		DoAttack(this, 5.0f, -(vec.Angle()), 60.0f, LWBRobotHitters::energy, swordTime);

		this.sub_u16("sword_time", 1);
	}

	CSpriteLayer@ effect = sprite.getSpriteLayer("edge");
	if (effect !is null)
	{
		if (effect.isAnimationEnded())
			effect.SetVisible(false);

		f32 chopAngle = -vec.Angle();
		f32 choplength = 60.0f;

		Vec2f offset = Vec2f(choplength, 0.0f);
		offset.RotateBy(chopAngle, Vec2f_zero);
		if (!this.isFacingLeft())
			offset.x *= -1.0f;
		offset.y += sprite.getOffset().y * 0.5f;

		effect.SetOffset(offset);
		effect.ResetTransform();
		/*if (this.isFacingLeft())
			effect.RotateBy(180.0f + chopAngle, Vec2f());
		else*/
			effect.RotateBy(chopAngle, Vec2f());
	}

	u16 busterTime = this.get_u16("buster_time");
	if (busterTime > 0)
	{
		this.sub_u16("buster_time", 1);
		if (busterTime % 5 == 0)
		{
			this.getSprite().PlaySound("maou_se_magic_fire09.ogg");
			if (getNet().isServer())
			{
				CBlob@ bullet = server_CreateBlob("robotbuster");
				if (bullet !is null)
				{
					bullet.IgnoreCollisionWhileOverlapped(this);
					bullet.server_setTeamNum(this.getTeamNum());
					bullet.setPosition(this.getPosition());
					Vec2f shootVel = this.getAimPos() - this.getPosition();
					shootVel.Normalize();
					bullet.setVelocity(shootVel * 8.0f);
				}
			}
		}
	}
}

// from knight logic
void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type, int deltaInt)
{
	if (!getNet().isServer())
	{
		return;
	}

	if (aimangle < 0.0f)
	{
		aimangle += 360.0f;
	}

	Vec2f blobPos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f thinghy(1, 0);
	thinghy.RotateBy(aimangle);
	Vec2f pos = blobPos - thinghy * 6.0f + vel + Vec2f(0, -2);
	vel.Normalize();

	f32 attack_distance = Maths::Min(60.0f + Maths::Max(0.0f, 1.75f * this.getShape().vellen * (vel * thinghy)), 64.0f);

	f32 radius = 64.0f;//this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;
	bool dontHitMoreMap = false;
	bool dontHitMoreLogs = false;

	//get the actual aim angle
	f32 exact_aimangle = (this.getAimPos() - blobPos).Angle();

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (map.getHitInfosFromArc(pos, aimangle, arcdegrees, radius + attack_distance, this, @hitInfos))
	{
		// HitInfo objects are sorted, first come closest hits
		// start from furthest ones to avoid doing too many redundant raycasts
		for (int i = hitInfos.size() - 1; i >= 0; i--)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;

			if (b !is null)
			{
				if (b.hasTag("ignore sword")) continue;
				if (!canHit(this, b)) continue;
				if (has_hit_actor(this, b)) continue;

				Vec2f hitvec = hi.hitpos - pos;

				// we do a raycast to given blob and hit everything hittable between knight and that blob
				// raycast is stopped if it runs into a "large" blob (typically a door)
				// raycast length is slightly higher than hitvec to make sure it reaches the blob it's directed at
				HitInfo@[] rayInfos;
				map.getHitInfosFromRay(pos, -(hitvec).getAngleDegrees(), hitvec.Length() + 2.0f, this, rayInfos);

				for (int j = 0; j < rayInfos.size(); j++)
				{
					CBlob@ rayb = rayInfos[j].blob;
					
					if (rayb is null) break; // means we ran into a tile, don't need blobs after it if there are any
					if (b.hasTag("ignore sword")) continue;
					if (!canHit(this, rayb)) continue;

					bool large = rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable(); // usually doors, but can also be boats/some mechanisms
					if (has_hit_actor(this, rayb)) 
					{
						// check if we hit any of these on previous ticks of slash
						if (large) break;
						if (rayb.getName() == "log")
						{
							dontHitMoreLogs = true;
						}
						continue;
					}

					f32 temp_damage = damage;
					
					if (rayb.getName() == "log")
					{
						if (!dontHitMoreLogs)
						{
							temp_damage /= 3;
							dontHitMoreLogs = true; // set this here to prevent from hitting more logs on the same tick
							CBlob@ wood = server_CreateBlobNoInit("mat_wood");
							if (wood !is null)
							{
								int quantity = Maths::Ceil(float(temp_damage) * 20.0f);
								int max_quantity = rayb.getHealth() / 0.024f; // initial log health / max mats
								
								quantity = Maths::Max(
									Maths::Min(quantity, max_quantity),
									0
								);

								wood.Tag('custom quantity');
								wood.Init();
								wood.setPosition(rayInfos[j].hitpos);
								wood.server_SetQuantity(quantity);
							}
						}
						else 
						{
							// print("passed a log on " + getGameTime());
							continue; // don't hit the log
						}
					}
					
					add_actor_limit(this, rayb);

					Vec2f velocity = rayb.getPosition() - pos;
					velocity.Normalize();
					velocity *= 12; // knockback force is same regardless of distance

					if (rayb.getTeamNum() != this.getTeamNum())
					{
						this.server_Hit(rayb, rayInfos[j].hitpos, velocity, temp_damage, type, true);
					}

					if (large)
					{
						break; // don't raycast past the door after we do damage to it
					}
				}
			}
			else  // hitmap
				if (!dontHitMoreMap && (deltaInt == 3))
				{
					bool ground = map.isTileGround(hi.tile);
					bool dirt_stone = map.isTileStone(hi.tile);
					bool dirt_thick_stone = map.isTileThickStone(hi.tile);
					bool gold = map.isTileGold(hi.tile);
					bool wood = map.isTileWood(hi.tile);

					Vec2f tpos = map.getTileWorldPosition(hi.tileOffset) + Vec2f(4, 4);
					Vec2f offset = (tpos - blobPos);
					f32 tileangle = offset.Angle();
					f32 dif = Maths::Abs(exact_aimangle - tileangle);
					if (dif > 180)
						dif -= 360;
					if (dif < -180)
						dif += 360;

					dif = Maths::Abs(dif);
					//print("dif: "+dif);

					if (dif < 20.0f)
					{
						//detect corner

						int check_x = -(offset.x > 0 ? -1 : 1);
						int check_y = -(offset.y > 0 ? -1 : 1);
						if (map.isTileSolid(hi.hitpos - Vec2f(map.tilesize * check_x, 0)) &&
						        map.isTileSolid(hi.hitpos - Vec2f(0, map.tilesize * check_y)))
							continue;

						//dont dig through no build zones
						bool canhit = canhit && map.getSectorAtPosition(tpos, "no build") is null;

						dontHitMoreMap = true;
						if (canhit)
						{
							map.server_DestroyTile(hi.hitpos, 0.1f, this);
							if (gold)
							{
								// Note: 0.1f damage doesn't harvest anything I guess
								// This puts it in inventory - include MaterialCommon
								//Material::fromTile(this, hi.tile, 1.f);
								CBlob@ ore = server_CreateBlobNoInit("mat_gold");
								if (ore !is null)
								{
									ore.Tag('custom quantity');
									ore.Init();
									ore.setPosition(hi.hitpos);
									ore.server_SetQuantity(4);
								}
							}
							else if (dirt_stone)
							{
								int quantity = 4;
								if(dirt_thick_stone)
								{
									quantity = 6;
								}
								CBlob@ ore = server_CreateBlobNoInit("mat_stone");
								if (ore !is null)
								{
									ore.Tag('custom quantity');
									ore.Init();
									ore.setPosition(hi.hitpos);
									ore.server_SetQuantity(quantity);
								}
							}
						}
					}
				}
		}
	}

	// destroy grass

	if (((aimangle >= 0.0f && aimangle <= 180.0f) || damage > 1.0f) &&    // aiming down or slash
	        (deltaInt == 3)) // hit only once
	{
		f32 tilesize = map.tilesize;
		int steps = Maths::Ceil(2 * radius / tilesize);
		int sign = this.isFacingLeft() ? -1 : 1;

		for (int y = 0; y < steps; y++)
			for (int x = 0; x < steps; x++)
			{
				Vec2f tilepos = blobPos + Vec2f(x * tilesize * sign, y * tilesize);
				TileType tile = map.getTile(tilepos).type;

				if (map.isTileGrass(tile))
				{
					map.server_DestroyTile(tilepos, damage, this);

					if (damage <= 1.0f)
					{
						return;
					}
				}
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
	if (cmd == this.getCommandID("sword"))
	{
		clear_actor_limits(this);
		this.getSprite().PlaySound("maou_se_battle_gun05.ogg");
		this.set_u16("sword_time", 3);
		CSpriteLayer@ effect = this.getSprite().getSpriteLayer("edge");
		if (effect !is null)
		{
			effect.animation.frame = 0;
			effect.SetVisible(true);
		}
	}
	else if (cmd == this.getCommandID("buster"))
	{
		//this.getSprite().PlaySound("maou_se_sound_machine08.ogg");
		this.set_u16("buster_time", 90);
	}
}

void onDie(CBlob@ this)
{
	CBlob@ landed = server_CreateBlob("boss_ufo_dead");
	if (landed !is null)
	{
		landed.setPosition(this.getPosition());
		landed.server_setTeamNum(this.getTeamNum());
	}
}