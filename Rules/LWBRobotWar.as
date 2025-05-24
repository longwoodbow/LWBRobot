
//RW gamemode logic script
// changed initial spawn class

#define SERVER_ONLY

#include "RW_Structs.as";
#include "RulesCore.as";
#include "RespawnSystem.as";

//RW spawn system

shared class RWSpawns : RespawnSystem
{
	RWCore@ RW_core;

	bool force;

	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@RW_core = cast < RWCore@ > (core);
	}

	void Update()
	{
		for (uint team_num = 0; team_num < RW_core.teams.length; ++team_num)
		{
			RWTeamInfo@ team = cast < RWTeamInfo@ > (RW_core.teams[team_num]);

			for (uint i = 0; i < team.spawns.length; i++)
			{
				RWPlayerInfo@ info = cast < RWPlayerInfo@ > (team.spawns[i]);

				UpdateSpawnTime(team, info, i);
				DoSpawnPlayer(team, info);
			}
		}
	}

	void UpdateSpawnTime(RWTeamInfo@ team, RWPlayerInfo@ info, int i)
	{
		//default
		u8 spawn_property = 254;

		//flag for no respawn
		bool huge_respawn = info.can_spawn_time >= 0x00ffffff;
		bool no_respawn = (RW_core.gameType != 1 && team.tickets == 0) || (RW_core.rules.isMatchRunning() ? huge_respawn : false);
		if (no_respawn)
		{
			spawn_property = 253;
		}

		if (i == 0 && info !is null && info.can_spawn_time > 0 && !no_respawn)
		{
			if (huge_respawn)
			{
				info.can_spawn_time = 5;
			}

			info.can_spawn_time--;
			spawn_property = u8(Maths::Min(250, (info.can_spawn_time / 30)));
		}

		string propname = "rw spawn time " + info.username;
		RW_core.rules.set_u8(propname, spawn_property);
		if (info !is null && info.can_spawn_time >= 0)
		{
			RW_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));
		}
	}

	void DoSpawnPlayer(RWTeamInfo@ team, PlayerInfo@ p_info)
	{
		if (force || canSpawnPlayer(p_info))
		{
			CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?

			if (player is null)
			{
				RemovePlayerFromSpawn(p_info);
				return;
			}
			if (player.getTeamNum() != int(p_info.team))
			{
				player.server_setTeamNum(p_info.team);
			}

			// remove previous players blob
			if (player.getBlob() !is null)
			{
				CBlob @blob = player.getBlob();
				blob.server_SetPlayer(null);
				blob.server_Die();
			}

			CBlob@ playerBlob = SpawnPlayerIntoWorld(getSpawnLocation(p_info), p_info);

			if (playerBlob !is null)
			{
				// spawn resources
				p_info.spawnsCount++;
				RemovePlayerFromSpawn(player);
				if (!getRules().isWarmup()) team.tickets--;
			}
		}
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		RWPlayerInfo@ info = cast < RWPlayerInfo@ > (p_info);

		if (info is null) { warn("RW LOGIC: Couldn't get player info ( in bool canSpawnPlayer(PlayerInfo@ p_info) ) "); return false; }

		if (force) { return true; }

		return info.can_spawn_time == 0;
	}

	Vec2f getSpawnLocation(PlayerInfo@ p_info)
	{
		CBlob@[] spawns;
		CBlob@[] teamspawns;

		if (getBlobsByName("robot_spawn", @spawns))
		{
			for (uint step = 0; step < spawns.length; ++step)
			{
				if (spawns[step].getTeamNum() == s32(p_info.team))
				{
					teamspawns.push_back(spawns[step]);
				}
			}
		}

		if (teamspawns.length > 0)
		{
			int spawnindex = XORRandom(997) % teamspawns.length;
			return teamspawns[spawnindex].getPosition();
		}

		return Vec2f(0, 0);
	}

	void RemovePlayerFromSpawn(CPlayer@ player)
	{
		RemovePlayerFromSpawn(core.getInfoFromPlayer(player));
	}

	void RemovePlayerFromSpawn(PlayerInfo@ p_info)
	{
		RWPlayerInfo@ info = cast < RWPlayerInfo@ > (p_info);

		if (info is null) { warn("RW LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(PlayerInfo@ p_info) )"); return; }

		string propname = "rw spawn time " + info.username;

		for (uint i = 0; i < RW_core.teams.length; i++)
		{
			RWTeamInfo@ team = cast < RWTeamInfo@ > (RW_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				team.spawns.erase(pos);
				break;
			}
		}

		RW_core.rules.set_u8(propname, 255);   //not respawning
		RW_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));

		info.can_spawn_time = 0;
	}

	void AddPlayerToSpawn(CPlayer@ player)
	{
		RemovePlayerFromSpawn(player);
		if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
			return;

		u32 tickspawndelay = u32(RW_core.spawnTime);


		RWPlayerInfo@ info = cast < RWPlayerInfo@ > (core.getInfoFromPlayer(player));

		if (info is null) { warn("RW LOGIC: Couldn't get player info  ( in void AddPlayerToSpawn(CPlayer@ player) )"); return; }

		if (info.team < RW_core.teams.length)
		{
			RWTeamInfo@ team = cast < RWTeamInfo@ > (RW_core.teams[info.team]);

			info.can_spawn_time = tickspawndelay;
			team.spawns.push_back(info);
		}
		else
		{
			error("PLAYER TEAM NOT SET CORRECTLY!");
		}
	}

	bool isSpawning(CPlayer@ player)
	{
		RWPlayerInfo@ info = cast < RWPlayerInfo@ > (core.getInfoFromPlayer(player));
		for (uint i = 0; i < RW_core.teams.length; i++)
		{
			RWTeamInfo@ team = cast < RWTeamInfo@ > (RW_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				return true;
			}
		}
		return false;
	}

};

shared class RWCore : RulesCore
{
	s32 warmUpTime;
	s32 gameDuration;
	s32 spawnTime;
	s32 minimum_players_in_team;
	s32 kills_to_win;
	s32 kills_to_win_per_player;
	bool all_death_counts_as_kill;
	bool sudden_death;

	u8 gameType;
	// 0 = tdm
	// 1 = destroy the base
	// 2 = boss raid

	s32 players_in_small_team;
	s32 players_in_large_team;
	bool scramble_teams;

	RWSpawns@ rw_spawns;

	RWCore() {}

	RWCore(CRules@ _rules, RespawnSystem@ _respawns)
	{
		super(_rules, _respawns);
	}

	void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
	{
		RulesCore::Setup(_rules, _respawns);
		gametime = getGameTime() + 300;
		@rw_spawns = cast < RWSpawns@ > (_respawns);
		server_CreateBlob("Entities/Meta/TDMMusic.cfg");
		players_in_small_team = -1;
		all_death_counts_as_kill = false;
		sudden_death = false;

		CBlob@[] temp;
		if (getBlobsByName("robot_spawn_shield", @temp)) gameType = 1;
		else if (getBlobsByTag("boss", @temp)) gameType = 2;
		else gameType = 0;

		printf("Game type = " + gameType);
		getRules().set_u8("gametype", gameType);

		sv_mapautocycle = true;
	}

	int gametime;
	void Update()
	{
		//HUD
		// lets save the CPU and do this only once in a while
		if (getGameTime() % 16 == 0)
		{
			updateHUD();
		}

		if (rules.isGameOver()) { return; }

		s32 ticksToStart = gametime - getGameTime();

		rw_spawns.force = false;

		if (ticksToStart <= 0 && (rules.isWarmup()))
		{
			rules.SetCurrentState(GAME);
			if (gameType == 0) // add ticket
			{
				for (uint team_num = 0; team_num < teams.length; ++team_num)
				{
					RWTeamInfo@ team = cast < RWTeamInfo@ > (teams[team_num]);

					team.tickets = kills_to_win;
				}
			}
		}
		else if (ticksToStart > 0 && rules.isWarmup()) //is the start of the game, spawn everyone + give mats
		{
			rules.SetGlobalMessage("Match starts in {SEC}");
			rules.AddGlobalMessageReplacement("SEC", "" + ((ticksToStart / 30) + 1));
			rw_spawns.force = true;

			//set kills and cache #players in smaller team

			if (players_in_small_team == -1 || (getGameTime() % 30) == 4)
			{
				players_in_small_team = 100;
				players_in_large_team = 0;

				CBlob@[] temp;
				getBlobsByTag("boss", @temp);

				for (uint team_num = 0; team_num < teams.length; ++team_num)
				{
					RWTeamInfo@ team = cast < RWTeamInfo@ > (teams[team_num]);

					if (team.players_count < players_in_small_team)
					{
						players_in_small_team = team.players_count;
					}
					if (team.players_count > players_in_large_team)
					{
						players_in_large_team = team.players_count;
					}
				}

				kills_to_win = Maths::Max(players_in_small_team, 1) * kills_to_win_per_player;

				for (uint i = 0; i < temp.length; i++)
				{
					CBlob@ boss = temp[i];
					if (boss !is null)
					{
						f32 health = (Maths::Max(players_in_large_team, 1) + 1) * 0.5f * boss.getInitialHealth();
						boss.server_SetHealth(health);
						rules.set_f32("boss_health", health);
					}
				}
			}
		}

		if ((rules.isIntermission() || rules.isWarmup()) && ((gameType != 2 && !allTeamsHavePlayers()) || (gameType == 2 && teams[0].players_count == 0)))  //CHECK IF TEAMS HAVE ENOUGH PLAYERS
		{
			gametime = getGameTime() + warmUpTime;
			rules.set_u32("game_end_time", gametime + gameDuration);
			rules.SetGlobalMessage("Not enough players in each team for the game to start.\nPlease wait for someone to join...");
			rw_spawns.force = true;
		}
		else if (rules.isMatchRunning())
		{
			rules.SetGlobalMessage("");
		}

		RulesCore::Update(); //update respawns
		CheckTeamWon();
	}

	void updateHUD()
	{
		bool hidekills = (rules.isIntermission() || rules.isWarmup());
		CBitStream serialised_team_hud;
		serialised_team_hud.write_u16(0x5afe); //check bits

		for (uint team_num = 0; team_num < teams.length; ++team_num)
		{
			RW_HUD hud;
			RWTeamInfo@ team = cast < RWTeamInfo@ > (teams[team_num]);
			hud.team_num = team_num;
			hud.kills = team.kills;
			hud.kills_limit = -1;
			if (!hidekills)
			{
				if (kills_to_win <= 0)
					hud.kills_limit = -2;
				else
					hud.kills_limit = kills_to_win;
			}

			hud.tickets = team.tickets;

			bool set_spawn_time = false;
			if (team.spawns.length > 0 && !rules.isIntermission())
			{
				u32 st = cast < RWPlayerInfo@ > (team.spawns[0]).can_spawn_time;
				if (st < 200)
				{
					hud.spawn_time = (st / 30);
					set_spawn_time = true;
				}
			}
			if (!set_spawn_time)
			{
				hud.spawn_time = 255;
			}

			CBlob@[] temp;
			if (getBlobsByTag("boss", @temp)) hud.boss_health = temp[0].getHealth();
			else hud.boss_health = 0.0f;

			CBlob@[] bases;
			if (getBlobsByName("robot_spawn", @bases))
			{
				for (int i = 0; i < bases.length; i++)
				{
					CBlob@ b = bases[i];
					if (b !is null) 
					{
						s32 team = bases[i].getTeamNum();
						if (team == team_num)
						{
							hud.base_health = b.getHealth();
						}
					}
				}
			}

			hud.Serialise(serialised_team_hud);
		}

		rules.set_CBitStream("rw_serialised_team_hud", serialised_team_hud);
		rules.Sync("rw_serialised_team_hud", true);
	}

	//HELPERS

	bool allTeamsHavePlayers()
	{
		for (uint i = 0; i < teams.length; i++)
		{
			if (teams[i].players_count < minimum_players_in_team)
			{
				return false;
			}
		}

		return true;
	}

	//team stuff

	void AddTeam(CTeam@ team)
	{
		RWTeamInfo t(teams.length, team.getName());
		teams.push_back(t);
	}

	void AddPlayer(CPlayer@ player, u8 team = 0, string default_config = "")
	{
		RWPlayerInfo p(player.getUsername(), player.getTeamNum(), "lwbrobot");
		players.push_back(p);
		ChangeTeamPlayerCount(p.team, 1);
	}

	void onPlayerDie(CPlayer@ victim, CPlayer@ killer, u8 customData)
	{
		if (!rules.isMatchRunning() && !all_death_counts_as_kill) return;

		if (victim !is null)
		{
			if (killer !is null && killer.getTeamNum() != victim.getTeamNum())
			{
				addKill(killer.getTeamNum());
			}
			else if (all_death_counts_as_kill)
			{
				for (int i = 0; i < rules.getTeamsNum(); i++)
				{
					if (i != victim.getTeamNum())
					{
						addKill(i);
					}
				}
			}
		}
	}

	void onSetPlayer(CBlob@ blob, CPlayer@ player)
	{
	}

	//setup the RW bases

	void SetupBase(CBlob@ base)
	{
		if (base is null)
		{
			return;
		}

		//nothing to do
	}


	void SetupBases()
	{
		const string base_name = "robot_spawn";
		// destroy all previous spawns if present
		CBlob@[] oldBases;
		getBlobsByName(base_name, @oldBases);

		for (uint i = 0; i < oldBases.length; i++)
		{
			oldBases[i].server_Die();
		}

		//spawn the spawns :D
		CMap@ map = getMap();

		if (map !is null)
		{
			// team 0 ruins
			Vec2f[] respawnPositions;
			Vec2f respawnPos;

			if (!getMap().getMarkers("blue main spawn", respawnPositions))
			{
				warn("RW: Blue spawn marker not found on map");
				respawnPos = Vec2f(150.0f, map.getLandYAtX(150.0f / map.tilesize) * map.tilesize - 32.0f);
				respawnPos.y -= 16.0f;
				SetupBase(server_CreateBlob(base_name, 0, respawnPos));
			}
			else
			{
				for (uint i = 0; i < respawnPositions.length; i++)
				{
					respawnPos = respawnPositions[i];
					respawnPos.y -= 16.0f;
					SetupBase(server_CreateBlob(base_name, 0, respawnPos));
				}
			}

			respawnPositions.clear();


			// team 1 ruins
			if (!getMap().getMarkers("red main spawn", respawnPositions))
			{
				if (gameType != 2)
				{
					warn("RW: Red spawn marker not found on map");
					respawnPos = Vec2f(map.tilemapwidth * map.tilesize - 150.0f, map.getLandYAtX(map.tilemapwidth - (150.0f / map.tilesize)) * map.tilesize - 32.0f);
					respawnPos.y -= 16.0f;
					SetupBase(server_CreateBlob(base_name, 1, respawnPos));
				}
			}
			else
			{
				for (uint i = 0; i < respawnPositions.length; i++)
				{
					respawnPos = respawnPositions[i];
					respawnPos.y -= 16.0f;
					SetupBase(server_CreateBlob(base_name, 1, respawnPos));
				}
			}

			respawnPositions.clear();
		}

		rules.SetCurrentState(WARMUP);
	}

	//checks
	void CheckTeamWon()
	{
		if (!rules.isMatchRunning()) { return; }

		int winteamIndex = -1;
		RWTeamInfo@ winteam = null;
		s8 team_wins_on_end = -1;

		if (gameType == 0)
		{
			array<bool> teams_alive;
			s32 teams_alive_count = 0;
			for (int i = 0; i < teams.length; i++)
				teams_alive.push_back(false);
	
			// check tickets
			for (uint team_num = 0; team_num < teams.length; ++team_num)
			{
				RWTeamInfo@ team = cast < RWTeamInfo@ > (teams[team_num]);
	
				if (team.tickets > 0 && !teams_alive[team_num])
				{
					teams_alive[team_num] = true;
					teams_alive_count++;
				}
			}
	
			//sudden death mode - check if anyone survives
			//clear the winning team - we'll find that ourselves
			@winteam = null;
			winteamIndex = -1;
	
			//set up an array of which teams are alive
			//check with each player
			for (int i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				CBlob@ b = p.getBlob();
				s32 team = p.getTeamNum();
				if (b !is null && !b.hasTag("dead") && //blob alive
				        team >= 0 && team < teams.length) //team sensible
				{
					if (!teams_alive[team])
					{
						teams_alive[team] = true;
						teams_alive_count++;
					}
				}
			}
	
			//only one team remains!
			if (teams_alive_count == 1)
			{
				for (int i = 0; i < teams.length; i++)
				{
					if (teams_alive[i])
					{
						@winteam = cast < RWTeamInfo@ > (teams[i]);
						winteamIndex = i;
						team_wins_on_end = i;
					}
				}
			}
			//no teams survived, draw
			if (teams_alive_count == 0)
			{
				rules.SetTeamWon(-1);   //game over!
				rules.SetCurrentState(GAME_OVER);
				rules.SetGlobalMessage("It's a tie!");
				return;
			}
		}
		else if (gameType == 1)
		{
			array<bool> teams_alive;
			s32 teams_alive_count = 0;
			for (int i = 0; i < teams.length; i++)
				teams_alive.push_back(false);

			CBlob@[] bases;
			if (getBlobsByName("robot_spawn", @bases))
			{
				for (int i = 0; i < bases.length; i++)
				{
					CBlob@ b = bases[i];
					s32 team = bases[i].getTeamNum();
					if (b !is null && !b.hasTag("dead") && //blob alive
					        team >= 0 && team < teams.length) //team sensible
					{
						if (!teams_alive[team])
						{
							teams_alive[team] = true;
							teams_alive_count++;
						}
					}
				}
			}

			//only one team remains!
			if (teams_alive_count == 1)
			{
				for (int i = 0; i < teams.length; i++)
				{
					if (teams_alive[i])
					{
						@winteam = cast < RWTeamInfo@ > (teams[i]);
						winteamIndex = i;
						team_wins_on_end = i;
					}
				}
			}
			//no teams survived, draw
			if (teams_alive_count == 0)
			{
				rules.SetTeamWon(-1);   //game over!
				rules.SetCurrentState(GAME_OVER);
				rules.SetGlobalMessage("It's a tie!");
				return;
			}
		}
		else if (gameType == 2)
		{
			//clear the winning team - we'll find that ourselves
			@winteam = null;
			winteamIndex = -1;

			//set up an array of which teams are alive
			array<bool> teams_alive;
			s32 teams_alive_count = 0;
			for (int i = 0; i < teams.length; i++)
				teams_alive.push_back(false);

			//check with each player
			for (int i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				CBlob@ b = p.getBlob();
				s32 team = p.getTeamNum();
				if (b !is null && !b.hasTag("dead") && //blob alive
				        team >= 0 && team < teams.length) //team sensible
				{
					if (!teams_alive[team])
					{
						teams_alive[team] = true;
						teams_alive_count++;
					}
				}
			}

			CBlob@[] bosses;
			if (getBlobsByTag("boss", @bosses))
			{
				if (!teams_alive[1])
				{
					teams_alive[1] = true;
					teams_alive_count++;
				}
			}

			//only one team remains!
			if (teams_alive_count == 1)
			{
				for (int i = 0; i < teams.length; i++)
				{
					if (teams_alive[i])
					{
						@winteam = cast < RWTeamInfo@ > (teams[i]);
						winteamIndex = i;
						team_wins_on_end = i;
					}
				}
			}
			//no teams survived, draw
			if (teams_alive_count == 0)
			{
				rules.SetTeamWon(-1);   //game over!
				rules.SetCurrentState(GAME_OVER);
				rules.SetGlobalMessage("It's a tie!");
				return;
			}
		}
		rules.set_s8("team_wins_on_end", team_wins_on_end);

		if (winteamIndex >= 0)
		{
			rules.SetTeamWon(winteamIndex);   //game over!
			rules.SetCurrentState(GAME_OVER);
		}
	}

	void addKill(int team)
	{
		if (team >= 0 && team < int(teams.length))
		{
			RWTeamInfo@ team_info = cast < RWTeamInfo@ > (teams[team]);
			team_info.kills++;
		}
	}

};

//pass stuff to the core from each of the hooks

void Reset(CRules@ this)
{
	printf("Restarting rules script: " + getCurrentScriptName());
	RWSpawns spawns();
	RWCore core(this, spawns);
	core.SetupBases();

	// config
	core.warmUpTime = getTicksASecond() * 10;
	core.gameDuration = getTicksASecond() * 60 * 10;
	core.spawnTime = getTicksASecond() * 10;
	core.minimum_players_in_team = 1;
	core.kills_to_win = 2;
	core.kills_to_win_per_player = 2;
	core.all_death_counts_as_kill= false;
	core.sudden_death = false;

	this.set_u8("gameType", core.gameType);
	this.set("core", @core);
	this.set("start_gametime", getGameTime() + core.warmUpTime);
	this.set_u32("game_end_time", getGameTime() + core.gameDuration); //for TimeToEnd.as
	this.set_s32("restart_rules_after_game_time", (core.spawnTime < 0 ? 5 : 10) * 30 );
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}
