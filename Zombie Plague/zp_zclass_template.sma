/* ================================================================
#	[ZP] Zombie Class Template	#
#			by YankoNL			#
#	   for experienced users	#
# ============================= #
#
#	This plugin is a template to make more customization 
#	to a zombie class for Zombie Plague.
#	Here you can add:
#		- (by default) name, description, player model,
#						knife, health, speed, gravity, knockback
#		- custom player sounds (infect, pain, death)
#		- custom knife sounds (miss slash, wall hit, hit, stab)
#		- custom grenade models
#		- custom ID
#
#	Feel free to modify the attributes to your liking!
#	
================================================================ */
#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>

// If no headshot sounds play - uncomment this
// #define _DEBUG_HEADSHOT_SOUND

// Standart Zombie Attributes
new const zclass_name[] = { "Template Zombie" };
new const zclass_info[] = { "It is a template Zombie" };
new const zclass_model[] = { "template_zombie" };
new const zclass_clawmodel[] = { "v_template_zm.mdl" };
const zclass_health = 3000;
const zclass_speed = 300;
const Float:zclass_gravity = 1.0;
const Float:zclass_knockback = 1.0;

// Custom Zombie Attributes (sounds)
// !!! All must exist and be in the same order !!!
new const zclass_sounds[][] =
{	// Infect sounds 							Sound numbers
	"zpmbie_plague/template/zm_infect1.wav",	// 0 - Infect #1
	"zpmbie_plague/template/zm_infect2.wav",	// 1 - Infect #2

	// Pain sounds
	"zpmbie_plague/template/zm_pain1.wav",		// 2 - Pain #1
	"zpmbie_plague/template/zm_pain2.wav",		// 3 - Pain #2

	// Death sounds
	"zpmbie_plague/template/zm_die1.wav",		// 4 - Death #1
	"zpmbie_plague/template/zm_die2.wav",		// 5 - Death #2

	// Knife sounds
	"zpmbie_plague/template/claw_miss.wav",		// 6 - Slash miss
	"zpmbie_plague/template/claw_hit_wall.wav",	// 7 - Wall hit
	"zpmbie_plague/template/claw_hit1.wav",		// 8 - Player hit #1
	"zpmbie_plague/template/claw_hit2.wav",		// 9 - Player hit #2
	"zpmbie_plague/template/claw_stab.wav"		// 10 - Stab
};

new const g_szGrenadeList[][] =
{
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
};

// Zombie Class Grenade Models
new const zclass_grenades_models[][] =
{
	"models/zombie_plague/template/v_grenade1.mdl",		// 0 - view model HE
	"models/zombie_plague/template/v_grenade2.mdl",		// 1 - view model Flash
	"models/zombie_plague/template/v_grenade3.mdl",		// 2 - view model Smoke
};

// Zombie Class ID (change it for every class)
new i, g_zclass_template;

// Condidions
#define IsCurrClass(%1)		(zp_get_user_zombie_class(%1) == g_zclass_template) // change class ID with the correct ID
#define IsUserZombie(%1)	(zp_get_user_zombie(%1))
#define IsUserNemesis(%1)	(zp_get_user_nemesis(%1))
/*============================================================================*/

public plugin_init()
{
	register_plugin("[ZP] Template Zombie Class (experienced)", "1.0", "YankoNL");

	register_forward(FM_EmitSound, "ZombieSounds");

	for(i = 0; i < sizeof g_szGrenadeList; i++)
		RegisterHam(Ham_Item_Deploy, g_szGrenadeList[i], "OnDeployGrenade", false);
}

public plugin_precache()
{
	// Register the class
	// change the zombie class ID with the correct ID
	g_zclass_template = zp_register_zombie_class(zclass_name, zclass_info, zclass_model,
		zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback);

	// Precache the sounds
	for (i = 0; i < sizeof zclass_sounds; i++)
		precache_sound(zclass_sounds[i]);

	// Precache the grenade models and their sounds (doesn't mater how many)
	for (i = 0; i < sizeof zclass_grenades_models; i++)
	{
		precache_model(zclass_grenades_models[i]);
		PrecacheSoundsFromModel(zclass_grenades_models[i]);
	}
}

public zp_user_infected_post(id, infector)
{
	if(IsCurrClass(id) && !IsUserNemesis(id)) // Check if zombie class is correct after infect
	{	// play random infect sound
		emit_sound(id, CHAN_WEAPON, zclass_sounds[random_num(0, 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		
		// you can print custom info ( comment or delete the line to remove this )
		client_print_color(id, print_team_default,"^4[Zombie Plague] You are ^3%s ^1[^4%s^1]", zclass_name, zclass_info);
	}
}

public ZombieSounds(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these next sounds for this zombie class only
	if (!IsCurrClass(id) && IsUserNemesis(id))
		return FMRES_IGNORED;
	
	// play pain (get hit) sound
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		emit_sound(id, CHAN_WEAPON, zclass_sounds[random_num(2, 3)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		return FMRES_SUPERCEDE;
	}
	
	// Zombie attacks with knife
	if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // play slash miss sound
		{
			emit_sound(id, CHAN_WEAPON, zclass_sounds[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			return FMRES_SUPERCEDE;
		}
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // play hit or wall hit sound
		{
			if (sample[17] == 'w') // wall
			{
				emit_sound(id, CHAN_WEAPON, zclass_sounds[7], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				return FMRES_SUPERCEDE;
			}
			else // hit
			{
				emit_sound(id, CHAN_WEAPON, zclass_sounds[random_num(8, 9)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				return FMRES_SUPERCEDE;
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // play stab sound
		{
			emit_sound(id, CHAN_WEAPON, zclass_sounds[10], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			return FMRES_SUPERCEDE;
		}
	}
	
	// Play random death sound
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		emit_sound(id, CHAN_WEAPON, zclass_sounds[random_num(4, 5)],VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		return FMRES_SUPERCEDE;
	}

	#if defined _DEBUG_HEADSHOT_SOUND
	if (sample[0] == 'p' && sample[1] == 'l') // Fix headshot sound not emitting the pain sounds
	{
		if (sample[7] == 'h' && sample[10] == 'd')
		{
			emit_sound(id, CHAN_WEAPON, zclass_sounds[random_num(2, 3)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			return FMRES_SUPERCEDE;
		}
	}
	#endif
	
	return FMRES_IGNORED;
}

public OnDeployGrenade(iWeapon)
{
	if(pev_valid(iWeapon) != 2)
		return HAM_IGNORED;
    
	new id = get_pdata_cbase(iWeapon, 41, 4);
    
	static entclass[32];
	pev(iWeapon, pev_classname, entclass, 31);
    
	for(i = 0; i < sizeof g_szGrenadeList; i++ )
		if(equal(entclass, g_szGrenadeList[i]))
			set_pev( id, pev_viewmodel2, zclass_grenades_models[i]);

	return HAM_IGNORED;
}

// Check if the grenade model has sound and download it
stock PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					precache_sound(szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}