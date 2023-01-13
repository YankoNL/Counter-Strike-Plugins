#include <amxmodx>
#include <reapi>

#pragma semicolon 1

enum _:Cvars {
	HOUR_START,
	HOUR_END,
	WEEKENDS,
	VIP_FLAGS,
	USE_DHUD,
	VIP_BOTS
};

new g_eCvars[Cvars], g_iHudSync;

public plugin_init()
{
	register_plugin("Free VIP Event", "1.2", "YankoNL");

	bind_pcvar_num(create_cvar("free_vip_start_hour", "21"), g_eCvars[HOUR_START]);
	bind_pcvar_num(create_cvar("free_vip_end_hour", "9"), g_eCvars[HOUR_END]);
	bind_pcvar_num(create_cvar("free_vip_weekends", "1"), g_eCvars[WEEKENDS]);
	bind_pcvar_string(create_cvar("free_vip_flags", "bs"), g_eCvars[VIP_FLAGS], charsmax(g_eCvars[VIP_FLAGS]));
	bind_pcvar_num(create_cvar("free_vip_dhud", "1"), g_eCvars[USE_DHUD]);
	bind_pcvar_num(create_cvar("free_vip_for_bots", "1"), g_eCvars[VIP_BOTS]);
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", true);

	g_iHudSync = CreateHudSyncObj();
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_eCvars[VIP_BOTS])
		return HC_CONTINUE;

	if(is_vip_time())
		set_task(1.0, "GiveVIP", id);

	return HC_CONTINUE;
}

public GiveVIP(id)
	set_user_flags(id, read_flags(g_eCvars[VIP_FLAGS]));

public OnPlayerSpawn(const id)
{
	if(is_vip_time() && is_user_alive(id) && !is_user_bot(id))
	{
		if(g_eCvars[USE_DHUD])
		{	//message stuff (R, G, B | X, Y | msg effect| msg eff T | msg up T | fadein T | fadeout Time)
			set_dhudmessage(0, 255, 0, -1.0, 0.2, 2, 0.1, 6.0, 0.2, 0.2);
			show_dhudmessage(id, "Free V.I.P Event: ON");
		}
		else
		{	//message stuff (R, G, B | X, Y | msg effect| msg eff T | msg up T | fadein T | fadeout Time | Channel)
			set_hudmessage(0, 255, 0, -1.0, 0.2, 2, 0.1, 6.0, 0.2, 0.2, -1);
			ShowSyncHudMsg(id, g_iHudSync, "Free V.I.P Event: ON");
		}
	}
}

bool:is_weekend()
{
	new szDay[2];
	get_time("%w", szDay, charsmax((szDay)));

	new iDay = str_to_num(szDay);

	return bool:(iDay == 0 || iDay == 6);
}

bool:is_time()
{
    static iHour; time(iHour);
    return bool:(g_eCvars[HOUR_START] < g_eCvars[HOUR_END] ? 
    	(g_eCvars[HOUR_START] <= iHour < g_eCvars[HOUR_END]) :
    	(g_eCvars[HOUR_START] <= iHour || iHour < g_eCvars[HOUR_END]));
}

bool:is_vip_time()
{
	if(g_eCvars[WEEKENDS])
		return bool:(is_weekend() || is_time());
	else
		return bool:is_time();
}
