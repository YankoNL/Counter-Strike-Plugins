#include <amxmodx>
#include <reapi>

#define VIP_FLAG ADMIN_RESERVATION

enum _:Cvars
{
	Float:MAX_HP, Float:VAMP_HP, Float:VAMP_HS,
	Float:MAX_HP_VIP, Float:VAMP_HP_VIP, Float:VAMP_HS_VIP
}

const FCVAR_TYPE = FCVAR_NONE	//FCVAR_SPONLY|FCVAR_PROTECTED

new g_eCvars[Cvars], g_iObject

public plugin_init()
{
	register_plugin("Vampire", "1.1", "YankoNL")
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKill", true)

	bind_pcvar_float(create_cvar("amx_vamp_limit", "100", FCVAR_TYPE, "Player max health limit", true, 0.0), g_eCvars[MAX_HP])
	bind_pcvar_float(create_cvar("amx_vamp_hp", "10", FCVAR_TYPE, "Regenerate Health for a kill", true, 0.0), g_eCvars[VAMP_HP])
	bind_pcvar_float(create_cvar("amx_vamp_hs", "20", FCVAR_TYPE, "Regenerate Health for a kill with headshot", true, 0.0), g_eCvars[VAMP_HS])

	bind_pcvar_float(create_cvar("amx_vamp_vip_limit", "120", FCVAR_TYPE, "Player max health limit", true, 0.0), g_eCvars[MAX_HP_VIP])
	bind_pcvar_float(create_cvar("amx_vamp_vip_hp", "15", FCVAR_TYPE, "Regenerate Health for a kill", true, 0.0), g_eCvars[VAMP_HP_VIP])
	bind_pcvar_float(create_cvar("amx_vamp_vip_hs", "30", FCVAR_TYPE, "Regenerate Health for a kill with headshot", true, 0.0), g_eCvars[VAMP_HS_VIP])

	g_iObject = CreateHudSyncObj()
}

public OnPlayerKill(iVictim, iAttacker)
{
	if (iVictim == iAttacker || !is_user_connected(iAttacker) || !is_user_vip(iAttacker))
		return HC_CONTINUE

	new Float:iHealth, Float:iAdd
	get_entvar(iAttacker, var_health, iHealth)

	if (get_member(iVictim, m_bHeadshotKilled))
		iAdd = is_user_vip(iAttacker) ? g_eCvars[VAMP_HS_VIP] : g_eCvars[VAMP_HS]
	else
		iAdd = is_user_vip(iAttacker) ? g_eCvars[VAMP_HP_VIP] : g_eCvars[VAMP_HP]


	if (iHealth < (is_user_vip(iAttacker) ? g_eCvars[MAX_HP_VIP] : g_eCvars[MAX_HP]))
		set_entvar(iAttacker, var_health, floatclamp(iHealth + iAdd, iHealth, is_user_vip(iAttacker) ? g_eCvars[MAX_HP_VIP] : g_eCvars[MAX_HP]))

	set_hudmessage(0, 255, 0, -1.0, 0.15, .holdtime = 1.5)
	ShowSyncHudMsg(iAttacker, g_iObject, "Life Steal: +%i Health", iAdd)

	return HC_CONTINUE
}

bool:is_user_vip(id)
	return (get_user_flags(id) & VIP_FLAG) != 0
