#include <amxmodx>
#include <amxmisc>
#if AMXX_VERSION_NUM < 183
    #include <dhudmessage>
#endif

/*==============================================================================*/

#define PLUGIN "[ZP] Countdown"
#define VERSION "0.1"
#define AUTHOR "YankoNL"

/*==============================================================================*/

const Float:HUD_EFF_SH = 0.00

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0") 
}

/*================================================================================
 [Precaches]
=================================================================================*/

public plugin_precache()
{
	precache_sound("Fatall-Error/downwego/fatall-10.wav")
	precache_sound("Fatall-Error/downwego/fatall-9.wav")
	precache_sound("Fatall-Error/downwego/fatall-8.wav")
	precache_sound("Fatall-Error/downwego/fatall-7.wav")
	precache_sound("Fatall-Error/downwego/fatall-6.wav")
	precache_sound("Fatall-Error/downwego/fatall-5.wav")
	precache_sound("Fatall-Error/downwego/fatall-4.wav")
	precache_sound("Fatall-Error/downwego/fatall-3.wav")
	precache_sound("Fatall-Error/downwego/fatall-2.wav")
	precache_sound("Fatall-Error/downwego/fatall-1.wav")
	precache_sound("Fatall-Error/downwego/fatall-come.wav")
}

/*================================================================================
 [Round start event]
=================================================================================*/

public event_round_start()
{
	set_task(0.5, "countdown")
}

/*================================================================================
 [Countdown]
=================================================================================*/

public countdown()
{
	set_task(9.0, "ten")
	set_task(10.0, "nine")
	set_task(11.0, "eight")
	set_task(12.0, "seven")
	set_task(13.0, "six")
	set_task(14.0, "five")
	set_task(15.0, "four")
	set_task(16.0, "three")
	set_task(17.0, "two")
	set_task(18.0, "one")
	set_task(19.0, "zero")
}

public ten()
{
	set_dhudmessage(0, 179, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 10 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-10")
}

public nine()
{
	set_dhudmessage(0, 179, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 9 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-9")
}

public eight()
{
	set_dhudmessage(0, 179, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 8 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-8")
}

public seven()
{
	set_dhudmessage(0, 179, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 7 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-7")
}

public six()
{
	set_dhudmessage(0, 179, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 6 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-6")
}

public five()
{
	set_dhudmessage(179, 179, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 5 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-5")
}

public four()
{
	set_dhudmessage(179, 179, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 4 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-4")
}

public three()
{
	set_dhudmessage(179, 0, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 3 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-3")
}

public two()
{
	set_dhudmessage(179, 0, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 2 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-2")
}

public one()
{
	set_dhudmessage(179, 0, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nInfection after 1 seconds")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-1")
}

public zero()
{
	set_dhudmessage(179, 0, 0, -1.0, 0.28, 1, 0.00, HUD_EFF_SH, 0.1, 1.1)
	show_dhudmessage(0, ".:Fatall-Error:.^nCOME MY CHILDREN!!!")
	client_cmd(0, "spk Fatall-Error/downwego/fatall-come")
}