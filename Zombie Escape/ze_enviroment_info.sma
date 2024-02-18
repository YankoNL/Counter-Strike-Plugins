/*
	[ZE] Enviroment Informer - 1.2

	* Description:
		Shows to everyone in the server who is pressing which buttons on the map.
		Shows to everyone who is breaking breakables (objects, critical path walls, ramps, ect.)
		Displays the health of the breakable to the user dealing damage to it. 

	* Requeriments:
		- AMXX 1.8.3 or higher.

	* Change Log:
		1.0 - First Release 22.11.2023

		1.1 - Anti-Spam
			- Added anti-spam button method (5 seconds)

		1.2 - Map support
			- Added map support for escape maps. (Starting with "ze_")
			- Added map support for custom maps that don't start with "ze_", but are considered as escape maps. (You can add more maps in "ze_maps")
*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

new bool:bPressed[33];

new ze_maps[] = 
{
	"zm_escape_prison",
	"zm_boatescape",
	"zm_osprey_escape",
	"zm_escapetrain",
	"zm_mechanix_escape"
};

new const BREAK_PREFIX[] = "[Breakables]";
new const BUTTON_PREFIX[] = "[Buttons]";

public plugin_init()
{
	register_plugin("[ZE] Enviroment Informer", "1.2", "YankoNL");
	register_cvar("ynl_ZeInfo", "1.2", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	RegisterHam(Ham_TakeDamage, "func_breakable", "OnBreakableTakeDamage", true);
	RegisterHam(Ham_Use, "func_button", "OnButtonPress", true);
}

public OnButtonPress(iButton, iActivator, iCaller, iUseType, Float:fValue)
{
	if(!zp_is_escape_map() || bPressed[iActivator]) return;

	new iMapButtonName[32];
	pev(iButton, pev_target, iMapButtonName, charsmax(iMapButtonName));

	client_print_color(0, print_team_default, "^4%s ^1Player ^3%n ^1pressed ^4%s ", BUTTON_PREFIX, iActivator, iMapButtonName);

	bPressed[iActivator] = true;
	set_task(5.0, "anti_spam", iActivator);
}

public anti_spam(iActivator) bPressed[iActivator] = false;

public OnBreakableTakeDamage(const iEnt, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	if(!zp_is_escape_map() || !is_valid_ent(iEnt) || !is_user_connected(iAttacker))
		return HAM_IGNORED;

	new iBreakable[32];
	pev(iEnt, pev_target, iBreakable, charsmax(iBreakable));

	if(entity_get_float(iEnt, EV_FL_health) <= 0.0)
	{
		client_print(iAttacker, print_center, "%s^nBroken!", BREAK_PREFIX);
		client_print_color(0, print_team_default, "^4%s ^1Player ^3%n ^1broke something", BREAK_PREFIX, iAttacker);
	}
	else
		client_print(iAttacker, print_center, "%s^nHealth: %.f", BREAK_PREFIX, entity_get_float(iEnt, EV_FL_health));

	return HAM_IGNORED;
}

bool:zp_is_escape_map()
{
	static map_name[32];
	get_mapname(map_name, sizeof(map_name));

	if(equal(map_name, "ze_", 3))
		return true;

	for(new i = 0; i < sizeof ze_maps; i++)
		if(equal(map_name, ze_maps[i]))
			return true;

	return false;
}