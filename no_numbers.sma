#include <amxmodx>

#define MAX_NUMBERS 10

public plugin_init()
{
	register_plugin("NoNumbers", "1.0", "YankoNL")
	register_clcmd("say", "OnSay")
	register_clcmd("say_team", "OnSay")
}

public OnSay(id)
{
	static szArgs[192]
	read_args(szArgs, charsmax(szArgs))
	return has_advertisement(szArgs) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	new szName[32]
	get_user_name(id, szName, charsmax(szName))
	
	if(has_advertisement(szName))
		server_cmd("kick #%i ^"Too many numbers in your name.^"", get_user_userid(id))
}

bool:has_advertisement(const szString[])
{
	static iCount, i
	iCount = 0
	
	for(i = 0; i < strlen(szString); i++)
	{
		if(isdigit(szString[i]))
			iCount++
	}
	
	return iCount >= MAX_NUMBERS
}
