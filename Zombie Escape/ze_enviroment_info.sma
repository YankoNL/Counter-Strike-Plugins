#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

new bool:bPressed[33]

new const BREAK_PREFIX[] = "[Breakables]"
new const BUTTON_PREFIX[] = "[Buttons]"

public plugin_init()
{
	register_plugin("[ZE] Enviroment Info", "1.1", "YankoNL")

	RegisterHam(Ham_TakeDamage, "func_breakable", "OnBreakableTakeDamage", true)
	RegisterHam(Ham_Use, "func_button", "OnButtonPress", true)

	register_cvar("yankonl", "ze-1.1-env-info", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);
}

public OnButtonPress(iButton, iActivator, iCaller, iUseType, Float:fValue)
{
	if(bPressed[iActivator]) return;

	new iMapButtonName[32];
	pev(iButton, pev_target, iMapButtonName, charsmax(iMapButtonName))

	client_print_color(0, print_team_default, "^4%s ^1Player ^3%n ^1pressed ^4%s ", BUTTON_PREFIX, iActivator, iMapButtonName)

	bPressed[iActivator] = true
	set_task(5.0, "anti_spam", iActivator)
}

public anti_spam(iActivator) bPressed[iActivator] = false

public OnBreakableTakeDamage(const iEnt, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	if(!is_valid_ent(iEnt) || !is_user_connected(iAttacker))
		return HAM_IGNORED;

	new iBreakable[32];
	pev(iEnt, pev_target, iBreakable, charsmax(iBreakable))

	if(entity_get_float(iEnt, EV_FL_health) <= 0.0)
	{
		client_print(iAttacker, print_center, "%s^nBroken!", BREAK_PREFIX)
		client_print_color(0, print_team_default, "^4%s ^1Player ^3%n ^1broke something", BREAK_PREFIX, iAttacker);
	}
	else
		client_print(iAttacker, print_center, "%s^nHealth: %.f", BREAK_PREFIX, entity_get_float(iEnt, EV_FL_health));

	return HAM_IGNORED;
}