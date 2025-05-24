// do it at the last because of on hit effect and more

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	// dont do while warmup
	if (this.hasTag("invincible")) return damage;

	// take with extra health

	if (this.get_f32("extra_health") * 2.0f >= damage)
	{
		this.set_f32("extra_health", this.get_f32("extra_health") - damage / 2.0f);
		damage = 0;
	}
	else
	{
		damage -= this.get_f32("extra_health") * 2.0f;
		this.set_f32("extra_health", 0.0f);
	}
	if (getNet().isServer()) this.Sync("extra_health", true); // sync, maybe a little different because of desynced shield 
	
	return damage;
}