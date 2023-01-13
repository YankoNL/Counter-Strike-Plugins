#include <amxmodx>
#include <reapi>

new const MDL_FILE[] = "models/xmas/ushanka.mdl"

enum { hat }

new g_MdlIndex, iHatEnt[MAX_CLIENTS + 1]
new bool:g_EnableHat[MAX_PLAYERS + 1]

public plugin_precache()
{
	g_MdlIndex = precache_model(MDL_FILE)
}

public plugin_init()
{
	register_plugin("Christmas Hats", "1.1", "YankoNL")
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", true)

	register_clcmd("say /hats", "toggle_hat");
	register_clcmd("team_say /hats", "toggle_hat");
}

public client_putinserver(id)
{
	g_EnableHat[id] = true;

	CheckEnt(id)
	if((iHatEnt[id] = rg_create_entity("info_target")))
	{
		set_entvar(iHatEnt[id], var_classname, "_christmas_hat_ent")
		set_entvar(iHatEnt[id], var_model, MDL_FILE)
		set_entvar(iHatEnt[id], var_modelindex, g_MdlIndex)
		set_entvar(iHatEnt[id], var_movetype, MOVETYPE_FOLLOW)
		set_entvar(iHatEnt[id], var_aiment, id)
	}
}

public toggle_hat(id)
{
	g_EnableHat[id] =! g_EnableHat[id]
	client_print(id, print_center, "Christmas Hat: %s ", g_EnableHat[id] ? "Enabled" : "Disabled")

	if(g_EnableHat[id])
		show_hat(id)
	else
		hide_hat(id)
}

public client_disconnected(id)
	CheckEnt(id)

public OnPlayerSpawn(const id)
{
	if(g_EnableHat[id])
	{
		if(is_entity(iHatEnt[id]) && is_user_alive(id))
		{
			SetEntModel(id, hat, get_member(id, m_iTeam))
			show_hat(id)
		}
	}
	else
		hide_hat(id)
}

show_hat(const id)
{
	if(is_entity(iHatEnt[id]) && is_user_alive(id))
	{
		set_entvar(iHatEnt[id], var_rendermode, kRenderNormal)
		set_entvar(iHatEnt[id], var_renderamt, 0.0)
	}
}

hide_hat(const id)
{
	if(is_entity(iHatEnt[id]) && is_user_alive(id))
	{
		set_entvar(iHatEnt[id], var_rendermode, kRenderTransAlpha)
		set_entvar(iHatEnt[id], var_renderamt, 0.0)
	}
}

CheckEnt(const id)
{
	if(iHatEnt[id] && is_entity(iHatEnt[id]))
	{
		set_entvar(iHatEnt[id], var_flags, FL_KILLME)
		set_entvar(iHatEnt[id], var_nextthink, get_gametime())
		iHatEnt[id] = 0
	}
}

SetEntModel(const id, const Body, const Skin = 0)
{
	set_entvar(iHatEnt[id], var_body, Body)
	
	if(Body == hat)
		set_entvar(iHatEnt[id], var_skin, Skin - 1)
}