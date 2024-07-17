/* _____                      _       _                          __    ______ 
  / ____|                    | |     | |                        /_ |  |____  |
 | |      ___   _   _  _ __  | |_  __| |  ___ __      __ _ __    | |      / / 
 | |     / _ \ | | | || '_ \ | __|/ _` | / _ \\ \ /\ / /| '_ \   | |     / /  
 | |____| (_) || |_| || | | || |_| (_| || (_) |\ V  V / | | | |  | | _  / /   
  \_____|\___/  \__,_||_| |_| \__|\__,_| \___/  \_/\_/  |_| |_|  |_|(_)/_/    

	* Description:
		Announces when the round is starting with music and countdown.

		Video: https://youtu.be/m_SFeLJYZHk

	* Requeriments:
		- AMXX 1.8.3 or higher.

	* Change Log:
		0.1 - First Release 13.07.2016

		1.0 - Code optimization
		
		1.1 - More optimizations
			- Replaced DHUD with HUD
			- Added round start sound
		
		1.2 - Added MP3 support for round start

		1.3 - Added cvar to select countdown message type (HUD or DHUD)
			- Cvar setting 'zp_countdown_dhud' - 0 is HUD | 1 is DHUD

		1.4 - Optimization
			- Removed cvar zp_coutdown_dhud
			- Added sound detection WAV and MP3 (Only for Round Start sound)
			- Added cvar zp_countdown_display_type (0 - Center Chat, 1 - HUD, 2 - DHUD)
			- Added cvar zp_countdown_custom_delay Set only if your mod isn't supported

		1.4.1 - Added Stocks for optimization and easy future edits
			- Added stock 'precache_sound_type()' that detects whether the file is WAV or MP3 and precaches it accordingly 
			- Added stock 'play_sound_type()' that detects whether the file is WAV or MP3 and plays it accordingly

		1.5 - Bugfix + Mod support define
			- Added most common zombie mods support
			- Little hardcoded, but no need to guess if the mod exists (User selects the mod before compilation)
			- Fixed an Audio and Visual bug when round restars or a mode is chosen during the countdown

		1.6 - Round Restart + Small bugfix
			- Added first round restart to prevent slow loading players from waiting until next round
			- Fixed countdown not stopping when a mod has been force started.
			- Removed '#pragma semicolon 1' due to users reporting that they can't compile the code.

		1.6.1 - Optimization
			- Now 'zp_countdown_display_type' applies to the first round restar message

		1.7 - Bugfix
			- Fixed a bug where the countdown and the warmup aren't executed correctly
			- Fixed a bug where the sound overlaps, stops and sometimes heard multipe times
			- Added full support + detection for .wav or .mp3 sounds in all categories

		* Current Mod Support:
			- Biohazard (bh_starttime)
			- Zombie Plague 4.3 or with the same cvar (zp_delay)
			- ZP 5.0 (zp_gamemode_delay)
			
*/
#define PLUGIN_VERSION "1.7"

#include <amxmodx>

/* ======================= Edit below this line =======================*/

// Uncomment the mod you are using or contact me to set it up your mod
// if it's different than the supported ones. Discord: yankonl
//
// Do not uncomment if you want to use custom countdown from the cvars

// #define BIO 		// Biohazard Support
// #define ZP43		// ZP 4.3 Support
// #define ZP50		// ZP 5.0 Support

new const g_szPrefix[] = "[ Countdown ]";

new const g_szRoundStart[] = "downwego/fatall-start.wav";
new const g_szZombieInfected[] = "downwego/fatall-come.wav";

new g_szCountSound[][] =
{
    "downwego/fatall-1.wav",
	"downwego/fatall-2.wav",
	"downwego/fatall-3.wav",
	"downwego/fatall-4.wav",
	"downwego/fatall-5.wav",
	"downwego/fatall-6.wav",
	"downwego/fatall-7.wav",
	"downwego/fatall-8.wav",
	"downwego/fatall-9.wav",
	"downwego/fatall-10.wav"
};

/* ============= DON'T EDIT BELOW (Edit at your own risk) ============= */

enum
{
	TYPE_CHAT = 0,
	TYPE_HUD,
	TYPE_DHUD
};

enum
{
	TYPE_INVALID = 0,
	TYPE_WAV,
	TYPE_MP3
};

#if defined BIO
	#include <biohazard>
	#define PLUGIN_NAME "[Bio] Countdown"
#elseif defined ZP43
	#include <zombieplague>
	#define PLUGIN_NAME "[ZP] Countdown"
#elseif defined ZP50
	#include <zp50_gamemodes>
	#define PLUGIN_NAME "[ZP50] Countdown"
#else
	new g_eCvarCustomDelay;
	#define PLUGIN_NAME "Countdown"
#endif

#if !defined g_eCvarCustomDelay
	new g_iOldDelay;
#endif

new g_szCounter, g_msgSyncHUD, g_eCvarShowType, g_eCvarRestart, bool:g_iStarted = false;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, "YankoNL");
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	register_cvar("ynl_countdown", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	g_eCvarRestart = register_cvar("countdown_warmup_seconds", "60");	// First round restart time. So you can wait for everyone to join.
	g_eCvarShowType = register_cvar("countdown_display_type", "2");		// 0 - Center Chat | 1 - HUD | 2 - DHUD
#if defined g_eCvarCustomDelay
	g_eCvarCustomDelay = register_cvar("countdown_custom_delay", "22");	// Set only if no mod cvar is detected
#endif

	g_msgSyncHUD = CreateHudSyncObj();
}

public plugin_precache()
{
	precache_sound_type(g_szRoundStart);
	precache_sound_type(g_szZombieInfected);

	for(new i = 0; i < sizeof g_szCountSound; i++)
		precache_sound_type(g_szCountSound[i]);
}

public plugin_cfg() set_task(1.0, "warmup");

public warmup()
{
	g_szCounter = get_pcvar_num(g_eCvarRestart);

#if defined BIO
	g_iOldDelay = get_cvar_num("bh_starttime");			// Biohazard Support
	server_cmd("bh_starttime 999");
#elseif defined ZP43
	g_iOldDelay = get_cvar_num("zp_delay");				// ZP 4.3 Support
	server_cmd("zp_delay 999");
#elseif defined ZP50
	g_iOldDelay = get_cvar_num("zp_gamemode_delay");	// ZP 5.0 Support
	server_cmd("zp_gamemode_delay 999");
#endif

	set_task(1.0, "first_round_restart");
}

public first_round_restart()
{
	if(g_szCounter)
	{
		switch(get_gvar_type(get_pcvar_num(g_eCvarShowType)))
		{
			case TYPE_CHAT: client_print(0, print_center, "Waiting for all players to join...^nGame Starting in %i", g_szCounter); 
		
			case TYPE_HUD:
			{
				set_hudmessage(0, 179, 179, -1.0, 0.28, 1, 0.0, 0.1, 0.1, 1.0, -1);
				ShowSyncHudMsg(0, g_msgSyncHUD, "Waiting for all players to join...^nGame Starting in %i", g_szCounter);
			}

			case TYPE_DHUD:
			{
				set_dhudmessage(0, 179, 179, -1.0, 0.28, 1, 0.0, 0.1, 0.1, 1.0);
				show_dhudmessage(0, "Waiting for all players to join...^nGame Starting in %i", g_szCounter);
			}
		}

		g_szCounter--;
		set_task(1.0, "first_round_restart");
	}
	else
	{
		g_iStarted = true;
	#if defined BIO
		server_cmd("bh_starttime %i", g_iOldDelay);
	#elseif defined ZP43
		server_cmd("zp_delay %i", g_iOldDelay);
	#elseif defined ZP50
		server_cmd("zp_gamemode_delay %i", g_iOldDelay);
	#endif
		server_cmd("sv_restartround 1");
	}
}

public Event_HLTV()
{
	if(!g_iStarted) return;

	play_sound_type(0, g_szRoundStart);

#if defined BIO
	g_szCounter = get_cvar_num("bh_starttime");			// Biohazard Support
#elseif defined ZP43
	g_szCounter = get_cvar_num("zp_delay");				// ZP 4.3 Support
#elseif defined ZP50
	g_szCounter = get_cvar_num("zp_gamemode_delay");	// ZP 5.0 Support
#else
	g_szCounter = get_pcvar_num(g_eCvarCustomDelay);	// Custom if no cvar is found
#endif

	Toggle_CountDown();
}

public Toggle_CountDown()
{
	if(is_mode_started()) return;

	switch(get_gvar_type(get_pcvar_num(g_eCvarShowType)))
	{
		case TYPE_CHAT:
		{
			if(11 < g_szCounter < 16)
				client_print(0, print_center, "%s^nZombies are getting closer!", g_szPrefix); 

			if(0 < g_szCounter < 11)
			{
				play_sound_type(0, g_szCountSound[g_szCounter - 1]);
				client_print(0, print_center, "%s^nInfection in %i", g_szPrefix, g_szCounter); 
			}

			if(g_szCounter == 0)
			{
				play_sound_type(0, g_szZombieInfected);
				client_print(0, print_center, "COME MY CHILDREN"); 
			}
		}
		
		case TYPE_HUD:
		{
			if(11 < g_szCounter < 16)
			{
				set_hudmessage(0, 179, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, 10);
				ShowSyncHudMsg(0, g_msgSyncHUD, "%s^nZombies are getting closer!", g_szPrefix); 
			}

			if(0 < g_szCounter < 11)
			{
				play_sound_type(0, g_szCountSound[g_szCounter - 1]);
				set_hudmessage(g_szCounter > 7 ? 0 : 200, g_szCounter < 4 ? 0 : 200, 0, -1.0, 0.28, 1, 0.02, 0.95, 0.01, 0.1, 10); 
				ShowSyncHudMsg(0, g_msgSyncHUD, "%s^nInfection in %i", g_szPrefix, g_szCounter); 
			}

			if(g_szCounter == 0)
			{
				play_sound_type(0, g_szZombieInfected);
				set_hudmessage(179, 0, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, 10);
				ShowSyncHudMsg(0, g_msgSyncHUD, "COME MY CHILDREN"); 
			}
		}

		case TYPE_DHUD:
		{
			if(11 < g_szCounter < 16)
			{
				set_dhudmessage(0, 179, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1);
				show_dhudmessage(0, "%s^nZombies are getting closer!", g_szPrefix); 
			}

			if(0 < g_szCounter < 11)
			{
				play_sound_type(0, g_szCountSound[g_szCounter - 1]);
				set_dhudmessage(g_szCounter > 7 ? 0 : 200, g_szCounter < 4 ? 0 : 200, 0, -1.0, 0.28, 1, 0.02, 0.95, 0.01, 0.1); 
				show_dhudmessage(0, "%s^nInfection in %i", g_szPrefix, g_szCounter); 
			}

			if(g_szCounter == 0)
			{
				play_sound_type(0, g_szZombieInfected);
				set_dhudmessage(179, 0, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1);
				show_dhudmessage(0, "COME MY CHILDREN"); 
			}
		}
	}

	g_szCounter--;

	if(g_szCounter >= 0)
		set_task(1.0, "Toggle_CountDown");
}

stock precache_sound_type(const szName[])
{
	new szData[128];
	formatex(szData, charsmax(szData), szName);

	switch(get_sound_type(szData))
	{
		case TYPE_WAV: precache_sound(szData);
		case TYPE_MP3:
		{
			format(szData, charsmax(szData), "sound/%s", szData);
			precache_generic(szData);
		}
		case TYPE_INVALID: return;
	}
}

stock play_sound_type(iPlayer, const szName[])
{
	new szData[128];
	formatex(szData, charsmax(szData), szName);

	switch(get_sound_type(szData))
	{
		case TYPE_WAV:
			client_cmd(iPlayer, "spk %s", szData);

		case TYPE_MP3:
		{
			format(szData, charsmax(szData), "sound/%s", szData);
			client_cmd(iPlayer, "mp3 play %s", szData);
		}

		case TYPE_INVALID: return;
	}
}

get_gvar_type(szCvar)
{
	switch(szCvar)
	{
		case 1: return TYPE_HUD;
		case 2: return TYPE_DHUD;
	}
	
	return TYPE_CHAT;
}

get_sound_type(szSound[])
{
	switch(szSound[strlen(szSound) - 1])
	{
		case 'v', 'V': return TYPE_WAV;
		case '3': return TYPE_MP3;
	}
	
	return TYPE_INVALID;
}

stock is_mode_started()
{
#if defined BIO
	return game_started();
#elseif defined ZP43
	return zp_has_round_started();
#elseif defined ZP50
	return zp_gamemodes_get_current() != ZP_NO_GAME_MODE;
#else
	return false;
#endif
}