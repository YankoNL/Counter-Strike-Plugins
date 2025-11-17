/*
	Simple Toggle Camera - v 1.2

	1.0 - First release

	1.1 - Small update
		- Added #pragma semicolon to ensures code syntax and correct compiling
		- Added command const to fit more commands easily (and it looks better)

	1.2 - Minor QOL Update
		- Replaced bool with BIT for maximum performance
*/
#define PLUGIN_VERSION "1.2"

#include <amxmodx>
#include <fakemeta>
#include <engine>

#pragma semicolon 1

#if !defined BIT
	#define BIT(%0)			(1<<(%0))
#endif

#define BIT_ADD(%0,%1)		(%0 |= BIT(%1))
#define BIT_SUB(%0,%1)		(%0 &= ~BIT(%1))
#define BIT_VALID(%0,%1)	bool:((%0 & BIT(%1)) ? true : false)

new g_bInThird;

new const g_szCommands[] =
{
	"cam", "camera",
	"say /cam", "say_team /cam",
	"say /camera", "say_team /camera",
};

public plugin_init()
{
	register_plugin("Toggle Camera", PLUGIN_VERSION, "YankoNL");
	register_cvar("ynl_camera", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	register_forward(FM_AddToFullPack, "Fwd_AddToFullPack", true);

	for(new i; i < sizeof g_szCommands; i++)
		register_clcmd(g_szCommands[i], "Cmd_Camera");
}

public plugin_precache()
	precache_model("models/rpgrocket.mdl");

public client_putinserver(id)
	if(BIT_VALID(g_bInThird, id))
		BIT_SUB(g_bInThird, id);

public Fwd_AddToFullPack(es_handle, e, ent, host, hostflags, player, pSe)
	if(player && (ent == host))
		set_es(es_handle, ES_RenderMode, kRenderNormal);

public Cmd_Camera(id)
{
	switch(BIT_VALID(g_bInThird, id))
	{
		case true: BIT_SUB(g_bInThird, id);
		case false: BIT_ADD(g_bInThird, id);
	}

	set_view(id, BIT_VALID(g_bInThird, id) ? CAMERA_3RDPERSON : CAMERA_NONE);
	client_cmd(id,"spk UI/buttonclickrelease.wav");

	return PLUGIN_HANDLED;
}