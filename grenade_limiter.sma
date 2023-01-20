#include <amxmodx>
#include <csx>
#include <hamsandwich>

#pragma semicolon 1

const Linux_Diff = 4;
const m_pPlayer = 41;

new he_used[33], flash_used[33], smoke_used[33];
new bool:is_he_used[33], bool:is_flash_used[33], bool:is_smoke_used[33];

public plugin_init()
{
	register_plugin("Grenade Throw Limiter", "1.0", "YankoNL");

	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_hegrenade", "OnThrowHE", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_flashbang", "OnThrowFlash", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_smokegrenade", "OnThrowSmoke", false);
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", true);
}

public client_putinserver(id)
	grenade_reset(id);

public OnPlayerSpawn(id)
	grenade_reset(id);

public OnThrowHE(pEntity)
{
	new id = get_pdata_cbase(pEntity , m_pPlayer , Linux_Diff);

	if(is_he_used[id])
	{
		client_print(id, print_center, "[Grenade Limiter]^nHE grenade throw limit reached!");
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public OnThrowFlash(pEntity)
{
	new id = get_pdata_cbase(pEntity , m_pPlayer , Linux_Diff);

	if(is_flash_used[id])
	{
		client_print(id, print_center, "[Grenade Limiter]^nFlash grenade throw limit reached!");
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public OnThrowSmoke(pEntity)
{
	new id = get_pdata_cbase(pEntity , m_pPlayer , Linux_Diff);

	if(is_smoke_used[id])
	{
		client_print(id, print_center, "[Grenade Limiter]^nSmoke grenade throw limit reached!");
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public grenade_reset(id)
{
	is_he_used[id] = false;
	is_flash_used[id] = false;
	is_smoke_used[id] = false;

	he_used[id] = 0;
	flash_used[id] = 0;
	smoke_used[id] = 0;

}

public grenade_throw(id, iGrenade, iWeapon)
{
	switch(iWeapon)
	{
		case CSW_HEGRENADE:
		{
			he_used[id]++;
			grenade_counter(id, he_used[id], flash_used[id], smoke_used[id]);
		}
		case CSW_FLASHBANG:
		{
			flash_used[id]++;
			grenade_counter(id, he_used[id], flash_used[id], smoke_used[id]);
		}
		case CSW_SMOKEGRENADE:
		{
			smoke_used[id]++;
			grenade_counter(id, he_used[id], flash_used[id], smoke_used[id]);
		}
	}
}

stock grenade_counter(id, iHE, iFlash, iSmoke)
{
	if(iHE == 2)
		is_he_used[id] = true;

	if(iFlash == 2)
		is_flash_used[id] = true;

	if(iSmoke == 2)
		is_smoke_used[id] = true;
}