
#include "Hitters.as";
#include "BombCommon.as";
#include "TeamStructureNear.as";
#include "KnockedCommon.as"
#include "LWBRobotCommon.as"
#include "MakeDustParticle.as";

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
	shape.SetRotationsAllowed(false);
	ShapeConsts@ consts = shape.getConsts();
	consts.mapCollisions = false;	 // weh ave our own map collision
	consts.bullet = false;
	consts.net_threshold_multiplier = 4.0f;
	this.Tag("projectile");

	
	//dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	// 5 seconds of floating around - gets cut down for fire arrow
	// in ArrowHitMap
	this.server_SetTimeToDie(5);

	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 3.0f);
	this.set_f32("map_damage_radius", 24.0f);
	this.set_f32("map_damage_ratio", 0.5f);
	this.set_bool("map_damage_raycast", true);

	u8 type = LWBRobotHitters::physical;
	if (this.exists("hand"))
	{
		type = this.get_bool("hand") ? LWBRobotHitters::physical_left : LWBRobotHitters::physical_right;
	}

	this.set_u8("custom_hitter", type);
	this.Tag("exploding");
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

		Vec2f velocity = this.getVelocity();
		angle = velocity.Angle();

		// hit check
		if (getNet().isServer() && this.getTickSinceCreated() % 3 == 0)
		{
			u8 type = this.get_u8("custom_hitter");

			CBlob@[] blobs;
			this.getMap().getBlobsInRadius(pos, this.getRadius(), @blobs);
			for (int i = 0; i < blobs.size(); i++)
			{
				if (blobs[i].getTeamNum() != this.getTeamNum() && !blobs[i].hasTag("projectile")) this.server_Hit(blobs[i], pos, velocity, 3.0f, type);
			}

			if (this.getTickSinceCreated() % 4 == 0)
			{
				Vec2f childVel = Vec2f(3.0f, 0.0f);

				for (int i = 0; i < 4; i++)
				{
					CBlob@ bullet = server_CreateBlobNoInit("robotplanetchild");
					if (bullet !is null)
					{
						bullet.SetDamageOwnerPlayer(this.getDamageOwnerPlayer());
						if (this.exists("hand")) bullet.set_bool("hand", this.get_bool("hand"));
						bullet.Init();
					
						bullet.IgnoreCollisionWhileOverlapped(this);
						bullet.server_setTeamNum(this.getTeamNum());
						bullet.setPosition(this.getPosition());
						bullet.setVelocity(childVel);

						childVel.RotateBy(90.0f);
					}
				}
			}
		}

		Pierce(this);   //map

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

void Pierce(CBlob @this, CBlob@ blob = null)
{
	Vec2f end;
	CMap@ map = this.getMap();
	Vec2f position = blob is null ? this.getPosition() : blob.getPosition();

	if (map.rayCastSolidNoBlobs(this.getShape().getVars().oldpos, position, end))
	{
		ArrowHitMap(this, end, this.getOldVelocity(), 0.5f, Hitters::arrow);
	}
}

void ArrowHitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	if (velocity.Length() > arrowFastSpeed)
	{
		this.getSprite().PlaySound("ArrowHitGroundFast.ogg");
	}
	else
	{
		this.getSprite().PlaySound("ArrowHitGround.ogg");
	}

	f32 radius = this.getRadius();

	f32 angle = velocity.Angle();

	this.set_u8("angle", Maths::get256DegreesFrom360(angle));

	Vec2f norm = velocity;
	norm.Normalize();
	norm *= (1.5f * radius);
	Vec2f lock = worldPoint - norm;
	this.set_Vec2f("lock", lock);

	this.Sync("lock", true);
	this.Sync("angle", true);

	this.setVelocity(Vec2f(0, 0));
	this.setPosition(lock);
	//this.getShape().server_SetActive( false );

	this.Tag("collided");

	if (!this.hasTag("dead"))
	{
		this.Tag("dead");
		this.doTickScripts = false;
		this.server_Die(); //explode
	}
}

//random object used for gib spawning
Random _gib_r(0xa7c3a);
void onDie(CBlob@ this)
{
	if (getNet().isClient())
	{
		Vec2f pos = this.getPosition();
		if (pos.x >= 1 && pos.y >= 1)
		{
			Vec2f vel = this.getVelocity();
			makeGibParticle(
				"GenericGibs.png", pos, vel,
				2, _gib_r.NextRanged(4) + 4,
				Vec2f(8, 8), 2.0f, 20, "/thud",
				this.getTeamNum()
			);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is this)
	{
		return 0.0f; //no cut arrows
	}

	return damage;
}

f32 getArrowDamage(CBlob@ this, f32 vellen = -1.0f)
{
	if (vellen < 0) //grab it - otherwise use cached
	{
		CShape@ shape = this.getShape();
		if (shape is null)
			vellen = this.getOldVelocity().Length();
		else
			vellen = this.getShape().getVars().oldvel.Length();
	}

	if (vellen >= arrowFastSpeed)
	{
		return 0.1f;
	}
	else if (vellen >= arrowMediumSpeed)
	{
		return 0.1f;
	}

	return 0.1f;
}