/*================================================================================
 [Plugin Log]
 
	v1.0(22.12.2018)
	-Removed shadow - Fixed 16bit on NANO_CLOAC
	-Fixed speedbug after infected with NANO_SPEED
	v1.1(23.12.2018)
	-Fixed EMI like effect when energy critical
	-Nano Glow weapons on ADMIN_LEVEL_E
	v1.2(23.12.2018)
	-Added Faster Energy (Extra Item)
	v1.3(24.12.2018)
	-Fixed correct chat Prefix on g_extraitem(Faster Energy)
	v1.5(27.12.2018)
	- Fixed if(g_has_fast_energy[id])
	v1.6(30.12.2018)
	-Fixed corret ammo packs
	v1.7(05.01.2019)
	-Fixed energy not regaining
	
=================================================================================*/
#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zombieplague>
#include <WPMGPrintChatColor>
#if AMXX_VERSION_NUM < 183
    #include <dhudmessage>
#endif
#include <bitsums>
#include <stock_color_message>

#if defined client_disconnected
	#define client_disconnect client_disconnected
#endif

#define PLUGIN	"Fatall-Error Nanosuit"
#define AUTHOR	"YankoNL & DJBosma"
#define VERSION	"1.7"
#define TE_ELIGHT				28	// Point entity light, no world effect
#define DMG_FALL (1<<5)
#define FFADE_IN 0x0000
#define SPECTATOR = 3

//#define REMOVE_VIEWMODEL_ON_CLOAK
#define USE_WEAPON_STATUSICONS

// Settings defines [here it is a good place to modify some of the settings]
// Maxplayers [the max players, change this if you don't have 32 players(Low memory usage)]
#define MAXPLAYERS 				 			32

// Refire Rate Manipulation
#define REFIRE_PISTOLS			 			0.85
#define REFIRE_KNIFE 			 			0.75
#define REFIRE_M3				 			0.70
#define REFIRE_SNIPERS 			 			0.60

// Reload Manipulation Defines
#define RELOAD_RATIO 			 			0.78
#define SH_CARTRAGE_RATIO		 			2
#define SH_AMMO_MSG_AMMOID					5

// Painshock constant
#define PAIN_SHOCK_ATTENUATION	 			1.0

// Strength grenade throw burst
#define GRENADE_STR_THROW_ADD	 			0

// Lowres defines  -> refresh rate for screen info in lowresources mode
#define NANO_LOW_RES  			 			5  // time 0.1 seconds

// Delay of energy recharge after ability usage (time in 0.1 seconds)
#define DELAY_STR_JUMP 			 			0
#define DELAY_STR_STAB 			 			0
#define DELAY_STR_SHOT 			 			2
#define DELAY_STR_G_THROW 		 			0
#define DELAY_ARM_DAMAGE	 	 			5
#define DELAY_SPD_RUN 			 			4
#define DELAY_SPD_FAST_ATTACK	 			6
#define DELAY_SPD_FAST_RELOAD	 			10
#define DELAY_SPD_SH_RELOAD		 			5
#define DELAY_CLK_DELAY			 			3 //3
#define DELAY_CLK_FORCED		 			5 // 5

// Energy regeneration multiply if user crouches
#define ENERGY_CROUCH 			 			1.2

// Critical border additive so that the plugin will not do the CRITICAL CRITCAL CRITICAL sound [Do not set this to 0.0 or dare!]
#define CRITICAL_EXTRA_ADD		 			13.0

// Plugin useful defines [DO NOT MODIFY!]
// Offsets defines
#define OFFSET_WEAPON_OWNER					41
#define OFFSET_WEAPON_ID					43
#define OFFSET_WEAPON_NEXT_PRIMARY_ATTACK   46
#define OFFSET_WEAPON_NEXT_SEC_ATTACK		47
#define OFFSET_WEAPON_IDLE_TIME				48
#define OFFSET_WEAPON_PRIMARY_AMMO_TYPE		49
#define OFFSET_WEAPON_CLIP					51
#define OFFSET_WEAPON_IN_RELOAD				54

#define OFFSET_PLAYER_NEXT_ATTACK			83
#define OFFSET_PLAYER_PAIN_SHOCK			108
#define OFFSET_PLAYER_ITEM_ACTIVE			373
#define OFFSET_PLAYER_AMMO_SLOT0			376

// Linux offset difference
#define EXTRA_OFFSET_PLAYER_LINUX  			5
#define EXTRA_OFFSET_WEAPON_LINUX			4

// Fall extras
#define FALL_TRUE_VELOCITY 					510.0
#define FALL_FALSE_VELOCITY					350.0
#define DMG_FALL_MULTIPLY					1.40

// Speed defines
#define SPEED_WATER_MUL_CONSTANT			0.7266666
#define SPEED_CROUCH_MUL_CONSTANT			0.3333333

// Damage offsets this is the knife/bullet damage
//#define DMG_CS_KNIFE_BULLETS		   		(0 << 0 | 0 << 0)

// Flags for speed mode cvar ground
#define NANO_FLAG_INWATER					(1<<1)
#define NANO_FLAG_CROUCHED					(1<<1)

// Recoil Manipulation Defines
new const UNREGISTERED_WEAPONS_BITSUM  = 	((1<<2) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_C4))
new const WEAPONS_WITH_SHIELD_BITSUM   =	((1<<CSW_GLOCK18) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_P228) | (1<<CSW_DEAGLE) | (1<<CSW_FIVESEVEN) | (1<<CSW_KNIFE) | (1<<CSW_USP))

// Reload Manipulation Defines
new const NO_RELOAD_WEAPONS_BITSUM	   =	((1<<CSW_M3) | (1<<CSW_XM1014) | (1<<CSW_KNIFE))

// Task defines
#define TASK_ENERGY 	0
#define TASK_AH_REC 	33
#define TASK_AI			66

// Macro Function defines [DO NOT MODIFY!]
#define is_user_player(%1) 					(1 <= %1 <= glb_maxplayers)
#define Ham_Player_ResetMaxSpeed			Ham_Item_PreFrame

new const ON_LAND_CONST		=	( FL_ONGROUND | FL_ONTRAIN | FL_PARTIALGROUND | FL_INWATER | FL_SWIM )
new const ON_WATER_CONST	=	( FL_INWATER | FL_SWIM )
new Float:energy

// Nanosuit status and modes information
enum NanoModes
{
	NANO_STREN = 0,
	NANO_ARMOR = 1,
	NANO_SPEED = 2,
	NANO_CLOAK = 3
}

new const NanoScreenColor[NanoModes][3] =
{
	{255, 0,   0  },
	{25,  25,  255},
	{255, 255, 16  },
	{255, 255, 255}
}

new const NanoStatusIcon[NanoModes][] = 
{
	"",
	"",
	"",
	""
}

new const NanoGlowColor[NanoModes][3] =
{
	{0, 0, 0},
	{0, 0, 0},
	{0, 0, 0},
	{0, 0, 0} 
}

new const NanoGlowAmmount[NanoModes] = 
{
	0,
	0,
	0,
	1
}

new const NanoGlowFX[NanoModes] =
{
	kRenderFxNone,
	kRenderFxNone,
	kRenderFxNone,
	kRenderFxNone
}

new const NanoGlowMode[NanoModes] =
{
	kRenderNormal,
	kRenderNormal,
	kRenderNormal,
	kRenderTransTexture
}

#define set_nano_glow(%1)  set_user_rendering(%1, NanoGlowFX[cl_nn_mode[%1]], NanoGlowColor[cl_nn_mode[%1]][0], NanoGlowColor[cl_nn_mode[%1]][1], NanoGlowColor[cl_nn_mode[%1]][2], NanoGlowMode[cl_nn_mode[%1]], NanoGlowAmmount[cl_nn_mode[%1]])
#define reset_rendering(%1) set_user_rendering(%1)

enum NanoStatus
{
	NANO_NO,
	NANO_YES
}

enum NanoSpdMode
{
	SPEED_MAXIMUM,
	SPEED_CRITICAL,
	SPEED_NORMAL
}

enum NanoSpeed
{
	SPD_STILL = 0,
	SPD_VSLOW,
	SPD_SLOW,
	SPD_NORMAL,
	SPD_FAST
}

enum NanoSpeedScreen
{
	SPD_SCR_STILL = 0,
	SPD_SCR_VSLOW,
	SPD_SCR_SLOW,
	SPD_SCR_NORMAL,
	SPD_SCR_FAST
}

enum IconStatus
{
	ICON_REMOVE = 0,
	ICON_SHOW,
	ICON_PULSE
}

enum ShadowIdX
{
	SHADOW_REMOVE = 0,
}

enum KnifeState
{
	KNIFE_NOT = 0,
	KNIFE_FIRST_ATTACK,
	KNIFE_SECOND_ATTACK
}

// HTML properties
new const html_header[] = "<html><head><style type=^"text/css^">body{background:#000000;margin-left:8px;margin-top:0px;}a{text-decoration: underline;}a:link {color#FFFFFF;}a:visited{color: #FFFFFF;}a:active    {   color:  #FFFFFF;    }a:hover {    color:  #FFFFFF;    text-decoration: underline;    }</style></head><body scroll=^"yes^" style=^"text-align: left; margin: 0 auto; color:#ffb000;^"><div style=^"width: 600px; text-align: left;^"><font style=^"font-size: 20px; color:#ffb000; ^">"

// Reload needed constants
stock const Float:wpn_reload_delay[CSW_P90+1] =
{
	0.00, 2.70, 0.00, 2.00, 0.00, 0.55, 0.00, 3.15, 3.30, 0.00, 4.50, 2.70, 3.50, 3.35, 2.45, 3.30, 2.70, 2.20, 2.50, 2.63, 4.70, 0.55, 3.05, 2.12, 3.50, 0.00, 2.20, 3.00, 2.45, 0.00, 3.40
}

stock const wpn_reload_anim[CSW_P90+1] = 
{
	-1,  5, -1, 3, -1, 6, -1, 1, 1, -1, 14, 4, 2, 3, 1, 1, 13, 7, 4, 1, 3, 6, 11, 1, 3, -1, 4, 1, 1, -1, 1
}

stock const wpn_max_clip[CSW_P90+1] = 
{
	-1,  13, -1, 10,  1, 7, 1, 30, 30,  1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8 , 30, 30, 20,  2, 7, 30, 30, -1, 50
}

stock const Float:wpn_act_speed[CSW_P90+1] = 
{
	0.0, 250.0, 0.0, 260.0, 250.0, 240.0, 250.0, 250.0, 240.0, 250.0, 250.0, 250.0, 250.0, 210.0, 240.0, 240.0, 250.0, 250.0, 210.0, 250.0, 220.0, 230.0, 230.0, 250.0, 210.0, 250.0, 250.0, 235.0, 221.0, 250.0, 245.0 
}

// HIT constant damage multi
new const Float:vec_hit_multi[] =
{
	1.0,
	4.0,
	1.0,
	1.25,
	1.0,
	1.0,
	0.75,
	0.75,
	0.0
}

new wpn_v_model[CSW_P90 + 1][30]
new wpn_v_shield_model[CSW_P90 + 1][50]
new wpn_ms_icon[CSW_P90 + 1][14]

// Sounds
new const sound_strengh[] =			"nanosuit/nanosuit_strength.wav"
new const sound_online[] =			"nanosuit/nanosuit_allonline.wav"
new const sound_armor[] = 			"nanosuit/nanosuit_armor.wav"
new const sound_speed[] = 			"nanosuit/nanosuit_speed.wav"
new const sound_cloak[] = 			"nanosuit/nanosuit_cloak.wav"
new const sound_energy[] = 			"nanosuit/nanosuit_energy.wav"
new const sound_critical[] = 			"nanosuit/nanosuit_critical.wav"
new const sound_menu[] = 			"nanosuit/nanosuit_menu.wav"
new const sound_strength_throw[] = 		"nanosuit/nanosuit_strength_hit.wav"
new const sound_switch_strength[] = 		"nanosuit/nanosuit_strength_switch.wav"
new const sound_switch_armor[] = 		"nanosuit/nanosuit_armor_switch.wav"
new const sound_switch_speed[] = 		"nanosuit/nanosuit_speed_switch.wav"
new const sound_switch_cloak[] = 		"nanosuit/nanosuit_cloak_switch.wav"
new const sound_slowdown[] =			"nanosuit/nanosuit_slowdown.wav"
new const regain_sound[] =			"nanosuit/nanosuit_regain.wav"

new const sound_ric_metal1[] = 			"weapons/ric_metal-1.wav"
new const sound_ric_metal2[] = 			"weapons/ric_metal-2.wav"

// Pcvars
new pcv_nn_price
new pcv_nn_ff
new pcv_nn_death
new pcv_nn_bot
new pcv_nn_bot_buy
new pcv_nn_team
new pcv_nn_critical
new pcv_nn_critical_dmg
new pcv_nn_critical_dmg_time
new pcv_nn_health
new pcv_nn_armor
new pcv_nn_buyzone
new pcv_nn_regenerate
new pcv_nn_hp_charge
new pcv_nn_ap_charge
new pcv_nn_ar_speed
new pcv_nn_ar_damage
new pcv_nn_st_impulse
new pcv_nn_st_stab
new pcv_nn_st_jump
new pcv_nn_st_throw
new pcv_nn_st_rec_att
new pcv_nn_st_g_throw
new pcv_nn_st_rec_en
new pcv_nn_st_can_th
new pcv_nn_sp_maxim
new pcv_nn_sp_ground
new pcv_nn_sp_critic
new pcv_nn_sp_energy
new pcv_nn_sp_reload
new pcv_nn_sp_fattack
new pcv_nn_sp_fatshre
new pcv_nn_cl_energy
new pcv_nn_cl_fire
new pcv_nn_cl_knife
new pcv_nn_cl_grenade
new pcv_nn_cl_c4
new pcv_zm_regive
new pcvarFade1
new maxplayers

new g_msgScreenFade
new g_itemindex1
new g_itemindex2
new g_has_fast_energy[MAXPLAYERS + 1] = {false, ...}
new g_iBsZombie

// Plugin info holders
new glb_maxplayers
new ShadowIdX:SHADOW_CREATE

// Client general info
new Float:g_nn_energy[MAXPLAYERS + 1]
new Float:cl_nn_controlling[33]
new cl_nn_weapon[MAXPLAYERS + 1]
new bool:cl_is_bot[MAXPLAYERS + 1] = {false, ...}
new bool:cl_nn_lowres[MAXPLAYERS + 1] = {false, ...}
new NanoStatus:cl_nn_has[MAXPLAYERS + 1] = {NANO_NO, ...}
new NanoStatus:cl_nn_had[MAXPLAYERS + 1] = {NANO_NO, ...}
new bool:cl_added_velocity[MAXPLAYERS + 1] = {false, ...}
new bool:cl_removed_shadow[MAXPLAYERS + 1] = {false, ...}
new bool:cl_nn_zombie[MAXPLAYERS + 1] = {false, ...}

// Nanosuit special info
new NanoSpdMode:cl_nn_sp_status[MAXPLAYERS + 1]
new NanoSpeed:cl_nn_speed[MAXPLAYERS + 1]
new NanoSpeedScreen:cl_nn_scr_speed[MAXPLAYERS + 1]
new NanoModes:cl_nn_mode[MAXPLAYERS + 1] = {NANO_ARMOR, ...}
new Float:cl_nn_energy[MAXPLAYERS + 1]
new bool:cl_nn_critical[MAXPLAYERS + 1]
new bool:cl_nn_online[MAXPLAYERS + 1]
new cl_nn_counter[MAXPLAYERS + 1] = {NANO_LOW_RES, ...}
new cl_nn_block_recharge[MAXPLAYERS + 1]
new KnifeState:cl_nn_st_knife[MAXPLAYERS + 1] = {KNIFE_NOT, ...}
new bool:cl_nn_st_jump[MAXPLAYERS + 1] = {false, ...}
new cl_is_thrown[MAXPLAYERS + 1] = {0, ...}
new Float:cl_nn_punch[MAXPLAYERS + 1][3]
new bool:cl_nn_actual_shot[MAXPLAYERS + 1] = {false, ...}
new cl_nn_shotgun_ammo[MAXPLAYERS + 1]
new Float:cl_nn_damage_time[MAXPLAYERS + 1]

// Needs -> hud + menu + monitor + messages
new nd_menu[MAXPLAYERS + 1]
new nd_hud_sync
new nd_ent_monitor
new nd_msg_saytext
new nd_msg_damage
new nd_msg_iconstatus
new nd_msg_shadowidx
new nd_msg_ammox

public plugin_precache()
{
	precache_sound(sound_armor)
	precache_sound(sound_strengh)
	precache_sound(sound_online)
	precache_sound(sound_speed)
	precache_sound(sound_cloak)
	precache_sound(sound_energy)
	precache_sound(sound_critical)
	precache_sound(sound_menu)
	precache_sound(sound_strength_throw)
	precache_sound(sound_switch_armor)
	precache_sound(sound_switch_cloak)
	precache_sound(sound_switch_speed)
	precache_sound(sound_switch_strength)
	precache_sound(sound_slowdown)
	precache_sound(regain_sound)
	precache_sound( "nanosuit/nanosuit_controller.wav" )
	
	precache_sound(sound_ric_metal1)
	precache_sound(sound_ric_metal2)	
}

public plugin_init() 
{
	// Register the plugin
	register_plugin(PLUGIN, VERSION, AUTHOR)
	set_msg_block(get_user_msgid("ShadowIdx"), BLOCK_SET);

	register_message(get_user_msgid("TextMsg"), "MessageTextMsg");
	register_clcmd("get_stren", "nanosuit_str_mode")
	register_clcmd("get_armor", "nanosuit_arm_mode")
	register_clcmd("get_speed", "nanosuit_spd_mode")
	register_clcmd("get_cloak", "nanosuit_clo_mode")
	register_clcmd("get_energy", "set_con_energy")
	register_clcmd("take_energy", "take_con_energy")
	
	register_clcmd("say /nanosuit", "nanosuit_menu_show")
	register_clcmd("say_team /nanosuit", "nanosuit_menu_show")
	register_clcmd("nanosuit", "nanosuit_menu_show")
	
	g_itemindex1 = zp_register_extra_item("Energy Boost \y[\r+10\y]", 30, ZP_TEAM_HUMAN)
	g_itemindex2 = zp_register_extra_item("Faster Energy \d(\rx3\d)", 60, ZP_TEAM_HUMAN)
	
	// The pcvars
	pcvarFade1 = register_cvar("dmg_screen_fade","1")
	maxplayers = get_maxplayers()
	pcv_nn_price      = register_cvar("zp_nanosuit_price","0")
	pcv_nn_death      = register_cvar("zp_nanosuit_death_remove","0")
	pcv_nn_buyzone    = register_cvar("zp_nanosuit_buyzone","0")
	pcv_nn_ff         = get_cvar_pointer("mp_friendlyfire")
	pcv_nn_bot        = register_cvar("zp_nanosuit_bot_allow","0")
	pcv_nn_bot_buy    = register_cvar("zp_nanosuit_bot_buy_mode","0")
	pcv_nn_team		  = register_cvar("zp_nanosuit_team_allow","2")
	pcv_zm_regive	  = register_cvar("zp_nanosuit_disinfect_regive", "1")
	
	pcv_nn_critical   = register_cvar("zp_nanosuit_critical","10")
	pcv_nn_critical_dmg = register_cvar("nanosuit_critical_damage","5")
	pcv_nn_critical_dmg_time = register_cvar("nanosuit_critical_damage_time","1.0")
	
	pcv_nn_health     = register_cvar("zp_nanosuit_health","100")
	pcv_nn_armor      = register_cvar("nanosuit_armor","999")
	
	pcv_nn_regenerate = register_cvar("zp_nanosuit_regenerate","1.0")
	pcv_nn_hp_charge  = register_cvar("zp_nanosuit_hpcharge","1")
	pcv_nn_ap_charge  = register_cvar("nanosuit_apcharge","0")
	
	pcv_nn_ar_speed   = register_cvar("zp_nanosuit_armor_speed","1.0")
	pcv_nn_ar_damage  = register_cvar("zp_nanosuit_armor_damage","0.95")
	
	pcv_nn_st_impulse = register_cvar("nanosuit_strength_impulse","240")
	pcv_nn_st_stab    = register_cvar("zp_nanosuit_strength_stab","0")
	pcv_nn_st_jump    = register_cvar("nanosuit_strength_jump","0")
	pcv_nn_st_throw   = register_cvar("zp_nanosuit_strength_throw","0")
	pcv_nn_st_rec_att = register_cvar("zp_nanosuit_strength_recoil_attenuation","3.0")
	pcv_nn_st_rec_en  = register_cvar("zp_nanosuit_strength_recoil_energy","2.5")
	pcv_nn_st_g_throw = register_cvar("zp_nanosuit_strength_grenade_throw","1")
	pcv_nn_st_can_th  = register_cvar("zp_nanosuit_strength_throw_override","0")
	
	pcv_nn_sp_maxim   = register_cvar("zp_nanosuit_speed_maximum","1.80")
	pcv_nn_sp_critic  = register_cvar("zp_nanosuit_speed_critical","1.20")
	pcv_nn_sp_energy  = register_cvar("zp_nanosuit_speed_energy","3.6")
	pcv_nn_sp_fattack = register_cvar("zp_nanosuit_speed_fast_attack", "3.0")
	pcv_nn_sp_fatshre = register_cvar("zp_nanosuit_speed_fast_sh_reload", "5.0")
	pcv_nn_sp_reload  = register_cvar("zp_nanosuit_speed_fast_reload", "10.0")
	pcv_nn_sp_ground  = register_cvar("zp_nanosuit_ground_affect", "3") // 0 normal ground, 1 also crouch, 2 water, 3 water + crouch
	
	pcv_nn_cl_energy  = register_cvar("zp_nanosuit_cloak_energy","0.65") // 0.65
	pcv_nn_cl_fire    = register_cvar("zp_nanosuit_cloak_punish_weapon_fire","1")
	pcv_nn_cl_knife   = register_cvar("zp_nanosuit_cloak_punish_knife_usage","0")
	pcv_nn_cl_grenade = register_cvar("zp_nanosuit_cloak_punish_grenade_throw","0")
	pcv_nn_cl_c4      = register_cvar("zp_nanosuit_cloak_punish_c4","0")

	g_msgScreenFade = get_user_msgid("ScreenFade")
	
	// Fakemeta forwards
	register_forward(FM_PlayerPreThink, "fw_prethink")
	register_forward(FM_SetModel, "fw_setmodel",1)
	
	// Ham forwards (yummy)
	RegisterHam(Ham_CS_RoundRespawn,"player","fw_spawn",1)
	RegisterHam(Ham_Spawn,"player","fw_spawn",1)
	RegisterHam(Ham_Killed,"player","fw_killed")
	RegisterHam(Ham_Player_ResetMaxSpeed,"player","fw_resetmaxspeed",1)
	
	new weapon_name[24]
	
	// Register all weapons for special functions
	for (new i=CSW_P228;i<=CSW_P90;i++)
	{
		if (!(UNREGISTERED_WEAPONS_BITSUM & 1<<i) && get_weaponname(i, weapon_name, charsmax(weapon_name)))
		{
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_primary_attack")
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_primary_attack_post",1)
			RegisterHam(Ham_Weapon_SecondaryAttack, weapon_name, "fw_secondary_attack")
			RegisterHam(Ham_Weapon_SecondaryAttack, weapon_name, "fw_secondary_attack_post",1)
			
			if (!(NO_RELOAD_WEAPONS_BITSUM & (1<<i)))
			{
				RegisterHam(Ham_Weapon_Reload, weapon_name, "fw_reload_post", 1)
			}
			else
			{
				if (i != CSW_KNIFE)
				{
					RegisterHam(Ham_Item_Deploy, weapon_name, "fw_shotgun_deploy", 1)
					RegisterHam(Ham_Weapon_Reload, weapon_name, "fw_special_reload_post", 1)
				}
			}
			
			
			format(wpn_ms_icon[i],13,"d_%s",weapon_name[7])
			replace(weapon_name,charsmax(weapon_name),"navy","")
			format(wpn_v_model[i],29,"models/v_%s.mdl",weapon_name[7])
			
		}
		
		if (WEAPONS_WITH_SHIELD_BITSUM & 1<<i)
		{
			format(wpn_v_shield_model[i],49,"models/shield/v_shield_%s.mdl",weapon_name[7])
		}
	}
	
	// Let's add the c4
	format(wpn_v_model[CSW_C4],29,"models/v_c4.mdl")
	
	format(wpn_v_model[CSW_SMOKEGRENADE],29,"models/v_smokegrenade.mdl")
	format(wpn_v_model[CSW_FLASHBANG],29,"models/v_flashbang.mdl")
	format(wpn_v_model[CSW_HEGRENADE],29,"models/v_hegrenade.mdl")
	
	format(wpn_v_shield_model[CSW_SMOKEGRENADE],49,"models/shield/v_shield_smokegrenade.mdl")
	format(wpn_v_shield_model[CSW_FLASHBANG],49,"models/shield/v_shield_flashbang.mdl")
	format(wpn_v_shield_model[CSW_HEGRENADE],49,"models/shield/v_shield_hegrenade.mdl")
	
	get_weaponname(CSW_C4, weapon_name, charsmax(weapon_name))
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_bomb_planting")
	RegisterHam(Ham_Use, "grenade", "fw_bomb_defusing")
	
	
	// In the previous function we didn't register the grenades
	wpn_ms_icon[CSW_HEGRENADE] = 	"d_grenade"
	wpn_ms_icon[CSW_FLASHBANG] = 	"d_grenade"
	wpn_ms_icon[CSW_SMOKEGRENADE] = "d_grenade"
	
	// Global Stuff
	glb_maxplayers = global_get(glb_maxClients)
	
	// Events
	register_event("CurWeapon", "event_active_weapon", "be","1=1")
	register_event("DeathMsg", "event_death", "ae")
	
	register_logevent("event_startround", 2, "1=Round_Start")
	
	
	// Register dictionary (for multilanguage)
	register_dictionary("fter_nanosuit.txt")
	
	// Tolls
	nd_hud_sync = CreateHudSyncObj()
	
	// Message variables
	nd_msg_saytext 		= get_user_msgid("SayText")
	nd_msg_damage 		= get_user_msgid("Damage")
	nd_msg_iconstatus 	= get_user_msgid("StatusIcon")
	nd_msg_shadowidx  	= get_user_msgid("ShadowIdx")
	nd_msg_ammox		= get_user_msgid("AmmoX")
	
	// Hud status display
	nd_ent_monitor = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if (nd_ent_monitor)
	{
		set_pev(nd_ent_monitor, pev_classname, "screen_status")
		set_pev(nd_ent_monitor, pev_nextthink, get_gametime() + 0.1)
		
		register_forward(FM_Think, "fw_screenthink")
	}
	
	set_task(1.0,"plugin_init_delay",674832)
//	set_task(60.0,"nanosuit_msg", 674837, _, _, "b", 0)
}

public zp_extra_item_selected(id, itemid)
{
if(itemid == g_itemindex1) {
g_nn_energy[id] += 100
client_cmd(id,"spk %s",regain_sound)
set_dhudmessage(255, 0, 0, 0.55, 0.56, 0, 6.0, 6.0);
show_dhudmessage(id, "+100% Energy");

ChatColor(id, "!g[Fatall-Error] !yYou successfully upgraded your suit!");

}
if(itemid == g_itemindex2)
{
if(g_has_fast_energy[id])
{
client_print(id, print_center, "You already have Fast Energy!")
return ZP_PLUGIN_HANDLED
}
g_has_fast_energy[id] = true

client_cmd(id,"spk %s",regain_sound)
set_dhudmessage(55, 55, 155, 0.55, 0.56, 0, 6.0, 6.0);
show_dhudmessage(id, "+Faster Energy");

ChatColor(id, "!g[Fatall-Error] !yYou successfully upgraded your suit!");

message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
write_short(1<<12)
write_short(1<<12)
write_short(0x0000)
write_byte(25)
write_byte(25)
write_byte(255)
write_byte(100)
message_end()
}
return PLUGIN_CONTINUE
}

public MessageTextMsg()
{
	new szArg2[32];
	
	get_msg_arg_string(2, szArg2, 31);
	
	if (!equal(szArg2, "#Game_unknown_command"))
		return PLUGIN_CONTINUE;
    
	return PLUGIN_HANDLED;
}

public plugin_init_delay(nr)
{
	// Register the takedamage after 1 second to let the other plugins mess with the variables
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage_post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_traceattack")
	
	// Speed fix
	server_cmd("sv_maxspeed 99999.0")
}

public plugin_natives()
{
	register_native("set_user_nanosuit", "native_set_user_nanosuit", 1)
}

public client_putinserver(id)
{
	if (is_user_bot(id))
		cl_is_bot[id] = true
		
	g_nn_energy[id] = 100.0
	cl_nn_controlling[id] = 50.0
	
	if (get_pcvar_num(pcv_nn_price) <= 0)
	{
		if (cl_is_bot[id] && get_pcvar_num(pcv_nn_bot))
			cl_nn_has[id] = NANO_YES
		if (!cl_is_bot[id])
			cl_nn_has[id] = NANO_YES
	}
	else
		cl_nn_has[id] = NANO_NO
}
	
public client_connect(id)
{
	client_cmd(id,"cl_sidespeed 99999")
	client_cmd(id,"cl_forwardspeed 99999")
	client_cmd(id,"cl_backspeed 99999")
	cl_nn_actual_shot[id] = false
	cl_removed_shadow[id] = true
}

public fw_resetmaxspeed(id)
{
	if (cl_is_thrown[id] != 0 && !bitsum_get(g_iBsZombie, id))
		set_user_maxspeed(id, 1.0)
	
	if (cl_nn_has[id] == NANO_YES)
		{
		switch (cl_nn_mode[id])
		{
			case NANO_ARMOR:
			{
				if (!bitsum_get(g_iBsZombie, id))
					set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_ar_speed))
			}
			case NANO_SPEED:
			{
				if (cl_nn_energy[id] > get_pcvar_float(pcv_nn_critical))
					cl_nn_sp_status[id] = SPEED_CRITICAL
				if (get_pcvar_float(pcv_nn_critical) >= cl_nn_energy[id] > 0)
					cl_nn_sp_status[id] = SPEED_CRITICAL
				if (0 >= cl_nn_energy[id])
					cl_nn_sp_status[id] = SPEED_NORMAL
				
			}
		}
	}
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	cl_nn_has[id] = NANO_NO
	cl_nn_mode[id] = NANO_ARMOR
	cl_is_bot[id] = false
	cl_added_velocity[id] = false
	nanosuit_reset(id)
}

public nanosuit_low_res_toggle(id)
{
	cl_nn_lowres[id] = !cl_nn_lowres[id]
	
	if (cl_nn_lowres[id])
	{
		msg_statusicon(id,ICON_REMOVE,NanoStatusIcon[cl_nn_mode[id]],NanoScreenColor[cl_nn_mode[id]])
		#if defined USE_WEAPON_STATUSICONS
		msg_statusicon(id,ICON_REMOVE,wpn_ms_icon[cl_nn_weapon[id]],{0,255,0})
		#endif
		client_print(id, print_chat, "%L", id, "NANO_LOWRES_ON")
	}
	else
	{
		if (cl_nn_has[id] == NANO_YES)
		{
			msg_statusicon(id,ICON_SHOW,NanoStatusIcon[cl_nn_mode[id]],NanoScreenColor[cl_nn_mode[id]])
			#if defined USE_WEAPON_STATUSICONS
			if (cl_nn_mode[id] == NANO_CLOAK)
				msg_statusicon(id,ICON_SHOW,wpn_ms_icon[cl_nn_weapon[id]],{0,255,0})
			#endif
		}
		client_print(id, print_chat, "%L", id, "NANO_LOWRES_OFF")
	}
	
	return
}

// Menu System
public nanosuit_menu_create(id)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id) || cl_nn_has[id] == NANO_NO)
	{
		client_print(id, print_center,"%L",id,"NANO_NO")
	}
	else
	{
		static text[200]
	
		format(text,199,"%L",id,"NANO_MENU")
		nd_menu[id] = menu_create(text, "nanosuit_menu_choose")
	
		format(text,199,"%L",id,"NANO_ST_MODE_MENU")
		menu_additem(nd_menu[id], text)
		format(text,199,"%L",id,"NANO_A_MODE_MENU")
		menu_additem(nd_menu[id], text)
		format(text,199,"%L",id,"NANO_S_MODE_MENU")
		menu_additem(nd_menu[id], text)
		format(text,199,"%L",id,"NANO_C_MODE_MENU")
		menu_additem(nd_menu[id], text)
	
		menu_setprop(nd_menu[id], MPROP_EXIT, MEXIT_NEVER)
	}
}

public nanosuit_menu_show(id)
{
	if (!is_user_alive(id))
		return
	
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id) || cl_nn_has[id] == NANO_NO)
	{
		client_print(id, print_center,"%L",id,"NANO_NO")
	}
	else
	{
		client_cmd(id,"spk %s",sound_menu)
		nanosuit_menu_create(id)
		menu_display(id, nd_menu[id])
		nanosuit_reset(id,false)
		return
	}
	return
}

public nanosuit_menu_choose(id, menu, item)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id) || cl_nn_has[id] == NANO_NO)
	{
		client_print(id, print_center,"%L",id,"NANO_NO")
	}
	else
	{
		if (item != -3 && cl_nn_mode[id] != NanoModes:item)
		{
			if (cl_nn_mode[id] == NANO_SPEED)
			{
				if (cl_nn_energy[id] > get_pcvar_float(pcv_nn_critical))
					cl_nn_sp_status[id] = SPEED_MAXIMUM
				if (get_pcvar_float(pcv_nn_critical) >= cl_nn_energy[id] > 0)
					cl_nn_sp_status[id] = SPEED_CRITICAL
				if (0 >= cl_nn_energy[id])
					cl_nn_sp_status[id] = SPEED_NORMAL
				
				switch (cl_nn_sp_status[id])
				{
					case SPEED_MAXIMUM: set_user_maxspeed(id,get_user_maxspeed(id) / get_pcvar_float(pcv_nn_sp_maxim))
					case SPEED_CRITICAL: set_user_maxspeed(id,get_user_maxspeed(id) / get_pcvar_float(pcv_nn_sp_critic))
				}
			}
		
			if (NanoModes:item == NANO_SPEED)
			{
				if (cl_nn_energy[id] > get_pcvar_float(pcv_nn_critical))
					cl_nn_sp_status[id] = SPEED_MAXIMUM
				if (get_pcvar_float(pcv_nn_critical) >= cl_nn_energy[id] > 0)
					cl_nn_sp_status[id] = SPEED_CRITICAL
				if (0 >= cl_nn_energy[id])
					cl_nn_sp_status[id] = SPEED_NORMAL
			
				switch (cl_nn_sp_status[id])
				{
					case SPEED_MAXIMUM: set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_sp_maxim))
				case SPEED_CRITICAL: set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_sp_critic))
				}
			}
		
			set_nano_mode(id,NanoModes:item)
		}
	
		if (menu != 0)
			menu_destroy(nd_menu[id])
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}


// Buy command
public nanosuit_buy(id)
{
	if (cl_nn_has[id] == NANO_YES)
	{
		client_print(id,print_center,"#Cstrike_Already_Own_Weapon")
		return PLUGIN_HANDLED

	}
	
	if (get_pcvar_num(pcv_nn_price) <= 0)
	{
		cl_nn_has[id] = NANO_YES
		nanosuit_reset(id, true)
		
		return PLUGIN_HANDLED

	}
	else
	{
		if (get_pcvar_num(pcv_nn_team) != _:cs_get_user_team(id) && get_pcvar_num(pcv_nn_team) != 3)
		{
			client_print(id,print_center,"You team is not allowed to buy!")
			return PLUGIN_HANDLED

		}
		
		if (get_pcvar_num(pcv_nn_buyzone) && !cs_get_user_buyzone(id))
		{
			client_print(id,print_center,"%L",id,"NANO_BUYZONE")
			return PLUGIN_HANDLED

		}
		
		static money
		money = cs_get_user_money(id)
		static price
		price = get_pcvar_num(pcv_nn_price)
		
		if (money >= price)
		{
			cs_set_user_money(id, money - price)
			
			cl_nn_has[id] = NANO_YES
			nanosuit_reset(id, true)
			
			client_print(id,print_center,"%L",id,"NANO_BUY")
			return PLUGIN_HANDLED

		}
		else
		{
			client_print(id,print_center,"#Cstrike_TitlesTXT_Not_Enough_Money")
			return PLUGIN_HANDLED

		}
	}
	
	return PLUGIN_CONTINUE
}

// Help command
public nanosuit_help(id)
{
	static help[3000]
	
	format(help,2999,"%s%s^n",help,html_header)
	
	format(help,2999,"%s%L^n",help,id,"NANO_HTML_BASIC")
	format(help,2999,"%s%L^n",help,id,"NANO_HTML_MODES")
	
	if (get_pcvar_num(pcv_nn_cl_fire))
		format(help,2999,"%s%L^n",help,id,"NANO_HTML_CL_FIRE")
	
	if (get_pcvar_num(pcv_nn_cl_knife))
		format(help,2999,"%s%L^n",help,id,"NANO_HTML_CL_KNIFE")
	
	if (get_pcvar_num(pcv_nn_cl_grenade))
		format(help,2999,"%s%L^n",help,id,"NANO_HTML_CL_NADE")
	
	format(help,2999,"%s%L^n",help,id,"NANO_HTML_ADVICE")
	
	delete_file("nanosuit.htm")
	write_file("nanosuit.htm",help)
	show_motd(id, "nanosuit.htm", "-= Crysis Nanosuit =-")
	return
}

/* ===================================================
[Events]
==================================================== */

public event_startround()
{
	if (get_pcvar_num(pcv_nn_bot_buy) || !get_pcvar_num(pcv_nn_bot))
		return PLUGIN_CONTINUE
	
	new players[32], count, id
	get_players(players,count,"ad")
	
	for (new i=0;i<count;i++)
	{
		id = players[i]
		nanosuit_buy(id)
	}
	
	return PLUGIN_CONTINUE
}

public event_active_weapon(id)
{
	new weapon
	weapon = read_data(2)
	
	if (weapon != CSW_KNIFE)
		cl_nn_st_knife[id] = KNIFE_NOT
	
	
	if (weapon != CSW_KNIFE && weapon != CSW_HEGRENADE && weapon != CSW_FLASHBANG && weapon != CSW_SMOKEGRENADE && cl_nn_zombie[id])
	{
		cl_nn_zombie[id] = false
		
		if (cl_nn_had[id] == NANO_YES && get_pcvar_num(pcv_zm_regive))
		{
			cl_nn_has[id] = NANO_YES
			nanosuit_reset(id)
		}
	}
	
	
	if (cl_nn_has[id] == NANO_YES && cl_nn_weapon[id] != weapon)
	{
		#if defined	REMOVE_VIEWMODEL_ON_CLOAK
		if (!cl_is_bot[id] && cl_nn_mode[id] == NANO_CLOAK)
			set_pev(id,pev_viewmodel2,"")
		#endif
		#if defined USE_WEAPON_STATUSICONS
		if (cl_nn_mode[id] == NANO_CLOAK && !cl_is_bot[id] && !equal(wpn_ms_icon[cl_nn_weapon[id]],wpn_ms_icon[weapon]))
		{
			msg_statusicon(id,ICON_REMOVE,wpn_ms_icon[cl_nn_weapon[id]],{0,0,0})
			msg_statusicon(id,ICON_SHOW,wpn_ms_icon[weapon],{0,255,0})
		}
		#endif
		
		if (cl_is_bot[id])
		{
			if (weapon == CSW_KNIFE)
			{
				new hit = -1
				new Float:origin[3]
				pev(id,pev_origin,origin)
				
				while ((hit = engfunc(EngFunc_FindEntityInSphere, hit, origin, 350.0)))
				{
					if (!is_user_alive(hit))
						continue
					
					if ((get_pcvar_num(pcv_nn_ff)) || (!get_pcvar_num(pcv_nn_ff) && cs_get_user_team(id) != cs_get_user_team(hit)))
					{
						nanosuit_menu_choose(id,0,_:NANO_STREN)
						break
					}
				}
			}
		}
	}
	
	cl_nn_weapon[id] = weapon
}

public event_death()
{
	static victim
	victim = read_data(2)
	
	if (victim == 0)
		return 
	
	reset_rendering(victim)
	
	if (get_pcvar_num(pcv_nn_price) > 0 && get_pcvar_num(pcv_nn_death))
	{
		cl_nn_has[victim] = NANO_NO
		nanosuit_reset(victim)
	}
	
	return
}

/* ===================================================
[Fakemeta forwards (fake!)]
==================================================== */
public fw_prethink(id)
{
	if (cl_nn_has[id] == NANO_YES && is_user_alive(id) && get_user_flags(id) & ADMIN_LEVEL_E)
	{
		new fOrigin[3], rgb[3]
		switch (cl_nn_mode[id])
		{
			case NANO_STREN: rgb = {255, 0, 0}
			case NANO_ARMOR: rgb = {0, 0, 255}
			case NANO_SPEED: rgb = {255, 255, 0}
		}
		
		pev(id, pev_origin, fOrigin)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_ELIGHT)
		write_short(id)
		write_coord(fOrigin[0])
		write_coord(fOrigin[1])
		write_coord(fOrigin[2])
		write_coord(10)
		write_byte(rgb[0])
		write_byte(rgb[1])
		write_byte(rgb[2])
		write_byte(2)
		write_coord(0)
		message_end()
	}
	
	if (!is_user_alive(id))
		return FMRES_IGNORED
		
	new Float:origin[3], Float:through[3], Float:vel[3], Float:endpos[3], bool:onground, flags
	
	flags = pev(id, pev_flags)
	
	onground = (flags & ON_LAND_CONST)  ? true : false
	
	pev(id,pev_origin,origin)
	pev(id,pev_velocity,vel)
	
	if (cl_is_thrown[id] && !onground && vel[2] <= -FALL_FALSE_VELOCITY && !cl_added_velocity[id])
	{
		static trace
		trace = create_tr2()
		
		xs_vec_add(origin,Float:{0.0,0.0,-50.0},through)
		
		engfunc(EngFunc_TraceLine,origin,through,IGNORE_MONSTERS, id, trace)
		get_tr2(trace,TR_vecEndPos,endpos)
		xs_vec_sub(endpos,origin,endpos)
		xs_vec_sub(through,origin,through)
		
		if (vector_length(through) != vector_length(endpos))
		{
			vel[2] += FALL_FALSE_VELOCITY - FALL_TRUE_VELOCITY
			cl_added_velocity[id] = true
			set_pev(id,pev_velocity,vel)
		}
		
		free_tr2(trace)
	}
	
	if (cl_is_thrown[id] && onground)
	{
		cl_added_velocity[id] = false
		cl_is_thrown[id] = 0
		
		ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
	}
	
	if (cl_is_bot[id] && cl_nn_has[id] == NANO_YES && !get_pcvar_num(pcv_nn_bot))
	{
		cl_nn_has[id] = NANO_NO
		nanosuit_reset(id)
	}
	
	static Float:health
	pev(id,pev_health,health)
	
	if (cl_is_bot[id] && cl_nn_has[id] == NANO_YES && health < 60.0)
		nanosuit_menu_choose(id,0,_:NANO_ARMOR)
	
	if (cl_nn_has[id] == NANO_YES)
		nanosuit_functions(id)

	// Maximum Speed
	if (cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_SPEED)
	{
				if (cl_nn_energy[id] < 100)
					set_pev(id, pev_maxspeed, 400.0)

				if (cl_nn_energy[id] < 13)
					set_pev(id, pev_maxspeed, 240.0)
	}
	
	// Run
	new Float:speed
	speed  = vector_length(vel)
	new Float:mspeed
	mspeed = get_user_maxspeed(id)
	
	if (get_pcvar_num(pcv_nn_sp_ground) & NANO_FLAG_INWATER && flags & ON_WATER_CONST)
		mspeed *= SPEED_WATER_MUL_CONSTANT
	
	if (get_pcvar_num(pcv_nn_sp_ground) & NANO_FLAG_CROUCHED && flags & FL_DUCKING)
		mspeed *= SPEED_CROUCH_MUL_CONSTANT
	
	// Remember the speed
	if (speed ==         0.0)		cl_nn_speed[id] = SPD_STILL
	if (speed >			 0.0)		cl_nn_speed[id] = SPD_VSLOW
	if (speed > 0.4 * mspeed)		cl_nn_speed[id] = SPD_SLOW
	if (speed > 0.6 * mspeed)		cl_nn_speed[id] = SPD_NORMAL
	if (speed > 0.9 * mspeed)		cl_nn_speed[id] = SPD_FAST
	
	if (speed < 0.6 * mspeed && cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_SPEED)	
		set_pev(id,pev_flTimeStepSound,100)
	
	// Screen display
	if (speed ==  0.0)				cl_nn_scr_speed[id] = SPD_SCR_STILL
	if (speed >	  0.0)				cl_nn_scr_speed[id] = SPD_SCR_VSLOW
	if (speed > 100.0)				cl_nn_scr_speed[id] = SPD_SCR_SLOW
	if (speed > 200.0)				cl_nn_scr_speed[id] = SPD_SCR_NORMAL
	if (speed > 265.0)				cl_nn_scr_speed[id] = SPD_SCR_FAST
	
	return FMRES_IGNORED
}

public fw_postthink(id)
{
	if (is_user_alive(id) && cl_nn_st_jump[id])
	{
		static Float:vecforce[3]
		pev(id,pev_velocity,vecforce)
		vecforce[2] = get_pcvar_float(pcv_nn_st_impulse)
		set_pev(id,pev_velocity,vecforce)
		set_nano_energy(id, cl_nn_energy[id] - get_pcvar_float(pcv_nn_st_jump), DELAY_STR_JUMP)
		cl_nn_st_jump[id] = false
	}
	
	return FMRES_IGNORED
}

public fw_setmodel(ent, const model[])
{
	if (!pev_valid(ent))
		return FMRES_IGNORED
	
	new Float:gravity
	pev(ent,pev_gravity,gravity)
	
	if (gravity == 0.0)
		return FMRES_IGNORED
	
	new owner
	owner = pev(ent,pev_owner)
	
	if (!(cl_nn_has[owner] == NANO_YES))
		return FMRES_IGNORED
	
	new classname[8]
	
	pev(ent,pev_classname,classname,7)
	
	if (equal("grenade",classname,7) && cl_nn_mode[owner] == NANO_CLOAK && get_pcvar_num(pcv_nn_cl_grenade))
	{
		set_nano_energy(owner,0.0,DELAY_CLK_FORCED)
		return FMRES_IGNORED
	}
	if (equal("grenade",classname,7) && cl_nn_mode[owner] == NANO_STREN && containi(model,"c4") == -1 && cl_nn_energy[owner] >= get_pcvar_float(pcv_nn_st_g_throw))
	{
		new Float:v[3], Float:v2[3]
		pev(ent,pev_velocity,v)
		velocity_by_aim(owner, GRENADE_STR_THROW_ADD, v2)
		xs_vec_add(v, v2, v)
		set_pev(ent,pev_velocity,v)
		set_nano_energy(owner,cl_nn_energy[owner] - get_pcvar_float(pcv_nn_st_g_throw),DELAY_STR_G_THROW)
		return FMRES_IGNORED
	}
	
	return FMRES_IGNORED
}

/* ===================================================
[Ham forwards chapter (yummy)]
==================================================== */
public fw_primary_attack(ent)
{
	new id = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, EXTRA_OFFSET_WEAPON_LINUX)
	
	if (cl_nn_weapon[id] == CSW_KNIFE && cl_nn_mode[id] == NANO_STREN && cl_nn_energy[id] >= get_pcvar_float(pcv_nn_st_stab) && cl_nn_has[id] == NANO_YES)
	{
		set_nano_energy(id, cl_nn_energy[id] - get_pcvar_float(pcv_nn_st_stab), DELAY_STR_STAB)
		cl_nn_st_knife[id] = KNIFE_FIRST_ATTACK
		// client_cmd(id,"spk %s",sound_strength_throw)
	}
	
	pev(id,pev_punchangle,cl_nn_punch[id])
	
	if (cl_nn_mode[id] == NANO_CLOAK)
	{
		if (cl_nn_weapon[id] == CSW_KNIFE &&  get_pcvar_num(pcv_nn_cl_knife))
		{
			set_nano_mode(id,NANO_ARMOR)
		}
		
		if (cl_nn_weapon[id] != CSW_KNIFE && get_pcvar_num(pcv_nn_cl_fire))
		{
			set_nano_mode(id,NANO_ARMOR)
		}
	}
	
	new ammo,clip
	get_user_ammo(id, cl_nn_weapon[id], ammo, clip)
	
	if (cs_get_weapon_id(ent) == CSW_M3 || cs_get_weapon_id(ent) == CSW_XM1014)
		cl_nn_shotgun_ammo[id] = ammo
	else
		cl_nn_shotgun_ammo[id] = -1
	
	if (ammo != 0)
		cl_nn_actual_shot[id] = true
	
	return HAM_IGNORED
}

public fw_primary_attack_post(ent)
{
if(!pev_valid(ent)) 
return HAM_IGNORED	
new id = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, EXTRA_OFFSET_WEAPON_LINUX)

if (cl_nn_actual_shot[id] && cl_nn_has[id] && cl_nn_weapon[id] != CSW_KNIFE && cl_nn_mode[id] == NANO_STREN)
{
new Float:push[3]
pev(id,pev_punchangle,push)
xs_vec_sub(push,cl_nn_punch[id],push)
xs_vec_div_scalar(push,get_pcvar_float(pcv_nn_st_rec_att),push)
set_pev(id,pev_punchangle,push)
set_nano_energy(id,cl_nn_energy[id] - get_pcvar_float(pcv_nn_st_rec_en), DELAY_STR_SHOT)
if(cl_nn_energy[id] > 10)
{
if(cl_nn_controlling[id] <= 10 && cl_nn_energy[id] >= 0.1)
{
xs_vec_div_scalar(push,2.0,push)
set_nano_energy(id,cl_nn_energy[id] - 0.1, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 20 && cl_nn_energy[id] >= 0.5)
{
xs_vec_div_scalar(push,1.7,push)
set_nano_energy(id,cl_nn_energy[id] - 0.5, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 30 && cl_nn_energy[id] >= 1.0)
{
xs_vec_div_scalar(push,1.5,push)
set_nano_energy(id,cl_nn_energy[id] - 1.0, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 40 && cl_nn_energy[id] >= 1.3)
{
xs_vec_div_scalar(push,1.4,push)
set_nano_energy(id,cl_nn_energy[id] - 1.3, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 50 && cl_nn_energy[id] >= 1.5)
{
xs_vec_div_scalar(push,1.3,push)
set_nano_energy(id,cl_nn_energy[id] - 1.5, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 60 && cl_nn_energy[id] >= 1.8)
{
xs_vec_div_scalar(push,1.0,push)
set_nano_energy(id,cl_nn_energy[id] - 1.8, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 70 && cl_nn_energy[id] >= 2.0)
{
xs_vec_div_scalar(push,0.9,push)
set_nano_energy(id,cl_nn_energy[id] - 2.0, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 80 && cl_nn_energy[id] >= 2.8)
{
xs_vec_div_scalar(push,0.9,push)
set_nano_energy(id,cl_nn_energy[id] - 2.8, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 85 && cl_nn_energy[id] >= 3.0)
{
xs_vec_div_scalar(push,0.8,push)
set_nano_energy(id,cl_nn_energy[id] - 3.0, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] <= 90 && cl_nn_energy[id] >= 3.0)
{
xs_vec_div_scalar(push,0.8,push)
set_nano_energy(id,cl_nn_energy[id] - 3.0, DELAY_STR_SHOT)
}
else if(cl_nn_controlling[id] >= 95 && cl_nn_energy[id] >= 4.5)
{
xs_vec_div_scalar(push,0.6,push)
set_nano_energy(id,cl_nn_energy[id] - 4.5, DELAY_STR_SHOT)
}
}else{
if(cl_nn_energy[id] > 0)
{
xs_vec_div_scalar(push,0.6,push)
set_nano_energy(id,cl_nn_energy[id] - 0.3, DELAY_STR_SHOT)
}
xs_vec_add(push,cl_nn_punch[id],push)
set_pev(id,pev_punchangle,push)
}
}
if (cl_nn_actual_shot[id] && cl_nn_has[id] && cl_nn_mode[id] == NANO_CLOAK)
{
if(cl_nn_energy[id] >= 4.0)
{
set_nano_energy(id,cl_nn_energy[id] - 4.0, DELAY_CLK_DELAY)
}
cl_nn_block_recharge[id] = DELAY_CLK_DELAY	
}
if (cl_nn_actual_shot[id] && cl_nn_has[id] && cl_nn_mode[id] == NANO_SPEED && cl_nn_energy[id] >= 10)
{
new Float:multi
multi = 1.0
switch (cl_nn_weapon[id])
{
case CSW_DEAGLE,CSW_ELITE,CSW_FIVESEVEN,CSW_P228,CSW_USP,CSW_GLOCK18:
{
multi = REFIRE_PISTOLS
}
case CSW_M3:
{
multi = REFIRE_M3
}
case CSW_KNIFE:
{
multi = REFIRE_KNIFE
static Float:M_Delay
M_Delay = get_pdata_float(ent, OFFSET_WEAPON_NEXT_SEC_ATTACK, EXTRA_OFFSET_WEAPON_LINUX) * multi
set_pdata_float(ent, OFFSET_WEAPON_NEXT_SEC_ATTACK, M_Delay,  EXTRA_OFFSET_WEAPON_LINUX)
}
case CSW_SCOUT,CSW_AWP:
{
multi = REFIRE_SNIPERS
}
}

if (multi != 1.0)
set_nano_energy(id, cl_nn_energy[id] - 10,DELAY_SPD_FAST_ATTACK)

new Float:Delay

Delay = get_pdata_float( ent, OFFSET_WEAPON_NEXT_PRIMARY_ATTACK,  EXTRA_OFFSET_WEAPON_LINUX) * multi
set_pdata_float( ent, OFFSET_WEAPON_NEXT_PRIMARY_ATTACK, Delay,  EXTRA_OFFSET_WEAPON_LINUX)
}

cl_nn_actual_shot[id] = false
return HAM_IGNORED
}

public fw_secondary_attack(ent)
{
new id = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, EXTRA_OFFSET_WEAPON_LINUX)

if (cl_nn_weapon[id] == CSW_KNIFE && cl_nn_mode[id] == NANO_STREN && cl_nn_energy[id] >= get_pcvar_float(pcv_nn_st_stab) && cl_nn_has[id] == NANO_YES)
{
set_nano_energy(id, cl_nn_energy[id] - get_pcvar_float(pcv_nn_st_stab), DELAY_STR_STAB)
cl_nn_st_knife[id] = KNIFE_SECOND_ATTACK
// client_cmd(id,"spk %s",sound_strength_throw)
}

if (cl_nn_mode[id] == NANO_CLOAK)
{
if (cl_nn_weapon[id] == CSW_KNIFE &&  get_pcvar_num(pcv_nn_cl_knife))
{
set_nano_mode(id,NANO_ARMOR)
return HAM_IGNORED
}
}

return HAM_IGNORED
}

public fw_secondary_attack_post(ent)
{
new id = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, EXTRA_OFFSET_WEAPON_LINUX)

if (cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_SPEED && cl_nn_energy[id] >= get_pcvar_float(pcv_nn_critical))
{
new Float:multi = 1.0
switch (cl_nn_weapon[id])
{
case CSW_KNIFE:
{
multi = REFIRE_KNIFE
new	Float:mdelay
mdelay = get_pdata_float( ent, OFFSET_WEAPON_NEXT_SEC_ATTACK, EXTRA_OFFSET_WEAPON_LINUX) * multi
set_pdata_float( ent, OFFSET_WEAPON_NEXT_SEC_ATTACK, mdelay, EXTRA_OFFSET_WEAPON_LINUX)
}
}
if (multi != 1.0)
set_nano_energy(id, cl_nn_energy[id] - get_pcvar_float(pcv_nn_sp_fattack),DELAY_SPD_FAST_ATTACK)

new	Float:delay
delay = get_pdata_float( ent, OFFSET_WEAPON_NEXT_PRIMARY_ATTACK, EXTRA_OFFSET_WEAPON_LINUX) * multi
set_pdata_float( ent, OFFSET_WEAPON_NEXT_PRIMARY_ATTACK, delay, EXTRA_OFFSET_WEAPON_LINUX)
}
return HAM_IGNORED
}

public fw_shotgun_deploy(ent)
{
	new id = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, EXTRA_OFFSET_WEAPON_LINUX)
	cl_nn_shotgun_ammo[id] = cs_get_weapon_ammo(ent)
}

public fw_special_reload_post(ent)
{
	new id = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, EXTRA_OFFSET_WEAPON_LINUX)
	
	new wpn_id	= cs_get_weapon_id(ent)
	new maxammo = wpn_max_clip[wpn_id]
	new curammo = cs_get_weapon_ammo(ent)
	
	if (cl_nn_shotgun_ammo[id] == -1)
	{
		cl_nn_shotgun_ammo[id] = curammo
		return HAM_IGNORED
	}
	else
	{
		if (!(cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_SPEED && cl_nn_energy[id] >= get_pcvar_float(pcv_nn_critical)))
		{
			cl_nn_shotgun_ammo[id] = curammo
			return HAM_IGNORED
		}
		
		if (curammo < cl_nn_shotgun_ammo[id])
			cl_nn_shotgun_ammo[id] = curammo
		
		if (curammo - cl_nn_shotgun_ammo[id] == SH_CARTRAGE_RATIO && cs_get_user_bpammo(id, wpn_id) && curammo + 1 <= maxammo)
		{
			cs_set_weapon_ammo(ent, curammo + 1)
			cs_set_user_bpammo(id, wpn_id, cs_get_user_bpammo(id, wpn_id) - 1)
			cl_nn_shotgun_ammo[id] = curammo + 1
			
			set_nano_energy(id, cl_nn_energy[id] - get_pcvar_float(pcv_nn_sp_fatshre), DELAY_SPD_SH_RELOAD)
			
			// Update hud weapon info, emessage to be blocked if needed
			emessage_begin(MSG_ONE, nd_msg_ammox, {0,0,0}, id)
			ewrite_byte(SH_AMMO_MSG_AMMOID)
			ewrite_byte(curammo + 1)
			emessage_end()
			
		}
	}
	
	return HAM_IGNORED
	
}

public fw_reload_post(ent)
{
	if(get_pdata_int(ent, OFFSET_WEAPON_IN_RELOAD, EXTRA_OFFSET_WEAPON_LINUX))
	{
		new id = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, EXTRA_OFFSET_WEAPON_LINUX)
		
		cl_nn_shotgun_ammo[id] = -1
		
		if (cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_SPEED && cl_nn_energy[id] >= get_pcvar_float(pcv_nn_critical))
		{
			new Float:delay = wpn_reload_delay[get_pdata_int(ent, OFFSET_WEAPON_ID, EXTRA_OFFSET_WEAPON_LINUX)] * RELOAD_RATIO
			
			set_pdata_float(id, OFFSET_PLAYER_NEXT_ATTACK, delay, EXTRA_OFFSET_PLAYER_LINUX)
			set_pdata_float(ent, OFFSET_WEAPON_IDLE_TIME, delay + 0.5, EXTRA_OFFSET_WEAPON_LINUX)
			
			set_nano_energy(id,cl_nn_energy[id] - get_pcvar_float(pcv_nn_sp_reload),DELAY_SPD_FAST_RELOAD)
		}
	}
	
	return HAM_IGNORED
}

public fw_spawn(id)
{
	if (is_user_alive(id))
	{
		msg_shadowidx(id,SHADOW_CREATE)
		nanosuit_reset(id,true)
		cl_nn_zombie[id] = false
		
		if (cl_nn_has[id] == NANO_NO && !cl_is_bot[id] && (get_pcvar_num(pcv_nn_team) == _:cs_get_user_team(id) || get_pcvar_num(pcv_nn_team) != 3) && get_pcvar_num(pcv_nn_price) <= 0)
		{
			if (!zp_get_user_zombie(id))
			{
				cl_nn_has[id] = NANO_YES
				nanosuit_reset(id,true)
			}
		}
		
		if (cl_is_bot[id] && get_pcvar_num(pcv_nn_price) > 0 && get_pcvar_num(pcv_nn_bot) && get_pcvar_num(pcv_nn_bot_buy))
			nanosuit_buy(id)
	}
	
	return HAM_IGNORED
}

public fw_killed(id,attacker,gib)
{
	if (cl_nn_has[id] == NANO_YES)
	{
		msg_statusicon(id,ICON_REMOVE,NanoStatusIcon[cl_nn_mode[id]],NanoScreenColor[cl_nn_mode[id]])
		#if defined USE_WEAPON_STATUSICONS
		msg_statusicon(id,ICON_REMOVE,wpn_ms_icon[cl_nn_weapon[id]],{0,255,0})
		#endif
	}
	
	return HAM_IGNORED
}

public fw_traceattack(victim, attacker, Float:damage, Float:direction[3], tr, damagebits)
{
	new hitzone
	hitzone = get_tr2(tr,TR_iHitgroup)
	damage *= vec_hit_multi[hitzone]
	new Float:origin[3]
	pev(attacker,pev_origin,origin)
	new use_strength
	use_strength = 0
	
	if (cl_nn_has[attacker] && cl_nn_mode[attacker] == NANO_STREN)
	{
		if(cl_nn_controlling[attacker] <= 5)damage *= 1.05
		else if(cl_nn_controlling[attacker] <= 10)damage *= 1.10
		else if(cl_nn_controlling[attacker] <= 15)damage *= 1.15
		else if(cl_nn_controlling[attacker] <= 20)damage *= 1.20
		else if(cl_nn_controlling[attacker] <= 25)damage *= 1.25
		else if(cl_nn_controlling[attacker] <= 30)damage *= 1.30
		else if(cl_nn_controlling[attacker] <= 35)damage *= 1.35
		else if(cl_nn_controlling[attacker] <= 40)damage *= 1.40
		else if(cl_nn_controlling[attacker] <= 45)damage *= 1.45
		else if(cl_nn_controlling[attacker] <= 50)damage *= 1.50
		else if(cl_nn_controlling[attacker] <= 55)damage *= 1.55
		else if(cl_nn_controlling[attacker] <= 60)damage *= 1.60
		else if(cl_nn_controlling[attacker] <= 65)damage *= 1.65
		else if(cl_nn_controlling[attacker] <= 70)damage *= 1.70
		else if(cl_nn_controlling[attacker] <= 75)damage *= 1.75
		else if(cl_nn_controlling[attacker] <= 80)damage *= 1.80
		else if(cl_nn_controlling[attacker] <= 85)damage *= 1.85
		else if(cl_nn_controlling[attacker] <= 90)damage *= 1.90
		else if(cl_nn_controlling[attacker] <= 90)damage *= 1.95
		else if(cl_nn_controlling[attacker] <= 95)damage *= 2.00
		else if(cl_nn_controlling[attacker] <= 100)damage *= 2.05
	}
	
	if (is_user_player(attacker))
	{
		// Strength Mode
		if (get_pcvar_num(pcv_nn_ff))
		{
			if (cs_get_user_team(victim) == cs_get_user_team(attacker))
			{
				damage /= 1.25
				use_strength = 3
			}
			else
			{
				use_strength = 1
			}
		}
		else
		{
			if (cs_get_user_team(victim) == cs_get_user_team(attacker))
			{
				if (get_pcvar_num(pcv_nn_st_can_th))
					use_strength = 1
			}
			else
			{
				use_strength = 1
			}
		}
		
		if (use_strength && cl_nn_has[attacker] == NANO_YES && cl_nn_mode[attacker] == NANO_STREN && CSW_KNIFE == cl_nn_weapon[attacker])
		{
			damage *= 4.0
			
			if (cl_nn_st_knife[attacker] == KNIFE_FIRST_ATTACK)
			{
				new Float:origin[3], Float:origin2[3], Float:throw[3], Float:aimvel[3]
				
				// Get the origin of attacker and victim
				pev(victim,pev_origin,origin)
				pev(attacker,pev_origin,origin2)
				velocity_by_aim(attacker,2,aimvel)
				
				// We need to make a vector between them and we multiply it's value so we can make it powerfull
				xs_vec_sub(origin,origin2,throw)
				xs_vec_div_scalar(throw,xs_vec_len(throw),throw)
				xs_vec_add(throw,aimvel,throw)
				xs_vec_div_scalar(throw,xs_vec_len(throw),throw)
				throw[2] += 0.6
				xs_vec_mul_scalar(throw,get_pcvar_float(pcv_nn_st_throw),throw)
				
				// We add it to the velocity so we can make it a throw
				set_pev(victim,pev_velocity,throw)
				
				// We block the speed of the player so he can't influence the direction of the throw (too much :P)
				set_user_maxspeed(victim, 1.0)
				cl_is_thrown[victim] = attacker
				set_pev(victim,pev_flags,pev(victim,pev_flags) & ~FL_ONGROUND)
			}
			
			cl_nn_st_knife[attacker] = KNIFE_NOT
		}
	}
	
	// Armor Mode
	if ((!is_user_player(attacker)) || (get_pcvar_num(pcv_nn_ff) || ((!get_pcvar_num(pcv_nn_ff) && zp_get_user_zombie(victim) != zp_get_user_zombie(attacker)))))
	{
		if ((get_tr2(tr,TR_iHitgroup) != 8) && cl_nn_has[victim] == NANO_YES && cl_nn_mode[victim] == NANO_ARMOR)
		{
			damage *= get_pcvar_float(pcv_nn_ar_damage)
			
			if (damage < cl_nn_energy[victim])
			{
				set_nano_energy(victim, cl_nn_energy[victim] - damage, DELAY_ARM_DAMAGE)
				set_tr2(tr,TR_iHitgroup,8)
				static Float:vec_end_pos[3]
				get_tr2(tr,TR_vecEndPos,vec_end_pos)
				
				if (hitzone != HIT_GENERIC)
					draw_spark(vec_end_pos)
				
				
				if (random(2) > 0)
				{
					engfunc(EngFunc_EmitSound,victim,CHAN_AUTO,sound_ric_metal1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
				}
				else
				{
					engfunc(EngFunc_EmitSound,victim,CHAN_AUTO,sound_ric_metal2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
				}
				
				set_pev(victim,pev_dmg_inflictor,attacker)
				emsg_damage(victim,0,floatround(damage),damagebits,origin)
				damage = 0.0
			}
			else
			{
				damage -= cl_nn_energy[victim]
				set_nano_energy(victim, 0.0, DELAY_ARM_DAMAGE)
			}
		}
	}
	
	if (use_strength == 2)
		damage *= 1.25
	
	if (hitzone != 8 && damage != 0.0)
		damage /= vec_hit_multi[hitzone]
	
	SetHamParamTraceResult(5,tr)
	SetHamParamFloat(3,damage)
	return HAM_HANDLED
}


public fw_takedamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	new Float:origin[3]
	pev(inflictor,pev_origin,origin)
	
	if (damagebits == DMG_FALL && cl_is_thrown[victim])
	{
		damage *= DMG_FALL_MULTIPLY
		attacker = cl_is_thrown[victim]
		SetHamParamEntity(3, attacker)
	}

	// Armor Mode
	if (((!(inflictor == attacker) || (attacker == victim)) || !is_user_player(attacker)) && cl_nn_has[victim] == NANO_YES && cl_nn_mode[victim] == NANO_ARMOR && ((get_pcvar_num(pcv_nn_ff)) || ((!get_pcvar_num(pcv_nn_ff) && (!is_user_player(attacker) && zp_get_user_zombie(victim) != zp_get_user_zombie(attacker) || attacker == victim)))))
	{
		damage *= get_pcvar_float(pcv_nn_ar_damage)
		
		if (damage < cl_nn_energy[victim])
		{
			set_nano_energy(victim, cl_nn_energy[victim] - damage, DELAY_ARM_DAMAGE)
			set_pev(victim,pev_dmg_inflictor,inflictor)
			emsg_damage(victim,0,floatround(damage),damagebits,origin)
			damage = 0.0
		}
		else
		{
			damage -= cl_nn_energy[victim]
			set_nano_energy(victim, 0.0, DELAY_ARM_DAMAGE)
		}
	}

	if (cl_nn_has[attacker] == NANO_YES && cl_nn_mode[attacker] == NANO_STREN)
	{
				if (cl_nn_energy[attacker] < 100)
						damage *= 1.25


				if (cl_nn_energy[attacker] < 12)
						damage *= 0.75
	}
	
	SetHamParamFloat(4,damage)
	return HAM_HANDLED
}

public fw_takedamage_post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (cl_nn_has[victim] == NANO_YES && cl_nn_mode[victim] == NANO_ARMOR)
	{
		new Float: painshock = get_pdata_float(victim, OFFSET_PLAYER_PAIN_SHOCK, EXTRA_OFFSET_PLAYER_LINUX)
		
		if (painshock == 0.0)
			return HAM_IGNORED
		
		painshock = (0.0 - ((0.0 - painshock) * PAIN_SHOCK_ATTENUATION))
		
		set_pdata_float(victim, OFFSET_PLAYER_PAIN_SHOCK, painshock, EXTRA_OFFSET_PLAYER_LINUX)
	}

	return HAM_IGNORED
}

public fw_bomb_planting(ent)
{
	new planter
	planter = get_pdata_cbase(ent, OFFSET_WEAPON_OWNER, EXTRA_OFFSET_WEAPON_LINUX)
	
	if (cl_nn_has[planter] == NANO_YES && cl_nn_mode[planter] == NANO_CLOAK && get_pcvar_num(pcv_nn_cl_c4))
	{
		set_nano_energy(planter,0.0,DELAY_CLK_FORCED)
	}
	
	return HAM_IGNORED
}

public fw_bomb_defusing(ent, caller, activator, use_type, Float:value)
{
	if (cl_nn_has[caller] == NANO_YES && cl_nn_mode[caller] == NANO_CLOAK && get_pcvar_num(pcv_nn_cl_c4) && cs_get_user_team(caller) == CS_TEAM_CT)
	{
		set_nano_energy(caller,0.0,DELAY_CLK_FORCED)
	}
	
	return HAM_IGNORED
}

/* ===================================================
[Screen think of all players]
==================================================== */
public fw_screenthink(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED
	
	if (ent != nd_ent_monitor)
		return FMRES_IGNORED
	
	new players[32], count, id
	energy = 100.0
	
	get_players(players, count, "ac")
	
	for (new i=0;i<count;i++)
	{
		id = players[i]
		
		if (cl_nn_has[id] == NANO_YES && ((cl_nn_lowres[id] && cl_nn_counter[id] == 0) || !cl_nn_lowres[id]))
		{
			// Current Mode
			static hud[200]
			
			formatex(hud, 199, "%L",id,"NANO_MODE")
			
			switch (cl_nn_mode[id])
			{
				case NANO_STREN: formatex(hud, 199, "%s %L ",hud,id,"NANO_ST_MODE")
				case NANO_ARMOR: formatex(hud, 199, "%s %L ",hud,id,"NANO_A_MODE")
				case NANO_SPEED: formatex(hud, 199, "%s %L ",hud,id,"NANO_S_MODE")
				case NANO_CLOAK: formatex(hud, 199, "%s %L ",hud,id,"NANO_C_MODE")
			}
			
			formatex(hud, 199, "%L",id,"NANO_ENERGY", hud, floatround(cl_nn_energy[id] / energy * 100))
			
			for (new x = 0; x < floatround(cl_nn_energy[id] / energy * 20); x++)
				formatex(hud, 199, "%s|", hud)
			
			formatex(hud, 199, "%s^n", hud)
			
			// Health, Armor, Speed
			//formatex(hud, 199, "%L",id,"NANO_POINTS", hud, get_user_health(id), get_user_armor(id))
			
			switch (cl_nn_scr_speed[id])
			{
				case SPD_SCR_STILL:  formatex(hud, 199, "%L",id,"NANO_SPD_ST", hud)
				case SPD_SCR_VSLOW:  formatex(hud, 199, "%L",id,"NANO_SPD_VS", hud)
				case SPD_SCR_SLOW:   formatex(hud, 199, "%L",id,"NANO_SPD_SL", hud)
				case SPD_SCR_NORMAL: formatex(hud, 199, "%L",id,"NANO_SPD_NO", hud)
				case SPD_SCR_FAST:   formatex(hud, 199, "%L",id,"NANO_SPD_FA", hud)
			}
			
			if (cl_nn_mode[id] == NANO_STREN)
			{
				formatex(hud, 199, "%s^nController:(%d%%)|||||||||||", hud, floatround(cl_nn_controlling[id] / energy * 100))
			}
			
			if (!cl_nn_lowres[id])
			{
				set_hudmessage(NanoScreenColor[cl_nn_mode[id]][0], NanoScreenColor[cl_nn_mode[id]][1], NanoScreenColor[cl_nn_mode[id]][2], 0.025, 0.6, 0, 0.0, 0.2, 0.01)
				ShowSyncHudMsg(id, nd_hud_sync, "%s", hud)
			}
			else
			{
				set_hudmessage(NanoScreenColor[cl_nn_mode[id]][0], NanoScreenColor[cl_nn_mode[id]][1], NanoScreenColor[cl_nn_mode[id]][2], -0.6, 0.5, 0, 0.0, (0.2 + (0.1 * float(NANO_LOW_RES))), 0.0, 0.0)
				ShowSyncHudMsg(id, nd_hud_sync, "%s", hud)
			}
		}
		
		if (cl_nn_counter[id] > 0)
			cl_nn_counter[id] -= 1
		else
			cl_nn_counter[id] = NANO_LOW_RES
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	return FMRES_IGNORED
}

/* ===================================================
[Energy manipulation task]
==================================================== */
public set_energy(id, client)
{
	id -= TASK_ENERGY
	
	if (!(cl_nn_has[id] == NANO_YES))
	{
		remove_task(id + TASK_ENERGY)
		return PLUGIN_CONTINUE
	}
	
	if (!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}
	
	new NanoModes:active = cl_nn_mode[id]
	new Float:energy = cl_nn_energy[id]
	new health = get_user_health(id)
	
	// Decrease when player is running in speed mode
	if (active == NANO_SPEED && pev(id,pev_flags) & ON_LAND_CONST)
	{
		new Float:multi
		
		switch (cl_nn_sp_status[id])
		{
			case SPEED_NORMAL:
			{
				switch (cl_nn_speed[id])
				{
					case SPD_STILL: multi = 0.0
					case SPD_VSLOW: multi = 0.0
					case SPD_SLOW: multi = 0.0
					case SPD_NORMAL: multi = 1.0
					case SPD_FAST: multi = 1.0
				}
				
				energy -= (0.1) * multi
			}
			case SPEED_CRITICAL:
			{
				switch (cl_nn_speed[id])
				{
					case SPD_STILL: multi = 0.0
					case SPD_VSLOW: multi = 0.0
					case SPD_SLOW: multi = 0.0
					case SPD_NORMAL: multi = 0.0
					case SPD_FAST: multi = 1.0
				}
				
				energy -= (0.2) * multi
			}
			case SPEED_MAXIMUM:
			{
				switch (cl_nn_speed[id])
				{
					case SPD_STILL: multi = 0.0
					case SPD_VSLOW: multi = 0.0
					case SPD_SLOW: multi = 0.0
					case SPD_NORMAL: multi = 0.0
					case SPD_FAST:
					{
						multi = 1.0
						// client_cmd(id, "speak %s", sound_speed_run)
					}
				}
				
				energy -= get_pcvar_float(pcv_nn_sp_energy) * multi
			}
		}
		
		if (multi != 0.0)
			cl_nn_block_recharge[id] = DELAY_SPD_RUN + 1
	}
	
	// Decrease in cloak mode
	if (active == NANO_CLOAK)
	{		
		static Float:multi = 1.0
		
		switch (cl_nn_speed[id])
		{
			case SPD_STILL: multi = 0.1
			case SPD_VSLOW: multi = 0.2
			case SPD_SLOW: multi = 0.5
			case SPD_NORMAL: multi = 1.0
			case SPD_FAST: multi = 1.4
		}
		
		energy -= get_pcvar_float(pcv_nn_cl_energy) * multi
	}
	
	if (energy < get_pcvar_num(pcv_nn_critical) && !cl_nn_critical[id])
	{
		cl_nn_critical[id] = true
		cl_nn_online[id] = true
		
		if (!cl_is_bot[id])
		{
			client_cmd(id, "spk %s", sound_critical)
			client_cmd(id, "spk %s", sound_energy)
			client_print(id, print_center, "%L", id, "NANO_CRITIC")
		}
	}

	if (energy >= 100 && cl_nn_online[id])
	{	
		if (!cl_is_bot[id])
		{
			client_cmd(id, "spk %s", sound_online)
			client_print(id, print_center, "-= All systems Online =-")
			cl_nn_online[id] = false
		}
	}

	if (cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_STREN)
	{
		if (energy < 13)
		{
			if (get_gametime() >= cl_nn_damage_time[id])
			{
				if (get_user_health(id) > 5)
				{
					set_user_health(id, min(get_pcvar_num(pcv_nn_health), health - get_pcvar_num(pcv_nn_critical_dmg)))
				}
				cl_nn_damage_time[id] = get_gametime() + get_pcvar_num(pcv_nn_critical_dmg_time)
			}
			
			static SpecIuser2,i
		
			if(get_pcvar_num(pcvarFade1))
			{
				message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
				write_short(1<<10)
				write_short(1<<10)
				write_short(1<<10)
				write_byte(255)
				write_byte(0)
				write_byte(0)
				write_byte(75)
				message_end()
				
				for(i=1;i<=maxplayers;i++)
				{
					if( is_user_connected(i) && !is_user_alive(i) )
					{
						SpecIuser2 = pev( i , pev_iuser2 )
						
						if( SpecIuser2 == client )
					{
						message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
						write_short(1<<10)
						write_short(1<<10)
						write_short(1<<10)
						write_byte(255)
						write_byte(0)
						write_byte(0)
						write_byte(75)
						message_end()
						}
					}
				}
			}
		}
	}
	else if (cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_ARMOR)
	{
		if (energy < 13)
		{
			if (get_gametime() >= cl_nn_damage_time[id])
			{
				if (get_user_health(id) > 5)
				{
					set_user_health(id, min(get_pcvar_num(pcv_nn_health), health - get_pcvar_num(pcv_nn_critical_dmg)))
				}
				cl_nn_damage_time[id] = get_gametime() + get_pcvar_num(pcv_nn_critical_dmg_time)
			}
			
			static SpecIuser2,i
		
			if(get_pcvar_num(pcvarFade1))
			{
				message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
				write_short(1<<10)
				write_short(1<<10)
				write_short(1<<10)
				write_byte(25)
				write_byte(25)
				write_byte(255)
				write_byte(75)
				message_end()
				
				for(i=1;i<=maxplayers;i++)
				{
					if( is_user_connected(i) && !is_user_alive(i) )
					{
						SpecIuser2 = pev( i , pev_iuser2 )
						
						if( SpecIuser2 == client )
					{
						message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
						write_short(1<<10)
						write_short(1<<10)
						write_short(1<<10)
						write_byte(25)
						write_byte(25)
						write_byte(255)
						write_byte(75)
						message_end()
						}
					}
				}
			}
		}
	}
	else if (cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_SPEED)
	{
		if (energy < 13)
		{
			if (get_gametime() >= cl_nn_damage_time[id])
			{
				if (get_user_health(id) > 5)
				{
					set_user_health(id, min(get_pcvar_num(pcv_nn_health), health - get_pcvar_num(pcv_nn_critical_dmg)))
				}
				cl_nn_damage_time[id] = get_gametime() + get_pcvar_num(pcv_nn_critical_dmg_time)
			}
			
			static SpecIuser2,i
		
			if(get_pcvar_num(pcvarFade1))
			{
				message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
				write_short(1<<10)
				write_short(1<<10)
				write_short(1<<10)
				write_byte(253)
				write_byte(247)
				write_byte(0)
				write_byte(50)
				message_end()
				
				for(i=1;i<=maxplayers;i++)
				{
					if( is_user_connected(i) && !is_user_alive(i) )
					{
						SpecIuser2 = pev( i , pev_iuser2 )
						
						if( SpecIuser2 == client )
					{
						message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
						write_short(1<<12)
						write_short(1<<10)
						write_short(1<<10)
						write_byte(253)
						write_byte(247)
						write_byte(0)
						write_byte(50)
						message_end()
						}
					}
				}
			}
		}
	}
	else if (cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_SPEED)
	{
		if (energy < 10)
		{
			if (get_gametime() >= cl_nn_damage_time[id])
			{
				if (get_user_health(id) > 5)
				{
					set_user_health(id, min(get_pcvar_num(pcv_nn_health), health - get_pcvar_num(pcv_nn_critical_dmg)))
				}
				cl_nn_damage_time[id] = get_gametime() + get_pcvar_num(pcv_nn_critical_dmg_time)
			}
		}
	}
	
	if (energy <= 0.0)
	{
		if (active == NANO_CLOAK)
		{
			cl_nn_block_recharge[id] = DELAY_CLK_DELAY
			set_nano_mode(id,NANO_ARMOR)
			#if defined REMOVE_VIEWMODEL_ON_CLOAK
			if (!cl_is_bot[id])
			{
				if (cs_get_user_shield(id) && (WEAPONS_WITH_SHIELD_BITSUM & 1<<cl_nn_weapon[id]))
				{
					set_pev(id,pev_viewmodel2,wpn_v_shield_model[cl_nn_weapon[id]])
				}
				else
					set_pev(id,pev_viewmodel2,wpn_v_model[cl_nn_weapon[id]])
			}
			#endif
		}
		
		energy = 0.0
	}
	
	// Increase but not when in cloak mode
	if (energy < g_nn_energy[id] && cl_nn_mode[id] != NANO_CLOAK && cl_nn_block_recharge[id] == 0)
	{
		static Float:energy2
		if(g_has_fast_energy[id]) { 
		energy2 = 3.0  //regen 
		}
		
		energy2 = get_pcvar_float(pcv_nn_regenerate)
		
		if (pev(id,pev_button) & IN_DUCK && cl_nn_speed[id] == SPD_STILL)
			energy2 *= ENERGY_CROUCH
		
		energy2 += energy
		
		// Useful to block the moment when a player energy is bigger than the maximum energy
		energy = floatmin(g_nn_energy[id], energy2)
		
		if (energy > get_pcvar_float(pcv_nn_critical) + CRITICAL_EXTRA_ADD)
			cl_nn_critical[id] = false
	}
	// White
	if (cl_nn_has[id] == NANO_YES && cl_nn_mode[id] == NANO_CLOAK)
	{
		message_begin(MSG_ONE, g_msgScreenFade, _, id)
		write_short((1<<12)*2) // duration
		write_short(0) // hold time
		write_short(0x0000) // fade type
		write_byte(200) // r
		write_byte(200) // g
		write_byte(200) // b
		write_byte(70) // nvg Alpha
		message_end()
			
		if(get_pcvar_num(pcvarFade1))
		{
			static SpecIuser2,i
					
			for(i=1;i<=maxplayers;i++)
			{
				if(is_user_connected(i) && !is_user_alive(i))
				{
					SpecIuser2 = pev(i , pev_iuser2)
							
					if(SpecIuser2 == id)
					{
						message_begin(MSG_ONE, g_msgScreenFade, _, id)
						write_short((1<<12)*2) // duration
						write_short(0) // hold time
						write_short(0x0000) // fade type
						write_byte(200) // r
						write_byte(200) // g
						write_byte(200) // b
						write_byte(70) // nvg Alpha
						message_end()
					}
				}
			}
		}
	}
		
	if (cl_nn_block_recharge[id] > 0)
		cl_nn_block_recharge[id] -= 1
	
	cl_nn_energy[id] = energy
		
	return PLUGIN_CONTINUE
}

/* ===================================================
[Armor and HitPoints nano recharge]
==================================================== */
public nanosuit_ah_charge(id)
{
	id -= TASK_AH_REC
	
	if (!(cl_nn_has[id] == NANO_YES))
	{
		remove_task(id + TASK_AH_REC)
		return PLUGIN_CONTINUE
	}
	
	if (!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}
	
	static CsArmorType:type
	
	if (cs_get_user_armor(id,type) < get_pcvar_num(pcv_nn_armor) || type != CS_ARMOR_VESTHELM && cl_nn_block_recharge[id] == 0)
		cs_set_user_armor(id, min(get_pcvar_num(pcv_nn_armor), get_user_armor(id) + get_pcvar_num(pcv_nn_ap_charge)), CS_ARMOR_KEVLAR)
	
	static Float:health
	pev(id,pev_health,health)
	
	if (floatround(health,floatround_floor) < get_pcvar_num(pcv_nn_health) && cl_nn_block_recharge[id] == 0)
		set_user_health(id, min(get_pcvar_num(pcv_nn_health), get_user_health(id) + get_pcvar_num(pcv_nn_hp_charge)))
	
	return PLUGIN_CONTINUE
}

/* ===================================================
[Nanosuit prethink functions]
==================================================== */
public nanosuit_functions(id)
{
	if (cl_nn_mode[id] == NANO_SPEED)
	{
		if (cl_nn_energy[id] > get_pcvar_float(pcv_nn_critical))
		{
			if (cl_nn_sp_status[id] == SPEED_NORMAL)
			{
				set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_sp_maxim))
			}
			if (cl_nn_sp_status[id] == SPEED_CRITICAL)
			{
				set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_sp_maxim) / get_pcvar_float(pcv_nn_sp_critic))
			}
			
			cl_nn_sp_status[id] = SPEED_MAXIMUM
		}
		if (get_pcvar_float(pcv_nn_critical) >= cl_nn_energy[id] > 0)
		{
			if (cl_nn_sp_status[id] == SPEED_NORMAL)
			{
				set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_sp_critic))
			}
			if (cl_nn_sp_status[id] == SPEED_MAXIMUM)
			{
				set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_sp_critic) / get_pcvar_float(pcv_nn_sp_maxim))
			}
			
			cl_nn_sp_status[id] = SPEED_CRITICAL
		}
		if (0 >= cl_nn_energy[id])
		{
			if (cl_nn_sp_status[id] == SPEED_MAXIMUM)
			{
				set_user_maxspeed(id,get_user_maxspeed(id) / get_pcvar_float(pcv_nn_sp_maxim))
			}
			if (cl_nn_sp_status[id] == SPEED_CRITICAL)
			{
				set_user_maxspeed(id,get_user_maxspeed(id) / get_pcvar_float(pcv_nn_sp_critic))
			}
			
			cl_nn_sp_status[id] = SPEED_NORMAL
		}
		
		return
	}
	
	if (cl_nn_mode[id] == NANO_STREN)
		set_pev(id, pev_fuser2, 0.0)
	
	if (!is_glowing_in_nano(id))
	if (is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_nemesis(id) && !zp_get_user_survivor(id))
	{
		set_nano_glow(id)
	}
	
	return
}

/* ===================================================
[Bot think task, allows bots to use the nano functions]
==================================================== */
public nanosuit_bot_think(id)
{
	id -= TASK_AI
	
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	if (!cl_is_bot[id])
	{
		remove_task(id + TASK_AI)
		return PLUGIN_CONTINUE
	}
	
	new Float:health
	pev(id,pev_health,health)
	
	if (health < 60.0)
	{
		nanosuit_menu_choose(id,0,_:NANO_ARMOR)
		return PLUGIN_CONTINUE
	}
	
	new hit = -1
	new Float:origin[3]
	pev(id,pev_origin,origin)
	new Float:velocity[3]
	pev(id,pev_velocity,velocity)
	vector_length(velocity)
	
	if (cl_nn_energy[id] > get_pcvar_float(pcv_nn_critical) && floatround(vector_length(velocity)) <= 20)
	{
		nanosuit_menu_choose(id,0,_:NANO_CLOAK)
		return PLUGIN_CONTINUE
	}
	
	if (cl_nn_weapon[id] == CSW_KNIFE)
	{	
		while ((hit = engfunc(EngFunc_FindEntityInSphere, hit, origin, 350.0)))
		{
			if (!is_user_alive(hit))
				continue
			
			if ((get_pcvar_num(pcv_nn_ff)) || (!get_pcvar_num(pcv_nn_ff) && cs_get_user_team(id) != cs_get_user_team(hit)))
			{
				nanosuit_menu_choose(id,0,_:NANO_STREN)
				break
			}
		}
	}
	else
	{
		if (random_num(0,100) <= 40)
			nanosuit_menu_choose(id,0,_:NANO_SPEED)
		else
			nanosuit_menu_choose(id,0,_:NANO_ARMOR)
	}
	
	return PLUGIN_CONTINUE
}

/* ===================================================
[Zombie Functons and Forwards]
==================================================== */
public event_infect(victim, attacker)
{
	cl_nn_zombie[victim] = true
	cl_nn_had[victim] = cl_nn_has[victim]
	cl_nn_has[victim] = NANO_NO
	nanosuit_reset(victim)
	
	return PLUGIN_CONTINUE
}

public zp_user_infected_post(victim, attacker)
{
	cl_nn_had[victim] = cl_nn_has[victim]
	cl_nn_has[victim] = NANO_NO
	nanosuit_reset(victim)
 
	return PLUGIN_CONTINUE
}


public zp_user_humanized_post(id, survivor)
{
	if (!get_pcvar_num(pcv_zm_regive))
		return PLUGIN_CONTINUE
   
	if (is_user_alive(id) && !zp_get_user_survivor(id) && cl_nn_has[id] == NANO_NO)
	{
		cl_nn_has[id] = NANO_YES
		nanosuit_reset(id)
	}
   
	if (zp_get_user_survivor(id))
	{
		client_print(id, print_center,"-= System Shutting Down =-")
		client_cmd(id,"spk %s",sound_slowdown)
		cl_nn_had[id] = NANO_NO
		cl_nn_has[id] = NANO_NO
		nanosuit_reset(id)
	}
   
	return PLUGIN_CONTINUE
}

/* ======================
[Mode Manuals by Aruba]
====================== */
public nanosuit_str_mode(id)
{
	if (!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id) || cl_nn_has[id] == NANO_NO)
	{
		client_print(id, print_center,"%L",id,"NANO_NO")
	}
	else
	{
		nanosuit_menu_choose(id,0,_:NANO_STREN)
		ExecuteHamB(Ham_Player_ResetMaxSpeed,id)
	}
}

public nanosuit_arm_mode(id)
{
	if (!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id) || cl_nn_has[id] == NANO_NO)
	{
		client_print(id, print_center,"%L",id,"NANO_NO")
	}
	else
	{
		nanosuit_menu_choose(id,0,_:NANO_ARMOR)
		ExecuteHamB(Ham_Player_ResetMaxSpeed,id)
	}
}

public nanosuit_spd_mode(id)
{
	if (!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id) || cl_nn_has[id] == NANO_NO)
	{
		client_print(id, print_center,"%L",id,"NANO_NO")
	}
	else
	{
		nanosuit_menu_choose(id,0,_:NANO_SPEED)
		ExecuteHamB(Ham_Player_ResetMaxSpeed,id)
	}
}

public nanosuit_clo_mode(id)
{
	if (!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id) || cl_nn_has[id] == NANO_NO)
	{
		client_print(id, print_center,"%L",id,"NANO_NO")
	}
	else
	{
		nanosuit_menu_choose(id,0,_:NANO_CLOAK)
		ExecuteHamB(Ham_Player_ResetMaxSpeed,id)
	}
}

/* ===================================================
[Functions that come in handy]
==================================================== */
set_nano_mode(id, NanoModes:mode, bool:announce = true)
{
	if (cl_nn_mode[id] == mode)
		return
	
	if (cl_nn_mode[id] == NANO_CLOAK)
	{
		#if defined REMOVE_VIEWMODEL_ON_CLOAK
		if (!cl_is_bot[id])
		{
			if (cs_get_user_shield(id) && (WEAPONS_WITH_SHIELD_BITSUM & 1<<cl_nn_weapon[id]))
			{
				set_pev(id,pev_viewmodel2,wpn_v_shield_model[cl_nn_weapon[id]])
			}
			else
				set_pev(id,pev_viewmodel2,wpn_v_model[cl_nn_weapon[id]])
		}
		#endif
		#if defined USE_WEAPON_STATUSICONS
		msg_statusicon(id,ICON_REMOVE,wpn_ms_icon[cl_nn_weapon[id]],{0,0,0})
		#endif
		
		msg_shadowidx(id,SHADOW_CREATE)
	}
	if (mode == NANO_CLOAK)
	{
		msg_shadowidx(id,SHADOW_REMOVE)
	}
	
	msg_statusicon(id,ICON_REMOVE,NanoStatusIcon[cl_nn_mode[id]],{0,0,0})
	msg_statusicon(id,ICON_SHOW,NanoStatusIcon[mode],NanoScreenColor[mode])
	
	cl_nn_mode[id] = mode
	
	set_nano_glow(id)
	
	if (!cl_is_bot[id] && announce)
	{
		switch (mode)
		{
			case NANO_ARMOR:
			{
				client_cmd(id, "spk %s", sound_switch_armor)
				// client_cmd(id, "spk %s", sound_armor)
				client_print(id, print_center, "%L", id, "NANO_ARM")
				client_cmd(id,"cl_sidespeed 400")
				client_cmd(id,"cl_forwardspeed 400")
				client_cmd(id,"cl_backspeed 400")

				message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
				write_short( 1<<10 )
				write_short( 1<<10 )
				write_short( 1<<12 )
				write_byte(18) // r
				write_byte(54) // g
				write_byte(177) // b
				write_byte(50) // Alpha
				message_end()
				
				if(get_pcvar_num(pcvarFade1))
				{
					static SpecIuser2,i
					
					for(i=1;i<=maxplayers;i++)
					{
						if(is_user_connected(i) && !is_user_alive(i))
						{
							SpecIuser2 = pev(i , pev_iuser2)
							
							if(SpecIuser2 == id)
							{
								message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
								write_short( 1<<10 )
								write_short( 1<<10 )
								write_short( 1<<12 )
								write_byte(18) // r
								write_byte(54) // g
								write_byte(177) // b
								write_byte(50) // Alpha
								message_end()
							}
						}
					}
				}
			}
			case NANO_STREN:
			{
				client_cmd(id, "spk %s", sound_switch_strength)
				// client_cmd(id, "spk %s", sound_strengh)
				client_print(id, print_center, "%L", id, "NANO_STR")
				client_cmd(id,"cl_sidespeed 99999")
				client_cmd(id,"cl_forwardspeed 99999")
				client_cmd(id,"cl_backspeed 99999")

				message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
				write_short( 1<<10 )
				write_short( 1<<10 )
				write_short( 1<<12 )
				write_byte(196) // r
				write_byte(0) // g
				write_byte(5) // b
				write_byte(50) // Alpha
				message_end()

				if(get_pcvar_num(pcvarFade1))
				{
					static SpecIuser2,i
					
					for(i=1;i<=maxplayers;i++)
					{
						if(is_user_connected(i) && !is_user_alive(i))
						{
							SpecIuser2 = pev(i , pev_iuser2)
							
							if(SpecIuser2 == id)
							{
								message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
								write_short( 1<<10 )
								write_short( 1<<10 )
								write_short( 1<<12 )
								write_byte(196) // r
								write_byte(0) // g
								write_byte(5) // b
								write_byte(50) // Alpha
								message_end()
							}
						}
					}
				}
			}
			case NANO_SPEED:
			{
				client_cmd(id, "spk %s", sound_switch_speed)
				// client_cmd(id, "spk %s", sound_speed)
				client_print(id, print_center, "%L", id, "NANO_SPD")
				client_cmd(id,"cl_sidespeed 99999")
				client_cmd(id,"cl_forwardspeed 99999")
				client_cmd(id,"cl_backspeed 99999")

				message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
				write_short( 1<<10 )
				write_short( 1<<10 )
				write_short( 1<<12 )
				write_byte(253) // r
				write_byte(247) // g
				write_byte(0) // b
				write_byte(50) // Alpha
				message_end()

				if(get_pcvar_num(pcvarFade1))
				{
					static SpecIuser2,i
					
					for(i=1;i<=maxplayers;i++)
					{
						if(is_user_connected(i) && !is_user_alive(i))
						{
							SpecIuser2 = pev(i , pev_iuser2)
							
							if(SpecIuser2 == id)
							{
								message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
								write_short( 1<<10 )
								write_short( 1<<10 )
								write_short( 1<<12 )
								write_byte(253) // r
								write_byte(247) // g
								write_byte(0) // b
								write_byte(50) // Alpha
								message_end()
							}
						}
					}
				}
			}
			case NANO_CLOAK:
			{
				#if defined REMOVE_VIEWMODEL_ON_CLOAK
				set_pev(id,pev_viewmodel2,"")
				#endif
				//#if defined USE_WEAPON_STATUSICONS
				//msg_statusicon(id,ICON_SHOW,wpn_ms_icon[cl_nn_weapon[id]],{0,255,0})
				//#endif
				client_cmd(id, "spk %s", sound_switch_cloak)
				// client_cmd(id, "spk %s", sound_cloak)
				client_print(id, print_center, "%L", id, "NANO_CLO")
				client_cmd(id,"cl_sidespeed 99999")
				client_cmd(id,"cl_forwardspeed 99999")
				client_cmd(id,"cl_backspeed 99999")
			}
		}
	}
}

set_nano_energy(id, Float:ammount, delay = 0)
{
	cl_nn_energy[id] = ammount
	if (delay > cl_nn_block_recharge[id])
		cl_nn_block_recharge[id] = delay
	if (ammount == 0.0 && cl_nn_mode[id] == NANO_CLOAK)
	{
		set_nano_mode(id,NANO_ARMOR)
	}
	
	return 1
}

nanosuit_reset(id, bool:affect_user_properties = false)
{
	if (cl_nn_has[id] == NANO_YES)
	{
		set_nano_glow(id)
		
		if (affect_user_properties)
		{
			cl_nn_energy[id] = g_nn_energy[id]
			
			if (cl_nn_mode[id] == NANO_SPEED)
			{
				switch (cl_nn_sp_status[id])
				{
					case SPEED_MAXIMUM: set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_sp_maxim))
					case SPEED_CRITICAL: set_user_maxspeed(id,get_user_maxspeed(id) * get_pcvar_float(pcv_nn_sp_critic))
				}
			}
		}
		
		if (task_exists(id + TASK_ENERGY))
			remove_task(id + TASK_ENERGY)
		
		if (task_exists(id + TASK_AH_REC))
			remove_task(id + TASK_AH_REC)
		
		if (task_exists(id + TASK_AI))
			remove_task(id + TASK_AI)
		
		msg_statusicon(id,ICON_SHOW,NanoStatusIcon[cl_nn_mode[id]],NanoScreenColor[cl_nn_mode[id]])
		
		set_task(0.1,"set_energy",id + TASK_ENERGY, _, _,"b", 0)
		set_task(1.0,"nanosuit_ah_charge",id + TASK_AH_REC, _, _,"b", 0)
		
		if (cl_is_bot[id])
		{
			set_task(2.0,"nanosuit_bot_think",id + TASK_AI, _, _,"b", 0)
		}
	}
	else
	{
		
		if (cl_nn_mode[id] == NANO_SPEED)
		{
			switch (cl_nn_sp_status[id])
			{
				case SPEED_MAXIMUM: set_user_maxspeed(id,get_user_maxspeed(id) / get_pcvar_float(pcv_nn_sp_maxim))
				case SPEED_CRITICAL: set_user_maxspeed(id,get_user_maxspeed(id) / get_pcvar_float(pcv_nn_sp_critic))
			}
		}
		
		if (task_exists(id + TASK_ENERGY))
			remove_task(id + TASK_ENERGY)
		
		if (task_exists(id + TASK_AH_REC))
			remove_task(id + TASK_AH_REC)
		
		if (task_exists(id + TASK_AI))
			remove_task(id + TASK_AI)
	}
}

/* ===================================================
[Controller functions]
==================================================== */
public set_con_energy(id)
{
if(!is_user_alive(id))
return PLUGIN_HANDLED

if(!cl_nn_has[id])
{
client_print(id, print_center,"You don't have Nanosuit!")
return PLUGIN_HANDLED
}

if (cl_nn_mode[id] != NANO_STREN)
return PLUGIN_HANDLED

set_controlling(id)
return PLUGIN_HANDLED
}
public take_con_energy(id)
{
if(!is_user_alive(id))
return PLUGIN_HANDLED

if(!cl_nn_has[id])
{
client_print(id, print_center,"You don't have Nanosuit!")
return PLUGIN_HANDLED
}

if (cl_nn_mode[id] != NANO_STREN)
return PLUGIN_HANDLED

take_controlling(id)
return PLUGIN_HANDLED
}
public set_controlling(id)
{
if (!cl_nn_has[id] && cl_nn_mode[id] != NANO_STREN)
return PLUGIN_CONTINUE

new Float:energy = cl_nn_controlling[id]
if (energy < 100.0)
{
static Float:energy2
energy2 = 5.0
energy2 += energy
energy = floatmin(100.0, energy2)
client_cmd(id, "spk nanosuit/nanosuit_controller.wav")	
}
cl_nn_controlling[id] = energy
return PLUGIN_CONTINUE
}
public take_controlling(id)
{
if (!cl_nn_has[id] && cl_nn_mode[id] != NANO_STREN)
return PLUGIN_CONTINUE

new Float:energy = cl_nn_controlling[id]
if (energy >= 5.0)
{
energy -= 5.0 
client_cmd(id, "spk nanosuit/nanosuit_controller.wav")	
}
cl_nn_controlling[id] = energy
return PLUGIN_CONTINUE
}



/* ===================================================
[Message stocks]
==================================================== */
stock draw_spark(const Float:origin[3])
{
	static o[3]
	o[0] = floatround(origin[0])
	o[1] = floatround(origin[1])
	o[2] = floatround(origin[2])
	emessage_begin(MSG_PVS, SVC_TEMPENTITY, o, 0)
	ewrite_byte(TE_SPARKS)
	ewrite_coord(o[0])
	ewrite_coord(o[1])
	ewrite_coord(o[2])
	emessage_end()	
}

stock emsg_damage(player,dmg_save,dmg_take,dmg_type,Float:origin[3])
{
	set_pev(player,pev_dmg_save,float(dmg_save))
	set_pev(player,pev_dmg_take,float(dmg_take))
	emessage_begin(MSG_ONE, nd_msg_damage, {0,0,0}, player)
	ewrite_byte(dmg_save)
	ewrite_byte(dmg_take)
	ewrite_long(dmg_type)
	ewrite_coord(floatround(origin[0]))
	ewrite_coord(floatround(origin[1]))
	ewrite_coord(floatround(origin[2]))
	emessage_end()
}

stock colored_msg(id,msg[])
{
	message_begin(MSG_ONE, nd_msg_saytext, {0,0,0}, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

stock msg_statusicon(id,IconStatus:mode,icon[],color[3])
{
	if (cl_is_bot[id] || (cl_nn_lowres[id] && mode != ICON_REMOVE))
		return
	
	new msg_type
	if (mode == ICON_REMOVE)
		msg_type = MSG_ONE
	else
	msg_type = MSG_ONE_UNRELIABLE
	
	message_begin(msg_type, nd_msg_iconstatus, {0,0,0}, id)
	write_byte(_:mode)
	write_string(icon)
	write_byte(color[0])
	write_byte(color[1])
	write_byte(color[2])
	message_end()
	
	return
}

stock msg_shadowidx(id, ShadowIdX:long)
{
	if ((cl_removed_shadow[id] && long == SHADOW_REMOVE) || (!cl_removed_shadow[id] && long == SHADOW_CREATE))
	{
		return
	}
	
	if (long == SHADOW_REMOVE)
		cl_removed_shadow[id] = true
	else
		cl_removed_shadow[id] = false
	
	message_begin(MSG_ONE, nd_msg_shadowidx, {0,0,0}, id)
	write_long(_:long)
	message_end()
}

bool:is_glowing_in_nano(id)
{
	if (pev(id, pev_renderfx) != NanoGlowFX[cl_nn_mode[id]])
		return false
	
	if (pev(id, pev_rendermode) != NanoGlowMode[cl_nn_mode[id]])
		return false
	
	static Float:ammount
	pev(id, pev_renderamt, ammount)
	
	if (floatround(ammount) != NanoGlowAmmount[cl_nn_mode[id]])
		return false
	
	return true
}

//Native is made by WaLkMaN - forums.alliedmods.net
public native_set_user_nanosuit(id, set)
{
if(set)
{
cl_nn_has[id] = NANO_YES
nanosuit_reset(id, true)
cl_nn_mode[id] = NANO_ARMOR
ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
}
else
{
cl_nn_had[id] = cl_nn_has[id]
cl_nn_has[id] = NANO_NO
nanosuit_reset(id)
ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
}

}



//Native (+20 energy)
public native_set_user_energy(id, set)
{
	if(set)
	{
		g_nn_energy[id] += 20
	}
}

//Native
public native_get_user_nanosuit(id)
{
	cl_nn_has[id] = NANO_YES
}
