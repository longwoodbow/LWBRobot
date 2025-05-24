#include "Hitters.as";

void onTick(CBlob@ this)
{
	if (this.hasTag("dead") && this.getTickSinceCreated() % 15 == 0)
	{
		this.server_Hit(this, this.getPosition(), Vec2f_zero, 1.0f, Hitters::burn);
	}
}