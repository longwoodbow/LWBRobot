//fall damage for all characters and fall damaged items
// apply Rules "fall vel modifier" property to change the damage velocity base
// need to change it because of movement reinforcement

#include "Hitters.as";
#include "KnockedCommon.as";
#include "LWBRobotCommon.as";

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (!solid || this.isInInventory())
	{
		return;
	}

	if (blob !is null && (blob.hasTag("player") || blob.hasTag("no falldamage")))
	{
		return; //no falldamage when stomping
	}

	f32 vely = this.getOldVelocity().y;

	if (vely < 0 || Maths::Abs(normal.x) > Maths::Abs(normal.y) * 2) { return; }

	bool reinforcement = false;

	LWBRobotInfo@ robot;
	if (this.get("robotInfo", @robot))
	{
		reinforcement = this.get_u8("module") == LWBRobotModules::movement;
	}

	f32 damage = FallDamageAmount(vely, reinforcement);
	if (damage != 0.0f) //interesting value
	{
		bool doknockdown = true;

		if (damage > 0.0f)
		{
			// check if we aren't touching a trampoline
			CBlob@[] overlapping;

			if (this.getOverlapping(@overlapping))
			{
				for (uint i = 0; i < overlapping.length; i++)
				{
					CBlob@ b = overlapping[i];

					if (b.hasTag("no falldamage"))
					{
						return;
					}
				}
			}

			if (damage > 0.1f)
			{
				this.server_Hit(this, point1, normal, damage, Hitters::fall);
			}
			else
			{
				doknockdown = false;
			}
		}

		// stun on fall
		const u8 knockdown_time = 12;

		if (doknockdown && setKnocked(this, knockdown_time))
		{
			if (damage < this.getHealth()) //not dead
				Sound::Play("/BreakBone", this.getPosition());
			else
			{
				Sound::Play("/FallDeath.ogg", this.getPosition());
			}
		}
	}
}

f32 BaseFallSpeed()
{
	const f32 BASE_FALL_VEL = 8.0f;
	return getRules().exists("fall vel modifier") ? getRules().get_f32("fall vel modifier") * BASE_FALL_VEL : BASE_FALL_VEL;
}

f32 FallDamageAmount(float vely, bool reinforcement)
{
	f32 base = BaseFallSpeed();
	if (reinforcement) base *= 1.5f;
	const f32 ramp = 1.2f;
	bool doknockdown = false;

	if (vely > base)
	{

		if (vely > base * ramp)
		{
			f32 damage = 0.0f;
			doknockdown = true;

			if (vely < base * Maths::Pow(ramp, 1))
			{
				damage = 0.5f;
			}
			else if (vely < base * Maths::Pow(ramp, 2))
			{
				damage = 1.0f;
			}
			else if (vely < base * Maths::Pow(ramp, 3))
			{
				damage = 2.0f;
			}
			else if (vely < base * Maths::Pow(ramp, 4)) //regular dead
			{
				damage = 8.0f;
			}
			else //very dead
			{
				damage = 100.0f;
			}

			damage *= 0.5f;

			return damage;
		}

		return -1.0f;
	}
	return 0.0f;
}