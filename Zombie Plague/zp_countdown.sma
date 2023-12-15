/*	
	[ZP] Countdown

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
			- Removed `#pragma semicolon 1` due to users reporting that they can't compile the code.

		* Current Mod Support:
			- Biohazard (bh_starttime)
			- Zombie Plague 4.3 or with the same cvar (zp_delay)
			- ZP 5.0 (zp_gamemode_delay)
			
*/
#include <amxmodx>

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

// Uncomment the mod you are using or contact me to set it up your mod
// if it's different than the supported ones. Discord: yankonl
//
// #define BIO 
// #define ZP43
// #define ZP50

#if defined BIO
	#include <biohazard>
#elseif defined ZP43
	#include <zombie_plague_special>
#elseif defined ZP50
	#include <zp50_gamemodes>
#else
	new g_eCvarCustomDelay;
#endif

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

new g_szCounter, g_msgSyncHUD, g_eCvarShowType, g_eCvarRestart, bool:g_iStarted = false;

#if !defined g_eCvarCustomDelay
	new g_iOldDelay;
#endif

public plugin_init()
{
	register_plugin("[ZP] Countdown", "1.6", "YankoNL");
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");
	register_cvar("yankonl", "1.6-countdown", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	g_eCvarRestart = register_cvar("zp_round_restart_seconds", "33");		// First round restart time. So you can wait for everyone to join.
	g_eCvarShowType = register_cvar("zp_countdown_display_type", "2");		// 0 - Center Chat | 1 - HUD | 2 - DHUD
#if defined g_eCvarCustomDelay
	g_eCvarCustomDelay = register_cvar("zp_countdown_custom_delay", "15");	// Set only if no mod cvar is detected
#endif

	g_msgSyncHUD = CreateHudSyncObj();
}

public plugin_precache()
{
	precache_sound_type(g_szRoundStart);
	precache_sound(g_szZombieInfected);

	for(new i = 0; i < sizeof g_szCountSound; i++)
		precache_sound(g_szCountSound[i]);
}

public plugin_cfg()
{
	if(g_iStarted) return;

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

	set_task(1.0, "first_restart");
	g_szCounter = get_pcvar_num(g_eCvarRestart);
}

public first_restart()
{
	if(g_szCounter)
	{
		set_dhudmessage(0, 179, 179, -1.0, 0.28, 1, 0.0, 0.1, 0.1, 1.0);
		show_dhudmessage(0, "Waiting for all players to join...^nGame Starting in %i", g_szCounter);

		g_szCounter--;
		set_task(1.0, "first_restart");
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

	play_sound_type(g_szRoundStart);

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
				emit_sound(0, CHAN_VOICE, g_szCountSound[g_szCounter - 1], 1.0, ATTN_NORM, 0, PITCH_NORM);
				client_print(0, print_center, "%s^nInfection in %i", g_szPrefix, g_szCounter); 
			}

			if(g_szCounter == 0)
			{
				emit_sound(0, CHAN_VOICE, g_szZombieInfected, 1.0, ATTN_NORM, 0, PITCH_NORM);
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
				emit_sound(0, CHAN_VOICE, g_szCountSound[g_szCounter - 1], 1.0, ATTN_NORM, 0, PITCH_NORM);
				set_hudmessage(g_szCounter > 7 ? 0 : 200, g_szCounter < 4 ? 0 : 200, 0, -1.0, 0.28, 1, 0.02, 0.95, 0.01, 0.1, 10); 
				ShowSyncHudMsg(0, g_msgSyncHUD, "%s^nInfection in %i", g_szPrefix, g_szCounter); 
			}

			if(g_szCounter == 0)
			{
				emit_sound(0, CHAN_VOICE, g_szZombieInfected, 1.0, ATTN_NORM, 0, PITCH_NORM);
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
				emit_sound(0, CHAN_VOICE, g_szCountSound[g_szCounter - 1], 1.0, ATTN_NORM, 0, PITCH_NORM);
				set_dhudmessage(g_szCounter > 7 ? 0 : 200, g_szCounter < 4 ? 0 : 200, 0, -1.0, 0.28, 1, 0.02, 0.95, 0.01, 0.1); 
				show_dhudmessage(0, "%s^nInfection in %i", g_szPrefix, g_szCounter); 
			}

			if(g_szCounter == 0)
			{
				emit_sound(0, CHAN_VOICE, g_szZombieInfected, 1.0, ATTN_NORM, 0, PITCH_NORM);
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

stock play_sound_type(const szName[])
{
	new szData[128];
	formatex(szData, charsmax(szData), szName);

	switch(get_sound_type(szData))
	{
		case TYPE_WAV:
			client_cmd(0, "spk %s", szData);

		case TYPE_MP3:
		{
			format(szData, charsmax(szData), "sound/%s", szData);
			client_cmd(0, "mp3 play %s", szData);
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