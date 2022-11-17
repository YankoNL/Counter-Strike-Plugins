#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <nvault>
#include <reapi>

#pragma semicolon 1

new const PREFIX[]= "^4[^1S ^3Point Shop^4]";

const ITEMS_LEFT = 	2;
new const PlayerModels[][] = 
{
	"arctic", "leet", "guerilla", "terror", "gign", "urban", "sas", "gsg9"
};

enum Shop_Info
{
	Item_Name[33],
	Item_Cost
};

new bool:is_UsedItem[][33];
new const iShop[][Shop_Info] =
{
	0,
	{"200 HP + 200 AP", 20},
	{"Speed Boost", 15},
	{"Low Gravity", 10},
	{"Invisible", 25},
	{"Chameleon", 15}
};

new g_szPoints[33], g_szVault, bool:g_szVIP[33], itemsleft[33];
// new g_SyncHudObj, g_szMaxPlayers;

public plugin_init()
{
	register_plugin("Simple Point Shop", "1.0", "YankoNL");
	
	register_concmd("shop_give_points", "GivePoints", ADMIN_RCON, "<name/@all> <points>");
	register_concmd("shop_remove_points", "RemovePoints", ADMIN_RCON, "<name> <points>");
	
	register_event("DeathMsg", "EventDeath", "a");
	register_event("CurWeapon", "eventCurWeapon", "be", "1=1");
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawn", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKill", true);
	
	register_clcmd("say /shop", "open_shop");
	register_clcmd("say_team /shop", "open_shop");
	
	g_szVault = nvault_open("SPointShop_Data");

	/*g_szMaxPlayers = get_maxplayers();
	g_SyncHudObj = CreateHudSyncObj();
	set_task(1.0, "task_Hud", _, _, _, "b");*/
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
		
		client_print_color(0, print_team_default, "%s ^1ADMIN:^3 %s^1 gave^4 %d^1 Point%s to^3 All Players", PREFIX, AdminName, points, points == 1 ? "" : "s");
	}
	else
	{
		new target = cmd_target(id, arg1, CMDTARGET_NO_BOTS);
		if(!target) return PLUGIN_HANDLED;
		
		g_szPoints[target] += points;
		SavePoints(target);
		
		new TargetName[64];
		get_user_name(target, TargetName, charsmax(TargetName));
		
		client_print_color(0, print_team_default, "%s ^1ADMIN:^3 %s^1 gave^4 %d^1 Point%s to^3 %s.", PREFIX, AdminName, points, points == 1 ? "" : "s", TargetName);
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
		
	client_print_color(0, print_team_default, "%s ^1ADMIN:^3 %s^1 removed^4 %d^1 Point%s from^3 %s.", PREFIX, AdminName, points, points == 1 ? "" : "s", TargetName);
	
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
		set_dhudmessage(255, 0, 0, -1.0, 0.85, 0, 0.0, 3.0, 0.1, 0.1);
		show_dhudmessage(iAttacker, "-%d", lost_points);
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
			set_dhudmessage(0, 255, 0, -1.0, 0.85, 0, 0.0, 3.0, 0.1, 0.1);
			show_dhudmessage(iAttacker, "+%d", win_points);
			win_points = 0;
			SavePoints(iAttacker);
		}
	}
	return HC_CONTINUE;
}

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
	formatex(iTitle, charsmax(iTitle), "\rSimple Point Shop");

	new menu = menu_create(iTitle, "ShopHandler");
	
	for(new i = 1; i < sizeof(iShop); i++)
	{
		new tempid[10], g_szItem[64];
		num_to_str(i, tempid, charsmax(tempid));
		
		if(g_szPoints[id] < iShop[i][Item_Cost])
			formatex(g_szItem, charsmax(g_szItem), "\d%s [%d point%s]", iShop[i][Item_Name], iShop[i][Item_Cost], iShop[i][Item_Cost] == 1 ? "" : "s");

		else if(is_UsedItem[i][id])
			formatex(g_szItem, charsmax(g_szItem), "\d%s \y[Owned]", iShop[i][Item_Name]);

		else
			formatex(g_szItem, charsmax(g_szItem), "\y%s \w[\r%d \ypoint%s\w]", iShop[i][Item_Name], iShop[i][Item_Cost], iShop[i][Item_Cost] == 1 ? "" : "s");

		menu_additem(menu, g_szItem, tempid, _, menu_makecallback("ShopCallback"));
	}
	
	menu_display(id, menu, 0);
}

public ShopCallback(id, menu, item)
{
	new g_szAccess, g_szInfo[3], g_szCallback;
	menu_item_getinfo(menu, item, g_szAccess, g_szInfo, charsmax(g_szInfo), _, _, g_szCallback);
	
	if(g_szPoints[id] < iShop[str_to_num(g_szInfo)][Item_Cost] || is_UsedItem[str_to_num(g_szInfo)][id])
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
	
	new iData[6], iName[63], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, iData, charsmax(iData), iName, charsmax(iName), iCallback);
	
	if(!is_user_alive(id)) return PLUGIN_HANDLED;
	new g_szData = str_to_num(iData);
	
	switch(g_szData)
	{
		case 1:
		{
			set_entvar(id, var_health, 200);
			rg_set_user_armor(id, 200, ARMOR_VESTHELM);
			
			ShopData(id, g_szData);
		}
		case 2:
		{
			set_user_maxspeed(id, 700.0);
			client_cmd(id, "cl_forwardspeed 700");
			ShopData(id, g_szData);
		}
		case 3:
		{
			set_user_gravity(id, 0.6);
			ShopData(id, g_szData);
		}
		case 4:
		{
			set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransColor, 60);
			ShopData(id, g_szData);
		}
		case 5:
		{
			rg_set_user_model(id, PlayerModels[get_member(id, m_iTeam) == TEAM_CT? random_num(0, 3) : random_num(4,7)]); 				
			ShopData(id, g_szData);
		}
	}
		
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

stock ShopData(id, g_Item)
{
	itemsleft[id]--;
	is_UsedItem[g_Item][id] = true;
	
	g_szPoints[id] -= iShop[g_Item][Item_Cost];
	client_print_color(id, print_team_default, "%s ^1You bought yourself ^4%s^1.", PREFIX, iShop[g_Item][Item_Name]);
}

public OnPlayerSpawn(id)
	if(is_user_alive(id))
		Reset(id);

public eventCurWeapon(id)
	if(is_UsedItem[2][id]) 
		set_user_maxspeed(id, 700.0);

stock Reset(id)
{
	for(new i = 1; i < sizeof(iShop); i++)
		is_UsedItem[i][id] = false;
	
	itemsleft[id] = ITEMS_LEFT;
	
	remove_task(id);
	
	set_user_maxspeed(id, 250.0);
	client_cmd(id, "cl_forwardspeed 400");

	set_user_gravity(id, 1.0);
	
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255);
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

bool:is_user_vip(id)
	return bool:(get_user_flags(id) & ADMIN_RESERVATION);
