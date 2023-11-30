#include <amxmodx>
#include <amxmisc>
#include <zombieplague>

#if AMXX_VERSION_NUM < 183
    #include <dhudmessage>
#endif

new g_szCounter;

new g_szSounds[][] =
{
	"Fatall-Error/downwego/fatall-1.wav",
	"Fatall-Error/downwego/fatall-2.wav",
	"Fatall-Error/downwego/fatall-3.wav",
	"Fatall-Error/downwego/fatall-4.wav",
	"Fatall-Error/downwego/fatall-5.wav",
	"Fatall-Error/downwego/fatall-6.wav",
	"Fatall-Error/downwego/fatall-7.wav",
	"Fatall-Error/downwego/fatall-8.wav",
	"Fatall-Error/downwego/fatall-9.wav",
	"Fatall-Error/downwego/fatall-10.wav"
};

public plugin_init()
{
	register_plugin("[ZP] Countdown", "1.0", "YankoNL");
	register_event("HLTV", "OnRoundStart", "a", "1=0", "2=0");
}

public plugin_precache()
{
	for (new i = 0; i < sizeof g_szSounds; i++)
		precache_sound(g_szSounds[i]);

	precache_sound("Fatall-Error/downwego/fatall-come.wav")
}

public OnRoundStart()
{
	g_szCounter = get_cvar_num("zp_delay");
	zombie_countdown();
}

public zombie_countdown()
{	
	if (0 < g_szCounter < 11)
	{
		client_cmd(0, "spk %s", g_szSounds[g_szCounter - 1]);
		set_dhudmessage(179, 0, 0, -1.0, 0.28, 1, 0.02, 0.02, 0.01, 0.1); 
		show_dhudmessage(0, ".:Fatall-Error:.^nInfection after %i seconds", g_szCounter); 
	}

	if(g_szCounter == 0)
	{
		client_cmd(0, "spk Fatall-Error/downwego/fatall-come");
		set_hudmessage(179, 0, 0, -1.0, 0.28, 1, 0.02, 0.02, 0.1, 1.1);
		show_dhudmessage(0, ".:Fatall-Error:.^nCOME MY CHILDREN!!!");
	}

	g_szCounter--;
		
	if (g_szCounter >= 0)
		set_task(1.0, "zombie_countdown");
}