#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

new bool:has_NightVision[33], g_NightVisison[33]

public plugin_init()
{
	register_plugin("[ZP] CSO Night Vision","1.0","YankoNL")

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1)
	RegisterHam(Ham_Killed, "player", "OnPlayerDeath")
	register_clcmd("nightvision", "toggle_NightVision")
}

public OnPlayerSpawn(id)
	check_vision(id)

public OnPlayerDeath(id)
	check_vision(id)

public zp_user_infected_post(id)
	check_vision(id)

public zp_user_humanized_post(id)
	check_vision(id)

public client_disconnected(id)
{
	remove_task(id)
	has_NightVision[id] = false
}

public client_connect(id)
	has_NightVision[id] = true

public toggle_NightVision(id)
{
	if(!has_NightVision[id])
		return PLUGIN_CONTINUE
	
	g_NightVisison[id] = 1 - g_NightVisison[id]
	
	if(g_NightVisison[id]) 
	{		
		set_task(0.1, "nv_on", id, _, _, "b")

		client_cmd(id, "spk ^"%s^"", "items/nvg_on.wav")

		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
		if(is_user_alive(id))
		{
			if(zp_get_user_zombie(id) || zp_get_user_nemesis(id))
			{
				write_short((1<<12)*2)	// duration
				write_short((1<<10)*10)	// hold time
				write_short(0x0004)	// fade type
				write_byte(253)	// red
				write_byte(110)	// green
				write_byte(110)	// blue
				write_byte(80)	// alpha
			}
			else
			{
				write_short((1<<12)*2)	// duration
				write_short((1<<10)*10)	// hold time
				write_short(0x0004)	// fade type
				write_byte(10)	// red
				write_byte(150)	// green
				write_byte(10)	// blue
				write_byte(80)	// alpha
			}
		}
		else
		{
			write_short(0)		// duration
			write_short(0)		// hold time
			write_short(0x0000)	// fade type
			write_byte(100)		// red
			write_byte(100)		// green
			write_byte(100)		// blue
			write_byte(255)		// alpha
		}
		message_end()
	}
	else
	{	
		remove_task(id)
		SetLight(id, "f")
		
		client_cmd(id, "spk ^"%s^"", "items/nvg_off.wav")
		
		message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
		write_short(0)		// duration
		write_short(0)		// hold time
		write_short(0x0000)	// fade type
		write_byte(100)		// red
		write_byte(100)		// green
		write_byte(100)		// blue
		write_byte(255)		// alpha
		message_end()
	}
	
	return PLUGIN_CONTINUE
}

public nv_on(id)
	SetLight(id, "1")

stock SetLight(id, szLight[])
{
	if(!is_user_connected(id)) 
		return PLUGIN_CONTINUE
	
	message_begin(MSG_ONE, SVC_LIGHTSTYLE, _, id)
	write_byte(0)
	write_string(szLight)
	message_end()

	return PLUGIN_CONTINUE
}

public check_vision(id)
	if(g_NightVisison[id] != 0)
		toggle_NightVision(id)
