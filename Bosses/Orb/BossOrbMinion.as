void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(10);
	this.getShape().SetRotationsAllowed(false);
	this.getShape().SetGravityScale(0.0f);

	this.set_f32("explosive_radius", 32.0f);
	this.set_f32("explosive_damage", 10.0f);
	this.set_f32("map_damage_radius", 32.0f);
	this.set_f32("map_damage_ratio", 0.2f);
	this.set_bool("map_damage_raycast", true);
	this.Tag("exploding");
}

void onTick(CBlob@ this)
{
	if (this.get_u8("cooldown") > 0) this.sub_u8("cooldown", 1);
	//else
	{
		Vec2f pos = this.getPosition();

		CMap@ map = this.getMap();
		HitInfo@[] hitInfos;
		CBlob@ target;
		if (map.getHitInfosFromArc(pos, 0.0f, 360.0f, 500.0f, this, @hitInfos))
		{
			for (int i = 0; i < hitInfos.size(); i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;

				if (b is null) continue;

				Vec2f hitvec = hi.hitpos - pos;

				if (b.hasTag("player") && this.getTeamNum() != b.getTeamNum())
				{
					@target = @b;
					break;
				}

			}
			
			if (target !is null)
			{

				Vec2f force = target.getPosition() - pos;
				force.Normalize();

				this.AddForce(force * 5.0f);
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getName() == "boss_orb_minion")
	{
		return 0.0f;
	}

	return damage;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob !is null && blob.hasTag("player") &&  this.getTeamNum() != blob.getTeamNum()) this.server_Die();
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() || blob.hasTag("projectile");
}