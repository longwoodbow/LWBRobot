#define SERVER_ONLY

#include "BrainCommon.as"

void onInit(CBrain@ this)
{
	InitBrain(this);

	this.server_SetActive(true); // always running

	CBlob @blob = this.getBlob();
	blob.set_u32("sword_cooldown", 0);
	blob.set_u32("buster_cooldown", 0);
}

void onTick(CBrain@ this)
{
	if (getRules().isWarmup()) return; // do nothing in warmup

	CBlob @blob = this.getBlob();
	//if (!blob.get_bool("awaken")) return;
	Vec2f mypos = blob.getPosition();
	this.SetTarget(getNewTarget(this, blob, false, true));// always search nearest one
	CBlob @target = this.getTarget();

	FloatInWater(blob);

	u32 swordTime = blob.get_u32("sword_cooldown");
	blob.add_u32("sword_cooldown", 1);

	u32 busterTime = blob.get_u32("buster_cooldown");
	blob.add_u32("buster_cooldown", 1);


	// logic for target

	if (target !is null)
	{
		Vec2f targetPos = target.getPosition();
		Vec2f targetVector = targetPos - mypos;
		f32 targetDistance = targetVector.Length();

		Chase(blob, target);
		blob.setAimPos(targetPos);
		
		if (busterTime >= 300 + XORRandom(150))// shoot buster
		{
			blob.SendCommand(blob.getCommandID("buster"));
			blob.set_u32("buster_cooldown", 0);
		}

		if (targetDistance <= 128.0f && swordTime >= 20)
		{
			blob.SendCommand(blob.getCommandID("sword"));
			blob.set_u32("sword_cooldown", 0);
		}
	}
} 
