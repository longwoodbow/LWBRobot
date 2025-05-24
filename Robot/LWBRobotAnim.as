// Knight animations

#include "LWBRobotCommon.as";
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "Accolades.as"
#include "CrouchCommon.as";
#include "ParticleSparks.as";
#include "Explosion.as";  // <---- onHit()

void onInit(CSprite@ this)
{
	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	ensureCorrectRunnerTexture(this, "lwbrobot", "LWBRobot");

	string texname = getRunnerTextureName(this);

	// add hand
	this.RemoveSpriteLayer("left_hand");
	CSpriteLayer@ lefthand = this.addSpriteLayer("left_hand", "LWBRobotHands.png" , 32, 16, this.getBlob().getTeamNum(), 0);

	if (lefthand !is null)
	{
		Animation@ anim = lefthand.addAnimation("default", 0, false);
		for (int i = 0; i < LWBRobotWeapons::count; i++)
		{
			anim.AddFrame(i);
		}
		lefthand.SetAnimation("default");

		Animation@ sAnim = lefthand.addAnimation("special", 0, false);
		// i < 2 means 2 special sprites
		// i + 22 means first special sprite frame is 22
		for (int i = 0; i < 2; i++)
		{
			sAnim.AddFrame(i + 22);
		}
	}

	this.RemoveSpriteLayer("right_hand");
	CSpriteLayer@ righthand = this.addSpriteLayer("right_hand", "LWBRobotHands.png" , 32, 16, this.getBlob().getTeamNum(), 0);

	if (righthand !is null)
	{
		Animation@ anim = righthand.addAnimation("default", 0, false);
		for (int i = 0; i < LWBRobotWeapons::count; i++)
		{
			anim.AddFrame(i);
		}
		righthand.SetAnimation("default");

		Animation@ sAnim = righthand.addAnimation("special", 0, false);
		// i < 2 means 2 special sprites
		// i + 22 means first special sprite frame is 22
		for (int i = 0; i < 2; i++)
		{
			sAnim.AddFrame(i + 22);
		}
	}

	// add module

	this.RemoveSpriteLayer("module");
	CSpriteLayer@ module = this.addSpriteLayer("module", "LWBRobotModules.png" , 16, 16, this.getBlob().getTeamNum(), 0);

	if (module !is null)
	{
		Animation@ anim = module.addAnimation("default", 0, false);
		for (int i = 0; i < LWBRobotModules::count; i++)
		{
			anim.AddFrame(i);
		}
		module.SetAnimation("default");
		module.SetRelativeZ(-0.1f);
	}

	this.RemoveSpriteLayer("laserLeft");
	CSpriteLayer@ laserLeft = this.addSpriteLayer("laserLeft", "LWBRobotLaser.png" , 32, 8, this.getBlob().getTeamNum(), 0);

	if (laserLeft !is null)
	{
		Animation@ anim = laserLeft.addAnimation("default", 0, false);
		anim.AddFrame(0);
		laserLeft.SetAnimation("default");
		laserLeft.SetRelativeZ(1.5f);
		laserLeft.SetVisible(false);
	}

	this.RemoveSpriteLayer("laserRight");
	CSpriteLayer@ laserRight = this.addSpriteLayer("laserRight", "LWBRobotLaser.png" , 32, 8, this.getBlob().getTeamNum(), 0);

	if (laserLeft !is null)
	{
		Animation@ anim = laserRight.addAnimation("default", 0, false);
		anim.AddFrame(0);
		laserRight.SetAnimation("default");
		laserRight.SetRelativeZ(1.5f);
		laserRight.SetVisible(false);
	}

	this.RemoveSpriteLayer("beamLeft");
	CSpriteLayer@ beamLeft = this.addSpriteLayer("beamLeft", "LWBRobotBeam.png" , 32, 8, this.getBlob().getTeamNum(), 0);

	if (beamLeft !is null)
	{
		Animation@ anim = beamLeft.addAnimation("default", 0, false);
		anim.AddFrame(0);
		beamLeft.SetAnimation("default");
		beamLeft.SetRelativeZ(1.5f);
		beamLeft.SetVisible(false);
	}

	this.RemoveSpriteLayer("beamRight");
	CSpriteLayer@ beamRight = this.addSpriteLayer("beamRight", "LWBRobotBeam.png" , 32, 8, this.getBlob().getTeamNum(), 0);

	if (beamRight !is null)
	{
		Animation@ anim = beamRight.addAnimation("default", 0, false);
		anim.AddFrame(0);
		beamRight.SetAnimation("default");
		beamRight.SetRelativeZ(1.5f);
		beamRight.SetVisible(false);
	}

	for (u8 i = 0; i < 2; i++)
	{
		this.RemoveSpriteLayer("beamChargeLeft" + i);
		CSpriteLayer@ chargeLeft = this.addSpriteLayer("beamChargeLeft" + i, "LWBRobotBeamCharging.png" , 32, 3, this.getBlob().getTeamNum(), 0);

		if (chargeLeft !is null)
		{
			Animation@ anim = chargeLeft.addAnimation("default", 0, false);
			anim.AddFrame(0);
			chargeLeft.SetAnimation("default");
			chargeLeft.SetRelativeZ(1.5f);
			chargeLeft.SetVisible(false);
		}
	}

	for (u8 i = 0; i < 2; i++)
	{
		this.RemoveSpriteLayer("beamChargeRight" + i);
		CSpriteLayer@ chargeRight = this.addSpriteLayer("beamChargeRight" + i, "LWBRobotBeamCharging.png" , 32, 3, this.getBlob().getTeamNum(), 0);

		if (chargeRight !is null)
		{
			Animation@ anim = chargeRight.addAnimation("default", 0, false);
			anim.AddFrame(0);
			chargeRight.SetAnimation("default");
			chargeRight.SetRelativeZ(1.5f);
			chargeRight.SetVisible(false);
		}
	}

	for (u8 i = 0; i < 3; i++)
	{
		this.RemoveSpriteLayer("sawDrone" + i);
		CSpriteLayer@ sawDrone = this.addSpriteLayer("sawDrone" + i, "LWBRobotSawDrone.png" , 16, 16, this.getBlob().getTeamNum(), 0);

		if (sawDrone !is null)
		{
			Animation@ anim = sawDrone.addAnimation("default", 0, false);
			anim.AddFrame(0);
			sawDrone.SetAnimation("default");
			sawDrone.SetRelativeZ(1000.0f);
			sawDrone.SetVisible(false);
		}
	}

	this.RemoveSpriteLayer("sunBeam");
	CSpriteLayer@ sunBeam = this.addSpriteLayer("sunBeam", "LWBRobotSunBeam.png" , 32, 32);

	if (sunBeam !is null)
	{
		Animation@ anim = sunBeam.addAnimation("default", 0, false);
		anim.AddFrame(0);
		sunBeam.SetAnimation("default");
		sunBeam.SetRelativeZ(1.5f);
		sunBeam.SetVisible(false);
	}

	for (u8 i = 0; i < 9; i++)
	{
		this.RemoveSpriteLayer("sunBeamCharge" + i);
		CSpriteLayer@ sunBeamCharge = this.addSpriteLayer("sunBeamCharge" + i, "LWBRobotSunBeamCharging.png" , 32, 1);

		if (sunBeamCharge !is null)
		{
			Animation@ anim = sunBeamCharge.addAnimation("default", 0, false);
			anim.AddFrame(0);
			sunBeamCharge.SetAnimation("default");
			sunBeamCharge.SetRelativeZ(1.5f);
			sunBeamCharge.SetVisible(false);
		}
	}

	this.RemoveSpriteLayer("emp");
	CSpriteLayer@ emp = this.addSpriteLayer("emp", "LWBRobotEMP.png" , 32, 16, this.getBlob().getTeamNum(), 0);

	if (emp !is null)
	{
		Animation@ anim = emp.addAnimation("default", 0, false);
		anim.AddFrame(0);
		emp.SetAnimation("default");
		emp.SetRelativeZ(1.5f);
		emp.SetVisible(false);
	}

	for (u8 i = 0; i < 3; i++)
	{
		this.RemoveSpriteLayer("empCharge" + i);
		CSpriteLayer@ empCharge = this.addSpriteLayer("empCharge" + i, "LWBRobotEMPCharging.png" , 32, 3, this.getBlob().getTeamNum(), 0);

		if (empCharge !is null)
		{
			Animation@ anim = empCharge.addAnimation("default", 0, false);
			anim.AddFrame(0);
			empCharge.SetAnimation("default");
			empCharge.SetRelativeZ(1.5f);
			empCharge.SetVisible(false);
		}
	}
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();

	if (blob.hasTag("dead"))
	{
		if (this.animation.name != "dead")
		{
			this.SetAnimation("dead");
		}
	}

	LWBRobotInfo@ robot;
	if (!blob.get("robotInfo", @robot))
	{
		return;
	}

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);
	const bool inair = (!blob.isOnGround() && !blob.isOnLadder());
	bool crouch = false;

	bool knocked = isKnocked(blob);
	Vec2f pos = blob.getPosition() + Vec2f(0, -2);
	Vec2f aimpos = blob.getAimPos();
	pos.x += this.isFacingLeft() ? 2 : -2;

	// get the angle of aiming with mouse
	Vec2f vec = aimpos - pos;
	f32 angle = vec.Angle();

	// weapons offsets and angles
	f32 armangle = -angle;


	if (this.isFacingLeft())
	{
		armangle = 180.0f - angle;
	}

	while (armangle > 180.0f)
	{
		armangle -= 360.0f;
	}

	while (armangle < -180.0f)
	{
		armangle += 360.0f;
	}

	if (blob.hasTag("dead"))
	{
		armangle = 0.0f;
	}

	// effect operate

	for (int i = 0; i < robot.effects.size(); i++)
	{
		CSpriteLayer@ effect = this.getSpriteLayer(robot.effects[i].name);

		if (effect !is null)
		{
			if (getGameTime() >= robot.effects[i].endTime)
			{
				this.RemoveSpriteLayer(robot.effects[i].name);
				robot.effects.erase(i);
			}
			else
			{
				switch (robot.effects[i].type)
				{
					case LWBRobotWeapons::railgun:
					case LWBRobotWeapons::lightning:
					{
						Vec2f offset = robot.effects[i].offset + (robot.effects[i].shootingPos - blob.getPosition());
						offset.x *= -1.0f;
						effect.SetOffset(offset);
					}
					break;

					case LWBRobotWeapons::blade:
					case LWBRobotWeapons::energyblade:
					{
						if (effect.isAnimationEnded())
							effect.SetVisible(false);

						f32 chopAngle = -vec.Angle();
						f32 choplength = 5.0f;

						Vec2f offset = Vec2f(choplength, 0.0f);
						offset.RotateBy(chopAngle, Vec2f_zero);
						if (!this.isFacingLeft())
							offset.x *= -1.0f;
						offset.y += this.getOffset().y * 0.5f;

						effect.SetOffset(offset);
						effect.ResetTransform();
						if (this.isFacingLeft())
							effect.RotateBy(180.0f + chopAngle, Vec2f());
						else
							effect.RotateBy(chopAngle, Vec2f());
					}
					break;
				}
			}
		}
	}

	//hands

	CSpriteLayer@ lefthand = this.getSpriteLayer(this.isFacingLeft() ? "right_hand" : "left_hand");
	if (lefthand !is null)
	{
		if (not this.isVisible()) {
			lefthand.SetVisible(false);
		}
		else lefthand.SetVisible(true);

		
		//face the same way (force)
		lefthand.SetIgnoreParentFacing(true);
		lefthand.SetFacingLeft(this.isFacingLeft());

		int layer = 0;
		Vec2f head_offset = getHeadOffset(blob, -1, layer);

		Vec2f off;
		if (layer != 0)
		{
			off.Set(this.getFrameWidth() / 2, -this.getFrameHeight() / 2);
			off += this.getOffset();
			off += Vec2f(-head_offset.x, head_offset.y);

			off += Vec2f(-1.0f, 4.0f);
			lefthand.SetOffset(off);
		}

		if ((this.isFacingLeft() ? blob.get_u8("righthand") : blob.get_u8("lefthand")) == LWBRobotWeapons::shield)
		{
			lefthand.SetAnimation("special");
			lefthand.animation.frame = 0;
		}
		else if ((this.isFacingLeft() ? blob.get_u8("righthand") : blob.get_u8("lefthand")) == LWBRobotWeapons::sawboomelang && getBlobByNetworkID(blob.get_netid("boomelang"  + (this.isFacingLeft() ? "Right" : "Left"))) !is null)
		{
			lefthand.SetAnimation("special");
			lefthand.animation.frame = 1;
		}
		else
		{
			lefthand.SetAnimation("default");
			lefthand.animation.frame = this.isFacingLeft() ? blob.get_u8("righthand") : blob.get_u8("lefthand");
		}
		lefthand.ResetTransform();
		lefthand.SetRelativeZ(-0.1f);
		lefthand.RotateBy(armangle, Vec2f_zero);
	}

	CSpriteLayer@ righthand = this.getSpriteLayer(this.isFacingLeft() ? "left_hand" : "right_hand");
	if (righthand !is null)
	{
		if (not this.isVisible()) {
			righthand.SetVisible(false);
		}
		else righthand.SetVisible(true);

		
		//face the same way (force)
		righthand.SetIgnoreParentFacing(true);
		righthand.SetFacingLeft(this.isFacingLeft());

		int layer = 0;
		Vec2f head_offset = getHeadOffset(blob, -1, layer);

		Vec2f off;
		if (layer != 0)
		{
			off.Set(this.getFrameWidth() / 2, -this.getFrameHeight() / 2);
			off += this.getOffset();
			off += Vec2f(-head_offset.x, head_offset.y);

			off += Vec2f(4.0f, 4.0f);
			righthand.SetOffset(off);
		}

		if ((this.isFacingLeft() ? blob.get_u8("lefthand") : blob.get_u8("righthand")) == LWBRobotWeapons::sawboomelang && getBlobByNetworkID(blob.get_netid("boomelang"  + (this.isFacingLeft() ? "Left" : "Right"))) !is null)
		{
			righthand.SetAnimation("special");
			righthand.animation.frame = 1;
		}
		else
		{
			righthand.SetAnimation("default");
			righthand.animation.frame =  this.isFacingLeft() ? blob.get_u8("lefthand") : blob.get_u8("righthand");
		}
		righthand.ResetTransform();
		righthand.SetRelativeZ(1.5f);
		righthand.RotateBy(armangle, Vec2f_zero);
	}

	// module offset
	// like archer quiver
	CSpriteLayer@ module = this.getSpriteLayer("module");
	if (module !is null)
	{
		if (not this.isVisible()) {
			module.SetVisible(false);
		}
		else module.SetVisible(true);

		
		//face the same way (force)
		module.SetIgnoreParentFacing(true);
		module.SetFacingLeft(this.isFacingLeft());

		int layer = 0;
		Vec2f head_offset = getHeadOffset(blob, -1, layer);

		Vec2f off;
		if (layer != 0)
		{
			off.Set(this.getFrameWidth() / 2, -this.getFrameHeight() / 2);
			off += this.getOffset();
			off += Vec2f(-head_offset.x, head_offset.y);

			off += Vec2f(5.0f, 3.0f);
			module.SetOffset(off);
		}

		module.animation.frame = blob.get_u8("module");
	}

	// damage effect
	if (getNet().isClient())
	{
		// health check
		f32 initHealth = getActualMaxHealth(blob);
		f32 healthRatio = getActualHealth(blob) / initHealth;

		// sparks
		if (healthRatio < 0.5f && XORRandom(256) > healthRatio * 256.0f + 128.0f)
		{
			sparks(blob.getPosition(), f32(XORRandom(360)), 0.1f);
			//this.PlaySound("metronome.ogg", 0.01f); // cant make sound smaller... why
		}

		// lightnings
		if ((healthRatio < 0.2f && XORRandom(256) > healthRatio * 256.0f + 200.0f) || (blob.hasTag("energy_stun") && blob.getTickSinceCreated() % 3 == 0))
		{
			CParticle@ p = ParticleAnimated("LWBRobotLightningeffect.png", blob.getPosition(), Vec2f(0, 0), 0.0f, 1.0f, 0, 0, Vec2f(32, 32), 1, 0, true);
			if (p !is null)
			{
				p.animated = 2;
				//p.style = XORRandom(4);
			    p.Z = 7;
			    p.timeout = 10;
				p.setRenderStyle(RenderStyle::light);
			}
		}
	}

	if (blob.hasTag("dead"))
	{
		if (this.animation.name != "dead")
		{
			this.SetAnimation("dead");
		}

		Vec2f vel = blob.getVelocity();

		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(0);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(1);
		}
		else
		{
			this.SetFrameIndex(2);
		}

		return;
	}

	if (knocked)
	{
		if (inair)
		{
			this.SetAnimation("knocked_air");
		}
		else
		{
			this.SetAnimation("knocked");
		}
	}
	else if (blob.hasTag("seated"))
	{
		this.SetAnimation("crouch");
	}
	else if (inair)
	{
		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
		}
		Vec2f vel = blob.getVelocity();
		f32 vy = vel.y;
		if (vy < -0.0f && moveVars.walljumped)
		{
			this.SetAnimation("run");
		}
		else
		{
			this.SetAnimation("fall");
			this.animation.timer = 0;
			bool inwater = blob.isInWater();

			if (vy < -1.5 * (inwater ? 0.7 : 1))
			{
				this.animation.frame = 0;
			}
			else if (vy > 1.5 * (inwater ? 0.7 : 1))
			{
				this.animation.frame = 2;
			}
			else
			{
				this.animation.frame = 1;
			}
		}
	}
	else if ((left || right) ||
	         (blob.isOnLadder() && (up || down)))
	{
		this.SetAnimation("run");
	}
	else
	{
		if (down && this.isAnimationEnded())
			crouch = true;

		int direction;

		if ((angle > 330 && angle < 361) || (angle > -1 && angle < 30) ||
		        (angle > 150 && angle < 210))
		{
			direction = 0;
		}
		else if (aimpos.y < pos.y)
		{
			direction = -1;
		}
		else
		{
			direction = 1;
		}

		defaultIdleAnim(this, blob, direction);
	}

	//set the head anim
	if (knocked)
	{
		blob.Tag("dead head");
	}
	else if (blob.isKeyPressed(key_action1) || blob.isKeyPressed(key_action2))
	{
		blob.Tag("attack head");
		blob.Untag("dead head");
	}
	else
	{
		blob.Untag("attack head");
		blob.Untag("dead head");
	}

}

// disabled because of issue on hand gibs
// Vec2f(32, 16) becomes like Vec2f(32, 32)

void onGib(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	Explode(blob, blob.get_f32("explosive_radius"), blob.get_f32("explosive_damage"));

	if (g_kidssafe || true)
	{
		return;
	}

	LWBRobotInfo@ robot;
	if (!blob.get("robotInfo", @robot))
	{
		return;
	}

	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("LWBRobotHands.png", pos, vel + getRandomVelocity(90, hp , 80), blob.get_u8("lefthand"), 0, Vec2f(32, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm      = makeGibParticle("LWBRobotHands.png", pos, vel + getRandomVelocity(90, hp , 80), blob.get_u8("righthand"), 0, Vec2f(32, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("LWBRobotModules.png", pos, vel + getRandomVelocity(90, hp , 80), blob.get_u8("module"), 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	//CParticle@ Sword    = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}