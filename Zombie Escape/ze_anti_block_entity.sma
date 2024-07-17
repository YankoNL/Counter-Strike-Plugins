#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

enum _:XYZ
{
	Float:X,
	Float:Y,
	Float:Z
}

new const Float:g_fSize[][XYZ] =
{
	{0.0, 2.0, 0.0},
	{0.0, -2.0, 0.0},
	{2.0, 0.0, 0.0},
	{-2.0, 0.0, 0.0}
}

new const szEntities[] =
{
    "func_train",
    "func_vehicle",
    "func_tracktrain",
    "func_door"
}

new g_Cvar_TraceMode, bool:g_bSemiclipFound

public plugin_init()
{
	register_plugin("[ZE] Anti-Block Map Entities", "1.0", "YankoNL")
	register_cvar("ynl_ZeAntiBlockEntity", "1.0", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	for(new i = 0; i <= charsmax(szEntities); i++)
		RegisterHam(Ham_Blocked, szEntities[i], "OnBlocked_Pre")

	bind_pcvar_num(create_cvar("amx_unstuck_trace_mode", "-1"), g_Cvar_TraceMode)

	g_bSemiclipFound = (get_cvar_pointer("resemiclip_version") != 0)
}

public OnBlocked_Pre(pBlocked, pBlocker)
	if(is_user_alive(pBlocker))
		RequestFrame("func_Unstuck", pBlocker)

public func_Unstuck(pBlocker)
{
	if(!is_user_alive(pBlocker))
		return

	new Float:fOrigin[XYZ], Float:fMins[XYZ], Float:fVec[XYZ], iHull

	pev(pBlocker, pev_origin, fOrigin)

	iHull = (pev(pBlocker, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;

	pev(pBlocker, pev_mins, fMins)

	for(new a; a < sizeof(g_fSize); a++)
	{
		fVec[X] = fOrigin[X] - fMins[X] * g_fSize[a][X]
		fVec[Y] = fOrigin[Y] - fMins[Y] * g_fSize[a][Y]
		fVec[Z] = fOrigin[Z] - fMins[Z] * g_fSize[a][Z]

		if(is_hull_vacant(fVec, iHull, pBlocker))
		{
			client_print(pBlocker, print_center, "[Anti-Block Escape]^nUnstucking... Don't block the Escape!")
			engfunc(EngFunc_SetOrigin, pBlocker, fVec)
			set_pev(pBlocker, pev_velocity, NULL_VECTOR)
			return
		}
	}

	user_kill(pBlocker)
	client_print_color(0, print_team_red, "^3[Anti-Block Escape] ^1Player ^4%n ^1has been killed for ^3blocking ^1the Escape.", pBlocker)
}

stock bool:is_hull_vacant(const Float:fOrigin[XYZ], iHull, pPlayer)
{
	new iTraceResult
	engfunc(EngFunc_TraceHull, fOrigin, fOrigin, func_GetTraceMode(), iHull, pPlayer, iTraceResult)

	return(!get_tr2(iTraceResult, TR_StartSolid) || !get_tr2(iTraceResult, TR_AllSolid))
}

func_GetTraceMode()
{
	switch(g_Cvar_TraceMode)
	{
		case -1: return g_bSemiclipFound ? IGNORE_MONSTERS : DONT_IGNORE_MONSTERS;
		case 0: return DONT_IGNORE_MONSTERS
		case 1: return IGNORE_MONSTERS
	}

	return IGNORE_MONSTERS
}