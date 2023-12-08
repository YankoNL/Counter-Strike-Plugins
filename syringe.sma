#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#define is_flashed(%0)			get_pdata_float(%0, 514) > get_gametime()
#define get_gun_in_hand(%1)	get_pdata_cbase(%1, 373, 5)

#define g_szModelStimpak	"models/test/v_syringe.mdl"
#define g_szSoundStimpak	"weapons/syringe/syringe_inject.wav"

enum _:Cvars
{
	HP_MAX,
	HP_HEAL,
	SOUND
}

new g_eCvars[Cvars]

public plugin_precache()
{
	precache_model(g_szModelStimpak)
	precache_sound(g_szSoundStimpak)
}

public plugin_init()
{
	register_plugin("Health Syringe", "1.3", "YankoNL")

	bind_pcvar_num(create_cvar("syringe_max_hp", "100", FCVAR_NONE, "Syringe max HP heal limit"), g_eCvars[HP_MAX])
	bind_pcvar_num(create_cvar("syringe_heal_hp", "50", FCVAR_NONE, "Syringe healing HP", true, 1.0), g_eCvars[HP_HEAL])
	bind_pcvar_num(create_cvar("syringe_sound", "1", FCVAR_NONE, "Enable or Disable healing sound", true, 0.0, true, 1.0), g_eCvars[SOUND])

	register_clcmd("stimpak", "get_stimpak")
}

public get_stimpak(id)
{
	if(!is_user_alive(id))
		return
	
	if(get_user_health(id) >= g_eCvars[HP_MAX])
		return
				
	new hand_model[128]
	pev(id, pev_viewmodel2, hand_model, charsmax(hand_model))
	
	if(equal(hand_model, g_szModelStimpak))
		return
	
	set_pev(id, pev_viewmodel2, g_szModelStimpak)
	UTIL_PlayWeaponAnimation(id, 0)
	
	set_pdata_float(id, 83, 3.0, 5)
	set_task(2.5, "get_hp", id)
}

public get_hp(id)
{	
	if(!is_user_alive(id))
		return

	ExecuteHamB(Ham_Item_Deploy, get_gun_in_hand(id))
	
	if(!(is_flashed(id)))
		set_fade(id, 0, 255, 0, 25)

	new iHealth = get_user_health(id)

	set_pev(id, pev_health, clamp(iHealth + g_eCvars[HP_HEAL], iHealth, g_eCvars[HP_MAX]))

	if(g_eCvars[SOUND])
		client_cmd(id,"spk items/medshot4.wav")
}

public set_fade(id, r, g, b, a)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
	write_short(1<<12)
	write_short(1<<8)
	write_short(1<<4)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(a)
	message_end()
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
   
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}
