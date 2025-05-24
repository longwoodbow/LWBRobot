#define SERVER_ONLY

#include "BrainCommon.as"

void onInit(CBrain@ this)
{
	InitBrain(this);

	this.server_SetActive(true); // always running

	CBlob @blob = this.getBlob();
	blob.set_u32("attack time", 0);
}

void onTick(CBrain@ this)
{
	if (getRules().isWarmup()) return; // do nothing in warmup

	CBlob @blob = this.getBlob();
	this.SetTarget(getNewTarget(this, blob, false, true));// always search nearest one
	CBlob @target = this.getTarget();

	FloatInWater(blob);

	u32 attackTime = blob.get_u32("attack time");
	blob.add_u32("attack time", 1);

	// logic for target

	if (target !is null)
	{
		Chase(blob, target);
		if (attackTime >= 150 + XORRandom(150))// shoot orb
		{
			Vec2f mypos = blob.getPosition();
			Vec2f targetPos = target.getPosition();
			Vec2f targetVector = targetPos - mypos;
			f32 targetDistance = targetVector.Length();

			/*
			bool worthShooting;
			bool hardShot = targetDistance > 30.0f * 8.0f || target.getShape().vellen > 5.0f;
			f32 aimFactor = 0.45f - XORRandom(100) * 0.003f;
			aimFactor += (-0.2f + XORRandom(100) * 0.004f) / 15.0f;
			blob.setAimPos(blob.getBrain().getShootAimPosition(targetPos, hardShot, worthShooting, aimFactor));
			*/

			blob.setAimPos(targetPos);
			CBitStream params;
			params.write_Vec2f(blob.getPosition());
			params.write_Vec2f(blob.getAimPos());
			blob.SendCommand(blob.getCommandID("shoot_orb"), params);
			blob.set_u32("attack time", 0);
			
			return;
		}
	}

	if (attackTime >= 155 + XORRandom(145))// summon orb
	{
		blob.SendCommand(blob.getCommandID("summon_orb"));;
		blob.set_u32("attack time", 0);
	}
} 
