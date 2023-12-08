#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

public plugin_init()
{
	register_plugin("[ZP] Addon: Damager", "1.0.1", "YankoNL");
	register_cvar("yankonl", "1.0-zp-damager", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);
	
	RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamagePost", true);
}

public OnPlayerTakeDamagePost(const iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	if(!is_user_alive(iAttacker))
		return;

	new iHealth = get_user_health(iVictim);
	new iArmor = get_user_armor(iVictim);

	if(zp_get_user_zombie(iAttacker))
	{
		if(zp_get_user_zombie(iVictim))
		{
			client_print(iAttacker, print_center, "Infected!");
			return;
		}

		if(iArmor > 0 && iHealth > 0)
			client_print(iAttacker, print_center, "HP: %d | Armor: %d | DMG: %.f", iHealth, iArmor, flDamage);
		else if(iHealth > 0)
			client_print(iAttacker, print_center, "HP: %d | DMG: %.f", iHealth, flDamage);
		else
			client_print(iAttacker, print_center, "KILLED!");
	}
	else
	{
		if(iHealth > 0)
			client_print(iAttacker, print_center, "HP: %d | DMG: %.f", iHealth, flDamage);
		else
			client_print(iAttacker, print_center, "KILLED!");
	}
}