// Robot logic

#include "LWBRobotCommon.as";
#include "Hitters.as";
#include "KnockedCommon.as"

//attacks limited to the one time per-actor before reset.

void actorlimit_setup(CBlob@ this)
{
	u16[] networkIDsLeft;
	this.set("LimitedActorsLeft", networkIDsLeft);

	u16[] networkIDsRight;
	this.set("LimitedActorsRight", networkIDsRight);
}

bool has_hit_actor(CBlob@ this, CBlob@ actor, bool isLeft)
{
	u16[]@ networkIDs;
	this.get(isLeft ? "LimitedActorsLeft" : "LimitedActorsRight", @networkIDs);
	return networkIDs.find(actor.getNetworkID()) >= 0;
}

u32 hit_actor_count(CBlob@ this, bool isLeft)
{
	u16[]@ networkIDs;
	this.get(isLeft ? "LimitedActorsLeft" : "LimitedActorsRight", @networkIDs);
	return networkIDs.length;
}

void add_actor_limit(CBlob@ this, CBlob@ actor, bool isLeft)
{
	this.push(isLeft ? "LimitedActorsLeft" : "LimitedActorsRight", actor.getNetworkID());
}

void clear_actor_limits(CBlob@ this, bool isLeft)
{
	this.clear(isLeft ? "LimitedActorsLeft" : "LimitedActorsRight");
}

u8 SpecialWeaponControl(CBlob@ this, LWBRobotInfo@ robot, bool isLeft)
{
	bool isServer = getNet().isServer();

	Vec2f pos = this.getPosition();
	Vec2f offsetPos = pos + Vec2f(this.isFacingLeft() ? 2 : -2, -2);// from archer logic
	Vec2f aimPos = this.getAimPos();
	Vec2f normVel = aimPos - offsetPos;
	normVel.Normalize();
	
	// laser effect
	string laserName = "laser" + (isLeft ? "Left" : "Right");
	CSpriteLayer@ laser = this.getSprite().getSpriteLayer(laserName);
	if (laser !is null)
	{
		laser.SetVisible(false);
	}

	string beamName = "beam" + (isLeft ? "Left" : "Right");
	CSpriteLayer@ beam = this.getSprite().getSpriteLayer(beamName);
	if (beam !is null)
	{
		beam.SetVisible(false);
	}

	for (u8 i = 0; i < 2; i++)
	{
		string chargeName = "beamCharge" + (isLeft ? "Left" : "Right") + i;
		CSpriteLayer@ charge = this.getSprite().getSpriteLayer(chargeName);

		if (charge !is null)
		{
			charge.SetVisible(false);
		}
	}

	if (this.hasTag("dead")) return 0;// no beam shooting on death

	switch (isLeft ? this.get_u8("lefthand") : this.get_u8("righthand"))
	{
		case LWBRobotWeapons::blade:
		{
			if ((isLeft ? robot.lefthand_special : robot.righthand_special) > 0)
			{
				Vec2f vec;
				this.getAimDirection(vec);
				DoAttack(this, 4.0f, -(vec.Angle()), 120.0f, isLeft ? LWBRobotHitters::physical_left : LWBRobotHitters::physical_right, isLeft ? robot.lefthand_special : robot.righthand_special, isLeft);

				if (isLeft)
				{
					robot.lefthand_special--;
				}
				else
				{
					robot.righthand_special--;
				}
			}
		}
		break;

		case LWBRobotWeapons::laser:
		{
			if (laser !is null)
			{
				if (!(isLeft ? (this.isKeyPressed(key_action1)) : (this.isKeyPressed(key_action2))))
				{
					return 0;
				}

				// check final hit like attacking

				CMap@ map = this.getMap();
				HitInfo@[] rayInfos;
				map.getHitInfosFromRay(offsetPos, -(normVel).getAngleDegrees(), 600.0f, this, rayInfos);
				f32 finalHit = 600.0f;

				for (int j = 0; j < rayInfos.size(); j++)
				{
					CBlob@ rayb = rayInfos[j].blob;
					
					if (rayb is null) // map hit
					{
						for (int i = 0; i < 4; i++)
						{
							finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
						}
						break;
					}

					if (rayb.hasTag("ignore sword")) continue;
					if (!canHit_robot(this, rayb)) continue;
				
					bool large = (rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable()) || (rayb.getName() == "lwbturretshield" && this.getTeamNum() != rayb.getTeamNum()); // usually doors, but can also be boats/some mechanisms

					if (large)
					{
						finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
						break; // don't raycast past the door after we do damage to it
					}
				}
			
				//effect check

				f32 laserlen = Maths::Max(0.1f, finalHit / 32.0f);

				laser.ResetTransform();
				laser.SetIgnoreParentFacing(true);
				laser.SetFacingLeft(true);// x offset is reversed... why
				laser.SetOffset(Vec2f(this.isFacingLeft() ? 2 : -2, -2));
				laser.ScaleBy(Vec2f(laserlen, 1.0f));

				laser.TranslateBy(Vec2f(laserlen * 16.0f, 0.0f));

				laser.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

				laser.SetVisible(true);
			}
		}
		break;

		case LWBRobotWeapons::beam:
		{
			// charge state
			if ((isLeft ? robot.lefthand_special : robot.righthand_special) > 0)
			{
				if ((isLeft ? robot.lefthand_special : robot.righthand_special) == 15)
				{
					this.getSprite().PlaySound("maou_se_battle_explosion04.ogg");
				}

				bool shootState = (isLeft ? robot.lefthand_special : robot.righthand_special) <= 15;
				bool hitTick = (isLeft ? robot.lefthand_special : robot.righthand_special) % 3 == 0;

				// offset
				Vec2f beamOff = normVel * 4.0f;
				beamOff.RotateBy(90.0f);

				CMap@ map = this.getMap();
				f32 finalHit = 0.0f;
				
				for (u8 i = 0; i < 2; i++)
				{
					Vec2f beamPos = offsetPos + (i == 0 ? beamOff : -beamOff);

					HitInfo@[] rayInfos;
					map.getHitInfosFromRay(beamPos, -(normVel).getAngleDegrees(), 350.0f, this, rayInfos);
				
					f32 tempFinal = 350.0f;

					for (int j = 0; j < rayInfos.size(); j++)
					{
						CBlob@ rayb = rayInfos[j].blob;
						
						if (rayb is null) // map hit
						{
							tempFinal = (rayInfos[j].hitpos - beamPos).getLength();
							if (isServer && shootState && hitTick && map.getSectorAtPosition(rayInfos[j].hitpos, "no build") is null)
							{
								for (int k = 0; k < 2; k++)
								{
									map.server_DestroyTile(rayInfos[j].hitpos, 0.1f, this);
								}
							}
							break;
						}
						if (rayb.hasTag("ignore sword")) continue;
						if (!canHit_robot(this, rayb)) continue;
					
						bool large = (rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable()) || (rayb.getName() == "lwbturretshield" && this.getTeamNum() != rayb.getTeamNum()); // usually doors, but can also be boats/some mechanisms
						
						Vec2f velocity = rayb.getPosition() - beamPos;
						velocity.Normalize();
						velocity *= 4; // knockback force is same regardless of distance
					
						if (isServer && shootState && hitTick && rayb.getTeamNum() != this.getTeamNum())
						{
							this.server_Hit(rayb, rayInfos[j].hitpos, velocity, 1.1f, isLeft ? LWBRobotHitters::energy_left : LWBRobotHitters::energy_right, true);
						}
					
						if (large)
						{
							tempFinal = (rayInfos[j].hitpos - beamPos).getLength();
							break; // don't raycast past the door after we do damage to it
						}
					}

					if (!shootState)
					{
						string chargeName = "beamCharge" + (isLeft ? "Left" : "Right") + i;
						CSpriteLayer@ charge = this.getSprite().getSpriteLayer(chargeName);

						if (charge !is null)
						{
							f32 beamlen = Maths::Max(0.1f, tempFinal / 32.0f);

							charge.ResetTransform();
							charge.SetIgnoreParentFacing(true);
							charge.SetFacingLeft(true);
							Vec2f chargeOff = (i == 0 ? beamOff : -beamOff);
							charge.SetOffset(Vec2f(this.isFacingLeft() ? 2 : -2, -2) + chargeOff);
							charge.ScaleBy(Vec2f(beamlen, 1.0f));

							charge.TranslateBy(Vec2f(beamlen * 16.0f, 0.0f));

							charge.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

							charge.SetVisible(true);
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
					beam.SetFacingLeft(true);
					beam.SetOffset(Vec2f(this.isFacingLeft() ? 2 : -2, -2));
					beam.ScaleBy(Vec2f(beamlen, 1.0f));

					beam.TranslateBy(Vec2f(beamlen * 16.0f, 0.0f));

					beam.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

					beam.SetVisible(true);
				}

				if (isLeft)
				{
					robot.lefthand_special--;
				}
				else
				{
					robot.righthand_special--;
				}
			}
		}
		break;

		case LWBRobotWeapons::energyblade:
		{
			if ((isLeft ? robot.lefthand_special : robot.righthand_special) > 0)
			{
				Vec2f vec;
				this.getAimDirection(vec);
				DoAttack(this, 3.0f, -(vec.Angle()), 120.0f, isLeft ? LWBRobotHitters::energy_left : LWBRobotHitters::energy_right, isLeft ? robot.lefthand_special : robot.righthand_special, isLeft);

				if (isLeft)
				{
					robot.lefthand_special--;
				}
				else
				{
					robot.righthand_special--;
				}
			}
		}
		break;

		case LWBRobotWeapons::shield:
		{
			// lose energy
			for (int i = 0; i < 2; i ++)
			{
				if (((isLeft ? robot.lefthand_energy : robot.righthand_energy) > 0) && (isLeft ? this.isKeyPressed(key_action1) : this.isKeyPressed(key_action2)))
				{
					if (isLeft)
					{
						robot.lefthand_energy--;
					}
					else
					{
						robot.righthand_energy--;
					}
				}
			}

			// shield effect
			// slowdown moving while using shield
			if (getNet().isClient() && (isLeft ? this.isKeyPressed(key_action1) : this.isKeyPressed(key_action2)))
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

				f32 shieldAngle = (this.getAimPos() - this.getPosition()).getAngleDegrees() + f32(XORRandom(256)) * 150.0f / 255.0f - 75.0f;
				CParticle@ p = ParticlePixelUnlimited(pos + Vec2f(8.0f, 0.0f).RotateBy(-shieldAngle), Vec2f(0.5f, 0.0f).RotateBy(-shieldAngle), color, true);
				if(p !is null)
				{
				    p.collides = true;
				    p.gravity = Vec2f_zero;
				    p.bounce = 0;
				    p.Z = 7;
				    p.timeout = 10;
					p.setRenderStyle(RenderStyle::light);
				}

				return 1;
			}
		}
		break;
	}
	return 0;
}

// from knight logic
void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type, int deltaInt, bool isLeft)
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

	f32 attack_distance = Maths::Min(16.0f + Maths::Max(0.0f, 1.75f * this.getShape().vellen * (vel * thinghy)), 18.0f);

	f32 radius = this.getRadius();
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
				if (!canHit_robot(this, b)) continue;
				if (has_hit_actor(this, b, isLeft)) continue;

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
					if (!canHit_robot(this, rayb)) continue;

					bool large = rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable(); // usually doors, but can also be boats/some mechanisms
					if (has_hit_actor(this, rayb, isLeft)) 
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
					
					add_actor_limit(this, rayb, isLeft);

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

void weaponOperate_server(CBlob@ this, LWBRobotInfo@ robot, bool isLeft, CBitStream @params)
{
	Vec2f pos;
	if (!params.saferead_Vec2f(pos)) pos = this.getPosition();
	Vec2f offsetPos = pos + Vec2f(this.isFacingLeft() ? 2 : -2, -2);// from archer logic
	Vec2f aimPos;
	if (!params.saferead_Vec2f(aimPos)) aimPos = this.getAimPos();
	Vec2f normVel = aimPos - offsetPos;
	normVel.Normalize();

	switch (isLeft ? this.get_u8("lefthand") : this.get_u8("righthand"))
	{
		case LWBRobotWeapons::cannon:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotcannonshell");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 17.59f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::gatling:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotgatlingbullet");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity((normVel * 25.0f).RotateBy(-6.0f + (( f32(XORRandom(2048)) / 2048.0f) * 12.0f),Vec2f(0,0)));
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::railgun:
		{
			CMap@ map = this.getMap();
			HitInfo@[] rayInfos;
			map.getHitInfosFromRay(offsetPos, -(normVel).getAngleDegrees(), 750.0f, this, rayInfos);
			f32 finalHit = 750.0f;

			for (int j = 0; j < rayInfos.size(); j++)
			{
				CBlob@ rayb = rayInfos[j].blob;
				
				if (rayb is null) // map hit
				{
					finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
					if (map.getSectorAtPosition(rayInfos[j].hitpos, "no build") is null)
					{
						for (int i = 0; i < 4; i++)
						{
							map.server_DestroyTile(rayInfos[j].hitpos, 0.1f, this);
						}
					}
					break;
				}
				if (rayb.hasTag("ignore sword")) continue;
				if (!canHit_robot(this, rayb)) continue;
			
				bool large = (rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable()) || (rayb.getName() == "lwbturretshield" && this.getTeamNum() != rayb.getTeamNum()); // usually doors, but can also be boats/some mechanisms
				
				Vec2f velocity = rayb.getPosition() - offsetPos;
				velocity.Normalize();
				velocity *= 18; // knockback force is same regardless of distance
			
				if (rayb.getTeamNum() != this.getTeamNum())
				{
					this.server_Hit(rayb, rayInfos[j].hitpos, velocity, 5.0f, isLeft ? LWBRobotHitters::physical_left : LWBRobotHitters::physical_right, true);
				}
			
				if (large)
				{
					finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
					break; // don't raycast past the door after we do damage to it
				}
			}

			CBitStream sendparams;
			sendparams.write_Vec2f(offsetPos);
			sendparams.write_Vec2f(normVel);
			sendparams.write_f32(finalHit);
			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"), sendparams);
		}
		break;

		case LWBRobotWeapons::rocket:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotrocket");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 3.0f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::homing:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robothomingrocket");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.set_Vec2f("aimpos", aimPos);
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 3.0f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::grenade:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotgrenade");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 11.0f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::blade:
		{
			clear_actor_limits(this, isLeft);
			if (isLeft)
			{
				robot.lefthand_special += 3;
			}
			else
			{
				robot.righthand_special += 3;
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::buster:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotbuster");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 12.0f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::laser:
		{
			CMap@ map = this.getMap();
			HitInfo@[] rayInfos;
			map.getHitInfosFromRay(offsetPos, -(normVel).getAngleDegrees(), 600.0f, this, rayInfos);
			f32 finalHit = 600.0f;

			for (int j = 0; j < rayInfos.size(); j++)
			{
				CBlob@ rayb = rayInfos[j].blob;
				
				if (rayb is null) // map hit
				{
					finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
					break;
				}
				if (rayb.hasTag("ignore sword")) continue;
				if (!canHit_robot(this, rayb)) continue;
			
				bool large = (rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable()) || (rayb.getName() == "lwbturretshield" && this.getTeamNum() != rayb.getTeamNum()); // usually doors, but can also be boats/some mechanisms
				
				Vec2f velocity = rayb.getPosition() - offsetPos;
				velocity.Normalize();
				velocity *= 1; // knockback force is same regardless of distance
			
				if (rayb.getTeamNum() != this.getTeamNum())
				{
					this.server_Hit(rayb, rayInfos[j].hitpos, velocity, 0.2f, isLeft ? LWBRobotHitters::energy_left : LWBRobotHitters::energy_right, true);
				}
			
				if (large)
				{
					finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
					break; // don't raycast past the door after we do damage to it
				}
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::beam:
		{
			if (isLeft)
			{
				robot.lefthand_special += 45;
			}
			else
			{
				robot.righthand_special += 45;
			}

			if(!isClient())this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::plasma:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotplasma");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.set_Vec2f("aimpos", aimPos);
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 4.0f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::napalm:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotnapalm");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 11.0f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::lightning:
		{
			CMap@ map = this.getMap();
			HitInfo@[] rayInfos;
			map.getHitInfosFromRay(offsetPos, -(normVel).getAngleDegrees(), 150.0f, this, rayInfos);
			f32 finalHit = 150.0f;

			for (int j = 0; j < rayInfos.size(); j++)
			{
				CBlob@ rayb = rayInfos[j].blob;
				
				if (rayb is null) // map hit
				{
					finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
					break;
				}
				if (rayb.hasTag("ignore sword")) continue;
				if (!canHit_robot(this, rayb)) continue;
			
				bool large = (rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable()) || (rayb.getName() == "lwbturretshield" && this.getTeamNum() != rayb.getTeamNum()); // usually doors, but can also be boats/some mechanisms
				
				Vec2f velocity = rayb.getPosition() - offsetPos;
				velocity.Normalize();
				velocity *= 18; // knockback force is same regardless of distance
			
				if (rayb.getTeamNum() != this.getTeamNum())
				{
					this.server_Hit(rayb, rayInfos[j].hitpos, velocity, 5.0f, isLeft ? LWBRobotHitters::energy_left : LWBRobotHitters::energy_right, true);
					if (isKnockable(rayb))
					{
						u8 duarition = 30;
						LWBRobotInfo@ enemy;
						if (rayb.exists("module") && rayb.get_u8("module") == LWBRobotModules::specialarmour)
						{
							duarition = 15;
						}
						setKnocked(rayb, duarition);
						rayb.Tag("energy_stun");
					}
					if (rayb.hasTag("player"))
					{
						finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
						break; // don't raycast past the door after we do damage to it
					}
				}
			
				if (large)
				{
					finalHit = (rayInfos[j].hitpos - offsetPos).getLength();
					break; // don't raycast past the door after we do damage to it
				}
			}

			CBitStream sendparams;
			sendparams.write_Vec2f(offsetPos);
			sendparams.write_Vec2f(normVel);
			sendparams.write_f32(finalHit);
			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"), sendparams);
		}
		break;

		case LWBRobotWeapons::energyblade:
		{
			clear_actor_limits(this, isLeft);
			if (isLeft)
			{
				robot.lefthand_special += 3;
			}
			else
			{
				robot.righthand_special += 3;
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::sawboomelang:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotsawbladeboomelang");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.set_netid("robot", this.getNetworkID());
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 15.0f);
			}
			
			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::diffuser:
		{
			int r = 0;
			for (int i = 0; i < 5; i++)
			{
				CBlob@ bullet = server_CreateBlobNoInit("robotenergy");
				if (bullet !is null)
				{
					bullet.SetDamageOwnerPlayer(this.getPlayer());
					bullet.set_bool("hand", isLeft);
					bullet.Init();
				
					bullet.IgnoreCollisionWhileOverlapped(this);
					bullet.server_setTeamNum(this.getTeamNum());
					bullet.setPosition(offsetPos);
					bullet.setVelocity(normVel * 7.0f);
				}

				r = r > 0 ? -(r + 1) : (-r) + 1;

				normVel = normVel.RotateBy(5 * r);
			}
			
			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::energyball:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotenergyball");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 15.0f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;

		case LWBRobotWeapons::planet:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotplanet");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_bool("hand", isLeft);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(normVel * 3.0f);
			}

			this.SendCommand(this.getCommandID(isLeft ? "shoot_left_client" : "shoot_right_client"));
		}
		break;
	}
}

void weaponOperate_client(CBlob@ this, LWBRobotInfo@ robot, bool isLeft, CBitStream @params)
{
	switch (isLeft ? this.get_u8("lefthand") : this.get_u8("righthand"))
	{
		case LWBRobotWeapons::cannon:
		{
			this.getSprite().PlaySound("KegExplosion.ogg");
		}
		break;

		case LWBRobotWeapons::gatling:
		{
			this.getSprite().PlaySound("M16Fire.ogg");
		}
		break;

		case LWBRobotWeapons::railgun:
		{
			this.getSprite().PlaySound("maou_se_battle_explosion03.ogg");

			Vec2f offsetPos;
			Vec2f normVel;
			f32 finalHit;
			if (!params.saferead_Vec2f(offsetPos) || !params.saferead_Vec2f(normVel) || !params.saferead_f32(finalHit)) return;

			// trail effect
			string name = "rail" + (isLeft ? "Left" : "Right") + getGameTime();
			CSpriteLayer@ rail = this.getSprite().addSpriteLayer(name, "LWBRobotRailBullet.png" , 32, 7);

			if (rail !is null)
			{

				Animation@ anim = rail.addAnimation("default", 0, false);
				anim.AddFrame(0);
				rail.SetRelativeZ(1.5f);

				f32 raillen = Maths::Max(0.1f, finalHit / 32.0f);

				rail.ResetTransform();
				rail.SetIgnoreParentFacing(true);
				rail.SetFacingLeft(false);
				rail.SetOffset(Vec2f(this.isFacingLeft() ? 2 : -2, -2));
				rail.ScaleBy(Vec2f(raillen, 1.0f));

				rail.TranslateBy(Vec2f(raillen * 16.0f, 0.0f));

				rail.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

				WeaponEffectInfo info;
				info.type = LWBRobotWeapons::railgun;
				info.name = name;
				info.endTime = getGameTime() + 10;
				info.shootingPos = offsetPos;
				info.offset = rail.getOffset();
				robot.effects.push_back(info);
			}
		}
		break;

		case LWBRobotWeapons::rocket:
		{
			this.getSprite().PlaySound("FireFwoosh.ogg");
			this.getSprite().PlaySound("maou_se_sound01.ogg");
		}
		break;

		case LWBRobotWeapons::homing:
		{
			this.getSprite().PlaySound("FireFwoosh.ogg");
			this.getSprite().PlaySound("maou_se_sound01.ogg");
		}
		break;

		case LWBRobotWeapons::grenade:
		{
			this.getSprite().PlaySound("KegExplosion.ogg");
		}
		break;

		case LWBRobotWeapons::blade:
		{
			this.getSprite().PlaySound("SwordSlash.ogg");

			if (!isServer())
			{
				if (isLeft)
				{
					robot.lefthand_special += 3;
				}
				else
				{
					robot.righthand_special += 3;
				}
			}
			// blade effect
			string name = "chop" + (isLeft ? "Left" : "Right") + getGameTime();
			CSpriteLayer@ chop = this.getSprite().addSpriteLayer(name, "LWBRobotEdge.png" , 32, 32);

			if (chop !is null)
			{

				Animation@ anim = chop.addAnimation("default", 1, false);
				anim.AddFrame(0);
				anim.AddFrame(1);
				anim.AddFrame(2);
				chop.SetRelativeZ(1000.0f);

				WeaponEffectInfo info;
				info.type = LWBRobotWeapons::blade;
				info.name = name;
				info.endTime = getGameTime() + 10;
				robot.effects.push_back(info);
			}
		}
		break;

		case LWBRobotWeapons::buster:
		{
			this.getSprite().PlaySound("maou_se_magic_fire09.ogg");
		}
		break;

		case LWBRobotWeapons::laser:
		{
			this.getSprite().PlaySound("beep00.ogg");
		}
		break;

		case LWBRobotWeapons::beam:
		{
			this.getSprite().PlaySound("PowerUp.ogg");

			if (isLeft)
			{
				robot.lefthand_special += 45;
			}
			else
			{
				robot.righthand_special += 45;
			}
		}
		break;

		case LWBRobotWeapons::plasma:
		{
			this.getSprite().PlaySound("maou_se_battle02.ogg");
		}
		break;

		case LWBRobotWeapons::napalm:
		{
			this.getSprite().PlaySound("KegExplosion.ogg");
		}
		break;

		case LWBRobotWeapons::lightning:
		{
			this.getSprite().PlaySound("Thunder?.ogg");

			Vec2f offsetPos;
			Vec2f normVel;
			f32 finalHit;
			if (!params.saferead_Vec2f(offsetPos) || !params.saferead_Vec2f(normVel) || !params.saferead_f32(finalHit)) return;

			// trail effect
			string name = "lightning" + (isLeft ? "Left" : "Right") + getGameTime();
			CSpriteLayer@ lightning = this.getSprite().addSpriteLayer(name, "LWBRobotLightning.png" , 32, 8);

			if (lightning !is null)
			{

				Animation@ anim = lightning.addAnimation("default", 2, false);
				anim.AddFrame(0);
				anim.AddFrame(1);
				anim.AddFrame(2);
				anim.AddFrame(3);
				lightning.SetRelativeZ(1.5f);

				f32 lightninglen = Maths::Max(0.1f, finalHit / 32.0f);

				lightning.ResetTransform();
				lightning.SetIgnoreParentFacing(true);
				lightning.SetFacingLeft(false);
				lightning.SetOffset(Vec2f(this.isFacingLeft() ? 2 : -2, -2));
				lightning.ScaleBy(Vec2f(lightninglen, 1.0f));

				lightning.TranslateBy(Vec2f(lightninglen * 16.0f, 0.0f));

				lightning.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

				WeaponEffectInfo info;
				info.type = LWBRobotWeapons::lightning;
				info.name = name;
				info.endTime = getGameTime() + 10;
				info.shootingPos = offsetPos;
				info.offset = lightning.getOffset();
				robot.effects.push_back(info);
			}
		}
		break;

		case LWBRobotWeapons::energyblade:
		{
			this.getSprite().PlaySound("maou_se_battle_gun05.ogg");

			if (!isServer())
			{
				if (isLeft)
				{
					robot.lefthand_special += 3;
				}
				else
				{
					robot.righthand_special += 3;
				}
			}
			// blade effect
			string name = "chop" + (isLeft ? "Left" : "Right") + getGameTime();
			CSpriteLayer@ chop = this.getSprite().addSpriteLayer(name, "LWBRobotEdge.png" , 32, 32);

			if (chop !is null)
			{

				Animation@ anim = chop.addAnimation("default", 1, false);
				anim.AddFrame(3);
				anim.AddFrame(4);
				anim.AddFrame(5);
				chop.SetRelativeZ(1000.0f);

				WeaponEffectInfo info;
				info.type = LWBRobotWeapons::energyblade;
				info.name = name;
				info.endTime = getGameTime() + 10;
				robot.effects.push_back(info);
			}
		}
		break;

		case LWBRobotWeapons::sawboomelang:
		{
			this.getSprite().PlaySound("SawOther.ogg");
		}
		break;

		case LWBRobotWeapons::diffuser:
		{
			this.getSprite().PlaySound("maou_se_magic_fire07.ogg");
		}
		break;

		case LWBRobotWeapons::energyball:
		{
			this.getSprite().PlaySound("maou_se_battle_gun05.ogg");
		}
		break;

		case LWBRobotWeapons::planet:
		{
			this.getSprite().PlaySound("OrbFireSound.ogg");
		}
		break;
	}
}
