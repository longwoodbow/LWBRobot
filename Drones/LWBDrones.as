void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
}

void onTick(CBlob@ this)
{
	// follow player
	CBlob@ owner = getBlobByNetworkID(this.get_netid("owner"));
	if (owner is null) return;

	Vec2f pos = this.getPosition();
	Vec2f ownerPos = owner.getPosition();

	Vec2f force = ownerPos - pos;
	force.Normalize();

	this.AddForce(force * 0.1f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() || blob.hasTag("projectile");
}