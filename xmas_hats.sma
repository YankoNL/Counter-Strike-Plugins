#include <amxmodx>
#include <reapi>

new const MDL_FILE[] = "models/xmas/ushanka.mdl"

enum { hat }

new g_MdlIndex, g_Ent[MAX_CLIENTS + 1]

public plugin_precache()
{
	g_MdlIndex = precache_model(MDL_FILE)
}

public plugin_init()
{
	register_plugin("Christmas Hats", "1.0", "YankoNL")
	RegisterHookChain(RG_CBasePlayer_Spawn, "FwdSpawnPost", true)
}

public client_putinserver(id)
{
	//if(is_user_bot(id) || is_user_hltv(id))
	//	return

	CheckEnt(id)
	if((g_Ent[id] = rg_create_entity("info_target")))
	{
		set_entvar(g_Ent[id], var_classname, "_christmas_hat_ent")
		set_entvar(g_Ent[id], var_model, MDL_FILE)
		set_entvar(g_Ent[id], var_modelindex, g_MdlIndex)
		set_entvar(g_Ent[id], var_movetype, MOVETYPE_FOLLOW)
		set_entvar(g_Ent[id], var_aiment, id)
	}
}

public client_disconnected(id)
	CheckEnt(id)

public FwdSpawnPost(const id)
{
	if(is_entity(g_Ent[id]) && is_user_alive(id))
		SetEntModel(id, hat, get_member(id, m_iTeam))
}

CheckEnt(const id)
{
	if(g_Ent[id] && is_entity(g_Ent[id]))
	{
		set_entvar(g_Ent[id], var_flags, FL_KILLME)
		set_entvar(g_Ent[id], var_nextthink, get_gametime())
		g_Ent[id] = 0
	}
}

SetEntModel(const id, const Body, const Skin = 0)
{
	set_entvar(g_Ent[id], var_body, Body)
	
	if(Body == hat)
		set_entvar(g_Ent[id], var_skin, Skin - 1)
}