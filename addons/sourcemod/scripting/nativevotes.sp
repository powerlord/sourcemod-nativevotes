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

// SourceMod 1.4 compatibility shim
#if !defined SOURCE_SDK_CSGO
	#define SOURCE_SDK_CSGO				80		/**< Engine released after CS:GO (no SDK yet) */
#endif
 
/*
* Which version are we compiling?  See the following table:
* TF2 - SOURCE_SDK_EPISODE2VALVE
* L4D - SOURCE_SDK_LEFT4DEAD
* L4D2 - SOURCE_SDK_LEFT4DEAD2
* CS:GO - SOURCE_SDK_CSGO
*/
#define SDK_VERSION SOURCE_SDK_EPISODE2VALVE

#include <sourcemod>
#include <sdktools>
#include "include/nativevotes.inc"

#if SDK_VERSION == SOURCE_SDK_EPISODE2VALVE
	#define PLUGIN_NAME "NativeVotes TF2"
	#include "include/nativevotes/game-tf2.inc"
#elseif SDK_VERSION == SOURCE_SDK_LEFT4DEAD
	#define PLUGIN_NAME "NativeVotes L4D"
	#include "include/nativevotes/game-left4dead.inc"
#elseif SDK_VERSION == SOURCE_SDK_LEFT4DEAD2
	#define PLUGIN_NAME "NativeVotes L4D2"
	#include "include/nativevotes/game-left4dead2.inc"
#elseif SDK_VERSION == SOURCE_SDK_CSGO
	#define PLUGIN_NAME "NativeVotes CS:GO"
	#include "include/nativevotes/game-csgo.inc"
#endif

// As long as it uses a Handle, you can switch out the data handling class here
#include "include/nativevotes/data-keyvalues.inc"

#define VERSION "0.1 alpha"

// SourceMod uses these internally, so... we do too.
#if !defined VOTE_NOT_VOTING
	#define VOTE_NOT_VOTING -2
#endif

#if !defined VOTE_PENDING
	#define VOTE_PENDING -1
#endif

new g_VoteController;

new Handle:g_Cvar_VoteHintbox;
new Handle:g_Cvar_VoteChat;
new Handle:g_Cvar_VoteConsole;
new Handle:g_Cvar_VoteClientConsole;

// These variables are only used during a vote
// These would normally be stored in an object/struct
new Handle:g_CurVote;
new g_StartTime = 0;
new g_VoteTime = 0;
new g_NumVotes = 0;
new g_ClientVotes[MAXPLAYERS];
new g_TotalClients = 0;
new String:g_LeaderList[1024];
new g_Items;
new Handle:g_Votes;
new Handle:g_VoteTimer;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "Powerlord",
	description = "Voting API to use the game's native vote panels",
	version = VERSION,
	url = "<- URL ->"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (!GetFeatureStatus(FeatureType_Capability, FEATURECAP_COMMANDLISTENER))
	{
		strcopy(error, err_max, "Game doesn't support command listeners.");
	}
	
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
}

public OnPluginStart()
{
	LoadTranslations("core.phrases");
	
	CreateConVar("nativevotes_version", VERSION, "NativeVotes API version", FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_Cvar_VoteHintbox = CreateConVar("nativevotes_progress_hintbox", "0", "Specifies whether or not to display vote progress to clients in the\n\"hint\" box (near the bottom of the screen in most games).\nValid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteChat = CreateConVar("nativevotes_progress_chat", "0", "Specifies whether or not to display vote progress to clients in the\nchat area. Valid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteConsole = CreateConVar("nativevotes_progress_chat", "0", "Specifies whether or not to display vote progress in the server console.\nValid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteClientConsole = CreateConVar("nativevotes_progress_client_console", "0", "Specifies whether or not to display vote progress to clients in the\nclient console. Valid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);

	AddCommandListener(Game_VoteParser, "vote");
	AddCommandListener(Game_VoteParser, "Vote");
	
	AutoExecConfig(true, "nativevotes");
}

public OnConfigsExecuted()
{
	g_VoteController = FindEntityByClassname(-1, "vote_controller");
	if (g_VoteController == INVALID_ENT_REFERENCE)
	{
		LogError("Could not find Vote Controller.");
	}
}

public OnMapEnd()
{
	if (g_CurVote != INVALID_HANDLE)
	{
		OnVoteCancel(g_CurVote, NativeVotesFail_Generic);
		g_CurVote = INVALID_HANDLE;
		// Don't close the handle, as the other plugin may still re-use it
	}

	g_VoteTimer = INVALID_HANDLE;
}

OnVoteStart(Handle:vote)
{
	new Handle:plugin;
	new Function:handler;
	Data_GetHandler(g_CurVote, plugin, handler);
	
	if (plugin == INVALID_HANDLE || handler == INVALID_FUNCTION)
	{
		return;
	}
	
	Call_StartFunction(plugin, handler);
	Call_PushCell(g_CurVote);
	Call_PushCell(MenuAction_Start);
	Call_PushCell(0);
	Call_PushCell(0);
	Call_Finish();
	
	Call_StartFunction(plugin, handler);
	Call_PushCell(g_CurVote);
	Call_PushCell(MenuAction_VoteStart);
	Call_PushCell(0);
	Call_PushCell(0);
	Call_Finish();

}

OnVoteCancel(Handle:vote, NativeVotesFailType:reason)
{
	new Handle:plugin;
	new Function:handler;
	Data_GetHandler(g_CurVote, plugin, handler);
	
	if (plugin == INVALID_HANDLE || handler == INVALID_FUNCTION)
	{
		return;
	}
	
	Call_StartFunction(plugin, handler);
	Call_PushCell(vote);
	Call_PushCell(MenuAction_VoteCancel);
	Call_PushCell(reason);
	Call_PushCell(0);
	Call_Finish();
}

OnVoteEnd(Handle:vote)
{
	new Handle:plugin;
	new Function:handler;
	Data_GetHandler(g_CurVote, plugin, handler);
	
	if (g_NumVotes == 0)
	{
		OnVoteCancel(vote, NativeVotesFail_NotEnoughVotes);
	}
	else
	{
		new num_items;
		new num_votes;
		
		new slots = Game_GetMaxItems();
		new votes[slots][2];
		
		for (new i = 0; i < g_Votes; i++)
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
			Data_GetHandler(g_CurVote, plugin, handler);
			
			if (plugin == INVALID_HANDLE || handler == INVALID_FUNCTION)
			{
				return;
			}
			
			Call_StartFunction(plugin, handler);
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
	new Handle:plugin;
	new Function:handler;
	Data_GetResultCallback(g_CurVote, plugin, handler);
	if (plugin == INVALID_HANDLE || handler == INVALID_FUNCTION)
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
	
	Call_StartFunction(plugin, handler);
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

public Native_Create(Handle:plugin, numParams)
{
	new MenuHandler:handler = GetNativeCell(1);
	new NativeVotesType:voteType = GetNativeCell(2);
	new MenuAction:actions = GetNativeCell(3);
	
	if (Game_CheckVoteType(voteType))
	{
		return _:Data_CreateVote(plugin, handler, voteType, actions);
	}
	else
	{
		return _:INVALID_HANDLE;
	}
}

public Native_Close(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	
	if (vote == INVALID_HANDLE)
	{
		return;
	}
	
	if (g_VoteTimer != INVALID_HANDLE)
	{
		KillTimer(g_VoteTimer);
		g_VoteTimer = INVALID_HANDLE;
	}
	
	Data_CloseVote(vote);
}

public Native_Display(Handle:plugin, numParams)
{
	
}

public Native_AddItem(Handle:plugin, numParams)
{
	new Handle:vote = GetNativeCell(1);
	if (vote == INVALID_HANDLE)
	{
		return;
	}
	
	decl String:info[256];
	decl String:display[256];
	GetNativeString(2, info, sizeof(info));
	GetNativeString(3, display, sizeof(display));
	
	Data_AddItem(vote, info, display);
}

public Native_InsertItem(Handle:plugin, numParams)
{
	
}

public Native_RemoveItem(Handle:plugin, numParams)
{
	
}

public Native_RemoveAllItems(Handle:plugin, numParams)
{
	
}

public Native_GetItem(Handle:plugin, numParams)
{
	
}

public Native_GetItemCount(Handle:plugin, numParams)
{
	
}

public Native_GetArgument(Handle:plugin, numParams)
{
	
}

public Native_SetArgument(Handle:plugin, numParams)
{
	
}

public Native_IsVoteInProgress(Handle:plugin, numParams)
{
	
}

public Native_GetMaxItems(Handle:plugin, numParams)
{
	
}

public Native_GetOptionFlags(Handle:plugin, numParams)
{
	
}

public Native_SetOptionFlags(Handle:plugin, numParams)
{
	
}

public Native_SetResultCallback(Handle:plugin, numParams)
{
	
}

public Native_CheckVoteDelay(Handle:plugin, numParams)
{
	
}

public Native_IsClientInVotePool(Handle:plugin, numParams)
{
	
}

public Native_RedrawClientVote(Handle:plugin, numParams)
{
	
}

public Native_GetType(Handle:plugin, numParams)
{
	
}

public Native_GetTeam(Handle:plugin, numParams)
{
	
}

public Native_SetTeam(Handle:plugin, numParams)
{
	
}

public Native_GetInitiator(Handle:plugin, numParams)
{
	
}

public Native_SetInitiator(Handle:plugin, numParams)
{
	
}

public Native_DisplayPass(Handle:plugin, numParams)
{
	
}

public Native_DisplayPassEx(Handle:plugin, numParams)
{
	
}

public Native_DisplayFail(Handle:plugin, numParams)
{
	
}
