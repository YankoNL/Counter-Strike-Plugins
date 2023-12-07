/*	
	[ZP] Fire In The Hole

	* Description:
		Shows to everyone in the server what grenade is thrown by who.
		Blocks the radio sound the player emits when throwing grenades.

	* Requeriments:
		- AMXX 1.8.3 or higher.
		- ReAPI Module

	* Change Log:
		1.0 - First Release 22.11.2023
			
*/

#include <amxmodx>
#include <reapi>

native zp_get_user_zombie(id)

public plugin_init()
{
	register_plugin("[ZP] Fire In The Hole", "1.0", "YankoNL")

	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "ThrowGrenade_Pre", .post = false);
	RegisterHookChain(RG_CBasePlayer_Radio, "Radio_Pre", .post = false);
}

public Radio_Pre(const iPlayer, const szMessageId[], const szMessageVerbose[], iPitch, bool:bShowIcon)
{
	#pragma unused iPlayer, szMessageId, iPitch, bShowIcon
	
	if (szMessageVerbose[0] == EOS)
		return HC_CONTINUE;
	
	if (szMessageVerbose[3] == 114) // 'r'
		return HC_SUPERCEDE;
	
	return HC_CONTINUE;
}

public ThrowGrenade_Pre(const id, const grenade, const Float:vecSrc[3], const Float:vecThrow[3], const Float:time, const usEvent)
{
	switch(get_member(grenade, m_iId))
	{
		case WEAPON_HEGRENADE:
			client_print_color(0, print_team_red, "^4(Radio) ^3%n^1: Throwing a %s", id, zp_get_user_zombie(id) ? "^4Infection Bomb" : "^3Fire")
		case WEAPON_FLASHBANG:
			client_print_color(0, print_team_blue, "^4(Radio) ^3%n^1: Throwing a ^3Frost", id)
		case WEAPON_SMOKEGRENADE:
			client_print_color(0, print_team_grey, "^4(Radio) ^3%n^1: Throwing a ^3Light", id)
	}
}