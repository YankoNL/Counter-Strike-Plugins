#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

public plugin_init()
{
	register_plugin("[ZP] Addon: Damager", "1.0", "YankoNL");
	
	RegisterHam(Ham_TakeDamage, "player", "Player_TakeDamage", true);
}

public Player_TakeDamage(const iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
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
			client_print(iAttacker, print_center, "HP: %d | Armor: %d", iHealth, iArmor);
		else if(iHealth > 0)
			client_print(iAttacker, print_center, "HP: %d", iHealth, flDamage);
		else
			client_print(iAttacker, print_center, "KILLED!");
	}
	else
	{
		if(iHealth)
			client_print(iAttacker, print_center, "HP: %d | DMG: %.f", iHealth, flDamage);
		else
			client_print(iAttacker, print_center, "KILLED!");
	}
}