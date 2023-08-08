/*
#	Version 1.0 - Release
#	- Model location fix by itz_bader (「 T B 」BADER)
#
#	Version 1.1 - Fix
#	- Non V.I.P players sometimes had stab protection
#	- Shield no longer works for players in the same team (reduce lag)
#	- Back Shield message no longer appears when randombly slashing with a knife behind a teammate with V.I.P status
#
#	Version 1.2 - New Feature (More Realisitc)
#	- Added spark when hitting a shield
#	- Added metal hit sound when hitting a shield
#
#	Version 1.2.1 - Sound Fix
#	- Removed the slash/stab player sound when hitting a shield
#
#	Version 1.2.2 - Sound Fix 2
#	- Fixed a bug where after hitting a shield and hitting a teammate would play the metal hit sound
*/
#define PLUGIN_VERSION "1.2.2"

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <xs>

#pragma semicolon 1

#define ENGINE

new const PREFIX[] = "Back Shield";

new const g_szPath[] = "models/back_shields";
new const g_szModel[][] = 
{
	"ancient_shield",
	"blackiron_shield",
	"gold_shield",
	"haystack_shield",
	"old_shield",
	"sherif_shield",
	"snowflake_shield"
};

new const g_szMetalSound[][] =
{
	"weapons/ric_metal-1.wav",
	"weapons/ric_metal-2.wav"
};

new g_szKnifeStabs[][] = 
{
	"weapons/knife_hit1.wav",
	"weapons/knife_hit2.wav",
	"weapons/knife_hit3.wav",
	"weapons/knife_hit4.wav",
	"weapons/knife_stab.wav"
};

#define REMOVE_ENTITY(%1) set_pev(%1, pev_flags, FL_KILLME)
new g_Ent[33], g_bHitShield[33];

public plugin_init()
{
	register_plugin("Back Shield", PLUGIN_VERSION, "YankoNL");
	register_cvar("BackShield", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);

	RegisterHam(Ham_TraceAttack, "player", "PreTraceAttack", false);
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", true);
	register_forward(FM_EmitSound , "EmitSound");
}

public plugin_precache()
{
	new model[128];

	for(new i = 0; i < sizeof g_szModel; i++)
	{
		formatex(model, charsmax(model), "%s/%s.mdl", g_szPath, g_szModel[i]);
		precache_model(model);
	}

	for(new i = 0; i < sizeof g_szMetalSound; i++)
		precache_sound(g_szMetalSound[i]);
}

public PreTraceAttack(iVictim, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_connected(iAttacker) || !is_user_vip(iVictim) || get_user_weapon(iAttacker) != CSW_KNIFE)
		return HAM_IGNORED;

	g_bHitShield[iAttacker] = false;

	if(get_user_team(iAttacker) == get_user_team(iVictim))
		return HAM_IGNORED;

	static Float:vecSrc[3];
	static Float:vecAngles[3];
	static Float:vecForward[3];
	static Float:vecAttackDir[3];
	
	GetCenter(iVictim, vecSrc);
	GetCenter(iAttacker, vecAttackDir);
	
	xs_vec_sub(vecAttackDir, vecSrc, vecAttackDir);
	xs_vec_normalize(vecAttackDir, vecAttackDir);
	
	pev(iVictim, pev_angles, vecAngles);
	engfunc(EngFunc_MakeVectors, vecAngles);
	
	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecAttackDir, -1.0, vecAttackDir);
	
	if(xs_vec_dot(vecForward, vecAttackDir) > 0.3)
	{
		client_print(iVictim, print_center, "[%s]^nPlayer '%n' tried to backstab you!", PREFIX, iAttacker);
		client_print(iAttacker, print_center, "[%s]^nStab blocked by V.I.P shield!", PREFIX);
		
		new Float:vecEnd[3];
		get_tr2(ptr, TR_vecEndPos, vecEnd);
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_SPARKS);
		engfunc(EngFunc_WriteCoord, vecEnd[0]);
		engfunc(EngFunc_WriteCoord, vecEnd[1]);
		engfunc(EngFunc_WriteCoord, vecEnd[2]);
		message_end();

		g_bHitShield[iAttacker] = true;

		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public EmitSound(entity, channel, const sound[]) 
{
	if(pev_valid(entity) && is_user_alive(entity)) 
	{
		if(g_bHitShield[entity])
		{
			for(new i = 0; i < sizeof g_szKnifeStabs; i++) 
			{
				if(equal(sound , g_szKnifeStabs[i]))
				{
					emit_sound(entity, channel, g_szMetalSound[random(sizeof g_szMetalSound)], 1.0, ATTN_NORM, 0, PITCH_NORM);
					return FMRES_SUPERCEDE;
				}
			}
		}
	}

	return FMRES_IGNORED;
}

#if defined ENGINE
public client_putinserver(id)
{
	if(!is_user_vip(id)) return PLUGIN_HANDLED;

	g_Ent[id] = create_entity("info_target");

	if(is_valid_ent(g_Ent[id]))
	{
		entity_set_int(g_Ent[id], EV_INT_movetype, MOVETYPE_FOLLOW);
		entity_set_edict(g_Ent[id], EV_ENT_aiment, id);
	}

	return PLUGIN_CONTINUE;
}

public OnPlayerSpawn(id)
{
	if(!is_user_alive(id) && !is_valid_ent(g_Ent[id]))
		return HAM_SUPERCEDE;

	if(is_user_vip(id))
	{
		new model[128];
		formatex(model, charsmax(model), "%s/%s.mdl", g_szPath, g_szModel[random(sizeof g_szModel)]);

		entity_set_model(g_Ent[id], model);
	}

	return HAM_IGNORED;
}

public client_disconnected(id)
	if(is_valid_ent(g_Ent[id]))
		remove_entity(g_Ent[id]);
#else
public client_putinserver(id)
{
	if(!is_user_vip(id)) return PLUGIN_HANDLED;

	g_Ent[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));

	if(pev_valid(g_Ent[id]))
	{
		set_pev(g_Ent[id], pev_classname, "back_shield");
		set_pev(g_Ent[id], pev_movetype, MOVETYPE_FOLLOW);
		set_pev(g_Ent[id], pev_effects, EF_NODRAW);
		set_pev(g_Ent[id], pev_aiment, id);
		set_pev(g_Ent[id], pev_sequence, 0);
		set_pev(g_Ent[id], pev_animtime, get_gametime());
		set_pev(g_Ent[id], pev_framerate, 1.0);
	}

	return PLUGIN_CONTINUE;
}

public OnPlayerSpawn(id)
{
	if(!is_user_alive(id))
		return HAM_SUPERCEDE;

	if(is_user_vip(id))
	{
		new model[128];
		formatex(model, charsmax(model), "%s/%s.mdl", g_szPath, g_szModel[random(sizeof g_szModel)]);

		engfunc(EngFunc_SetModel, g_Ent[id], model);
		fm_set_entity_visibility(g_Ent[id], 1);
	}

	return HAM_IGNORED;
}

public client_disconnected(id)
	if(pev_valid(g_Ent[id]))
		REMOVE_ENTITY(g_Ent[id]);
#endif

GetCenter(const iEntity, Float: vecSrc[3])
{
	static Float:vecAbsMax[3];
	static Float:vecAbsMin[3];
	
	pev(iEntity, pev_absmax, vecAbsMax);
	pev(iEntity, pev_absmin, vecAbsMin);
	
	xs_vec_add(vecAbsMax, vecAbsMin, vecSrc);
	xs_vec_mul_scalar(vecSrc, 0.5, vecSrc);
}

stock fm_set_entity_visibility(iEntity, iVisible = 1) 
	set_pev(iEntity, pev_effects, iVisible == 1 ? pev(iEntity, pev_effects) & ~EF_NODRAW : pev(iEntity, pev_effects) | EF_NODRAW);

bool:is_user_vip(id)
	return bool:(get_user_flags(id) & ADMIN_RESERVATION);
