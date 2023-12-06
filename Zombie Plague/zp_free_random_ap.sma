#include <zombieplague>
#include <amxmodx>

#pragma semicolon 1

#define is_user_valid(%1)			(1 <= %1 <= szMaxPlayers)

new szMaxPlayers, bool:iBonus[MAX_PLAYERS + 1] = false;

new const PREFIX[]= "^4[^3Free AP^4]";

public plugin_init()
{
	register_plugin("[ZP] Random Ammo Packs", "1.0", "YankoNL");

	register_clcmd("say /free", "give_map_bonus");
	register_clcmd("say_team /free", "give_map_bonus");

	szMaxPlayers = get_maxplayers();
}

public give_map_bonus(id)
{
	if(iBonus[id])
	{
		client_print_color(id, print_team_default, "%s You've already got your map bonus! Wait till next map!", PREFIX);
		return PLUGIN_HANDLED;
	}
	
	if(is_user_valid(id))
	{
		new iRandom = random_num(5, 70);
		zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + iRandom);
		client_print_color(id, print_team_default, "%s You just got ^3%d ^1AP's bonus!", PREFIX, iRandom);
		iBonus[id] = true;
	}
	return PLUGIN_CONTINUE;
}