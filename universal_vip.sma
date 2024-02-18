#define PLUGIN_VERSION "2.3"

#include <amxmodx>
#include <reapi_stocks>

#define VIP_FLAG ADMIN_RESERVATION

new g_szSoundFile[] = "buttons/blip1.wav";

enum _:Cvars
{
	MODE, PARACHUTE, MULTIJUMP, SHOW_DMG,
	Float:VIP_HP, VIP_AP,
	Float:KILL_HP, KILL_AP, KILL_MONEY,
	Float:HEADSHOT_HP, HEADSHOT_AP, HEADSHOT_MONEY,
}

new g_eCvars[Cvars],iJumps[33], g_SyncHudObj

const FCVAR_TYPE = FCVAR_NONE	//FCVAR_SPONLY|FCVAR_PROTECTED

public plugin_init()
{
	register_plugin("Universal V.I.P", PLUGIN_VERSION, "YankoNL")
	register_cvar("ynl-universal-vip", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	bind_pcvar_num(create_cvar("vip_classic_mode", "1", FCVAR_TYPE, "Enable or Disable classic mode^nOn spawn the V.I.P player gets:^n- HE Grenade x1^n- Flash Grenade x1^n- Deagle with 35 BP ammo^n- Defuse Kit if CT", true, 0.0, true, 1.0), g_eCvars[MODE])

	bind_pcvar_num(create_cvar("vip_parachute", "0", FCVAR_TYPE, "Enable or Disable parachute for V.I.P players", true, 0.0, true, 1.0), g_eCvars[PARACHUTE])

	bind_pcvar_num(create_cvar("vip_multijump", "0", FCVAR_TYPE, "Enable or Disable multi-jumping for V.I.P players", true, 0.0, true, 1.0), g_eCvars[MULTIJUMP])

	bind_pcvar_num(create_cvar("vip_show_dmg", "0", FCVAR_TYPE, "Enable or Disable DMG display for V.I.P players", true, 0.0, true, 1.0), g_eCvars[SHOW_DMG])

	bind_pcvar_float(create_cvar("vip_hp", "105", FCVAR_TYPE, "Spawn health Max Limit", true, 1.0), g_eCvars[VIP_HP])

	bind_pcvar_num(create_cvar("vip_ap", "100", FCVAR_TYPE, "Spawn armor Max Limit", true, 0.0), g_eCvars[VIP_AP])

	bind_pcvar_float(create_cvar("vip_kill_hp", "2", FCVAR_TYPE, "Regenerate Health for a kill", true, 0.0), g_eCvars[KILL_HP])

	bind_pcvar_num(create_cvar("vip_kill_ap", "5", FCVAR_TYPE, "Regenerate Armor for a kill", true, 0.0), g_eCvars[KILL_AP])

	bind_pcvar_num(create_cvar("vip_kill_money", "25", FCVAR_TYPE, "Bonus Money for a kill", true, 0.0), g_eCvars[KILL_MONEY])

	bind_pcvar_float(create_cvar("vip_headshot_hp", "5", FCVAR_TYPE, "Regenerate Health for a kill with headshot", true, 0.0), g_eCvars[HEADSHOT_HP])

	bind_pcvar_num(create_cvar("vip_headshot_ap", "10", FCVAR_TYPE, "Regenerate Armor for a kill with headshot", true, 0.0), g_eCvars[HEADSHOT_AP])

	bind_pcvar_num(create_cvar("vip_headshot_money", "50", FCVAR_TYPE, "Bonus Money for a kill with headshot", true, 0.0), g_eCvars[HEADSHOT_MONEY])

	AutoExecConfig(true, "universal_vip")

	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", true)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamagePost", true)
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKill", true)
	RegisterHookChain(RG_CBasePlayer_Jump, "OnPlayerJump", false)
	RegisterHookChain(RG_PM_AirMove, "OnPlayerAirborn", false)

	register_message(get_user_msgid("ScoreAttrib"), "msg_ScoreAttrib")

	g_SyncHudObj = CreateHudSyncObj()
}

public plugin_precache()
	precache_sound(g_szSoundFile);

public client_putinserver(id)
{
	if(is_user_vip(id))
	{
		client_print_color(0, print_team_default, "^4[^3Universal V.I.P^4] ^3V.I.P ^1Player ^4%n ^1has connected! ", id)
		client_cmd(0, "spk %s", g_szSoundFile);
	}
}

public OnPlayerSpawn(id)
{
	if(!is_user_alive(id) || !is_user_vip(id))
		return HC_CONTINUE

	rg_set_user_health(id, g_eCvars[VIP_HP])
	rg_set_user_armor(id, g_eCvars[VIP_AP], ARMOR_VESTHELM) // ARMOR_NONE / ARMOR_KEVLAR / ARMOR_VESTHELM

	if(g_eCvars[MODE])
	{
		rg_give_item_ex(id, "weapon_hegrenade")
		rg_give_item_ex(id, "weapon_flashbang", .ammo = 1)
		rg_give_item_ex(id, "weapon_deagle", GT_REPLACE, 7, 35)
	
		if(rg_get_user_team(id) == TEAM_CT && !rg_user_has_defuser(id))
			rg_give_defusekit(id, true)
	}

	return HC_CONTINUE
}

public OnPlayerTakeDamagePost(const iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	if(!g_eCvars[SHOW_DMG]) return HC_CONTINUE;

	if(!is_user_connected(iAttacker) || !is_user_vip(iAttacker) || !rg_is_player_can_takedamage(iAttacker, iVictim) || flDamage < 1.0)
		return HC_CONTINUE
	
	set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
	ShowSyncHudMsg(iVictim, g_SyncHudObj, "%.f", flDamage)
	
	set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
	ShowSyncHudMsg(iAttacker, g_SyncHudObj, "%.f", flDamage)

	return HC_CONTINUE
}

public OnPlayerKill(iVictim, iAttacker)
{
	if(iVictim == iAttacker || !is_user_connected(iAttacker) || !is_user_vip(iAttacker))
		return HC_CONTINUE

	new Float:iHealth, iArmor, Float:iAddHealth, iAddArmor, iAddMoney

	iHealth = rg_get_user_health(iAttacker)
	iArmor = rg_get_user_armor(iAttacker)

	iAddHealth = rg_user_killed_by_headshot(iVictim) ? g_eCvars[HEADSHOT_HP] : g_eCvars[KILL_HP]
	iAddArmor = rg_user_killed_by_headshot(iVictim) ? g_eCvars[HEADSHOT_AP] : g_eCvars[KILL_AP]
	iAddMoney = rg_user_killed_by_headshot(iVictim) ? g_eCvars[HEADSHOT_MONEY] : g_eCvars[KILL_MONEY]

	if(iHealth < g_eCvars[VIP_HP])
		rg_add_user_health(iAttacker, iAddHealth, .fMaxs = g_eCvars[VIP_HP], .ClampHp = true)
		//set_entvar(iAttacker, var_health, floatclamp(iHealth + iAddHealth, iHealth, g_eCvars[VIP_HP]))

	if(iArmor < g_eCvars[VIP_AP])
		rg_set_user_armor(iAttacker, clamp(iArmor + iAddArmor, iArmor, g_eCvars[VIP_AP]), ARMOR_VESTHELM) // ARMOR_NONE / ARMOR_KEVLAR / ARMOR_VESTHELM

	rg_add_account(iAttacker, iAddMoney, AS_ADD, false)

	return HC_CONTINUE
}

public msg_ScoreAttrib(MsgID, MsgDest, MsgReciver)
{
	if(is_user_vip(get_msg_arg_int(1)) && is_user_alive(get_msg_arg_int(1)))
		set_msg_arg_int(2, ARG_BYTE,(1<<2))
}

public OnPlayerAirborn(id)
{
	if(!g_eCvars[PARACHUTE] || !is_user_alive(id) || !is_user_vip(id))
		return HC_CONTINUE

	if(!(get_entvar(id, var_button) & IN_USE) || get_entvar(id, var_waterlevel) > 0)
		return HC_CONTINUE

	new Float:flVelocity[3]
	get_entvar(id, var_velocity, flVelocity)
	if(flVelocity[2] < 0.0)
	{
		flVelocity[2] =(flVelocity[2] + 40.0 < -100.0) ? flVelocity[2] + 40.0 : -100.0
		set_entvar(id, var_sequence, ACT_WALK)
		set_entvar(id, var_gaitsequence, ACT_IDLE)
		set_pmove(pm_velocity, flVelocity)
		set_movevar(mv_gravity, 80.0)
	}

	return HC_CONTINUE
}

public OnPlayerJump(id)
{
	if(!g_eCvars[MULTIJUMP] || !is_user_alive(id) || !is_user_vip(id))
		return HC_CONTINUE

	new iFlags = get_entvar(id, var_flags)

	if(iFlags & FL_WATERJUMP || get_entvar(id, var_waterlevel) >= 2 || !(get_member(id, m_afButtonPressed) & IN_JUMP))
		return HC_CONTINUE

	if(iFlags & FL_ONGROUND)
	{
		iJumps[id] = 0
		return HC_CONTINUE
	}

	if(++iJumps[id] <= 1)
	{
		new Float:fVelocity[3]
		get_entvar(id, var_velocity, fVelocity)
		fVelocity[2] = 268.328157
		set_entvar(id, var_velocity, fVelocity)
			
		return HC_CONTINUE
	}

	return HC_CONTINUE
}

bool:is_user_vip(id)
	return bool:(get_user_flags(id) & VIP_FLAG)
