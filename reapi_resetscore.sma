#include <amxmodx>
#include <reapi>

public plugin_init()
{
	register_plugin("[ReAPI] Simple Reset Score", "1.0", "YankoNL")
	
	register_clcmd("say /rs", "Cmd_ResetScore")
	register_clcmd("say_team /rs", "Cmd_ResetScore")
}

public Cmd_ResetScore(id)
{
	set_entvar(id, var_frags, 0.0)
	set_member(id, m_iDeaths, 0)
	
	message_begin(MSG_ALL, 85)
	write_byte(id) 
	write_short(0)
	write_short(0)
	write_short(0)
	write_short(0)
	message_end()
	
	//client_print_color(id, print_chat, "^4[^3Reset Score^4] ^1Your score has been reset")
	client_print_color(0, print_chat, "^4[^3Reset Score^4] ^1Player ^3%n ^1has just reset his score!", id)
	return PLUGIN_CONTINUE
}