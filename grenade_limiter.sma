#include <amxmodx>
#include <csx>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

const Linux_Diff = 4;
const m_pPlayer = 41;
const m_iWeap = 43;

enum (+=1)
{
	NADE_HE = 0,
	NADE_FLASH,
	NADE_SMOKE,
	NADE_NONE
};

new const szGrenadeType[][] =
{
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
};

new const szGrenadeName[][]=
{
	"HE Grenade",
	"Flashbang",
	"Smoke Grenade"
};

new g_pCvars[NADE_NONE];
new g_iLimit[MAX_PLAYERS+1][NADE_NONE];

public plugin_init()
{
	register_plugin("Grenade Throw Limiter", "1.1", "YankoNL");
	register_cvar("ynl_grenade_limiter", "1.1", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	g_pCvars[NADE_HE] = register_cvar("ynl_hegrenade_limit", "1");
	g_pCvars[NADE_FLASH] = register_cvar("ynl_flashbang_limit", "2");
	g_pCvars[NADE_SMOKE] = register_cvar("ynl_smokegrenade_limit", "1");

	for(new i; i < sizeof(szGrenadeType); i++)
		RegisterHam(Ham_Weapon_PrimaryAttack, szGrenadeType[i], "TryThrow", false);

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", true);
}

public client_putinserver(id)
	arrayset(g_iLimit[id], 0, sizeof(g_iLimit[]));

public OnPlayerSpawn(id)
	arrayset(g_iLimit[id], 0, sizeof(g_iLimit[]));

public grenade_throw(id, iGrenade, iWeapon)
{
	new iKey = get_grenade_type(iWeapon);

	if(iKey == NADE_NONE) return;

	++g_iLimit[id][iKey];
}

public TryThrow(pEntity)
{
	static iWeapon, id;

	iWeapon = get_pdata_int(pEntity, m_iWeap, Linux_Diff);
	id = get_pdata_cbase(pEntity, m_pPlayer, Linux_Diff);

	new iType = get_grenade_type(iWeapon);

	new iLimit = get_pcvar_num(g_pCvars[iType]);

	if(g_iLimit[id][iType] >= iLimit)
	{
		client_print(id, print_center, "[Grenade Limiter]^n%s throw limit reached!", szGrenadeName[iType]);
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

get_grenade_type(item)
{
	switch(item)
	{
		case CSW_HEGRENADE: return NADE_HE;
		case CSW_FLASHBANG: return NADE_FLASH;
		case CSW_SMOKEGRENADE: return NADE_SMOKE;
	}
	
	return NADE_NONE;
}