#define SERVER_ONLY

#include "BrainCommon.as"

void onInit(CBrain@ this)
{
	InitBrain(this);

	this.server_SetActive(true); // always running

	CBlob @blob = this.getBlob();
	blob.set_u32("attack time", 0);
	blob.set_bool("move_left", true);
}

void onTick(CBrain@ this)
{
	if (getRules().isWarmup()) return; // do nothing in warmup

	CBlob @blob = this.getBlob();
	Vec2f mypos = blob.getPosition();
	this.SetTarget(getNewTarget(this, blob, false, true));// always search nearest one
	CBlob @target = this.getTarget();

	bool moveLeft = blob.get_bool("move_left");

	u32 attackTime = blob.get_u32("attack time");
	blob.add_u32("attack time", 1);

	// logic for target

	if (target !is null)
	{
		Vec2f targetPos = target.getPosition();

		// chase
		if (targetPos.x < mypos.x) moveLeft = false;
		else moveLeft = true;
		
		if (attackTime >= 300 + XORRandom(150) && Maths::Abs(targetPos.x - mypos.x) <= 128.0f)// shoot laser
		{
			blob.SendCommand(blob.getCommandID("shoot_laser"));
			blob.set_u32("attack time", 0);
		}
	}

	if (attackTime >= 305 + XORRandom(145))// summon drones
	{
		blob.SendCommand(blob.getCommandID("summon_drones"));
		blob.set_u32("attack time", 0);
	}

	CMap@ map = getMap();
	float mapSize = map.tilemapwidth * map.tilesize;
	if (mypos.x < 64.0f) moveLeft = true;
	else if (mypos.x > mapSize - 64.0f) moveLeft = false;

	if (moveLeft) blob.setVelocity(Vec2f(1.0f, 0.0f));
	else blob.setVelocity(Vec2f(-1.0f, 0.0f));

	blob.set_bool("move_left", moveLeft);
} 
