// management structs

#include "Rules/CommonScripts/BaseTeamInfo.as";
#include "Rules/CommonScripts/PlayerInfo.as";

shared class RWPlayerInfo : PlayerInfo
{
	u32 can_spawn_time;
	bool thrownBomb;

	RWPlayerInfo() { Setup("", 0, ""); }
	RWPlayerInfo(string _name, u8 _team, string _default_config) { Setup(_name, _team, _default_config); }

	void Setup(string _name, u8 _team, string _default_config)
	{
		PlayerInfo::Setup(_name, _team, _default_config);
		can_spawn_time = 0;
		thrownBomb = false;
	}
};

//teams

shared class RWTeamInfo : BaseTeamInfo
{
	PlayerInfo@[] spawns;
	int kills;
	int tickets;

	RWTeamInfo() { super(); }

	RWTeamInfo(u8 _index, string _name)
	{
		super(_index, _name);
	}

	void Reset()
	{
		BaseTeamInfo::Reset();
		kills = 0;
		tickets = 0;
		//spawns.clear();
	}
};

shared class RW_HUD
{
	//is this our team?
	u8 team_num;
	//exclaim!
	u8 spawn_time;
	u16 tickets;
	//units
	s16 kills;
	s16 kills_limit; //here for convenience

	f32 boss_health;
	f32 base_health;

	RW_HUD() { }
	RW_HUD(CBitStream@ bt) { Unserialise(bt); }

	void Serialise(CBitStream@ bt)
	{
		bt.write_u8(team_num);
		bt.write_u8(spawn_time);
		bt.write_u16(tickets);
		bt.write_s16(kills);
		bt.write_s16(kills_limit);
		bt.write_f32(boss_health);
		bt.write_f32(base_health);
	}

	void Unserialise(CBitStream@ bt)
	{
		team_num = bt.read_u8();
		spawn_time = bt.read_u8();
		tickets = bt.read_u16();
		kills = bt.read_s16();
		kills_limit = bt.read_s16();
		boss_health = bt.read_f32();
		base_health = bt.read_f32();
	}

};
