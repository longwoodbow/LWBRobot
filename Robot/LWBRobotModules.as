// Robot logic

#include "LWBRobotCommon.as";
#include "Hitters.as";
//#include "ShieldCommon.as";
#include "KnockedCommon.as"

void SpecialModuleControl(CBlob@ this, LWBRobotInfo@ robot)
{
	bool isServer = getNet().isServer();
	Vec2f pos = this.getPosition();
	Vec2f offsetPos = pos + Vec2f(this.isFacingLeft() ? 2 : -2, -2);// from archer logic
	Vec2f aimPos = this.getAimPos();
	Vec2f normVel = (this.get_u8("module") == LWBRobotModules::sunbeam) ? this.get_Vec2f("sunbeamAngle") : (this.get_u8("module") == LWBRobotModules::emp) ? this.get_Vec2f("empAngle") : (aimPos - offsetPos);
	normVel.Normalize();

	for (u8 i = 0; i < 3; i++)
	{
		string sawDroneName = "sawDrone" + i;
		CSpriteLayer@ sawDrone = this.getSprite().getSpriteLayer(sawDroneName);

		if (sawDrone !is null)
		{
			sawDrone.SetVisible(false);
		}
	}

	string beamName = "sunBeam";
	CSpriteLayer@ sunBeam = this.getSprite().getSpriteLayer(beamName);
	if (sunBeam !is null)
	{
		sunBeam.SetVisible(false);
	}

	for (u8 i = 0; i < 9; i++)
	{
		string chargeName = "sunBeamCharge" + i;
		CSpriteLayer@ charge = this.getSprite().getSpriteLayer(chargeName);

		if (charge !is null)
		{
			charge.SetVisible(false);
		}
	}

	string empName = "emp";
	CSpriteLayer@ emp = this.getSprite().getSpriteLayer(empName);
	if (emp !is null)
	{
		emp.SetVisible(false);
	}

	for (u8 i = 0; i < 9; i++)
	{
		string chargeName = "empCharge" + i;
		CSpriteLayer@ charge = this.getSprite().getSpriteLayer(chargeName);

		if (charge !is null)
		{
			charge.SetVisible(false);
		}
	}

	if (this.hasTag("dead")) return;// no beam shooting on death
	
	switch (this.get_u8("module"))
	{
		case LWBRobotModules::jetpack:
		{
			if (robot.module_energy < 3 || !this.isKeyPressed(key_action3)) return;

			robot.module_energy -= 3;
			this.AddForce(Vec2f(0.0f, -35.0f));
			
			if (!getNet().isClient()) return;

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

			CParticle@ p = ParticlePixelUnlimited(pos + Vec2f(this.isFacingLeft() ? 2 : -2, 0.0f), Vec2f(0.0f, 10.0f).RotateBy(-2.5f + f32(XORRandom(256)) * 5.0f / 255.0f), color, true);
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
		break;

		case LWBRobotModules::nanohealer:
		{
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
		break;

		case LWBRobotModules::homingmissile:
		{
			if (robot.module_special > 0)
			{
				robot.module_special--;

				if(robot.module_special % 10 == 0)
				{
					this.getSprite().PlaySound("FireFwoosh.ogg");
					this.getSprite().PlaySound("maou_se_sound01.ogg");

					if (!isServer) return;

					u8 number = (robot.module_special == 30) ? 0 :
								(robot.module_special == 20) ? 1 :
								(robot.module_special == 10) ? 2 :
								3;

					CBlob@ bullet = server_CreateBlobNoInit("robotpodhomingrocket");
					if (bullet !is null)
					{
						bullet.SetDamageOwnerPlayer(this.getPlayer());
						CBlob@ target;
						bullet.set_netid("target", this.get_netid("target" + number));
						bullet.Init();
				
						bullet.IgnoreCollisionWhileOverlapped(this);
						bullet.server_setTeamNum(this.getTeamNum());
						bullet.setPosition(offsetPos);
						bullet.setVelocity(Vec2f(0.0f, -3.0f));
					}
				}
			}
		}
		break;

		case LWBRobotModules::saw:
		{
			f32 angle = this.getTickSinceCreated() * 4.0f;

			while (angle < 0.0f)
			{
				angle += 360.0f;
			}

			Vec2f point0 = Vec2f(30.0f, 0.0f).RotateBy(angle);
			Vec2f point1 = Vec2f(30.0f, 0.0f).RotateBy(angle + 120.0f);
			Vec2f point2 = Vec2f(30.0f, 0.0f).RotateBy(angle + 240.0f);

			f32 sawAngle = this.getTickSinceCreated() * 30.0f;

			while (sawAngle > 360.0f)
			{
				sawAngle -= 360.0f;
			}

			{
				string sawDroneName = "sawDrone0";
				CSpriteLayer@ sawDrone = this.getSprite().getSpriteLayer(sawDroneName);

				if (sawDrone !is null)
				{
					sawDrone.ResetTransform();
					sawDrone.SetIgnoreParentFacing(true);
					sawDrone.SetFacingLeft(true);// why do i need to set this true?
					sawDrone.SetOffset(point0 + Vec2f(-0.5f, -0.5f));
					sawDrone.RotateBy(sawAngle, Vec2f(-0.5f, -0.5f));
					sawDrone.SetVisible(true);
				}
			}
			{
				string sawDroneName = "sawDrone1";
				CSpriteLayer@ sawDrone = this.getSprite().getSpriteLayer(sawDroneName);

				if (sawDrone !is null)
				{
					sawDrone.ResetTransform();
					sawDrone.SetIgnoreParentFacing(true);
					sawDrone.SetFacingLeft(true);
					sawDrone.SetOffset(point1 + Vec2f(-0.5f, -0.5f));
					sawDrone.RotateBy(sawAngle, Vec2f(-0.5f, -0.5f));
					sawDrone.SetVisible(true);
				}
			}
			{
				string sawDroneName = "sawDrone2";
				CSpriteLayer@ sawDrone = this.getSprite().getSpriteLayer(sawDroneName);

				if (sawDrone !is null)
				{
					sawDrone.ResetTransform();
					sawDrone.SetIgnoreParentFacing(true);
					sawDrone.SetFacingLeft(true);
					sawDrone.SetOffset(point2 + Vec2f(-0.5f, -0.5f));
					sawDrone.RotateBy(sawAngle, Vec2f(-0.5f, -0.5f));
					sawDrone.SetVisible(true);
				}
			}

			// hit check
			if (getNet().isServer() && this.getTickSinceCreated() % 3 == 0)
			{
				CBlob@[] blobs;
				this.getMap().getBlobsInRadius(pos + point0, 6.0f, @blobs);
				for (int i = 0; i < blobs.size(); i++)
				{
					if (blobs[i].getTeamNum() != this.getTeamNum() && !blobs[i].hasTag("projectile")) this.server_Hit(blobs[i], pos + point0, Vec2f_zero, 1.0f, LWBRobotHitters::physical_module);
				}
				blobs.clear();

				this.getMap().getBlobsInRadius(pos + point1, 6.0f, @blobs);
				for (int i = 0; i < blobs.size(); i++)
				{
					if (blobs[i].getTeamNum() != this.getTeamNum() && !blobs[i].hasTag("projectile")) this.server_Hit(blobs[i], pos + point1, Vec2f_zero, 1.0f, LWBRobotHitters::physical_module);
				}
				blobs.clear();

				this.getMap().getBlobsInRadius(pos + point2, 6.0f, @blobs);
				for (int i = 0; i < blobs.size(); i++)
				{
					if (blobs[i].getTeamNum() != this.getTeamNum() && !blobs[i].hasTag("projectile")) this.server_Hit(blobs[i], pos + point2, Vec2f_zero, 1.0f, LWBRobotHitters::physical_module);
				}
			}
		}
		break;

		case LWBRobotModules::sunbeam:
		{
			// charge state
			if (robot.module_special > 0)
			{
				if (robot.module_special == 30)
				{
					this.getSprite().PlaySound("maou_se_battle_explosion02.ogg");
				}
				else if (robot.module_special % 30 == 0)
				{
					this.getSprite().PlaySound("maou_se_system02.ogg");
				}

				bool shootState = robot.module_special <= 30;
				bool hitTick = robot.module_special % 3 == 0;

				// offset
				Vec2f beamOff = normVel * 4.0f;
				beamOff.RotateBy(90.0f);

				CMap@ map = this.getMap();
				f32 finalHit = 0.0f;
				
				for (u8 i = 0; i < 9; i++)
				{
					Vec2f beamPos = offsetPos + (beamOff * ((i + 1) / 2) * (i % 2 == 1 ? -1.0f : 1.0f));

					HitInfo@[] rayInfos;
					map.getHitInfosFromRay(beamPos, -(normVel).getAngleDegrees(), 1000.0f, this, rayInfos);
				
					f32 tempFinal = 1000.0f;

					for (int j = 0; j < rayInfos.size(); j++)
					{
						CBlob@ rayb = rayInfos[j].blob;
						
						if (rayb is null) // map hit
						{
							tempFinal = (rayInfos[j].hitpos - beamPos).getLength();
							if (isServer && shootState && hitTick && map.getSectorAtPosition(rayInfos[j].hitpos, "no build") is null)
							{
								for (int k = 0; k < 3; k++)
								{
									map.server_DestroyTile(rayInfos[j].hitpos, 0.1f, this);
									if (map.isTileBedrock(map.getTile(rayInfos[j].hitpos).type)) map.server_SetTile(rayInfos[j].hitpos, CMap::tile_thickstone);
								}
							}
							break;
						}
						if (rayb.hasTag("ignore sword")) continue;
						if (!canHit_robot(this, rayb)) continue;
					
						bool large = (rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable()); // || (rayb.getName() == "lwbturretshield" && this.getTeamNum() != rayb.getTeamNum()); // usually doors, but can also be boats/some mechanisms
						
						Vec2f velocity = rayb.getPosition() - beamPos;
						velocity.Normalize();
						velocity *= 4; // knockback force is same regardless of distance
					
						if (isServer && shootState && hitTick) // && rayb.getTeamNum() != this.getTeamNum()
						{
							this.server_Hit(rayb, rayInfos[j].hitpos, velocity, (rayb.hasTag("boss") || rayb.getName() == "robot_spawn") ? 0.5f : 5.0f, LWBRobotHitters::energy_module, true);
						}
					
						if (large)
						{
							tempFinal = (rayInfos[j].hitpos - beamPos).getLength();
							break; // don't raycast past the door after we do damage to it
						}
					}

					if (!shootState)
					{
						string chargeName = "sunBeamCharge" + i;
						CSpriteLayer@ charge = this.getSprite().getSpriteLayer(chargeName);

						if (charge !is null)
						{
							f32 beamlen = Maths::Max(0.1f, tempFinal / 32.0f);

							charge.ResetTransform();
							charge.SetIgnoreParentFacing(true);
							charge.SetFacingLeft(true);
							Vec2f chargeOff = (beamOff * ((i + 1) / 2) * (i % 2 == 1 ? -1.0f : 1.0f));
							charge.SetOffset(Vec2f(this.isFacingLeft() ? 2 : -2, -2) + chargeOff);
							charge.ScaleBy(Vec2f(beamlen, 1.0f));

							charge.TranslateBy(Vec2f(beamlen * 16.0f, 0.0f));

							charge.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

							charge.SetVisible(true);
						}
					}

					// particles

					if (getNet().isClient())
					{
						for (int i = 0; i < 4; i++)
						{
							CParticle@ p = ParticlePixelUnlimited(beamPos + Vec2f(tempFinal * XORRandom(256) / 255.0f, 0.0f).RotateBy(-(normVel).getAngleDegrees()), Vec2f(0.1f, 0.0f).RotateBy(f32(XORRandom(256)) * 360.0f / 256.0f), SColor(0xf0fea53d), true);
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
				if (shootState && sunBeam !is null)
				{
					f32 beamlen = Maths::Max(0.1f, finalHit / 32.0f);

					sunBeam.ResetTransform();
					sunBeam.SetIgnoreParentFacing(true);
					sunBeam.SetFacingLeft(true);
					sunBeam.SetOffset(Vec2f(this.isFacingLeft() ? 2 : -2, -2));
					sunBeam.ScaleBy(Vec2f(beamlen, 1.0f));

					sunBeam.TranslateBy(Vec2f(beamlen * 16.0f, 0.0f));

					sunBeam.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

					sunBeam.SetVisible(true);
				}

				robot.module_special--;
			}
		}
		break;

		case LWBRobotModules::emp:
		{
			// charge state
			if (robot.module_special > 0)
			{
				if (robot.module_special == 15)
				{
					this.getSprite().PlaySound("maou_se_magical12.ogg");
				}

				robot.module_special--;

				bool shootState = robot.module_special < 15;

				// offset
				Vec2f beamOff = normVel * 8.0f;
				beamOff.RotateBy(90.0f);

				CMap@ map = this.getMap();
				f32 finalHit = 0.0f;
				
				for (u8 i = 0; i < 3; i++)
				{
					Vec2f beamPos = offsetPos + (beamOff * ((i + 1) / 2) * (i % 2 == 1 ? -1.0f : 1.0f));

					HitInfo@[] rayInfos;
					map.getHitInfosFromRay(beamPos, -(normVel).getAngleDegrees(), 500.0f, this, rayInfos);
				
					f32 tempFinal = 500.0f;

					for (int j = 0; j < rayInfos.size(); j++)
					{
						CBlob@ rayb = rayInfos[j].blob;
						
						if (rayb is null) // map hit
						{
							tempFinal = (rayInfos[j].hitpos - beamPos).getLength();
							break;
						}
						if (rayb.hasTag("ignore sword")) continue;
						if (!canHit_robot(this, rayb)) continue;
					
						bool large = (rayb.hasTag("blocks sword") && !rayb.isAttached() && rayb.isCollidable()); // || (rayb.getName() == "lwbturretshield" && this.getTeamNum() != rayb.getTeamNum()); // usually doors, but can also be boats/some mechanisms
						
						Vec2f velocity = rayb.getPosition() - beamPos;
						velocity.Normalize();
						velocity *= 4; // knockback force is same regardless of distance
					
						if (isServer && shootState && isKnockable(rayb) && rayb.getTeamNum() != this.getTeamNum()) //
						{
							u8 duarition = 90;
							if (rayb.exists("module") && rayb.get_u8("module") == LWBRobotModules::specialarmour)
							{
								duarition = 45;
							}
							setKnocked(rayb, duarition);
							rayb.Tag("energy_stun");
						}
					
						if (large)
						{
							tempFinal = (rayInfos[j].hitpos - beamPos).getLength();
							break; // don't raycast past the door after we do damage to it
						}
					}

					if (!shootState)
					{
						string chargeName = "empCharge" + i;
						CSpriteLayer@ charge = this.getSprite().getSpriteLayer(chargeName);

						if (charge !is null)
						{
							f32 beamlen = Maths::Max(0.1f, tempFinal / 32.0f);

							charge.ResetTransform();
							charge.SetIgnoreParentFacing(true);
							charge.SetFacingLeft(true);
							Vec2f chargeOff = (beamOff * ((i + 1) / 2) * (i % 2 == 1 ? -1.0f : 1.0f));
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
				if (shootState && emp !is null)
				{
					f32 beamlen = Maths::Max(0.1f, finalHit / 32.0f);

					emp.ResetTransform();
					emp.SetIgnoreParentFacing(true);
					emp.SetFacingLeft(true);
					emp.SetOffset(Vec2f(this.isFacingLeft() ? 2 : -2, -2));
					emp.ScaleBy(Vec2f(beamlen, 1.0f));

					emp.TranslateBy(Vec2f(beamlen * 16.0f, 0.0f));

					emp.RotateBy(-(normVel).getAngleDegrees() , Vec2f());

					emp.SetVisible(true);
				}
			}
		}
		break;
	}
}

void moduleOperate_server(CBlob@ this, LWBRobotInfo@ robot, CBitStream @params)
{
	Vec2f pos;
	if (!params.saferead_Vec2f(pos)) pos = this.getPosition();
	Vec2f offsetPos = pos + Vec2f(this.isFacingLeft() ? 2 : -2, -2);// from archer logic
	Vec2f aimPos;
	if (!params.saferead_Vec2f(aimPos)) aimPos = this.getAimPos();
	Vec2f normVel = aimPos - offsetPos;
	normVel.Normalize();

	switch (this.get_u8("module"))
	{
		case LWBRobotModules::healdrone:
		{
			CBlob@ bullet = server_CreateBlob("lwbhealdrone");
			if (bullet !is null)
			{
				bullet.set_netid("owner", this.getNetworkID());
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(pos);
			}

			this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;

		case LWBRobotModules::shieldturret:
		{
			CBlob@ bullet = server_CreateBlobNoInit("lwbshieldturret");
			if (bullet !is null)
			{
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(pos);
				bullet.Init();
			}

			this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;

		case LWBRobotModules::homingmissile:
		{
			// find enemies and sort
			CBlob@[] blobs;
			CBlob@[] targets;
			if (getBlobsByTag("player", @blobs))
			{
				for (int i = 0; i < blobs.size(); i++)
				{
					CBlob@ blob = blobs[i];
					if (blob !is null && blob.getTeamNum() != this.getTeamNum())
					{
						for (int j = 0; j <= targets.size(); j++)
						{
							if (j == targets.size() || (blob.getPosition() - pos).Length() < (targets[j].getPosition() - pos).Length())
							{
								targets.insert(j, blob);
								break;
							}
						}
					}
				}
			}

			// set targets
			int j = 0;
			for (int i = 0; i < 4; i++)
			{
				string name = "target" + i;

				if (targets.size() <= 0)
				{
					this.set(name, null);
				}
				else
				{
					if (j >= targets.size()) j = 0;
					this.set_netid(name, targets[j].getNetworkID());
				}

				j++;
			}

			robot.module_special = 31; // shoot missiles at 31/21/11/01

			if(!isClient()) this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;
		
		case LWBRobotModules::clustermissile:
		{
			CBlob@ bullet = server_CreateBlobNoInit("robotpodclusterrocket");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_Vec2f("aimPoint", aimPos);
				bullet.Init();
			
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(offsetPos);
				bullet.setVelocity(Vec2f(0.0f, -3.0f));
			}

			this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;
		
		case LWBRobotModules::sunbeam:
		{
			robot.module_special += 120;

			this.set_Vec2f("sunbeamAngle", normVel);
			this.Sync("sunbeamAngle", true);
			this.set_bool("sunbeamLeft", this.isFacingLeft());
			this.Sync("sunbeamLeft", true);

			if(!isClient()) this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;
		
		case LWBRobotModules::orbit:
		{
			CBlob@ bullet = server_CreateBlobNoInit("lwborbitalstrike");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(Vec2f(aimPos.x, -8.0f));
				bullet.Init();
			}

			this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;
		
		case LWBRobotModules::emp:
		{
			robot.module_special += 45;

			this.set_Vec2f("empAngle", normVel);
			this.Sync("empAngle", true);
			this.set_bool("empLeft", this.isFacingLeft());
			this.Sync("empLeft", true);

			if(!isClient()) this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;
		
		case LWBRobotModules::gundrone:
		{
			CBlob@ bullet = server_CreateBlob("lwbgundrone");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_netid("owner", this.getNetworkID());
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(pos);
			}
			
			this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;
		
		case LWBRobotModules::beamdrone:
		{
			this.getSprite().PlaySound("maou_se_sound_machine08.ogg");
			
			CBlob@ bullet = server_CreateBlob("lwbbeamdrone");
			if (bullet !is null)
			{
				bullet.SetDamageOwnerPlayer(this.getPlayer());
				bullet.set_netid("owner", this.getNetworkID());
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(pos);
			}
			
			this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;

		case LWBRobotModules::antigravity:
		{
			this.getSprite().PlaySound("maou_se_sound_machine07.ogg");

			CBlob@ bullet = server_CreateBlobNoInit("lwbantigravityfield");
			if (bullet !is null)
			{
				bullet.IgnoreCollisionWhileOverlapped(this);
				bullet.server_setTeamNum(this.getTeamNum());
				bullet.setPosition(pos);
				bullet.Init();
			}
			
			this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;

		case LWBRobotModules::disperser:
		{
			for (int i = 0; i < 10; i++)
			{
				CBlob@ bullet = server_CreateBlobNoInit("robotenergyballmini");
				if (bullet !is null)
				{
					bullet.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
					bullet.Init();
				
					bullet.IgnoreCollisionWhileOverlapped(this);
					bullet.server_setTeamNum(this.getTeamNum());
					bullet.setPosition(this.getPosition());
					bullet.setVelocity((Vec2f(0.0f, -5.0f).RotateBy(30.0f - (XORRandom(XORRandom(256)) / 255.0f * 60.0f))) * ((XORRandom(256)) / 255.0f + 1));
				}
			}

			this.SendCommand(this.getCommandID("shoot_module_client"));
		}
		break;
	}
}

void moduleOperate_client(CBlob@ this, LWBRobotInfo@ robot, CBitStream @params)
{
	bool isServer = getNet().isServer();
	switch (this.get_u8("module"))
	{
		case LWBRobotModules::healdrone:
		{
			this.getSprite().PlaySound("maou_se_sound_machine08.ogg");
		}
		break;

		case LWBRobotModules::shieldturret:
		{
			this.getSprite().PlaySound("maou_se_sound_machine07.ogg");
		}
		break;

		case LWBRobotModules::homingmissile:
		{
			robot.module_special = 31; // shoot missiles at 31/21/11/01
		}
		break;
		
		case LWBRobotModules::clustermissile:
		{
			this.getSprite().PlaySound("FireFwoosh.ogg");
			this.getSprite().PlaySound("maou_se_sound01.ogg");
		}
		break;
		
		case LWBRobotModules::sunbeam:
		{
			this.getSprite().PlaySound("PowerUp.ogg");

			robot.module_special += 120;
		}
		break;
		
		case LWBRobotModules::orbit:
		{
			this.getSprite().PlaySound("PowerUp.ogg");
		}
		break;
		
		case LWBRobotModules::emp:
		{
			this.getSprite().PlaySound("PowerUp.ogg");

			robot.module_special += 45;
		}
		break;
		
		case LWBRobotModules::gundrone:
		{
			this.getSprite().PlaySound("maou_se_sound_machine08.ogg");
		}
		break;
		
		case LWBRobotModules::beamdrone:
		{
			this.getSprite().PlaySound("maou_se_sound_machine08.ogg");
		}
		break;

		case LWBRobotModules::antigravity:
		{
			this.getSprite().PlaySound("maou_se_sound_machine07.ogg");
		}
		break;

		case LWBRobotModules::disperser:
		{
			this.getSprite().PlaySound("KegExplosion.ogg");
		}
		break;
	}
}