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

		* Current Mod Support:
			- Biohazard (bh_starttime)
			- Zombie Plague 4.3 or with the same cvar (zp_delay)
			- ZP 5.0 (zp_gamemode_delay)
			
*/
#include <amxmodx>

#pragma semicolon 1

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

new g_szCounter, g_msgSyncHUD, g_eCvarShowType, g_eCvarDelay;

public plugin_init()
{
	register_plugin("[ZP] Countdown", "1.4.1", "YankoNL");
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");

	g_eCvarShowType = register_cvar("zp_countdown_display_type", "2");	// 0 - Center Chat | 1 - HUD | 2 - DHUD
	g_eCvarDelay = register_cvar("zp_countdown_custom_delay", "15");		// Set only if no mod cvar is detected

	g_msgSyncHUD = CreateHudSyncObj();
}

public plugin_precache()
{
	precache_sound_type(g_szRoundStart);
	precache_sound(g_szZombieInfected);

	for(new i = 0; i < sizeof g_szCountSound; i++)
		precache_sound(g_szCountSound[i]);
}

public Event_HLTV()
{
	play_sound_type(g_szRoundStart);

	if(cvar_exists("bh_starttime"))
		g_szCounter = get_cvar_num("bh_starttime");			// Biohazard Support
	else if(cvar_exists("zp_delay"))
		g_szCounter = get_cvar_num("zp_delay");				// ZP 4.3 Support
	else if(cvar_exists("zp_gamemode_delay"))
		g_szCounter = get_cvar_num("zp_gamemode_delay");	// ZP 5.0 Support
	else
		g_szCounter = get_pcvar_num(g_eCvarDelay);			// Custom if no cvar is found

	Toggle_CountDown();
}

public Toggle_CountDown()
{
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
				set_hudmessage(random_num(100, 250), random_num(100, 250), random_num(100, 250), -1.0, 0.28, 1, 0.02, 0.95, 0.01, 0.1, 10); 
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
				set_dhudmessage(random_num(100, 250), random_num(100, 250), random_num(100, 250), -1.0, 0.28, 1, 0.02, 0.95, 0.01, 0.1); 
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

	if (g_szCounter >= 0)
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