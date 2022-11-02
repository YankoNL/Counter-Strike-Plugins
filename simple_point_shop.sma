#include <amxmodx>
#include <fun>
#include <reapi>

new bool:is_half_invisible[33] = false
new bool:is_invisible[33] = false
new iJumps[33] = 0
new g_eItem[33]

enum Infos
{
	Name[32],
	Price
}
new const g_eItems[][Infos] =
{
	{"100 Health", 5},
	{"200 Health", 10},
	{"100 Armor", 4},
	{"200 Armor", 8},
	{"Invisibility 50 %", 20},
	{"Invisibility 100 %", 60},
	{"Godmode (15 sec)", 40},
	{"Godmode (30 sec)", 70},
	{"Multi-jump (x4)", 25},
	{"Silent walk", 30},
	{"Speed Boost", 40},
	{"Low Gravity", 20}
}

new iPoints[33]
new jumps_value[33]
new has_gItem[33]

public plugin_init()
{
	register_plugin("Simple Point Shop", "0.1-Beta", "YankoNL")
	register_clcmd("say /shop", "open_shop")
	register_clcmd("team_say /shop", "open_shop")
	register_clcmd("say /points", "show_points")
	register_clcmd("team_say /points", "show_points")

	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKill", true)
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", true)
	RegisterHookChain(RG_CBasePlayer_Jump, "Fw_PlayerJump_Pre", 0)
}

public client_connected(id)
{
	has_gItem[id] = -1
	iJumps[id] = 0
}

public client_disconnected(id)
{
	has_gItem[id] = -1
	iJumps[id] = 0
}

public OnPlayerKill(iVictim, iAttacker)
{
	if(iAttacker && iVictim)
		iPoints[iAttacker] += 1
}

public OnPlayerSpawn(id)
{
	if(!is_user_alive(id))
		return HC_CONTINUE

	set_user_rendering(id)
	//set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)

	return HC_CONTINUE
}

public show_points(id)
	client_print_color(id, print_team_default, "^4[^3RSP Shop^4] ^1You have ^4%d ^1points. ", iPoints[id])

public open_shop(id)
{
	if(!is_user_alive(id))
		client_print_color(id, print_team_default, "^4[^3RSP Shop^4] ^1You have to be ^4alive ^1.")

	new iMenu = menu_create("Point Shop", "Shop_Handler")
	new szItem[64]
	
	for(new szKey[4], i; i < sizeof(g_eItems); i++)
	{
		if(g_iWeapon[id] == i)
			formatex(szItem, charsmax(szItem), "\d%s \y[Owned]", g_eItems[i][Name])
		else
			formatex(szItem, charsmax(szItem), "%s%s \r[%d points]", iPoints[id] >= g_eItems[i][Price] ? "\w" : "\d", g_eItems[i][Name], g_eItems[i][Price])
				
		num_to_str(i, szKey, charsmax(szKey))
		menu_additem(iMenu, szItem, szKey)
	}
		
	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public Shop_Handler(id, iMenu, iItem)
{
	if(iItem != MENU_EXIT && is_user_alive(id))
	{
		new szKey[4], iUnused
		menu_item_getinfo(iMenu, iItem, iUnused, szKey, charsmax(szKey), .callback = iUnused)
		
		new iKey = str_to_num(szKey)

		if(g_eItem[id] == iKey)
			client_print(id, print_center, "[S-Point Shop]^nYou already have thsi item!")
		else
		{
			if(iPoints[id] < g_eItems[iKey][Price])
				client_print(id, print_center, "[S-Point Shop]^nNot enough points. You need %d more!", g_eItems[iKey][Price] - iPoints[id])
			else
			{
				iPoints[id] -= g_eItems[iKey][Price]
				client_print_color(id, print_team_default, "^4[^3S-Point Shop^4] ^1You have bought ^3%s ^1for ^4%d points", g_eItems[iKey][Name], g_eItems[iKey][Price])	// You have bought ^3%s ^1for ^4%i$
				g_eItem[id] = iKey

				set_item(id, g_eItem[id])
			}
		}
	}
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}


set_item(id, item)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_HANDLED

	switch(item)
	{
		case 0:
			set_entvar(id, var_health, get_entvar(id, var_health) + 100)

		case 1:
			set_entvar(id, var_health, get_entvar(id, var_health) + 200)

		case 2:
			rg_set_user_armor(id, rg_get_user_armor(id) + 100, ARMOR_VESTHELM)

		case 3:
			rg_set_user_armor(id, rg_get_user_armor(id) + 200, ARMOR_VESTHELM)

		case 4:
		{
			if(!is_half_invisible[id])
			{
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 120)
				is_half_invisible[id] = true
			}
			else
				iHave(id)
		}
		case 5:
		{
			if(!is_invisible[id])
			{
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0)
				is_half_invisible[id] = true
				is_invisible[id] = true
			}
			else
				iHave(id)
		}
		case 6:
		{
			if(!get_user_godmode(id))
			{
				set_user_godmode(id, 1)
				set_task(15.0, "remove_short_gm", 24680 + id)
			}
			else
				iHave(id)
		}
		case 7:
		{
			if(!get_user_godmode(id))
			{
				set_user_godmode(id, 1)
				set_task(30.0, "remove_long_gm", 13579 + id)
			}
			else
				iHave(id)
		}
		case 8:
			if(jumps_value[id] < 1)
				jumps_value[id] = 3
			else
				iHave(id)
		case 9:
			rg_set_user_footsteps(id, true)

		case 10:
			set_user_maxspeed(id,  350.0)

		case 11:
			set_user_gravity(id, 0.6)
	}

	return PLUGIN_HANDLED
}

public remove_short_gm(id)
{
	id -= 24680
	set_user_godmode(id, 0)
}

public remove_long_gm(id)
{
	id -= 13579
	set_user_godmode(id, 0)
}


public Fw_PlayerJump_Pre(id)
{
	if (!is_user_alive(id))
		return HC_CONTINUE

	new iFlags = get_entvar(id, var_flags)

	if (iFlags & FL_WATERJUMP || get_entvar(id, var_waterlevel) >= 2 || !(get_member(id, m_afButtonPressed) & IN_JUMP))
		return HC_CONTINUE

	if (iFlags & FL_ONGROUND)
	{
		iJumps[id] = 0
		return HC_CONTINUE
	}

	if (++iJumps[id] <= jumps_value[id])
	{
		new Float:fVelocity[3]
		get_entvar(id, var_velocity, fVelocity)
		fVelocity[2] = 268.328157
		set_entvar(id, var_velocity, fVelocity)
			
		return HC_CONTINUE
	}

	return HC_CONTINUE
}

public iHave(id)
	client_print(id, print_center, "[S-Point Shop]^nYou already have thsi item!")
/*
public iRemover(id)
{
	iJumps[id] = 0
	set_user_rendering(id, kRenderGlow, 0, 0, 0, kRenderTransAlpha, 100)
	set_user_godmode(id, 0)
	rg_set_user_footsteps(id, false)
	rg_reset_maxspeed(id)
	set_user_gravity(id, 1.0)
}*/
