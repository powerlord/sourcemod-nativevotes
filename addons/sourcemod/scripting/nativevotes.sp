/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes
 * Copyright (C) 2011-2012 Ross Bemrose (Powerlord).  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>
#include <sdktools>

#include "include/nativevotes.inc"

// SourceMod 1.4 compatibility shim
#if !defined SOURCE_SDK_CSGO
	#define SOURCE_SDK_CSGO					80		/**< Engine released after CS:GO (no SDK yet) */
#endif
 
#define VOTE_DELAY_TIME 					3.0

// SourceMod uses these internally, so... we do too.
#define VOTE_NOT_VOTING 					-2
#define VOTE_PENDING 						-1

#define VERSION "0.1 alpha"

//----------------------------------------------------------------------------
// These values are swapped from their NativeVotes equivalent
#define L4D2_VOTE_YES_INDEX					1
#define L4D2_VOTE_NO_INDEX					0

#define L4DL4D2_COUNT						2
#define TF2CSGO_COUNT						5

//----------------------------------------------------------------------------
// Translation strings

//----------------------------------------------------------------------------
// L4D/L4D2

#define L4D_VOTE_KICK_START					"#L4D_vote_kick_player"
#define L4D_VOTE_KICK_PASSED				"#L4D_vote_passed_kick_player"

// User vote to restart map.
#define L4D_VOTE_RESTART_START				"#L4D_vote_restart_game"
#define L4D_VOTE_RESTART_PASSED				"#L4D_vote_passed_restart_game"

// User vote to change maps.
#define L4D_VOTE_CHANGECAMPAIGN_START		"#L4D_vote_mission_change"
#define L4D_VOTE_CHANGECAMPAIGN_PASSED		"#L4D_vote_passed_mission_change"
#define L4D_VOTE_CHANGELEVEL_START			"#L4D_vote_chapter_change"
#define L4D_VOTE_CHANGELEVEL_PASSED			"#L4D_vote_passed_chapter_change"

// User vote to return to lobby.
#define L4D_VOTE_RETURNTOLOBBY_START		"#L4D_vote_return_to_lobby"
#define L4D_VOTE_RETURNTOLOBBY_PASSED		"#L4D_vote_passed_return_to_lobby"

// User vote to change difficulty.
#define L4D_VOTE_CHANGEDIFFICULTY_START		"#L4D_vote_change_difficulty"
#define L4D_VOTE_CHANGEDIFFICULTY_PASSED	"#L4D_vote_passed_change_difficulty"

// While not a vote string, it works just as well.
#define L4D_VOTE_CUSTOM						"#L4D_TargetID_Player"

//----------------------------------------------------------------------------
// L4D2

// User vote to change alltalk.
#define L4D2_VOTE_ALLTALK_START				"#L4D_vote_alltalk_change"
#define L4D2_VOTE_ALLTALK_PASSED			"#L4D_vote_passed_alltalk_change"
#define L4D2_VOTE_ALLTALK_ENABLE			"#L4D_vote_alltalk_enable"
#define L4D2_VOTE_ALLTALK_DISABLE			"#L4D_vote_alltalk_disable"

//----------------------------------------------------------------------------
// TF2/CSGO
#define TF2CSGO_VOTE_PREFIX					"option"

//----------------------------------------------------------------------------
// TF2
// User vote to kick user.
#define TF2_VOTE_KICK_IDLE_START			"#TF_vote_kick_player_idle"
#define TF2_VOTE_KICK_SCAMMING_START		"#TF_vote_kick_player_scamming"
#define TF2_VOTE_KICK_CHEATING_START		"#TF_vote_kick_player_cheating"
#define TF2_VOTE_KICK_START					"#TF_vote_kick_player_other"
#define TF2_VOTE_KICK_PASSED				"#TF_vote_passed_kick_player"

// User vote to restart map.
#define TF2_VOTE_RESTART_START				"#TF_vote_restart_game"
#define TF2_VOTE_RESTART_PASSED				"#TF_vote_passed_restart_game"

// User vote to change maps.
#define TF2_VOTE_CHANGELEVEL_START			"#TF_vote_changelevel"
#define TF2_VOTE_CHANGELEVEL_PASSED			"#TF_vote_passed_changelevel"

// User vote to change next level.
#define TF2_VOTE_NEXTLEVEL_SINGLE_START		"#TF_vote_nextlevel"
#define TF2_VOTE_NEXTLEVEL_MULTIPLE_START	"#TF_vote_nextlevel_choices" // Started by server
#define TF2_VOTE_NEXTLEVEL_EXTEND_PASSED	"#TF_vote_passed_nextlevel_extend"
#define TF2_VOTE_NEXTLEVEL_PASSED			"#TF_vote_passed_nextlevel"

// User vote to scramble teams.  Can be immediate or end of round.
#define TF2_VOTE_SCRAMBLE_IMMEDIATE_START	"#TF_vote_scramble_teams"
#define TF2_VOTE_SCRAMBLE_ROUNDEND_START	"#TF_vote_should_scramble_round"
#define TF2_VOTE_SCRAMBLE_PASSED 			"#TF_vote_passed_scramble_teams"

// User vote to change MvM mission
#define TF2_VOTE_CHANGEDIFFICULTY_START		"#TF_vote_changechallenge"
#define TF2_VOTE_CHANGEDIFFICULTY_PASSED	"#TF_vote_passed_changechallenge"

// While not a vote string, it works just as well.
#define TF2_TRANSLATION_VOTE_CUSTOM			"#TF_playerid_noteam"

//----------------------------------------------------------------------------
// CSGO
// User vote to kick user.
#define CSGO_VOTE_KICK_IDLE_START			"#SFUI_vote_kick_player_idle"
#define CSGO_VOTE_KICK_SCAMMING_START		"#SFUI_vote_kick_player_scamming"
#define CSGO_VOTE_KICK_CHEATING_START		"#SFUI_vote_kick_player_cheating"
#define CSGO_VOTE_KICK_START				"#SFUI_vote_kick_player_other"
#define CSGO_VOTE_KICK_PASSED				"#SFUI_vote_passed_kick_player"

// User vote to restart map.
#define CSGO_VOTE_RESTART_START				"#SFUI_vote_restart_game"
#define CSGO_VOTE_RESTART_PASSED			"#SFUI_vote_passed_restart_game"

// User vote to change maps.
#define CSGO_VOTE_CHANGELEVEL_START			"#SFUI_vote_changelevel"
#define CSGO_VOTE_CHANGELEVEL_PASSED		"#SFUI_vote_passed_changelevel"

// User vote to change next level.
#define CSGO_VOTE_NEXTLEVEL_SINGLE_START	"#SFUI_vote_nextlevel"
#define CSGO_VOTE_NEXTLEVEL_MULTIPLE_START	"#SFUI_vote_nextlevel_choices" // Started by server
#define CSGO_VOTE_NEXTLEVEL_EXTEND_PASSED	"#SFUI_vote_passed_nextlevel_extend"
#define CSGO_VOTE_NEXTLEVEL_PASSED			"#SFUI_vote_passed_nextlevel"

// User vote to scramble teams.  Can be immediate or end of round.
#define CSGO_VOTE_SCRAMBLE_START			"#SFUI_vote_scramble_teams"
#define CSGO_VOTE_SCRAMBLE_PASSED 			"#SFUI_vote_passed_scramble_teams"

#define CSGO_VOTE_SWAPTEAMS_START			"#SFUI_vote_swap_teams"
#define CSGO_VOTE_SWAPTEAMS_PASSED 			"#SFUI_vote_passed_swap_teams"

// While not a vote string, it works just as well.
#define CSGO_VOTE_CUSTOM					"#SFUI_Scoreboard_NormalPlayer"

//----------------------------------------------------------------------------
// Global Variables
new g_GameVersion = SOURCE_SDK_UNKNOWN;

new Float:g_NextVote = 0.0;

new g_VoteController;

//----------------------------------------------------------------------------
// CVars
new Handle:g_Cvar_VoteHintbox;
new Handle:g_Cvar_VoteChat;
new Handle:g_Cvar_VoteConsole;
new Handle:g_Cvar_VoteClientConsole;
new Handle:g_Cvar_VoteDelay;

new Handle:g_Forward_VoteResults;

// Public Forwards

new Handle:g_Forward_OnCallVoteSetup;
new Handle:g_Forward_OnCallVote;

//----------------------------------------------------------------------------
// Used to track current vote data
new g_Clients;
new g_TotalClients;
new g_Items;
new Handle:g_hVotes;
new Handle:g_hCurVote;
new bool:g_bStarted;
new bool:g_bCancelled;
new bool:g_bWasCancelled;
new g_NumVotes;
new g_VoteTime;
new g_VoteFlags;
new Float:g_fStartTime;
new g_nVoteTime;
new g_TimeLeft;
new g_ClientVotes[MAXPLAYERS+1];
new bool:g_bRevoting[MAXPLAYERS+1];
new String:g_LeaderList[1024];
new Handle:g_DisplayTimer;

public Plugin:myinfo = 
{
	name = "NativeVotes",
	author = "Powerlord",
	description = "Voting API to use the game's native vote panels. Compatible with L4D, L4D2, TF2, and CS:GO.",
	version = VERSION,
	url = "<- URL ->"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Guess which game we're using.
	g_GameVersion = GuessSDKVersion();
	
	new bool:load;
	
	switch(g_GameVersion)
	{
		case SOURCE_SDK_EPISODE2VALVE:
		{
			decl String:gameFolder[8];
			GetGameFolderName(gameFolder, PLATFORM_MAX_PATH);
			if (StrEqual(gameFolder, "tf", false) || StrEqual(gameFolder, "tf_beta", false))
			{
				load = true;
			}
			else
			{
				// Fail for HL2:MP, DoD:S, and CS:S
				load = false;
			}
		}
		
		case SOURCE_SDK_LEFT4DEAD, SOURCE_SDK_LEFT4DEAD2, SOURCE_SDK_CSGO:
		{
			load = true;
		}
		
		default:
		{
			load = false;
		}
	}
	
	if (!load)
	{
		strcopy(error, err_max, "NativeVotes only supports L4D, L4D2, TF2, and CS:GO");
		return APLRes_Failure;
	}
	
	CreateNative("NativeVotes_IsVoteTypeSupported", Native_IsVoteTypeSupported);
	CreateNative("NativeVotes_Create", Native_Create);
	CreateNative("NativeVotes_Close", Native_Close);
	CreateNative("NativeVotes_Display", Native_Display);
	CreateNative("NativeVotes_AddItem", Native_AddItem);
	CreateNative("NativeVotes_InsertItem", Native_InsertItem);
	CreateNative("NativeVotes_RemoveItem", Native_RemoveItem);
	CreateNative("NativeVotes_RemoveAllItems", Native_RemoveAllItems);
	CreateNative("NativeVotes_GetItem", Native_GetItem);
	CreateNative("NativeVotes_GetItemCount", Native_GetItemCount);
	CreateNative("NativeVotes_SetArgument", Native_SetArgument);
	CreateNative("NativeVotes_GetArgument", Native_GetArgument);
	CreateNative("NativeVotes_IsVoteInProgress", Native_IsVoteInProgress);
	CreateNative("NativeVotes_GetMaxItems", Native_GetMaxItems);
	CreateNative("NativeVotes_SetOptionFlags", Native_SetOptionFlags);
	CreateNative("NativeVotes_GetOptionFlags", Native_GetOptionFlags);
	CreateNative("NativeVotes_SetResultCallback", Native_SetResultCallback);
	CreateNative("NativeVotes_CheckVoteDelay", Native_CheckVoteDelay);
	CreateNative("NativeVotes_IsClientInVotePool", Native_IsClientInVotePool);
	CreateNative("NativeVotes_RedrawClientVote", Native_RedrawClientVote);
	CreateNative("NativeVotes_GetType", Native_GetType);
	CreateNative("NativeVotes_SetTeam", Native_SetTeam);
	CreateNative("NativeVotes_GetTeam", Native_GetTeam);
	CreateNative("NativeVotes_SetInitiator", Native_SetInitiator);
	CreateNative("NativeVotes_GetInitiator", Native_GetInitiator);
	CreateNative("NativeVotes_DisplayPass", Native_DisplayPass);
	CreateNative("NativeVotes_DisplayPassEx", Native_DisplayPassEx);
	CreateNative("NativeVotes_DisplayFail", Native_DisplayFail);
	
	RegPluginLibrary("nativevotes");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("core.phrases");
	
	CreateConVar("nativevotes_version", VERSION, "NativeVotes API version", FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_Cvar_VoteHintbox = CreateConVar("nativevotes_progress_hintbox", "0", "Specifies whether or not to display vote progress to clients in the\n\"hint\" box (near the bottom of the screen in most games).\nValid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteChat = CreateConVar("nativevotes_progress_chat", "0", "Specifies whether or not to display vote progress to clients in the\nchat area. Valid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteConsole = CreateConVar("nativevotes_progress_chat", "0", "Specifies whether or not to display vote progress in the server console.\nValid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteClientConsole = CreateConVar("nativevotes_progress_client_console", "0", "Specifies whether or not to display vote progress to clients in the\nclient console. Valid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteDelay = CreateConVar("nativevotes_vote_delay", "30", "Sets the recommended time in between public votes", FCVAR_NONE, true, 0.0, true);
	
	HookConVarChange(g_Cvar_VoteDelay, OnVoteDelayChange);

	AddCommandListener(Command_Vote, "vote"); // TF2, CS:GO
	AddCommandListener(Command_Vote, "Vote"); // L4D, L4D2
	
	g_Forward_OnCallVoteSetup = CreateForward(ET_Event, Param_Array);
	g_Forward_OnCallVote = CreateForward(ET_Ignore, Param_Cell, Param_String, Param_Cell);
	
	AutoExecConfig(true, "nativevotes");
}

public OnConfigsExecuted()
{
	// This is done every map for safety reasons... it usually doesn't change
	g_VoteController = FindEntityByClassname(-1, "vote_controller");
	if (g_VoteController == INVALID_ENT_REFERENCE)
	{
		LogError("Could not find Vote Controller.");
	}
}

public Action:Command_VCallote(client, const String:command[], argc)
{
}


public OnVoteDelayChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	/* See if the new vote delay isn't something we need to account for */
	if (GetConVarFloat(convar) < 1.0)
	{
		g_NextVote = 0.0;
		return;
	}
	
	/* If there was never a last vote, ignore this change */
	if (g_NextVote < 0.1)
	{
		return;
	}
	
	/* Subtract the original value, then add the new one. */
	g_NextVote -= StringToFloat(oldValue);
	g_NextVote += GetConVarFloat(convar);
}

public OnMapEnd()
{
	if (g_hCurVote != INVALID_HANDLE)
	{
		// Cancel the ongoing vote, but don't close the handle, as the other plugin may still re-use it
		OnVoteCancel(g_hCurVote, NativeVotesFail_Generic);
		g_hCurVote = INVALID_HANDLE;
	}

	g_hVoteTimer = INVALID_HANDLE;
}

public Action:Command_Vote(client, const String:command[], argc)
{
	// If we're not running a vote, return the vote control back to the server
	if (!Handler_IsVoteInProgress())
	{
		return Plugin_Continue;
	}
	
	decl String:vote[32];
	GetCmdArg(1, vote, sizeof(vote));
	
	new item;
	
	new bool:success = Game_ParseVote(vote, item);
	
	if (!success)
	{
		return Plugin_Handled;
	}
	
	//TODO More voting logic
	
	Game_ClientSelectedItem(client, item);
	
	return Plugin_Handled;
}

OnVoteSelect(Handle:vote, client, item)
{
	DoAction(vote, MenuAction_Select, client, item);
}

OnEnd(Handle:vote)
{
	DoAction(vote, MenuAction_End, 0, 0);
}

OnVoteEnd(Handle:vote, item)
{
	DoAction(vote, MenuAction_VoteEnd, item, 0);
}

OnVoteStart(Handle:vote)
{
	// Fire both Start and VoteStart in the other plugin.
	
	DoAction(vote, MenuAction_Start, 0, 0);
	
	DoAction(vote, MenuAction_VoteStart, 0, 0);
}

OnVoteCancel(Handle:vote, NativeVotesFailType:reason)
{
	DoAction(vote, MenuAction_VoteCancel, reason, 0);
}

DoAction(Handle:vote, MenuAction action, param1, param2, Action:def_res = Plugin_Continue)
{
	new Action:res = def_res;
	
	new Handle:handler = Data_GetHandler(vote);
	Call_StartForward(handler);
	Call_PushCell(vote);
	Call_PushCell(action);
	Call_PushCell(param1);
	Call_PushCell(param2);
	Call_Finish(res);
	return res;
}

OnVoteResults(vote, const votes[][]. item_count)
{
	new Handle:resultsHandler = Data_GetResultCallback(vote);
	
	if (resultsHandler == INVALID_HANDLE)
	{
		/* Call MenuAction_VoteEnd instead.  See if there are any extra winners. */
		new num_items = 1;
		for (new i = 1; i < num_items; i++)
		{
			if (votes[i][VOTEINFO_ITEM_VOTES] != votes[0][VOTEINFO_ITEM_VOTES])
			{
				break;
			}
			num_items++;
		}
		
		/* See if we need to pick a random winner. */
		new winning_item;
		if (num_items > 1)
		{
			/* Yes, we do */
			winning_item = GetRandomInt(0, num_items - 1);
			winning_item = votes[winning_item][VOTEINFO_ITEM_INDEX];
		}
		else 
		{
			/* No, take the first */
			winning_item = votes[winning_item][VOTEINFO_ITEM_INDEX];
		}
	}
	else
	{
		// TODO Safety save
	}
}


VoteEnd(Handle:vote)
{
	if (g_NumVotes == 0)
	{
		// Fire VoteCancel in the other plugin
		OnVoteCancel(vote, NativeVotesFail_NotEnoughVotes);
	}
	else
	{
		new num_items;
		new num_votes;
		
		new slots = Game_GetMaxItems();
		new votes[slots][2];
		
		for (new i = 0; i < slots; i++)
		{
			if (g_Votes[i] > 0)
			{
				votes[num_items][VOTEINFO_ITEM_INDEX] = i;
				votes[num_items][VOTEINFO_ITEM_VOTES] = g_Votes[i];
				num_items++;
				num_votes += g_Votes[i];
			}
		}
		
		/* Sort the item list descending */
		SortCustom2D(votes, sizeof(votes), SortVoteItems);
		
		if (!SendResultCallback(vote, num_votes, num_items, votes))
		{
			new Handle:handler = Data_GetHandler(g_hCurVote);
			
			Call_StartForward(handler);
			Call_PushCell(g_CurVote);
			Call_PushCell(MenuAction_VoteEnd);
			Call_PushCell(votes[0][VOTEINFO_ITEM_INDEX]);
			Call_PushCell(0);
			Call_Finish();
		}
	}
	
}

bool:SendResultCallback(Handle:vote, num_votes, num_items, votes[][])
{
	new Handle:voteResults = Data_GetResultCallback(g_CurVote);
	if (GetForwardFunctionCount(voteResults) == 0)
	{
		return false;
	}
	
	// This block is present because we can't pass 2D arrays to other plugins' functions
	new item_indexes[];
	new item_votes[];
	
	for (int i = 0, i < num_items; i++)
	{
		item_indexes[i] = votes[i][VOTEINFO_ITEM_INDEX];
		item_votes[i] = votes[i][VOTEINFO_ITEM_VOTES];
	}
	
	// Client block
	new client_indexes[MaxClients];
	new client_votes[MaxClients];
	
	new num_clients;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_ClientVotes[i] > VOTE_PENDING)
		{
			client_indexes[num_clients] = i;
			client_votes[num_clients] = g_ClientVotes[i];
			num_clients++;
		}
	}
	
	Call_StartForward(voteResults);
	Call_PushCell(vote);
	Call_PushCell(num_votes);
	Call_PushCell(num_clients);
	Call_PushArray(client_indexes, num_clients);
	Call_PushArray(client_votes, num_clients);
	Call_PushCell(num_items);
	Call_PushArray(item_indexes, num_items);
	Call_PushArray(item_votes, num_items);
	Call_Finish();
	
	return true;
}

DrawHintProgress()
{
	if (!GetConVarBool(g_Cvar_VoteHintbox))
	{
		return;
	}
	
	new timeRemaining = (g_StartTime + g_VoteTime) - GetTime();
	
	if (timeRemaining < 0)
	{
		timeRemaining = 0;
	}

	PrintHintTextToAll("%t%s", "Vote Count", g_NumVotes, g_TotalClients, timeRemaining, g_LeaderList);
}

BuildVoteLeaders()
{
	if (g_NumVotes == 0 || !GetConVarBool(g_Cvar_VoteHintbox))
	{
		return;
	}
	
	// Since we can't have structs, we get "struct" with this instead
	new num_items;
	
	new slots = Game_GetMaxItems();
	new votes[slots][2];
	
	for (new i = 0; i < g_Votes; i++)
	{
		if (g_Votes[i] > 0)
		{
			votes[num_items][VOTEINFO_ITEM_INDEX] = i;
			votes[num_items][VOTEINFO_ITEM_VOTES] = g_Votes[i];
			num_items++;
		}
	}
	
	/* Sort the item list descending */
	SortCustom2D(votes, sizeof(votes), SortVoteItems);
	
	/* Take the top 3 (if applicable) and draw them */
	new len = 0;
	
	for (new i = 0; i < num_items && i < 3; i++)
	{
		new cur_item = votes[i][VOTEINFO_ITEM_INDEX];
		decl String:choice[256];
		Data_GetItemDisplay(g_CurVote, cur_item, choice, sizeof(choice));
		Format(g_LeaderList + len, sizeof(g_LeaderList) - len, "\n%i. %s: (%i)", i+1, choice, votes[i][VOTEINFO_ITEM_VOTES]);
	}
	
}

public SortVoteItems(a[], b[], const array[][], Handle:hndl)
{
	if (b[VOTEINFO_ITEM_VOTES] == a[VOTEINFO_ITEM_VOTES])
	{
		return 0;
	}
	else if (b[VOTEINFO_ITEM_VOTES] > a[VOTEINFO_ITEM_VOTES])
	{
		return 1;
	}
	else
	{
		return -1;
	}
}

bool:Internal_IsClientInVotePool(client)
{
	if (client < 1
		|| client > MaxClients
		|| g_CurVote == INVALID_HANDLE)
	{
		return false;
	}

	return (g_ClientVotes[client] > VOTE_NOT_VOTING);
}

bool:Internal_RedrawToClient(client, bool:revotes)
{
	if (!Internal_IsClientInVotePool(client))
	{
		return false;
	}
	
	if (g_ClientVotes[client] >= 0)
	{
		if ((g_VoteFlags & VOTEFLAG_NO_REVOTES) || !revote || g_VoteTime <= VOTE_DELAY_TIME)
		{
			return false;
		}
		
		// Display the vote fail screen for a few seconds
		Game_DisplayVoteFail(g_CurVote, NativeVotesFail_Generic);
		
		g_Clients++;
		g_Votes[g_ClientVotes[client]]--;
		g_ClientVotes[client] = VOTE_PENDING;
		g_Revoting[client] = true;
		g_NumVotes--;
	}
	
	new Handle:data;
	
	CreateDataTimer(VOTE_DELAY_TIME, RedrawTimer, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, client);
	WritePackCell(data, g_CurVote);
	
	return true;
}

public Action:RedrawTimer(Handle:timer, Handle:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	new Handle:vote = Handle:ReadPackCell(data);
	
	if (Internal_IsVoteInProgress() && !Internal_IsCancelling(vote) && !Internal_WasCancelled(vote))
	{
		
	}
}


//----------------------------------------------------------------------------
// Natives

public Native_IsVoteTypeSupported(Handle:plugin, numParams)
{
	NativeVotesType:type = GetNativeCell(1);
	new bool:returnVal = false;
	
	switch(g_GameVersion)
	{
		case SOURCE_SDK_EPISODE2VALVE:
		{
			returnVal = TF2_
		}
		
		case SOURCE_SDK_LEFT4DEAD:
		{
		}
		
		case SOURCE_SDK_LEFT4DEAD2:
		{
		}
		
		case SOURCE_SDK_CSGO:
		{
		}
	}
	return Game_CheckVoteType(GetNativeCell(1));
}

public Native_Create(Handle:plugin, numParams)
{
	new MenuHandler:handler = GetNativeCell(1);
	new NativeVotesType:voteType = GetNativeCell(2);
	new MenuAction:actions = GetNativeCell(3);
	
	if (handler == INVALID_FUNCTION)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Menuhandler handle %x is invalid", handler);
	}
	
	new Handle:vote;
	if (Game_CheckVoteType(voteType))
	{
		vote = Data_CreateVote(voteType, actions);
	}
	else
	{
		return _:INVALID_HANDLE;
	}
	
	new Handle:menuForward = Data_GetHandler(vote);
	
	AddToForward(menuForward, plugin, handler);
	
	return _:vote;
}

public Native_Close(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	
	if (vote == INVALID_HANDLE)
	{
		return;
	}
	
	if (g_CurVote == vote)
	{
		g_CurVote = INVALID_HANDLE;
		
		if (g_VoteTimer != INVALID_HANDLE)
		{
			KillTimer(g_VoteTimer);
			g_VoteTimer = INVALID_HANDLE;
		}
	}
	
	Data_CloseVote(vote);
	
}

public Native_Display(Handle:plugin, numParams)
{
	//TODO
}

public Native_AddItem(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return false;
	}
	
	decl String:info[256];
	decl String:display[256];
	GetNativeString(2, info, sizeof(info));
	GetNativeString(3, display, sizeof(display));
	
	return Data_AddItem(vote, info, display);
}

public Native_InsertItem(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return false;
	}

	new position = GetNativeCell(2);
	
	if (position < 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Vote index can't be negative: %d", position);
		return false;
	}
	
	decl String:info[256];
	decl String:display[256];
	GetNativeString(3, info, sizeof(info));
	GetNativeString(4, display, sizeof(display));
	
	return Data_InsertItem(vote, position, info, display);
	
}

public Native_RemoveItem(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	//TODO
}

public Native_RemoveAllItems(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	//TODO
}

public Native_GetItem(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	//TODO
}

public Native_GetItemCount(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
}

public Native_GetArgument(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new maxlength = GetNativeCell(3);
	decl String:argument[maxlength];
	
	Data_GetArgument(vote, argument, maxlength);
}

public Native_SetArgument(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new maxlength;
	GetNativeStringLength(2, maxlength);
	
	decl String:argument[maxlength];
	GetNativeString(2, argument, maxlength);
	
	Data_SetArgument(vote, argument);
}

public Native_IsVoteInProgress(Handle:plugin, numParams)
{
	return Internal_IsVoteInProgress();
}

public Native_GetMaxItems(Handle:plugin, numParams)
{
	return Game_GetMaxItems();
}

public Native_GetOptionFlags(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	//TODO
}

public Native_SetOptionFlags(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	//TODO
}

public Native_SetResultCallback(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new NativeVotes_VoteHandler:function = GetNativeCell(2);
	
	if (function == INVALID_FUNCTION)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes_VoteHandler function %x is invalid", function);
		return;
	}
	
	new Handle:voteResults = Data_GetResultCallback(vote);
	
	RemoveAllFromForward(voteResults, plugin);
	AddToForward(voteResults, plugin, function);
}

public Native_CheckVoteDelay(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	//TODO
}

public Native_IsClientInVotePool(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client <= 0 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
		return false;
	}
	
	if (!Internal_IsVoteInProgress())
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No vote is in progress");
		return false;
	}
	
	return Internal_IsClientInVotePool(client);
}

public Native_RedrawClientVote(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	//TODO
}

public Native_GetType(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return 0;
	}
	
	return _:Data_GetType(vote);
}

public Native_GetTeam(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return NATIVEVOTES_ALL_TEAMS;
	}
	
	return Data_GetTeam(vote);
	
}

public Native_SetTeam(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new team = GetNativeCell(2);
	
	// Teams are numbered starting with 0
	// Currently 4 is the maximum (Unassigned, Spectator, Team 1, Team 2)
	if (team >= GetTeamCount())
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Team %d is invalid", team);
		return;
	}
	
	Data_SetTeam(vote, team);
}

public Native_GetInitiator(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return NATIVEVOTES_SERVER_INDEX;
	}
	
	return Data_GetInitiator(vote);
}

public Native_SetInitiator(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new initiator = GetNativeCell(2);
	Data_SetInitiator(vote, initiator);
}

public Native_DisplayPass(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new size;
	GetNativeStringLength(2, size);
	
	decl String:winner[size];
	GetNativeString(2, winner, size);

	Game_DisplayVotePass(vote, winner);
}

public Native_DisplayPassEx(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	NativeVotesPassType:passType = NativeVotesPassType:GetNativeCell(2);
	
	new size;
	GetNativeStringLength(3, size);
	
	decl String:winner[size];
	GetNativeString(3, winner, size);
	
	Game_DisplayVotePassEx(vote, passType, winner);
}

public Native_DisplayFail(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new NativeVotesFailType:reason = NativeVotesFailType:GetNativeCell(2);
	
	Game_DisplayVoteFail(vote, reason);
}

public Native_GetTarget(Handle:plugin,  numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	return Data_GetTarget(vote);
}

public Native_GetTargetSteam(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new size = GetNativeCell(3);
	decl String:steamId[size];
	GetNativeString(2, steamId, size);
	
	Data_GetTargetSteam(vote, steamId, size);
}

public Native_SetTarget(Handle:plugin,  numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "NativeVotes handle %x is invalid", vote);
		return;
	}
	
	new client = GetNativeCell(2);
	
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
		return;
	}
	
	if (!IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
		return;
	}
	
	new userid = GetClientUserId(client);

	Data_SetTarget(vote, userid);
	
	decl String:steamId[19];
	GetClientAuthString(client, steamId, sizeof(steamId));
	
	Data_SetTargetSteam(vote, steamId);

	new bool:changeArgument = GetNativeCell(3);
	if (changeArgument)
	{
		decl String:name[MAX_NAME_LENGTH];
		if (client > 0)
		{
			GetClientName(client, name, MAX_NAME_LENGTH);
			Data_SetArgument(vote, name);
		}
	}
}

//----------------------------------------------------------------------------
// Data functions

//----------------------------------------------------------------------------
// L4D/L4D2 shared functions

L4DL4D2_VoteTypeToTranslation(NativeVotesType:voteType, String:translation[], maxlength)
{
	switch(voteType)
	{
		case NativeVotesType_ChgCampaign:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGECAMPAIGN_START);
		}
		
		case NativeVotesType_ChgDifficulty:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGEDIFFICULTY_START);
		}
		
		case NativeVotesType_ReturnToLobby:
		{
			strcopy(translation, maxlength, L4D_VOTE_RETURNTOLOBBY_START);
		}
		
		case NativeVotesType_Alltalk:
		{
			strcopy(translation, maxlength, L4D2_VOTE_ALLTALK_START);
		}
		
		case NativeVotesType_Restart:
		{
			strcopy(translation, maxlength, L4D_VOTE_RESTART_START);
		}
		
		case NativeVotesType_Kick:
		{
			strcopy(translation, maxlength, L4D_VOTE_KICK_START);
		}
		
		case NativeVotesType_ChangeLevel:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGELEVEL_START);
		}
		
		default:
		{
			strcopy(translation, maxlength, L4D_VOTE_CUSTOM);
		}
	}
	
	return bYesNo;
}

L4DL4D2_VotePassToTranslation(NativeVotesPassType:passType, String:translation[], maxlength)
{
	switch(passType)
	{
		case NativeVotesPass_Custom:
		{
			strcopy(translation, maxlength, L4D_VOTE_CUSTOM);
		}
		
		case NativeVotesPass_ChgCampaign:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGECAMPAIGN_PASSED);
		}
		
		case NativeVotesPass_ChgDifficulty:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGEDIFFICULTY_PASSED);
		}
		
		case NativeVotesPass_ReturnToLobby:
		{
			strcopy(translation, maxlength, L4D_VOTE_RETURNTOLOBBY_PASSED);
		}
		
		case NativeVotesPass_AlltalkOn, NativeVotesPass_AlltalkOff:
		{
			strcopy(translation, maxlength, L4D2_VOTE_ALLTALK_PASSED);
		}
		
		case NativeVotesPass_Restart:
		{
			strcopy(translation, maxlength, L4D_VOTE_RESTART_PASSED);
		}
		
		case NativeVotesPass_Kick:
		{
			strcopy(translation, maxlength, L4D_VOTE_KICK_PASSED);
		}
		
		case NativeVotesPass_ChangeLevel:
		{
			strcopy(translation, maxlength, L4D_VOTE_CHANGELEVEL_PASSED);
		}
		
		default:
		{
			strcopy(translation, maxlength, L4D_VOTE_CUSTOM);
		}
	}
}

//----------------------------------------------------------------------------
// L4D functions

bool:L4D_CheckVoteType(NativeVotesType:voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_ChgCampaign, NativeVotesType_ChgDifficulty,
		NativeVotesType_ReturnToLobby, NativeVotesType_Restart, NativeVotesType_Kick,
		NativeVotesType_ChangeLevel:
		{
			return true;
		}
	}
	
	return false;
}

bool:L4D_CheckVotePassType(NativeVotesPass:passType)
{
	switch(passType)
	{
		case NativeVotesPass_Custom, NativeVotesPass_ChgCampaign, NativeVotesPass_ChgDifficulty,
		NativeVotesPass_ReturnToLobby, NativeVotesPass_Restart, NativeVotesPass_Kick,
		NativeVotesPass_ChangeLevel:
		{
			return true;
		}
	}
	
	return false;
}

//----------------------------------------------------------------------------
// L4D2 functions

bool:L4D2_CheckVoteType(NativeVotesType:voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_ChgCampaign, NativeVotesType_ChgDifficulty,
		NativeVotesType_ReturnToLobby, NativeVotesType_Alltalk, NativeVotesType_Restart,
		NativeVotesType_Kick, NativeVotesType_ChangeLevel:
		{
			return true;
		}
	}
	
	return false;
}

bool:L4D2_CheckVotePassType(NativeVotesPass:passType)
{
	switch(passType)
	{
		case NativeVotesPass_Custom, NativeVotesPass_ChgCampaign, NativeVotesPass_ChgDifficulty,
		NativeVotesPass_ReturnToLobby, NativeVotesPass_AlltalkOn, NativeVotesPass_AlltalkOff,
		NativeVotesPass_Restart, NativeVotesPass_Kick, NativeVotesPass_ChangeLevel:
		{
			return true;
		}
	}
	
	return false;
}

//----------------------------------------------------------------------------
// TF2/CSGO shared functions

TF2CSGO_ClientSelectedItem(Handle:vote, client, item)
{
	new Handle:castEvent = CreateEvent("vote_cast");
	
	SetEventInt(castEvent, "team", Data_GetTeam(vote));
	SetEventInt(castEvent, "entityid", client);
	SetEventInt(castEvent, "vote_option", item);
	FireEvent(castEvent);
	
	CloseHandle(castEvent);
}

TF2CSGO_DisplayVote(Handle:vote, clients[], num_clients)
{
	
	if (!Data_GetOptionsSent(vote))
	{
		// This vote never sent its options
		new Handle:optionsEvent = CreateEvent("vote_options");
		
		new maxCount = Data_GetItemCount(vote);
		
		for (new i = 0; i < maxCount; i++)
		{
			decl String:option[8];
			Format(option, sizeof(option), "%s%d", TF2CSGO_VOTE_PREFIX, i+1);
			
			decl String:display[64];
			Data_GetItemDisplay(vote, i, display, sizeof(display));
			SetEventString(optionsEvent, option, display);
		}
		SetEventInt(optionsEvent, "count", maxCount);
		FireEvent(optionsEvent);
		
		Data_SetOptionsSent(vote, true);
	}
	
	decl String:translation[64];
	new bool:bYesNo = true;
	
	new NativeVotesType:voteType = Data_GetType(vote);
	
	switch(g_GameVersion)
	{
		case SOURCE_SDK_EPISODE2VALVE:
		{
			bYesNo = TF2_VoteTypeToTranslation(voteType, translation, sizeof(translation));
		}
		
		case SOURCE_SDK_CSGO:
		{
			bYesNo = CSGO_VoteTypeToTranslation(voteType, translation, sizeof(translation));
		}
	}
	
	decl String:argument[64];
	Data_GetArgument(vote, argument, sizeof(argument));
	new Handle:voteStart = StartMessage("VoteStart", clients, num_clients, USERMSG_RELIABLE);
	BfWriteByte(voteStart, Data_GetTeam(vote));
	BfWriteByte(voteStart, Data_GetInitiator(vote));
	BfWriteString(voteStart, translation);
	BfWriteString(voteStart, argument);
	BfWriteBool(voteStart, bYesNo);
	EndMessage();
	
}

TF2CSGO_DisplayVotePass(Handle:vote, const String:param1[])
{
	new NativeVotesType:voteType = Data_GetType(vote);
	
	new NativeVotesPassType:passType = NativeVotesPass_None;
	
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Custom_Mult:
		{
			passType = NativeVotesPass_Custom;
		}
		
		case NativeVotesType_ChgDifficulty:
		{
			passType = NativeVotesPass_ChgDifficulty;
		}
		
		case NativeVotesType_Restart:
		{
			passType = NativeVotesPass_Restart;
		}
		
		case NativeVotesType_Kick, NativeVotesType_KickIdle, NativeVotesType_KickScamming, NativeVotesType_KickCheating:
		{
			passType = NativeVotesPass_Kick;
		}
		
		case NativeVotesType_ChangeLevel:
		{
			passType = NativeVotesPass_ChangeLevel;
		}
		
		case NativeVotesType_NextLevel, NativeVotesType_NextLevelMult:
		{
			passType = NativeVotesPass_NextLevel;
		}
		
		case NativeVotesType_ScrambleNow, NativeVotesType_ScrambleEnd:
		{
			passType = NativeVotesPass_Scramble;
		}
		
		default:
		{
			passType = NativeVotesPass_Custom;
		}
	}
	
	TF2CSGO_DisplayVotePassEx(vote, passType, param1);
}

TF2CSGO_DisplayVotePassEx(Handle:vote, NativeVotesPassType:passType, const String:param1[])
{
	decl String:translation[64];
	
	switch(g_GameVersion)
	{
		case SOURCE_SDK_EPISODE2VALVE:
		{
			TF2_VotePassToTranslation(passType, translation, sizeof(translation));
		}
		
		case SOURCE_SDK_CSGO:
		{
			CSGO_VotePassToTranslation(passType, translation, sizeof(translation));
		}
	}
	
	new Handle:bf = StartMessageAll("VotePass", USERMSG_RELIABLE);
	BfWriteByte(bf, Data_GetTeam(vote));
	BfWriteString(bf, translation);
	BfWriteString(bf, param1);
	EndMessage();
	
	CloseHandle(bf);
}

TF2CSGO_DisplayVoteFail(Handle:vote, NativeVotesFailType:reason)
{
	new Handle:bf = StartMessageAll("VoteFail", USERMSG_RELIABLE);
	
	BfWriteByte(bf, Data_GetTeam(vote));
	BfWriteByte(bf, _:reason);
	EndMessage();
	
	CloseHandle(bf);
}

TF2CSGO_DisplayVoteFailOne(Handle:vote, client, NativeVotesFailType:reason)
{
	new Handle:bf = StartMessageOne("VoteFail", client, USERMSG_RELIABLE);
	
	BfWriteByte(bf, Data_GetTeam(vote));
	BfWriteByte(bf, reason);
	EndMessage();
	
	CloseHandle(bf);
}

TF2CSGO_DisplayCallVoteFail(client, NativeVotesCallFailType:reason, param1)
{
	new Handle:bf = StartMessageOne("CallVoteFail", client, USERMSG_RELIABLE);
	
	BfWriteByte(bf, reason);
	BfWriteShort(bf, param1);
	EndMessage();
	
	CloseHandle(bf);
}


//----------------------------------------------------------------------------
// TF2 functions

bool:TF2_CheckVoteType(NativeVotesType:voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Custom_Mult, NativeVotesType_ChgDifficulty,
		NativeVotesType_Restart, NativeVotesType_Kick, NativeVotesType_KickIdle, 
		NativeVotesType_KickScamming, NativeVotesType_KickCheating, NativeVotesType_ChangeLevel,
		NativeVotesType_NextLevel, NativeVotesType_NextLevelMult, NativeVotesType_ScrambleNow,
		NativeVotesType_ScrambleEnd,
		{
			return true;
		}
	}
	
	return false;
}

bool:TF2_CheckVotePassType(NativeVotesPass:passType)
{
	switch(passType)
	{
		case NativeVotesPass_ChgDifficulty, NativeVotesPass_Custom, NativeVotesPass_Restart,
		NativeVotesPass_ChangeLevel, NativeVotesPass_Kick, NativeVotesPass_NextLevel,
		NativeVotesPass_Extend, NativeVotesPass_Scramble:
		{
			return true;
		}
	}
	
	return false;
}

bool:TF2_VoteTypeToTranslation(NativeVotesType:voteType, String:translation[], maxlength)
{
	new bool:bYesNo = true;
	switch(voteType)
	{
		case NativeVotesType_Custom_Mult:
		{
			strcopy(translation, maxlength, TF2_VOTE_CUSTOM);
			bYesNo = false;
		}
		
		case NativeVotesType_ChgDifficulty:
		{
			strcopy(translation, maxlength, TF2_VOTE_CHANGEDIFFICULTY_START);
		}
		
		case NativeVotesType_Restart:
		{
			strcopy(translation, maxlength, TF2_VOTE_RESTART_START);
		}
		
		case NativeVotesType_Kick:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_START);
		}
		
		case NativeVotesType_KickIdle:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_IDLE_START);
		}
		
		case NativeVotesType_KickScamming:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_SCAMMING_START);
		}
		
		case NativeVotesType_KickCheating:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_CHEATING_START);
		}
		
		case NativeVotesType_ChangeLevel:
		{
			strcopy(translation, maxlength, TF2_VOTE_CHANGELEVEL_START);
		}
		
		case NativeVotesType_NextLevel:
		{
			strcopy(translation, maxlength, TF2_VOTE_NEXTLEVEL_SINGLE_START);
		}
		
		case NativeVotesType_NextLevelMult:
		{
			
			strcopy(translation, maxlength, TF2_VOTE_NEXTLEVEL_MULTIPLE_START);
			bYesNo = false;
		}
		
		case NativeVotesType_ScrambleNow:
		{
			strcopy(translation, maxlength, TF2_VOTE_SCRAMBLE_IMMEDIATE_START);
		}
		
		case NativeVotesType_ScrambleEnd:
		{
			strcopy(translation, maxlength, TF2_VOTE_SCRAMBLE_ROUNDEND_START);
		}
		
		default:
		{
			strcopy(translation, maxlength, TF2_VOTE_CUSTOM);
		}
	}
	
	return bYesNo;
}

TF2_VotePassToTranslation(NativeVotesPassType:passType, String:translation[], maxlength)
{
	switch(passType)
	{
		case NativeVotesPass_Custom:
		{
			strcopy(translation, maxlength, TF2_VOTE_CUSTOM);
		}
		
		case NativeVotesPass_ChgDifficulty:
		{
			strcopy(translation, maxlength, TF2_VOTE_CHANGEDIFFICULTY_PASSED);
		}
		
		case NativeVotesPass_Restart:
		{
			strcopy(translation, maxlength, TF2_VOTE_RESTART_PASSED);
		}
		
		case NativeVotesPass_Kick:
		{
			strcopy(translation, maxlength, TF2_VOTE_KICK_PASSED);
		}
		
		case NativeVotesPass_ChangeLevel:
		{
			strcopy(translation, maxlength, TF2_VOTE_CHANGELEVEL_PASSED);
		}
		
		case NativeVotesPass_NextLevel:
		{
			strcopy(translation, maxlength, TF2_VOTE_NEXTLEVEL_PASSED);
		}
		
		case NativeVotesPass_Extend:
		{
			strcopy(translation, maxlength, TF2_VOTE_NEXTLEVEL_EXTEND_PASSED);
		}
		
		case NativeVotesPass_Scramble:
		{
			strcopy(translation, maxlength, TF2_VOTE_SCRAMBLE_PASSED);
		}
	}
}

//----------------------------------------------------------------------------
// CSGO functions

bool:CSGO_CheckVoteType(NativeVotesType:voteType)
{
	switch(voteType)
	{
		case NativeVotesType_Custom_YesNo, NativeVotesType_Custom_Mult, NativeVotesType_Restart,
		NativeVotesType_Kick, NativeVotesType_KickIdle, NativeVotesType_KickScamming,
		NativeVotesType_KickCheating, NativeVotesType_ChangeLevel, NativeVotesType_NextLevel,
		NativeVotesType_NextLevelMult, NativeVotesType_ScrambleNow, NativeVotesType_SwapTeams:
		{
			return true;
		}
	}
	
	return false;
}

bool:CSGO_CheckVotePassType(NativeVotesPass:passType)
{
	switch(passType)
	{
		case NativeVotesPass_Custom, NativeVotesPass_Restart, NativeVotesPass_Kick,
		NativeVotesPass_ChangeLevel, NativeVotesPass_NextLevel, NativeVotesPass_Extend,
		NativeVotesPass_Scramble, NativeVotesPass_SwapTeams:
		{
			return true;
		}
	}
	
	return false;
}

bool:CSGO_VoteTypeToTranslation(NativeVotesType:voteType, String:translation[], maxlength)
{
	new bool:bYesNo = true;
	switch(voteType)
	{
		case NativeVotesType_Custom_Mult:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CUSTOM);
			bYesNo = false;
		}
		
		case NativeVotesType_Restart:
		{
			strcopy(translation, maxlength, CSGO_VOTE_RESTART_START);
		}
		
		case NativeVotesType_Kick:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_START);
		}
		
		case NativeVotesType_KickIdle:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_IDLE_START);
		}
		
		case NativeVotesType_KickScamming:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_SCAMMING_START);
		}
		
		case NativeVotesType_KickCheating:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_CHEATING_START);
		}
		
		case NativeVotesType_ChangeLevel:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CHANGELEVEL_START);
		}
		
		case NativeVotesType_NextLevel:
		{
			strcopy(translation, maxlength, CSGO_VOTE_NEXTLEVEL_SINGLE_START);
		}
		
		case NativeVotesType_NextLevelMult:
		{
			
			strcopy(translation, maxlength, CSGO_VOTE_NEXTLEVEL_MULTIPLE_START);
			bYesNo = false;
		}
		
		case NativeVotesType_ScrambleNow:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SCRAMBLE_START);
		}
		
		case NativeVotesType_SwapTeams:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SWAPTEAMS_START);
		}
		
		default:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CUSTOM);
		}
	}
	
	return bYesNo;
}

CSGO_VotePassToTranslation(NativeVotesPassType:passType, String:translation[], maxlength)
{
	switch(passType)
	{
		case NativeVotesPass_Custom:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CUSTOM);
		}
		
		case NativeVotesPass_Restart:
		{
			strcopy(translation, maxlength, CSGO_VOTE_RESTART_PASSED);
		}
		
		case NativeVotesPass_Kick:
		{
			strcopy(translation, maxlength, CSGO_VOTE_KICK_PASSED);
		}
		
		case NativeVotesPass_ChangeLevel:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CHANGELEVEL_PASSED);
		}
		
		case NativeVotesPass_NextLevel:
		{
			strcopy(translation, maxlength, CSGO_VOTE_NEXTLEVEL_PASSED);
		}
		
		case NativeVotesPass_Extend:
		{
			strcopy(translation, maxlength, CSGO_VOTE_NEXTLEVEL_EXTEND_PASSED);
		}
		
		case NativeVotesPass_Scramble:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SCRAMBLE_PASSED);
		}
		
		case NativeVotesPass_SwapTeams:
		{
			strcopy(translation, maxlength, CSGO_VOTE_SWAPTEAMS_PASSED);
		}
		
		default:
		{
			strcopy(translation, maxlength, CSGO_VOTE_CUSTOM);
		}
	}
}
