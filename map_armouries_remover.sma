#include <amxmodx>
#include <engine>

#define PLUGIN_NAME "Map Armouries Remover"

public plugin_init()
{
	register_plugin(PLUGIN_NAME, "1.0", "YankoNL")
	register_cvar("yankonl", "1.0-armouries-remover", FCVAR_SERVER|FCVAR_UNLOGGED|FCVAR_SPONLY);

	remove_armouries()
}

remove_armouries()
{
	new iEntity, iRemovedEnt = 0
	while((iEntity = find_ent_by_class(iEntity, "armoury_entity")))
	{
		remove_entity(iEntity)
		iRemovedEnt++
	}

	server_print("[%s] Removed %d weapon%s from the map.", PLUGIN_NAME, iRemovedEnt, iRemovedEnt != 1 ? "s" : "")
}