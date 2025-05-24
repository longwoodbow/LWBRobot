void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(6);
	this.getShape().SetRotationsAllowed(false);

	if (getNet().isServer())
	{
		CBlob@ bullet = server_CreateBlob("lwbturretshield");
		if (bullet !is null)
		{
			bullet.server_setTeamNum(this.getTeamNum());
			bullet.setPosition(this.getPosition());
			this.set("shield", @bullet);
		}
	}
}

void onTick(CBlob@ this)
{
	CBlob@ bullet;
	if (getNet().isServer() && this.get("shield", @bullet))
	{
		bullet.setPosition(this.getPosition());
	}
}

void onDie(CBlob@ this)
{
	CBlob@ bullet;
	if (getNet().isServer() && this.get("shield", @bullet))
	{
		bullet.server_Die();
	}
}