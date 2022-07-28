#include <amxmodx>
#include <fakemeta>
#include <engine>

new bool:g_bInThird[33]

public plugin_init()
{
	register_plugin("Toggle Camera", "1.0", "YankoNL")

	register_forward(FM_AddToFullPack, "Fwd_AddToFullPack", 1)

	register_clcmd("say /cam", "Cmd_Camera")
	register_clcmd("say_team /cam", "Cmd_Camera")
}

public plugin_precache()
	precache_model("models/rpgrocket.mdl")

public client_putinserver(id)
	g_bInThird[id] = false

public Fwd_AddToFullPack (es_handle, e, ent, host, hostflags, player, pSe )
	if(player && (ent == host))
		set_es(es_handle, ES_RenderMode, kRenderNormal)

public Cmd_Camera(id)
{
	g_bInThird[id] = !g_bInThird[id]
	set_view(id, g_bInThird[id] ? CAMERA_3RDPERSON : CAMERA_NONE)
	client_cmd(id,"spk UI/buttonclickrelease.wav")
	client_print(id, print_center, "Camera Mode: %s Person", g_bInThird[id] ? "3rd" : "1st")

	return PLUGIN_HANDLED
}
