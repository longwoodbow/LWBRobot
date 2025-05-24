#include "Hitters.as"
#include "LWBRobotCommon.as";
#include "ParticleSparks.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0.0f && (hitterBlob !is this || customData == Hitters::crush))  //sound for anything actually painful
	{

		u8 type = getDamageType(customData);

		//read customdata for hitter
		switch (customData)
		{
			case Hitters::sword:
				Sound::Play("SwordKill", this.getPosition());
				break;

			case Hitters::stab:
				if (this.getHealth() > 0.0f && damage > 2.0f)
				{
					this.Tag("cutthroat");
				}
				break;

			default:
				if (customData != Hitters::bite)
					//Sound::Play("FleshHit.ogg", this.getPosition());
				break;
		}

		Sound::Play(type == LWBRobotHitters::energy ? "FireFwoosh.ogg" : "dig_stone?", this.getPosition());

		sparks(worldPoint, velocity == Vec2f_zero ? -90.0f : -velocity.Angle(), damage * 0.5f, 10.0f);

		worldPoint.y -= this.getRadius() * 0.5f;
	}

	return damage;
}

