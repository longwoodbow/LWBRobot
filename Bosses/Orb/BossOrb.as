// skills

void onInit(CBlob@ this)
{
	this.Tag("boss");
	this.Tag("flesh");

	this.addCommandID("shoot_orb");
	this.addCommandID("summon_orb");
}

/*
void onTick(CBlob@ this)
{

}
*/

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();
	Vec2f pos;
	if (!params.saferead_Vec2f(pos)) pos = this.getPosition();
	Vec2f offsetPos = pos;// + Vec2f(this.isFacingLeft() ? 2 : -2, -2);// from archer logic
	Vec2f aimPos;
	if (!params.saferead_Vec2f(aimPos)) aimPos = this.getAimPos();
	Vec2f normVel = aimPos - offsetPos;
	normVel.Normalize();

	if (cmd == this.getCommandID("shoot_orb"))
	{
		this.getSprite().PlaySound("MigrantHmm.ogg");

		if (isServer)
		{
			int r = 0;

			for (int i = 0; i < 5; i++)
			{
				CBlob@ bullet = server_CreateBlobNoInit("boss_orb_bullet");
				if (bullet !is null)
				{
					bullet.SetDamageOwnerPlayer(this.getPlayer());
					bullet.Init();
			
					bullet.IgnoreCollisionWhileOverlapped(this);
					bullet.server_setTeamNum(this.getTeamNum());
					bullet.setPosition(offsetPos);
					bullet.setVelocity(normVel * 17.59f);
				}

				r = r > 0 ? -(r + 1) : (-r) + 1;
			
				normVel = normVel.RotateBy(5 * r, Vec2f());
			}
		}
	}
	else if (cmd == this.getCommandID("summon_orb"))
	{
		this.getSprite().PlaySound("ZombieKnightGrowl.ogg");

		if (isServer)
		{
			for (int i = 0; i < 5; i++)
			{
				CBlob@ bullet = server_CreateBlob("boss_orb_minion");
				if (bullet !is null)
				{
					bullet.SetDamageOwnerPlayer(this.getPlayer());
					bullet.set_netid("owner", this.getNetworkID());
					bullet.IgnoreCollisionWhileOverlapped(this);
					bullet.server_setTeamNum(this.getTeamNum());
					bullet.setPosition(pos);
					bullet.setVelocity(Vec2f((1.0f + XORRandom(10)) * 0.1f, 0.0f).RotateBy(XORRandom(360)));
				}
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

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("WraithDie.ogg");
}