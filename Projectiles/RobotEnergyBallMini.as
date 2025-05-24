
#include "Hitters.as";
#include "BombCommon.as";
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
	consts.bullet = true;
	consts.net_threshold_multiplier = 4.0f;
	this.Tag("projectile");

	
	//dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);

	// 3 seconds of floating around - gets cut down for fire arrow
	// in ArrowHitMap
	this.server_SetTimeToDie(3);
}

void onTick(CBlob@ this)
{
	Vec2f pos = this.getPosition();
	//prevent leaving the map
	
		if (
			pos.x < 0.1f ||
			pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f
		) {
			this.server_Die();
			return;
		}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null || this.getTeamNum() == blob.getTeamNum()) return;

	this.server_Hit(blob, point1, this.getOldVelocity(), 1.0f, LWBRobotHitters::energy_module);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (blob.getName() == "lwbturretshield" && this.getTeamNum() != blob.getTeamNum());
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is this)
	{
		return 0.0f; //no cut arrows
	}

	return damage;
}