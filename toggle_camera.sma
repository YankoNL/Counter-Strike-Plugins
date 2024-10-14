#include <amxmodx>
#include <fakemeta>
#include <engine>

#pragma semicolon 1

new bool:g_bInThird[33];

new const g_szCommands[] =
{
	"cam", "camera",
	"say /cam", "say_team /cam",
	"say /camera", "say_team /camera",
};

public plugin_init()
{
	register_plugin("Toggle Camera", "1.1", "YankoNL");
	register_cvar("ynl_camera", "1.1", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	register_forward(FM_AddToFullPack, "Fwd_AddToFullPack", true);

	for(new i; i < sizeof g_szCommands; i++)
		register_clcmd(g_szCommands[i], "Cmd_Camera");
}

public plugin_precache()
	precache_model("models/rpgrocket.mdl");

public client_putinserver(id)
	g_bInThird[id] = false;

public Fwd_AddToFullPack(es_handle, e, ent, host, hostflags, player, pSe)
	if(player && (ent == host))
		set_es(es_handle, ES_RenderMode, kRenderNormal);

public Cmd_Camera(id)
{
	g_bInThird[id] = !g_bInThird[id];
	set_view(id, g_bInThird[id] ? CAMERA_3RDPERSON : CAMERA_NONE);
	client_cmd(id,"spk UI/buttonclickrelease.wav");

	return PLUGIN_HANDLED;
}