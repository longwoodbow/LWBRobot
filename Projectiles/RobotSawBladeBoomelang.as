
#include "Hitters.as";
#include "TeamStructureNear.as";
#include "LWBRobotCommon.as"

const s32 bomb_fuse = 120;
const f32 arrowMediumSpeed = 8.0f;
const f32 arrowFastSpeed = 13.0f;
//maximum is 15 as of 22/11/12 (see ArcherCommon.as)

const f32 ARROW_PUSH_FORCE = 6.0f;
const f32 SPECIAL_HIT_SCALE = 1.0f; //special hit on food items to shoot to team-mates

const s32 FIRE_IGNITE_TIME = 5;

const u32 STUCK_ARROW_DECAY_SECS = 30;

//Arrow logic

//blob functions
void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // penetrate blocks
	consts.bullet = false;
	consts.net_threshold_multiplier = 4.0f;
	this.Tag("projectile");
	this.Tag("prevent_antigravity");

	
	//dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	// 3 seconds of floating around - gets cut down for fire arrow
	// in ArrowHitMap
	this.server_SetTimeToDie(3);

	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(1000.0f);

	CSpriteLayer@ wire = sprite.addSpriteLayer("wire", "RobotSawBladeBoomelangWire.png" , 32, 1);

	if (wire !is null)
	{
		Animation@ anim = wire.addAnimation("default", 0, false);
		anim.AddFrame(0);
		wire.SetAnimation("default");
		wire.SetRelativeZ(1001.0f);
		wire.SetVisible(false);
	}

	if (this.exists("robot") && this.exists("hand"))
	{
		CBlob@ owner = getBlobByNetworkID(this.get_netid("robot"));
		if (owner !is null)
		{
			owner.set_netid("boomelang" + (this.get_bool("hand") ? "Left" : "Right"), this.getNetworkID());
		}
	}
}

void onTick(CBlob@ this)
{
	CShape@ shape = this.getShape();

	f32 angle;
	if (!this.hasTag("collided")) //we haven't hit anything yet!
	{
		Vec2f pos = this.getPosition();
		//prevent leaving the map
		{
			if (
				pos.x < 0.1f ||
				pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f
			) {
				this.server_Die();
				return;
			}
		}

		f32 sawAngle = this.getTickSinceCreated() * 30.0f;

		while (sawAngle > 360.0f)
		{
			sawAngle -= 360.0f;
		}

		this.setAngleDegrees(sawAngle);

		Vec2f velocity = this.getVelocity();
		angle = velocity.Angle();

		// follow mouse
		CPlayer@ owner = this.getDamageOwnerPlayer();
		

		if (owner !is null)
		{
			CBlob@ ownerBlob = owner.getBlob();

			if (ownerBlob !is null)
			{
				Vec2f aim = ownerBlob.getPosition();
				Vec2f aimedDirection = aim - pos;

				CSpriteLayer@ wire = this.getSprite().getSpriteLayer("wire");

				if (wire !is null)
				{
					f32 wirelen = Maths::Max(0.1f, aimedDirection.Length() / 32.0f);

					wire.ResetTransform();
					wire.ScaleBy(Vec2f(wirelen, 1.0f));

					wire.TranslateBy(Vec2f(wirelen * 16.0f, 0.0f));

					wire.RotateBy(-(aimedDirection).getAngleDegrees() - sawAngle , Vec2f());

					wire.SetVisible(true);
				}

				aimedDirection.Normalize();
				f32 aimAngle = aimedDirection.Angle();

				f32 dif = aimAngle - angle;

				while (dif > 180.0f)
				{
					dif -= 360.0f;
				}
				while (dif < -180.0f)
				{
					dif += 360.0f;
				}

				if (velocity.Length() >= 5.0f && (dif <= 45.0f || dif > -45.0f) && this.getTickSinceCreated() > 15)
				{
					this.setVelocity(velocity.RotateBy(-dif));
				}

				this.AddForce(aimedDirection * 0.5f);
			}
			else
			{
				this.getSprite().RemoveSpriteLayer("wire");
			}
		}
		else
		{
			this.getSprite().RemoveSpriteLayer("wire");
		}

		// hit check
		if (getNet().isServer())
		{
			u8 type = LWBRobotHitters::physical;
			if (this.exists("hand"))
			{
				type = this.get_bool("hand") ? LWBRobotHitters::physical_left : LWBRobotHitters::physical_right;
			}

			CBlob@[] blobs;
			this.getMap().getBlobsInRadius(pos, this.getRadius(), @blobs);
			for (int i = 0; i < blobs.size(); i++)
			{
				if (blobs[i].getTeamNum() != this.getTeamNum() && !blobs[i].hasTag("projectile")) this.server_Hit(blobs[i], pos, velocity, 0.75f, type);
				else if (owner !is null && this.getTickSinceCreated() > 15)
				{
					CBlob@ ownerBlob = owner.getBlob();

					if (ownerBlob !is null && blobs[i] is ownerBlob) this.server_Die();
				}
			}
		}

		shape.SetGravityScale(0.0f);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "lwbturretshield" && this.getTeamNum() != blob.getTeamNum()) this.server_Die();
	return false;
}

bool specialArrowHit(CBlob@ blob)
{
	string bname = blob.getName();
	return (bname == "fishy" && blob.hasTag("dead") || bname == "food"
		|| bname == "steak" || bname == "grain"/* || bname == "heart"*/); //no egg because logic
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is this)
	{
		return 0.0f; //no cut arrows
	}

	return damage;
}