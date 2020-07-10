#include <sourcemod>
#include <tf2_stocks>


#define PLUGIN_VERSION		"1.2.0"
bool deadPlayers[MAXPLAYERS + 1];
ConVar stockEnable, respawnEnable, clearHud;

public Plugin myinfo = {
	name = "[TF2] PasstimeControl",
	author = "EasyE",
	description = "Intended for 4v4 Competitive Passtime use. Can prevent players from using shotgun, stickies, and needles. Can disable the screenoverlay blur effect after intercepting or stealing the jack.",
	version = PLUGIN_VERSION,
	url = "https://github.com/eaasye/passtime"
}

public void OnPluginStart() {
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", Event_PlayerResup, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	AddCommandListener(OnChangeClass, "joinclass");

	stockEnable = CreateConVar("sm_passtime_whitelist", "0", "Enables/Disables passtime stock weapon locking");
	respawnEnable = CreateConVar("sm_passtime_respawn", "0", "Enables/disables fixed respawn time");
	clearHud = CreateConVar("sm_passtime_hud", "1", "Enables/Disables blocking the blur effect after intercepting or stealing the ball");
	CreateConVar("sm_passtimecontrol_version", PLUGIN_VERSION, "*DONT MANUALLY CHANGE* Passtime-Control Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
}

public void OnClientDisconnect(int client) {
	deadPlayers[client] = false;
}

public void TF2_OnConditionAdded(int client, TFCond condition) {
	if (condition == TFCond_PasstimeInterception && clearHud.BoolValue) {
		ClientCommand(client, "r_screenoverlay \"\"");
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	deadPlayers[client] = true;
}


public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	deadPlayers[client] = false;
	RemoveShotty(client);
}

public Action Event_PlayerResup(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	RemoveShotty(client);
}

public Action OnChangeClass(int client, const char[] strCommand, int args) {
    if(deadPlayers[client] == true && respawnEnable.BoolValue) {
        PrintCenterText(client, "You cant change class yet.");
        return Plugin_Handled;
    }
        
    return Plugin_Continue;
}


public void RemoveShotty(int client) {
	if(stockEnable.BoolValue) {
		TFClassType class = TF2_GetPlayerClass(client);
		int iWep;
		if (class == TFClass_DemoMan || class == TFClass_Soldier) iWep = GetPlayerWeaponSlot(client, 1)
		else if (class == TFClass_Medic) iWep = GetPlayerWeaponSlot(client, 0);

		if(iWep >= 0) {
			char classname[64];
			GetEntityClassname(iWep, classname, sizeof(classname));
			
			if (StrEqual(classname, "tf_weapon_shotgun_soldier") || StrEqual(classname, "tf_weapon_pipebomblauncher")) {
				PrintToChat(client, "\x07ff0000 [PASS] Shotgun/Stickies equipped");
				TF2_RemoveWeaponSlot(client, 1);
			}

			if (StrEqual(classname, "tf_weapon_syringegun_medic")) {
				PrintToChat(client, "\x07ff0000 [PASS] Syringe Gun equipped");
				TF2_RemoveWeaponSlot(client, 0);
			}

		}
	}
}
