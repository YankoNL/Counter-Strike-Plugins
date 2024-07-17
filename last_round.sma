#include <amxmodx>

new bool:g_bIsLastRound, g_HudSync;
new g_iOldTimelimit = 0;

#define CHECK_FOR_MAPEND 140522		// The task ID is the creation date - 14.05.2022
#define DELAY_MAP_CHANGE 141522
#define LAST_ROUND_HUD 142522

public plugin_init()
{
	register_plugin("Last Round", "1.1" ,"YankoNL");
	register_cvar("yankonl", "1.1-last-round", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);
	
	register_event("SendAudio", "Event_EndRound","a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin", "2=%!MRAD_rounddraw");
	set_task(15.0, "Task_MapEnd", CHECK_FOR_MAPEND, _, _, "d", 1);

	g_HudSync = CreateHudSyncObj();
}

public Task_MapEnd()
{
	if(get_playersnum())
	{
		g_bIsLastRound = true;
		g_iOldTimelimit = get_cvar_num("mp_timelimit")
		server_cmd("mp_timelimit 0")
		client_print_color(0, print_team_default, "^4[^3Announcer^4] ^1Time Limit reached! The map will change after this round!")

		set_task(1.0, "displayLastRound", LAST_ROUND_HUD)
	}
}

public displayLastRound()
{
	set_hudmessage(200, 200, 0, 0.888, 0.19, 2, 0.2, 1.0, 0.1, 0.1, -1)
	ShowSyncHudMsg(0, g_HudSync, "Last Round")
	set_task(1.0, "displayLastRound", LAST_ROUND_HUD)
}

public Event_EndRound()
{
	if(g_bIsLastRound)
	{
		client_print_color(0, print_team_default, "^4[^3Announcer^4] ^1Round over! Changing map in^3 5 ^1seconds.")
		set_task(5.0, "Task_DelayMapEnd", DELAY_MAP_CHANGE, _, _, "a", 1) // Delay the map end, so you can see the last guys death
		remove_task(LAST_ROUND_HUD)
	}
}

public server_changelevel(map[])
	if(g_bIsLastRound)
		Task_DelayMapEnd()

public Task_DelayMapEnd()
{
	remove_task(DELAY_MAP_CHANGE)
	g_bIsLastRound = false;

	if(get_cvar_num("mp_timelimit") == 0)
		server_cmd("mp_timelimit %d", g_iOldTimelimit)
}