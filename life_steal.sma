#include <amxmodx>
#include <reapi>

#define VIP_FLAG ADMIN_RESERVATION

enum _:Cvars
{
	Float:life_steal_multiply,
	Float:life_steal_limit,
	Float:life_steal_vip_multiply,
	Float:life_steal_vip_limit
}

new g_eCvars[Cvars]

public plugin_init()
{
	register_plugin("Life Steal", "1.0", "YankoNL")
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBase_Player_TakeDamage", true)
	
	new pCvar

	pCvar = create_cvar("amx_ls_limit", "100.0")
	bind_pcvar_float(pCvar, g_eCvars[life_steal_limit])
	
	pCvar = create_cvar("amx_ls_multiply", "0.18")			// Percentage (0.2 = 20%) => 0.18 =  18%
	bind_pcvar_float(pCvar, g_eCvars[life_steal_multiply])

	pCvar = create_cvar("amx_ls_vip_limit", "120.0")
	bind_pcvar_float(pCvar, g_eCvars[life_steal_vip_limit])
	
	pCvar = create_cvar("amx_ls_vip_multiply", "0.24")		// Percentage (0.2 = 20%) => 0.24 =  24%
	bind_pcvar_float(pCvar, g_eCvars[life_steal_vip_multiply])
}

public CBase_Player_TakeDamage(const iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	if (is_user_alive(iAttacker) && flDamage >= 1.0)
	{
		static Float:flHealth, Float:flMaxHealth, Float:flBonusHealth
		flHealth = get_entvar(iAttacker, var_health) 
		flMaxHealth = is_user_vip(iAttacker) ? g_eCvars[life_steal_vip_limit] : g_eCvars[life_steal_limit]
		if(flHealth >= flMaxHealth) return

		flBonusHealth = flDamage * (is_user_vip(iAttacker) ? g_eCvars[life_steal_vip_multiply] : g_eCvars[life_steal_multiply])
		
		set_entvar(iAttacker, var_health, floatclamp(flHealth + flBonusHealth, flHealth, flMaxHealth))
	}
}

bool:is_user_vip(id)
	return !!(get_user_flags(id) & VIP_FLAG)
