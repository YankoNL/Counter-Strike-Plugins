#include <amxmodx>

#pragma semicolon 1

new const g_szPrefix[] = "[ Countdown ]";

new const g_szRoundStart[] = "downwego/fatall-start.wav";
new const g_szZombieInfected[] = "downwego/fatall-come.wav";
new g_szSounds[][] =
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

new g_szCounter, g_msgSyncHUD;

public plugin_init()
{
	register_plugin("[ZP] Countdown", "1.1", "YankoNL");
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0");

	g_msgSyncHUD = CreateHudSyncObj();
}

public plugin_precache()
{
	precache_sound(g_szRoundStart);
	precache_sound(g_szZombieInfected);

	for (new i = 0; i < sizeof g_szSounds; i++)
		precache_sound(g_szSounds[i]);
}

public Event_HLTV()
{
	emit_sound(0, CHAN_VOICE, g_szRoundStart, 1.0, ATTN_NORM, 0, PITCH_NORM);

	g_szCounter = get_cvar_num("zp_delay");
	Toggle_CountDown();
}

public Toggle_CountDown()
{ 
	if (11 < g_szCounter < 16)
	{
		set_hudmessage(0, 179, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, -1);
		ShowSyncHudMsg(0, g_msgSyncHUD, "%s^nZombies are getting closer!", g_szPrefix); 
	}

	if (0 < g_szCounter < 11)
	{
		emit_sound(0, CHAN_VOICE, g_szSounds[g_szCounter - 1], 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_hudmessage(random_num(100, 250), random_num(100, 250), random_num(100, 250), -1.0, 0.28, 1, 0.02, 0.95, 0.01, 0.1, 9, 0, {100, 0, 20, 250}); 
		ShowSyncHudMsg(0, g_msgSyncHUD, "%s^nInfection in %i", g_szPrefix, g_szCounter); 
	}

	if (g_szCounter == 0)
	{
		emit_sound(0, CHAN_VOICE, g_szZombieInfected, 1.0, ATTN_NORM, 0, PITCH_NORM);
		set_hudmessage(179, 0, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, 10);
		ShowSyncHudMsg(0, g_msgSyncHUD, "COME MY CHILDREN"); 
	}
	g_szCounter--;

	if (g_szCounter >= 0)
		set_task(1.0, "Toggle_CountDown");
}