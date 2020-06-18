#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION		"1.0.0"
public Plugin myinfo = {
	name = "[TF2] Pass the Stats",
	author = "easye",
	description = "Stats for Competitve 4v4 Passtime",
	version = "PLUGIN_VERSION",
	url=""
}


//playerArray: 0 = scores, 1 = interceptions, 2 = steals
int playerArray[MAXPLAYERS][3];
ConVar statsEnable;


public void OnPluginStart() {
	statsEnable = CreateConVar("sm_passthestats_enabled", "1", "Enables passtime stats")
	CreateConVar("sm_passthestats_version", PLUGIN_VERSION, "*DONT MANUALLY CHANGE* PassTheStats Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	
	char mapName[64], prefix[16];
        GetCurrentMap(mapName, sizeof(mapName));
	prefix[0] = mapName[0], prefix[1] = mapName[1];
        if (StrEqual("pa", prefix)) statsEnable.SetInt(1);
        else statsEnable.SetInt(0);
	
	HookEvent("teamplay_round_win", Event_TeamWin, EventHookMode_Post);
	HookEvent("pass_score", Event_PassScore, EventHookMode_Post);
	HookEvent("pass_pass_caught", Event_PassCaught, EventHookMode_Post);
	HookEvent("pass_ball_stolen", Event_PassStolen, EventHookMode_Post);
}


public Action Event_PassScore(Event event, const char[] name, bool dontbroadcast) {
	if (!statsEnable.BoolValue) return Plugin_Handled;

	int client = event.GetInt("scorer")
	if (!IsValidClient(client)) return Plugin_Handled;
	char playerName[64];
	GetClientName(client, playerName, sizeof(playerName));
	PrintToChatAll("\x0700ffff[PASS] %s\x073BC43B scored a goal!", playerName);
	playerArray[client][0]++;
	return Plugin_Handled;
}

public Action Event_PassCaught(Event event, const char[] name, bool dontBroadcast) {
	if (!statsEnable.BoolValue) return Plugin_Handled;

	int passer = event.GetInt("passer");
	int catcher = event.GetInt("catcher");
	if (TF2_GetClientTeam(passer) == TF2_GetClientTeam(catcher)) return Plugin_Handled;
	if (TF2_GetClientTeam(passer) == TFTeam_Spectator || TF2_GetClientTeam(catcher) == TFTeam_Spectator) return Plugin_Handled;

	char passerName[64], catcherName[64];
	GetClientName(passer, passerName, 64);
	GetClientName(catcher, catcherName, 64);
	PrintToChatAll("\x0700ffff[PASS] %s \x07ff00ffintercepted \x0700ffff%s!", catcherName, passerName);
	playerArray[catcher][1]++;

	return Plugin_Handled;	
}

public Action Event_PassStolen(Event event, const char[] name, bool dontBroadcast) {
	if (!statsEnable.BoolValue) return Plugin_Handled;

	int thief = event.GetInt("attacker");
	int victim = event.GetInt("victim");
	char thiefName[64], victimName[64];
	GetClientName(thief, thiefName, 64);
	GetClientName(victim, victimName, 64);
	PrintToChatAll("\x0700ffff[PASS] %s\x07ff8000 stole from\x0700ffff %s!", thiefName, victimName);
	playerArray[thief][2]++;

	return Plugin_Handled;
}

public Action Event_TeamWin(Event event, const char[] name, bool dontBroadcast) {
	if (!statsEnable.BoolValue) return Plugin_Handled;	
	displayStats();
	return Plugin_Handled;
}

//this is really fucking sloppy but shrug
public void displayStats() {
	int redTeam[16], bluTeam[16];
	int redCursor, bluCursor = 0;
	for (int x=1; x < MaxClients+1; x++) {
		if (!IsValidClient(x)) continue;

		if (TF2_GetClientTeam(x) == TFTeam_Red) {
			redTeam[redCursor] = x;
			redCursor++;
		}

		else if (TF2_GetClientTeam(x) == TFTeam_Blue) {
			bluTeam[bluCursor] = x;
			bluCursor++;
		}
	}
	for (int x=1; x < MaxClients+1; x++) {
		if (!IsValidClient2(x)) continue;
		
		if (TF2_GetClientTeam(x) == TFTeam_Red) {
			for (int i=0; i < bluCursor; i++) {
				char playerName[64];
				GetClientName(bluTeam[i], playerName, sizeof(playerName))
				PrintToChat(x, "\x0700ffff[PASS]\x074EA6C1 %s:\x073BC43B goals %d,\x07ff00ff intercepts %d,\x07ff8000 steals %d", playerName, playerArray[bluTeam[i]][0], playerArray[bluTeam[i]][1], playerArray[bluTeam[i]][2])
			}

			for (int i=0; i < redCursor; i++) {
				char playerName[64];
				GetClientName(redTeam[i], playerName, sizeof(playerName))
				PrintToChat(x, "\x0700ffff[PASS]\x07C43F3B %s:\x073BC43B goals %d,\x07ff00ff intercepts %d,\x07ff8000 steals %d", playerName, playerArray[redTeam[i]][0], playerArray[redTeam[i]][1], playerArray[redTeam[i]][2])
			}
		}

		else if (TF2_GetClientTeam(x) == TFTeam_Blue|| TF2_GetClientTeam(x) == TFTeam_Spectator) {
			for (int i=0; i < redCursor; i++) {
                                 char playerName[64];
                                 GetClientName(redTeam[i], playerName, sizeof(playerName))
                                 PrintToChat(x, "\x0700ffff[PASS]\x07C43F3B %s:\x073BC43B goals %d,\x07ff00ff intercepts %d,\x07ff8000 steals %d", playerName, playerArray[redTeam[i]][0], playerArray[redTeam[i]][1], playerArray[redTeam[i]][2])
                         }

			for (int i=0; i < bluCursor; i++) {
				char playerName[64];
				GetClientName(bluTeam[i], playerName, sizeof(playerName))
				PrintToChat(x, "\x0700ffff[PASS]\x074EA6C1 %s:\x073BC43B goals %d,\x07ff00ff intercepts %d,\x07ff8000 steals %d", playerName, playerArray[bluTeam[i]][0], playerArray[bluTeam[i]][1], playerArray[bluTeam[i]][2])
			}

		}
	}

}

//i have two of these because i have no friends so i test with robots
public bool IsValidClient(int client) {
	if (client > 4096) client = EntRefToEntIndex(client);
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (IsFakeClient(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	return true;
}

public bool IsValidClient2(int client) {
	if (client > 4096) client = EntRefToEntIndex(client);
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	return true;
}
