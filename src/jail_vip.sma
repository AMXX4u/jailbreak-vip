#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <reapi>
#include <CromChat>
#include <jailbreak>

enum _:CVARS
{
	VIP_PLAYER_FLAG[MAX_NAME],
	VIP_HP_PRISONER,
	VIP_HP_GUARD,
	VIP_JUMPS,
	VIP_MODEL_ENABLE
};

enum _:VIP_MODELS
{
	V_DEAGLE,
	P_DEAGLE,
	V_M4A1,
	P_M4A1,
	V_AK47,
	P_AK47
};

static const name[]			= "JB: VIP";
static const version[]		= "1.0";
static const author[]		= "AMXX4u";
static const url_author[]	= "https://amxx4u.pl/";

static const menu_title[]  	= "\d© AMXX4u.pl | VIP^n\r[VIP]\w";
static const menu_prefix[] 	= "\d×\w";
static const chat_prefix[] 	= "&x07[» JB | VIP «]&x01";

static const vip_info[][] =
{
	"/vip",
	"/vipinfo",
	"/v"
};

static const vip_models[][] =
{
	"models/jb_amxx4u/vip_svip/v_deagle_jb.mdl",
	"models/jb_amxx4u/vip_svip/p_deagle_jb.mdl",
	"models/jb_amxx4u/vip_svip/v_m4a1_jb.mdl",
	"models/jb_amxx4u/vip_svip/p_m4a1_jb.mdl",
	"models/jb_amxx4u/vip_svip/v_ak47_jb.mdl",
	"models/jb_amxx4u/vip_svip/p_ak47_jb.mdl"
};

new bool:player_vip[MAX_PLAYERS + 1];
new vip_cvars[CVARS];

public plugin_init()
{
	register_plugin(name, version, author, url_author);

	register_commands(vip_info, sizeof(vip_info), "show_info", ADMIN_USER);

	_register_cvars();
	_register_event();

	CC_SetPrefix(chat_prefix);
}

public plugin_natives()
{
	register_native("get_vip_flag", "_get_vip_flag", 1);
	register_native("get_user_vip", "_get_user_vip", 1);

	register_native("amxx4u_open_vip", "_amxx4u_open_vip", 1);
}

public plugin_precache()
{ 
	ForArray(i, vip_models)
		precache_model(vip_models[i]);
}

public client_authorized(index)
{
	if(is_user_hltv(index))
		return;

	if(_get_user_vip(index))
		player_vip[index] = true;
}

public client_disconnected(index)
{
	if(is_user_hltv(index))
		return;

	if(_get_user_vip(index))
		player_vip[index] = false;
}

public player_equip(index)
{
	if(!player_vip[index])
		return;

	if(get_member(index, m_iTeam) == TEAM_CT)
		set_entvar(index, var_health, Float:get_entvar(index, var_health) + vip_cvars[VIP_HP_GUARD]);

	if(get_member(index, m_iTeam) == TEAM_TERRORIST)
		set_entvar(index, var_health, Float:get_entvar(index, var_health) + vip_cvars[VIP_HP_PRISONER]);

	rg_set_user_armor(index, 100, ARMOR_VESTHELM);
}

public player_spawn(index)
{
	if(!is_user_connected(index) || !is_user_alive(index))
		return PLUGIN_HANDLED;

	if(!player_vip[index])
		return PLUGIN_HANDLED;

	if(get_member(index, m_iTeam) == TEAM_CT)
		set_entvar(index, var_health, vip_cvars[VIP_HP_GUARD]);

	if(get_member(index, m_iTeam) == TEAM_TERRORIST)
		set_entvar(index, var_health, vip_cvars[VIP_HP_PRISONER]);

	rg_set_user_armor(index, 100, ARMOR_VESTHELM);
	return PLUGIN_HANDLED;
}

public show_info(index)
{
	new menu = menu_create(fmt("%s Opis VIP'a:", menu_title), "vip_info_handle");
	new vip_text[MAX_MENU];

	formatex(vip_text, charsmax(vip_text), "^n\
		\d›\w Status\r VIP\w w tabeli^n\
		\d›\w Prefix\r VIP\w na czacie^n\
		\d›\w %d HP jako Wiezien^n\
		\d›\w %d HP jako Straznik^n\
		\d›\w %d dodatkowych skokow",
		vip_cvars[VIP_HP_PRISONER], vip_cvars[VIP_HP_GUARD],
		vip_cvars[VIP_JUMPS]);

	menu_additem(menu, fmt("%s OK!", menu_prefix));
	menu_addtext(menu, vip_text, .slot = 0);

	menu_setprop(menu, MPROP_EXITNAME, fmt("%s Wyjdz", menu_prefix));
	menu_display(index, menu);
}

public vip_info_handle(index, menu)
	menu_destroy(menu);

public players_jump(index)
{
	if(!player_vip[index])
		return;

	new flags = get_entvar(index, var_flags);

	if(~flags & FL_WATERJUMP && get_entvar(index, var_waterlevel) < 2 && get_member(index, m_afButtonPressed) & IN_JUMP)
	{
		static _jump[MAX_PLAYERS + 1];

		if(flags & FL_ONGROUND)
			_jump[index] = 0;
		else if(Float: get_member(index, m_flFallVelocity) < CS_PLAYER_MAX_SAFE_FALL_SPEED && _jump[index]++ < vip_cvars[VIP_JUMPS])
		{
			static Float:vecSrc[3];
			get_entvar(index, var_velocity, vecSrc);

			vecSrc[2] = 268.328157;
			set_entvar(index, var_velocity, vecSrc);
		}
	}
}

public cur_weapon(index)
{
	if(!is_user_alive(index) || !player_vip[index] || vip_cvars[VIP_MODEL_ENABLE] < 1)
		return PLUGIN_HANDLED;

	new weapon_id = read_data(2);

	if(weapon_id == CSW_DEAGLE)
	{
		entity_set_string(index, EV_SZ_viewmodel, vip_models[V_DEAGLE]);
		entity_set_string(index, EV_SZ_weaponmodel, vip_models[P_DEAGLE]);
	}

	if(weapon_id == CSW_M4A1)
	{
		entity_set_string(index, EV_SZ_viewmodel, vip_models[V_M4A1]);
		entity_set_string(index, EV_SZ_weaponmodel, vip_models[P_M4A1]);
	}

	if(weapon_id == CSW_AK47)
	{
		entity_set_string(index, EV_SZ_viewmodel, vip_models[V_AK47]);
		entity_set_string(index, EV_SZ_weaponmodel, vip_models[P_AK47]);
	}

	return PLUGIN_CONTINUE;
}

public vip_status(index, type, ent)
{
	new index = get_msg_arg_int(1);

	if(is_user_alive(index) && player_vip[index])
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | 4);
}

public vip_prefix(index, dest, ent)
{
	new index = get_msg_arg_int(1);

	if(!is_user_connected(index) || !player_vip[index])
		return PLUGIN_CONTINUE;	

	new original_message[MAX_MESSAGE];
	new final_message[MAX_MESSAGE];

	new prefix_vip[MAX_NAME];

	get_msg_arg_string(2, original_message, charsmax(original_message));
	formatex(prefix_vip, charsmax(prefix_vip), "^x04[VIP]^x01");

	if(!equal(original_message, "#Cstrike_Chat_All"))
	{
		add(final_message, charsmax(final_message), "^x01");
		add(final_message, charsmax(final_message), prefix_vip);
		add(final_message, charsmax(final_message), "");
		add(final_message, charsmax(final_message), original_message);
	}
	else
	{
		get_msg_arg_string(4, original_message, charsmax(original_message));
		set_msg_arg_string(4, "");

		add(final_message, charsmax(final_message), prefix_vip);
		add(final_message, charsmax(final_message), "^x03 ");
		add(final_message, charsmax(final_message), fmt("%n", index));
		add(final_message, charsmax(final_message), "^x01: ");
		add(final_message, charsmax(final_message), original_message);
	}

	set_msg_arg_string(2, final_message);
	return PLUGIN_CONTINUE;
}

public _get_vip_flag()
	return vip_cvars[VIP_PLAYER_FLAG];

public _get_user_vip(index)
{
	if(get_user_flags(index) & has_flag(index, vip_cvars[VIP_PLAYER_FLAG]))
		return true;

	return false;
}

public _amxx4u_open_vip(index)
	show_info(index);

_register_cvars()
{
	bind_pcvar_string(create_cvar("vip_player_flag", "t",
		.description = "Jaką flagę gracz musi posiadać, aby otrzymać VIP'a"), vip_cvars[VIP_PLAYER_FLAG], charsmax(vip_cvars[VIP_PLAYER_FLAG]));

	bind_pcvar_num(create_cvar("vip_health_prisoner", "30",
		.description = "+ ile HP (od 100) ma otrzymywać wiezien?"), vip_cvars[VIP_HP_PRISONER]);

	bind_pcvar_num(create_cvar("vip_health_guard", "60",
		.description = "+ ile HP (od 100) ma otrzymywać straznik?"), vip_cvars[VIP_HP_GUARD]);

	bind_pcvar_num(create_cvar("vip_jumps", "1",
		.description = "Ile dodatkowych skokow ma miec VIP?"), vip_cvars[VIP_JUMPS]);

	bind_pcvar_num(create_cvar("vip_model_enable", "1",
		.description = "Czy modele broni maja byc wlaczone? 1 - tak, 0 - nie"), vip_cvars[VIP_MODEL_ENABLE]);

	create_cvar("amxx4u_pl", VERSION, FCVAR_SERVER);
}

_register_event()
{
	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "player_equip", 1);
	RegisterHookChain(RG_CBasePlayer_Jump, "players_jump", 1);

	register_message(get_user_msgid("ScoreAttrib"), "vip_status");
	register_message(get_user_msgid("SayText"), "vip_prefix");

	register_event("CurWeapon", "cur_weapon", "be", "1=1");
}