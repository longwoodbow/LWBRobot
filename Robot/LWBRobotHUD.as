//robot HUD
#include "/Entities/Common/GUI/ActorHUDStartPos.as";
#include "LWBRobotCommon.as";

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	this.getBlob().set_u8("gui_HUD_slots_width", 6);
}

void ManageCursors(CBlob@ this)
{
	if (getHUD().hasButtons())
	{
		getHUD().SetDefaultCursor();
	}
	else
	{
		getHUD().SetCursorImage("Entities/Characters/Archer/ArcherCursor.png", Vec2f(32, 32));
		getHUD().SetCursorOffset(Vec2f(-15.5, -15.5) * cl_mouse_scale);
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	ManageCursors(blob);
	
	LWBRobotInfo@ robot;
	if (!blob.get("robotInfo", @robot))
	{
		return;
	}

	Vec2f pos = blob.getPosition();

	f32 zoom = getCamera().targetDistance;

	// square gauges for robot pos

	// left hand
	{
		Vec2f start = pos + Vec2f(-16.0f, 16.0f) / zoom;
		f32 dif = 32.0f * robot.lefthand_energy / weaponCooldown[blob.get_u8("lefthand")];
		Vec2f end = pos + Vec2f(-16.0f, 16.0f - dif) / zoom;

		SColor color = (robot.lefthand_energy == weaponCooldown[blob.get_u8("lefthand")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

		GUI::DrawLine(start, end, color);
	}

	// right hand
	{
		Vec2f start = pos + Vec2f(16.0f, 16.0f) / zoom;
		f32 dif = 32.0f * robot.righthand_energy / weaponCooldown[blob.get_u8("righthand")];
		Vec2f end = pos + Vec2f(16.0f, 16.0f - dif) / zoom;

		SColor color = (robot.righthand_energy == weaponCooldown[blob.get_u8("righthand")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

		GUI::DrawLine(start, end, color);
	}

	// module
	{
		Vec2f start = pos + Vec2f(-16.0f, -16.0f) / zoom;
		f32 dif = 32.0f;
		if (moduleCooldown[blob.get_u8("module")] > 0)
		{
			dif *= f32(robot.module_energy) / f32(moduleCooldown[blob.get_u8("module")]);
		}
		Vec2f end = pos + Vec2f(-16.0f + dif, -16.0f) / zoom;

		SColor color = (moduleCooldown[blob.get_u8("module")] > 0 && robot.module_energy == moduleCooldown[blob.get_u8("module")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xff, 0xff, 0xff);

		GUI::DrawLine(start, end, color);
	}

	// health
	{
		Vec2f start = pos + Vec2f(-16.0f, 16.0f) / zoom;
		f32 initHealth = blob.getInitialHealth() * (blob.get_u8("module") == LWBRobotModules::armour ? (1.0f + armour_health_ratio) : 1.0f);
		f32 health = getActualHealth(blob);
		f32 dif = 32.0f * health / initHealth;
		Vec2f end = pos + Vec2f(-16.0f + dif, 16.0f) / zoom;

		SColor color = (health >= initHealth) ? SColor(0xff, 0x00, 0xff, 0x00) :
					   (health > initHealth * 0.5f) ? SColor(0xff, 0xff, 0xff, 0xff) :
					   (health > initHealth * 0.2f) ? SColor(0xff, 0xff, 0xff, 0x00) :
					   SColor(0xff, 0xff, 0x00, 0x00);
		GUI::DrawLine(start, end, color);
	}



	// text infos

	GUI::SetFont("menu");
	CControls@ c = getControls();
	if (c is null) return;
	Vec2f textPos = c.getMouseScreenPos();
	f32 sum = blob.get_f32("damagedeal_left") + blob.get_f32("damagedeal_right") + blob.get_f32("damagedeal_module");
	if (sum <= 0.0f) sum = 1.0f; // avoid /0

	// circle gaugesfor cursor pos

	pos = blob.getAimPos();

	f32 gaugePos = 4.0f * cl_mouse_scale / zoom;
	f32 hPos = gaugePos * 4.0f;

	// left hand
	{
		f32 startDegrees = Maths::Pi * 3.0f / 4.0f;
		Vec2f start = pos + Vec2f(gaugePos, 0.0f).RotateByRadians(startDegrees);
		f32 dif = Maths::Pi / 2.0f * robot.lefthand_energy / weaponCooldown[blob.get_u8("lefthand")];
		Vec2f end = pos + Vec2f(gaugePos, 0.0f).RotateByRadians(startDegrees + dif);

		Vec2f h1 = start + Vec2f(hPos / 3.0f * Maths::Tan(dif / 4.0f), 0.0f).RotateByRadians(startDegrees + Maths::Pi / 2.0f);
		Vec2f h2 = end + Vec2f(hPos / 3.0f * Maths::Tan(dif / 4.0f), 0.0f).RotateByRadians(startDegrees + dif - Maths::Pi / 2.0f);

		SColor color = (robot.lefthand_energy == weaponCooldown[blob.get_u8("lefthand")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

		GUI::DrawSpline(start, end, h1, h2, 255, color);
	}

	// right hand
	{
		f32 startDegrees = Maths::Pi * 1.0f / 4.0f;
		Vec2f start = pos + Vec2f(gaugePos, 0.0f).RotateByRadians(startDegrees);
		f32 dif = Maths::Pi / 2.0f * robot.righthand_energy / weaponCooldown[blob.get_u8("righthand")];
		Vec2f end = pos + Vec2f(gaugePos, 0.0f).RotateByRadians(startDegrees - dif);

		Vec2f h1 = start + Vec2f(hPos / 3.0f * Maths::Tan(dif / 4.0f), 0.0f).RotateByRadians(startDegrees - Maths::Pi / 2.0f);
		Vec2f h2 = end + Vec2f(hPos / 3.0f * Maths::Tan(dif / 4.0f), 0.0f).RotateByRadians(startDegrees - dif + Maths::Pi / 2.0f);

		SColor color = (robot.righthand_energy == weaponCooldown[blob.get_u8("righthand")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

		GUI::DrawSpline(start, end, h1, h2, 255, color);
	}

	// module
	{
		f32 startDegrees = Maths::Pi * 5.0f / 4.0f;
		Vec2f start = pos + Vec2f(gaugePos, 0.0f).RotateByRadians(startDegrees);
		f32 dif = Maths::Pi / 2.0f;
		if (moduleCooldown[blob.get_u8("module")] > 0)
		{
			dif *= f32(robot.module_energy) / f32(moduleCooldown[blob.get_u8("module")]);
		}
		Vec2f end = pos + Vec2f(gaugePos, 0.0f).RotateByRadians(startDegrees + dif);

		Vec2f h1 = start + Vec2f(hPos / 3.0f * Maths::Tan(dif / 4.0f), 0.0f).RotateByRadians(startDegrees + Maths::Pi / 2.0f);
		Vec2f h2 = end + Vec2f(hPos / 3.0f * Maths::Tan(dif / 4.0f), 0.0f).RotateByRadians(startDegrees + dif - Maths::Pi / 2.0f);

		SColor color = (moduleCooldown[blob.get_u8("module")] > 0 && robot.module_energy == moduleCooldown[blob.get_u8("module")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xff, 0xff, 0xff);

		GUI::DrawSpline(start, end, h1, h2, 255, color);
	}

	// health
	{
		f32 startDegrees = Maths::Pi * 3.0f / 4.0f;
		Vec2f start = pos + Vec2f(gaugePos, 0.0f).RotateByRadians(startDegrees);
		f32 initHealth = blob.getInitialHealth() * (blob.get_u8("module") == LWBRobotModules::armour ? (1.0f + armour_health_ratio) : 1.0f);
		f32 health = blob.getHealth() + blob.get_f32("extra_health");
		f32 dif = Maths::Pi / 2.0f * health / initHealth;
		Vec2f end = pos + Vec2f(gaugePos, 0.0f).RotateByRadians(startDegrees - dif);

		Vec2f h1 = start + Vec2f(hPos / 3.0f * Maths::Tan(dif / 4.0f), 0.0f).RotateByRadians(startDegrees - Maths::Pi / 2.0f);
		Vec2f h2 = end + Vec2f(hPos / 3.0f * Maths::Tan(dif / 4.0f), 0.0f).RotateByRadians(startDegrees - dif + Maths::Pi / 2.0f);

		SColor color = (health >= initHealth) ? SColor(0xff, 0x00, 0xff, 0x00) :
					   (health > initHealth * 0.5f) ? SColor(0xff, 0xff, 0xff, 0xff) :
					   (health > initHealth * 0.2f) ? SColor(0xff, 0xff, 0xff, 0x00) :
					   SColor(0xff, 0xff, 0x00, 0x00);

		GUI::DrawSpline(start, end, h1, h2, 255, color);
	}

	// limit points
	{
		SColor color = SColor(0xff, 0xFF, 0xff, 0xFF);

		GUI::DrawLine(pos + Vec2f(-gaugePos, -gaugePos), pos + Vec2f(gaugePos, gaugePos), color);
		GUI::DrawLine(pos + Vec2f(gaugePos, -gaugePos), pos + Vec2f(-gaugePos, gaugePos), color);

	}


	// left hand
	{
		SColor color = (robot.lefthand_energy == weaponCooldown[blob.get_u8("lefthand")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);
		GUI::DrawTextCentered("Left Hand", textPos + Vec2f(-32.0f * cl_mouse_scale, -24.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered(robot.lefthand_energy + "/" + weaponCooldown[blob.get_u8("lefthand")], textPos + Vec2f(-32.0f * cl_mouse_scale, -12.0f), color);
		GUI::DrawTextCentered("Damage Deal", textPos + Vec2f(-32.0f * cl_mouse_scale, 0.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered("" + blob.get_f32("damagedeal_left"), textPos + Vec2f(-32.0f * cl_mouse_scale, 12.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered("(" + blob.get_f32("damagedeal_left") / sum * 100.0f + "%)", textPos + Vec2f(-32.0f * cl_mouse_scale, 24.0f), SColor(0xff, 0xff, 0xff, 0xff));
	}

	// right hand
	{
		SColor color = (robot.righthand_energy == weaponCooldown[blob.get_u8("righthand")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);
		GUI::DrawTextCentered("Right Hand", textPos + Vec2f(32.0f * cl_mouse_scale, -24.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered(robot.righthand_energy + "/" + weaponCooldown[blob.get_u8("righthand")], textPos + Vec2f(32.0f * cl_mouse_scale, -12.0f), color);
		GUI::DrawTextCentered("Damage Deal", textPos + Vec2f(32.0f * cl_mouse_scale, 0.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered("" + blob.get_f32("damagedeal_right"), textPos + Vec2f(32.0f * cl_mouse_scale, 12.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered("(" + blob.get_f32("damagedeal_right") / sum * 100.0f + "%)", textPos + Vec2f(32.0f * cl_mouse_scale, 24.0f), SColor(0xff, 0xff, 0xff, 0xff));
	}

	// module
	{
		SColor color = (moduleCooldown[blob.get_u8("module")] > 0 && robot.module_energy == moduleCooldown[blob.get_u8("module")]) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xff, 0xff, 0xff);
		GUI::DrawTextCentered("Module", textPos + Vec2f(0.0f, -16.0f * cl_mouse_scale - 48.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered(robot.module_energy + "/" + moduleCooldown[blob.get_u8("module")], textPos + Vec2f(0.0f, -16.0f * cl_mouse_scale - 36.0f), color);
		GUI::DrawTextCentered("Damage Deal", textPos + Vec2f(0.0f, -16.0f * cl_mouse_scale - 24.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered("" + blob.get_f32("damagedeal_module"), textPos + Vec2f(0.0f, -16.0f * cl_mouse_scale - 12.0f), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered("(" + blob.get_f32("damagedeal_module") / sum * 100.0f + "%)", textPos + Vec2f(0.0f, -16.0f * cl_mouse_scale), SColor(0xff, 0xff, 0xff, 0xff));
	}

	// health
	{
		f32 initHealth = blob.getInitialHealth() * (blob.get_u8("module") == LWBRobotModules::armour ? (1.0f + armour_health_ratio) : 1.0f);
		f32 health = getActualHealth(blob);
		SColor color = (health >= initHealth) ? SColor(0xff, 0x00, 0xff, 0x00) :
					   (health > initHealth * 0.5f) ? SColor(0xff, 0xff, 0xff, 0xff) :
					   (health > initHealth * 0.2f) ? SColor(0xff, 0xff, 0xff, 0x00) :
					   SColor(0xff, 0xff, 0x00, 0x00);
		GUI::DrawTextCentered("Health", textPos + Vec2f(0.0f, 16.0f * cl_mouse_scale), SColor(0xff, 0xff, 0xff, 0xff));
		GUI::DrawTextCentered((health * 2.0f) + "/" + (initHealth * 2.0f), textPos + Vec2f(0.0f, 16.0f * cl_mouse_scale + 12.0f), color);

	}

}