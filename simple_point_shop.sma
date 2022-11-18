#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <reapi>

#pragma semicolon 1

new const PREFIX[]= "^4[^1S ^3Point Shop^4]";

const ITEMS_LEFT = 	2;
const ITEMS_LEFT_VIP = 	3;

new const PlayerModels[][] = 
{
	"arctic", "leet", "guerilla", "terror", "gign", "urban", "sas", "gsg9"
};

enum _:ItemNames
{
        HEALTH_ARMOR,
        SPEED_BOOST,
        LOW_GRAVITY,
        INVISIBLE,
        CHAMELEON,
        AWP
}

enum _:ShopInfo
{
	Item_Name[MAX_NAME_LENGTH],
	Item_Cost
};

new bool:is_UsedItem[MAX_PLAYERS + 1][ItemNames];

new const g_eItems[ItemNames][ShopInfo] =
{
	{"200 HP + 200 AP", 20},
	{"Speed Boost", 15},
	{"Lower Gravity", 10},
	{"Invisibility 80%", 25},
	{"Chameleon", 15},
	{"AWP", 100}
};

new g_szPoints[MAX_PLAYERS + 1], g_szVault, bool:g_szVIP[MAX_PLAYERS + 1];
new itemsleft[MAX_PLAYERS + 1], items_bought[MAX_PLAYERS +1] = 0;
//new g_SyncHudObj, g_szMaxPlayers;

public plugin_init()
{
	register_plugin("Simple Point Shop", "1.1", "YankoNL");
	
	register_concmd("shop_give_points", "GivePoints", ADMIN_RCON, "<name/@all> <points>");
	register_concmd("shop_remove_points", "RemovePoints", ADMIN_RCON, "<name> <points>");
	
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "OnPlayerWeaponChange", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKill", true);
	
	register_clcmd("say /shop", "open_shop");
	register_clcmd("say_team /shop", "open_shop");

	register_clcmd("say /points", "show_points");
	register_clcmd("say_team /points", "show_points");
	
	g_szVault = nvault_open("SPointShop_Data");

	//g_szMaxPlayers = get_maxplayers();
	//g_SyncHudObj = CreateHudSyncObj();
	//set_task(1.0, "task_Hud", _, _, _, "b");
}

// 

/*public task_Hud()
{
	for(new id = 1; id <= g_szMaxPlayers; id++)
	{
		if(!is_user_connected(id) || !is_user_alive(id)) continue;

		set_hudmessage(255, 255, 255, 0.01, 0.91, 0, 0.9, 0.9, 0.1, 0.1, -1);
		ShowSyncHudMsg(id, g_SyncHudObj, "Health: %d | Armor: %d | Point%s: %d | Item%s left: %d", get_user_health(id), get_user_armor(id), g_szPoints[id] == 1 ? "" : "s", g_szPoints[id], itemsleft[id] == 1 ? "" : "s", itemsleft[id]);
	}
}*/

public GivePoints(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3)) return PLUGIN_HANDLED;
	
	new arg1[64], arg2[33], points;
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	
	points = str_to_num(arg2);
	if(points <= 0) return PLUGIN_HANDLED;
	
	new AdminName[64];
	get_user_name(id, AdminName, charsmax(AdminName));
	
	if(equal(arg1, "@all"))
	{
		new iPlayers[32], iNum, all_index;
		get_players(iPlayers, iNum, "ch");
		
		for(new i = 0; i < iNum; i++)
		{
			all_index = iPlayers[i];
			g_szPoints[all_index] += points;
			SavePoints(all_index);
		}
		
		client_print_color(0, print_team_default, "%s ^1Admin ^3%s ^1gave ^4%d ^1Point%s to ^3All Players", PREFIX, AdminName, points, points == 1 ? "" : "s");
	}
	else
	{
		new target = cmd_target(id, arg1, CMDTARGET_NO_BOTS);
		if(!target) return PLUGIN_HANDLED;
		
		g_szPoints[target] += points;
		SavePoints(target);
		
		new TargetName[64];
		get_user_name(target, TargetName, charsmax(TargetName));
		
		client_print_color(0, print_team_default, "%s ^1Admin ^3%s ^1gave ^4%d ^1Point%s to ^3%s.", PREFIX, AdminName, points, points == 1 ? "" : "s", TargetName);
	}

	return PLUGIN_HANDLED;
}

public RemovePoints(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3)) return PLUGIN_HANDLED;
	
	new arg1[64], arg2[33], points;
	read_argv(1, arg1, charsmax(arg1));
	read_argv(2, arg2, charsmax(arg2));
	
	new target = cmd_target(id, arg1, CMDTARGET_NO_BOTS);
	if(!target) return PLUGIN_HANDLED;
		
	points = str_to_num(arg2);
	if(points <= 0) return PLUGIN_HANDLED;
	
	new AdminName[64];
	get_user_name(id, AdminName, charsmax(AdminName));

	g_szPoints[target] -= points;
	SavePoints(target);
		
	new TargetName[64];
	get_user_name(target, TargetName, charsmax(TargetName));
		
	client_print_color(0, print_team_default, "%s ^1Admin ^3%s ^1removed ^4%d ^1Point%s from ^3%s.", PREFIX, AdminName, points, points == 1 ? "" : "s", TargetName);
	
	return PLUGIN_HANDLED;
}

public client_authorized(id)
{
	LoadPoints(id);
	
	g_szVIP[id] = is_user_vip(id);
}

public client_disconnected(id)
{
	SavePoints(id);
	
	g_szVIP[id] = false;
}

public OnPlayerKill(iVictim, iAttacker)
{
	if (iVictim == iAttacker || !is_user_connected(iAttacker))
		return HC_CONTINUE;

	if(get_member(iAttacker, m_iTeam) == get_member(iVictim, m_iTeam))
	{
		new lost_points = 20;
			
		g_szPoints[iAttacker] -= lost_points;
		set_dhudmessage(255, 0, 0, -1.0, 0.85, 0, 0.0, 2.0, 0.1, 0.1);
		show_dhudmessage(iAttacker, "[-%d points]", lost_points);
		SavePoints(iAttacker);
			
		client_print_color(iAttacker, print_team_default, "%s ^1You lost^3 %d^4 point%s^1 for killing^3 teammate^1.", PREFIX, lost_points, lost_points == 1 ? "" : "s");
		lost_points = 0;
	}
	else
	{
		new win_points;
		if(get_member(iVictim, m_bHeadshotKilled))
			win_points = g_szVIP[iAttacker] ? 4 : 2;
		else
			win_points = g_szVIP[iAttacker] ? 2 : 1;
			
		if(win_points)
		{
			g_szPoints[iAttacker] += win_points;
			set_dhudmessage(0, 255, 0, -1.0, 0.85, 0, 0.0, 2.0, 0.1, 0.1);
			show_dhudmessage(iAttacker, "[+%d points]", win_points);
			win_points = 0;
			SavePoints(iAttacker);
		}
	}
	return HC_CONTINUE;
}

public show_points(id)
	client_print_color(id, print_team_default, "%s ^1You have ^4%d ^1point%s in your account", PREFIX, g_szPoints[id], g_szPoints[id] == 1 ? "" : "s");


public open_shop(id)
{
	if(get_member(id, m_iTeam) == TEAM_SPECTATOR) 
		return PLUGIN_CONTINUE;
	
	if(!itemsleft[id])
	{
		client_print_color(id, print_team_default, "%s ^1Please ^3wait ^1until ^4next spawn ^1to use the shop again.", PREFIX);
		return PLUGIN_CONTINUE;
	}
	
	if(!is_user_alive(id))
	{
		client_print_color(id, print_team_default, "%s ^1You need to be ^4alive ^1to use the shop!", PREFIX);
		return PLUGIN_CONTINUE;
	}
	
	ShowShop(id);
	return PLUGIN_CONTINUE;
}

public ShowShop(id)
{
	new iTitle[256];
	formatex(iTitle, charsmax(iTitle), "\rSimple Point Shop^n ^n\yYou have \r%i \ypoint%s^n\yItems Bought: %d", g_szPoints[id], g_szPoints[id] == 1 ? "" : "s", items_bought[id]);

	new menu = menu_create(iTitle, "ShopHandler");
	
	for(new i = 0; i < sizeof(g_eItems); i++)
	{
		new tempid[10], g_szItem[64];
		num_to_str(i, tempid, charsmax(tempid));

		if(is_UsedItem[id][i])
			formatex(g_szItem, charsmax(g_szItem), "\d%s \y[Owned]", g_eItems[i][Item_Name]);
		else
			formatex(g_szItem, charsmax(g_szItem), "%s%s \r[%i point%s]", g_szPoints[id] >= g_eItems[i][Item_Cost] ? "\w" : "\d", g_eItems[i][Item_Name], g_eItems[i][Item_Cost], g_eItems[i][Item_Cost] == 1 ? "" : "s");

		menu_additem(menu, g_szItem, tempid, _, menu_makecallback("ShopCallback"));
	}
	
	menu_display(id, menu, 0);
}

public ShopCallback(id, menu, item)
{
	if(g_szPoints[id] < g_eItems[item][Item_Cost] || is_UsedItem[id][item])
		return ITEM_DISABLED;

	return ITEM_ENABLED;
}

public ShopHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_alive(id)) return PLUGIN_HANDLED;
	
	switch(item)
	{
		case HEALTH_ARMOR:
		{
			set_entvar(id, var_health, 200.0);
			rg_set_user_armor(id, 200, ARMOR_VESTHELM);
		}
		case SPEED_BOOST:
		{
			set_entvar(id, var_maxspeed, 350.0);
		}
		case LOW_GRAVITY:
		{
			set_entvar(id, var_gravity, 0.6);
		}
		case INVISIBLE:
		{
			new iPercent = 20; 
			new iAlphaAmount = iPercent * 255 / 100; 
			rg_set_user_rendering(id, kRenderFxNone, {0.0, 0.0, 0.0}, kRenderTransAlpha, float(iAlphaAmount));
		}
		case CHAMELEON:
		{
			rg_set_user_model(id, PlayerModels[get_member(id, m_iTeam) == TEAM_CT? random_num(0, 3) : random_num(4,7)]);
		}
		case AWP:
		{
			rg_give_item_ex(id, "weapon_awp", GT_REPLACE, 30);
		}
	}
	ShopData(id, item);
		
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

stock ShopData(id, g_Item)
{
	if(g_szPoints[id] < g_eItems[g_Item][Item_Cost])
		client_print_color(id, print_team_default, "%s ^1You don't have enough points for ^4%s^1.", PREFIX, g_eItems[g_Item][Item_Name]);
	else
	{
		itemsleft[id]--;
		items_bought[id]++;
		is_UsedItem[id][g_Item] = true;
	
		g_szPoints[id] -= g_eItems[g_Item][Item_Cost];
		client_print_color(id, print_team_default, "%s ^1You bought yourself ^4%s^1.", PREFIX, g_eItems[g_Item][Item_Name]);

		set_dhudmessage(200, 200, 0, -1.0, 0.80, 0, 0.0, 3.0, 0.1, 0.1);
		if(itemsleft[id] == 0)
			show_dhudmessage(id, "[No Items Left]");
		else
			show_dhudmessage(id, "[Items left: %d]", itemsleft[id]);
	}
}

public OnPlayerSpawn(id)
	if(is_user_alive(id))
		Reset(id);

public OnPlayerWeaponChange(id)
{
	if (!is_user_alive(id))
		return HC_CONTINUE;

	if (is_UsedItem[id][SPEED_BOOST])
		set_entvar(id, var_maxspeed, 350.0);

	if (is_UsedItem[id][LOW_GRAVITY])
		set_entvar(id, var_gravity, 0.6);

	return HC_CONTINUE;
}

stock Reset(id)
{
	for(new i = 0; i < sizeof(g_eItems); i++)
		is_UsedItem[id][i] = false;
	if(is_user_vip(id))
		itemsleft[id] = ITEMS_LEFT_VIP;
	else
		itemsleft[id] = ITEMS_LEFT;

	items_bought[id] = 0;
	
	remove_task(id);
	
	rg_reset_maxspeed(id);
	set_entvar(id, var_gravity, 1.0);
	rg_set_user_rendering(id);
	rg_reset_user_model(id);
}

public LoadPoints(id)
{
	if(!is_user_bot(id) && !is_user_hltv(id))
	{
		new vaultdata[256], points[33], UserName[33];
		get_user_name(id, UserName, charsmax(UserName));

		format(vaultdata, charsmax(vaultdata), "%i#", g_szPoints[id]);
		nvault_get(g_szVault, UserName, vaultdata, 255);
		
		replace_all(vaultdata, 255, "#", " ");
		parse(vaultdata, points, 32);
		
		g_szPoints[id] = str_to_num(points);
	}
}

public SavePoints(id)
{
	if(!is_user_bot(id) && !is_user_hltv(id))
	{
		new vaultdata[256], UserName[33];
		get_user_name(id, UserName, charsmax(UserName));

		format(vaultdata, charsmax(vaultdata), "%i#", g_szPoints[id]);
		nvault_set(g_szVault, UserName, vaultdata);
	}
}

stock rg_give_item_ex(id, weapon[], GiveType:type = GT_APPEND, amount = 0)
{
	rg_give_item(id, weapon, type);
	if (amount)
		rg_set_user_bpammo(id, rg_get_weapon_info(weapon, WI_ID), amount);
}

// example: rg_set_user_rendering(id, kRenderFxGlowShell, {255,0,0}, kRenderNormal, 20.0);
stock rg_set_user_rendering(index, fx = kRenderFxNone, {Float,_}:color[3] = {0.0,0.0,0.0}, render = kRenderNormal, Float:amount = 0.0)
{
	set_entvar(index, var_renderfx, fx);
	set_entvar(index, var_rendercolor, color);
	set_entvar(index, var_rendermode, render);
	set_entvar(index, var_renderamt, amount);
}

bool:is_user_vip(id)
	return bool:(get_user_flags(id) & ADMIN_RESERVATION);
