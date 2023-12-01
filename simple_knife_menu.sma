#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

enum _:KnifeInfo
{
	Knife_Name[MAX_NAME_LENGTH],
	Float:Knife_Speed,
	Float:Knife_Gravity,
	Float:Knife_Damage,
	Knife_Flag,
	Knife_ModelV[64],
	Knife_ModelP[64]
};

new g_eSelected[MAX_PLAYERS + 1];

// Settings Here - Look at the examples and edit your data
new const PREFIX[]= "^4[^3Simple Knife^4]";

new const g_eKnife[][KnifeInfo] =
{	// Knife Name, Speed, Gravity, *Damage, Admin Flag, path with v_ model, path with p_ model
	{"Damage Knife", 260.0, 1.0, 2.5, 0, "models/simple_knife/v_blink_knife.mdl", "models/simple_knife/p_blink_knife.mdl"},
	{"Speed Knife", 330.0, 1.0, 1.0, 0, "models/simple_knife/v_frost_knife.mdl", "models/simple_knife/p_frost_knife.mdl"},
	{"Gravity Knife", 260.0, 0.55, 1.0, 0, "models/simple_knife/v_leap_knife.mdl", "models/simple_knife/p_leap_knife.mdl"},
	{"Ninja Knife (balanced)", 290.0, 0.75, 1.5, 0, "models/simple_knife/v_ninja_knife.mdl", "models/simple_knife/p_ninja_knife.mdl"},
	{"Slap Axe", 300.0, 0.60, 2.0, ADMIN_LEVEL_A, "models/simple_knife/v_slap_knife.mdl", "models/simple_knife/p_slap_knife.mdl"}
};
// End of Setting - Change bellow at your own risk

public plugin_init()
{
	register_plugin("Simple Knife Menu", "1.4", "YankoNL");
	register_clcmd("say /knife","knife_menu");
	register_event("CurWeapon","knife_stats_set","be","1=1");
	RegisterHam(Ham_TakeDamage, "player", "PreTakeDamage", false);
}

public client_putinserver(id)
	g_eSelected[id] = 0;

public plugin_precache()
{
	for(new i; i < sizeof(g_eKnife); i++)
	{
		if(g_eKnife[i][Knife_ModelV][0])
			precache_model(g_eKnife[i][Knife_ModelV]);
			
		if(g_eKnife[i][Knife_ModelP][0])
			precache_model(g_eKnife[i][Knife_ModelP]);
	}
}

public knife_menu(id)
{
	new iTitle[256];
	formatex(iTitle, charsmax(iTitle), "\r[SK] \wKnife Menu");

	new menu = menu_create(iTitle, "KnifeMenuHandler");
	
	for(new i = 0; i < sizeof(g_eKnife); i++)
	{
		new szKey[10], g_szItem[64];
		num_to_str(i, szKey, charsmax(szKey));

		if(g_eSelected[id] == i)
			formatex(g_szItem, charsmax(g_szItem), "\d%s \y[Selected]", g_eKnife[i][Knife_Name]);
		else if(g_eKnife[i][Knife_Flag] != 0)
			formatex(g_szItem, charsmax(g_szItem), "%s \r[Special]", g_eKnife[i][Knife_Name]);
			
		else
			formatex(g_szItem, charsmax(g_szItem), "%s", g_eKnife[i][Knife_Name]);

		menu_additem(menu, g_szItem, szKey);
	}

	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	menu_display(id, menu, 0);
	return PLUGIN_CONTINUE;
}

public KnifeMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	new szKey[4], iUnused;
	menu_item_getinfo(menu, item, iUnused, szKey, charsmax(szKey), .callback = iUnused);
		
	new iKey = str_to_num(szKey);

	if(g_eSelected[id] == iKey)
		client_print_color(id, print_team_default, "%s ^1Already selected!", PREFIX);
	else if(~get_user_flags(id) & g_eKnife[iKey][Knife_Flag])
		client_print_color(id, print_team_default, "%s ^1This Knife is Locked! Specific ^4flag ^1needed.", PREFIX);
	else
	{
		g_eSelected[id] = iKey;
		knife_stats_set(id);
		client_print_color(id, print_team_default, "%s ^1You have selected ^3%s", PREFIX, g_eKnife[iKey][Knife_Name]);
		emit_sound(id, CHAN_AUTO, "items/gunpickup2.wav", 0.7, ATTN_NORM, 0, PITCH_NORM);
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public knife_stats_set(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	if(get_user_weapon(id) == CSW_KNIFE && is_user_alive(id))
	{
		set_pev(id, pev_viewmodel2, g_eKnife[g_eSelected[id]][Knife_ModelV]);
		set_pev(id, pev_weaponmodel2, g_eKnife[g_eSelected[id]][Knife_ModelP]);
		set_user_maxspeed(id, g_eKnife[g_eSelected[id]][Knife_Speed]);
		set_user_gravity(id, g_eKnife[g_eSelected[id]][Knife_Gravity]);
	}
	else
		set_user_gravity(id, 1.0);

	return PLUGIN_CONTINUE;
}

public PreTakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iDamageBits)
	if(get_user_weapon(iAttacker) == CSW_KNIFE && is_user_alive(iAttacker))
		SetHamParamFloat(4, fDamage * g_eKnife[g_eSelected[iAttacker]][Knife_Damage]);