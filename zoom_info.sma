#include <amxmodx>
#include <fakemeta>

#define HUDMSG_X -1.00
#define HUDMSG_Y 0.9

new g_iHudSync;

public plugin_init()
{
	register_plugin("Zoom Distance", "1.1", "YankoNL");
	register_forward(FM_PlayerPostThink, "fwPlayerPostThink");

	g_iHudSync = CreateHudSyncObj();
}

public fwPlayerPostThink(id)
{
	static fov		// Made for nipers only (AUG and SG552 zoom FOV was 55 I think)
	if((fov = pev(id, pev_fov)) >= 50 || !fov)
		return FMRES_IGNORED

	static Float:units, player
	units = get_user_aiming(id, player, _:units)

	if(!is_user_alive(player))	// Aiming at something - default yellow (255, 255, 0)
		set_hudmessage(255, 255, 0, HUDMSG_X, HUDMSG_Y, 0, 0.0, 0.1, 0.0, 0.0, 4)

	else if(get_user_team(id) == get_user_team(player)) // Aiming at a teammate - default green (0, 255, 0)
		set_hudmessage(0, 255, 0, HUDMSG_X, HUDMSG_Y, 0, 0.0, 0.1, 0.0, 0.0, 4)

	else	// Aiming at an enemy - default red (255, 0, 0)
		set_hudmessage(255, 0, 0, HUDMSG_X, HUDMSG_Y, 0, 0.0, 0.1, 0.0, 0.0, 4)

	ShowSyncHudMsg(id, g_iHudSync, "Distance: %.1fm", UnitsToMeters(units))

	return FMRES_IGNORED
}

stock Float:UnitsToMeters(Float:iNum)
{
	new Float:iMeters = iNum * 0.0254

	return iMeters;
}