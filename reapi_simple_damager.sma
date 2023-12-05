#include <amxmodx>
#include <reapi>

public plugin_init() 
{
	register_plugin("[ReAPI] Super Simple Damager", "1.0", "YankoNL");
	
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "OnPlayerTakeDamagePost", true);
}

public OnPlayerTakeDamagePost(const iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	if(!is_user_connected(iAttacker) || !rg_is_player_can_takedamage(iAttacker, iVictim))
		return HC_CONTINUE;

	new Float:iVicHealth;
	get_entvar(iVictim, var_health, iVicHealth);

	if(iVicHealth > 0.0)
		client_print(iAttacker, print_center, "HP: %.f | DMG: %.f", iVicHealth, flDamage);
	else
		client_print(iAttacker, print_center, "KILLED!");

	return HC_CONTINUE;
}