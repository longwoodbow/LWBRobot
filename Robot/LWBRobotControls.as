//set facing direction to aiming direction
#include "LWBRobotCommon.as";

void onInit(CMovement@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";
	//this.getCurrentScript().tickFrequency = 3;
}

void onTick(CMovement@ this)
{
	CBlob@ blob = this.getBlob();
	bool facing = (blob.getAimPos().x <= blob.getPosition().x);

	LWBRobotInfo@ robot;
	if (!blob.get("robotInfo", @robot))
	{
		return;
	}

	if ((blob.get_u8("module") == LWBRobotModules::sunbeam || blob.get_u8("module") == LWBRobotModules::emp) && robot.module_special > 0)
	{
		facing = (blob.get_u8("module") == LWBRobotModules::sunbeam) ? blob.get_bool("sunbeamLeft") : blob.get_bool("empLeft");

		blob.setKeyPressed(key_left, false);
		blob.setKeyPressed(key_right, false);
		blob.setKeyPressed(key_up, false);
		blob.setKeyPressed(key_down, false);
	}

	blob.SetFacingLeft(facing);

	// face for all attachments

	if (blob.hasAttached())
	{
		AttachmentPoint@[] aps;
		if (blob.getAttachmentPoints(@aps))
		{
			for (uint i = 0; i < aps.length; i++)
			{
				AttachmentPoint@ ap = aps[i];
				if (ap.socket && ap.getOccupied() !is null)
				{
					ap.getOccupied().SetFacingLeft(facing);
				}
			}
		}
	}


}
