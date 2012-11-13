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

new Float:g_NextVote = 0.0;

new Handle:g_Cvar_VoteHintbox;
new Handle:g_Cvar_VoteChat;
new Handle:g_Cvar_VoteConsole;
new Handle:g_Cvar_VoteClientConsole;
new Handle:g_Cvar_VoteDelay;

#define VOTE_NOT_VOTING -2
#define VOTE_PENDING -1

#define VOTE_DELAY_TIME 3

// Would be part of an object
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

Handler_GetRemainingVoteDelay()
{
	if (g_NextVote <= GetGameTime())
	{
		return 0;
	}
	
	return g_NextVote - GetGameTime();
}

Handler_OnLoad()
{
	g_Cvar_VoteHintbox = CreateConVar("nativevotes_progress_hintbox", "0", "Specifies whether or not to display vote progress to clients in the\n\"hint\" box (near the bottom of the screen in most games).\nValid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteChat = CreateConVar("nativevotes_progress_chat", "0", "Specifies whether or not to display vote progress to clients in the\nchat area. Valid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteConsole = CreateConVar("nativevotes_progress_chat", "0", "Specifies whether or not to display vote progress in the server console.\nValid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteClientConsole = CreateConVar("nativevotes_progress_client_console", "0", "Specifies whether or not to display vote progress to clients in the\nclient console. Valid values are 0 (Disabled) or 1 (Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_VoteDelay = CreateConVar("nativevotes_vote_delay", "30", "Sets the recommended time in between public votes", FCVAR_NONE, true, 0.0, true);
	
	HookConVarChange(g_Cvar_VoteDelay, OnVoteDelayChange);
}

Handler_OnMapStart()
{
	g_NextVote = 0.0;
	
	Handler_CancelVoting();
}

public OnClientDisconnect(client)
{
	if (!Handler_IsVoteInProgress())
	{
		return;
	}
	
	new item;
	if ((item = g_ClientVotes[client]) >= VOTE_PENDING)
	{
		if (item >= 0)
		{
			SetArrayCell(g_hCurVote, item, GetArrayCell(g_hCurVote, item) - 1);
		}
		g_ClientVotes[client] = VOTE_NOT_VOTING;
	}
}

bool:Handler_IsVoteInProgress()
{
	return (g_hCurVote != INVALID_HANDLE);
}

bool:Handler_StartVote(Handle:vote, num_clients, clients[], max_time, flags)
{
	if (!InitializeVoting(vote, max_time, flags))
	{
		return false;
	}
	
	new Float:fVoteDelay = GetConVarFloat(g_Cvar_VoteDelay);
	if (fVoteDelay < 1.0)
	{
		g_NextVote = 0.0;
	}
	else
	{
		/* This little trick breaks for infinite votes!
		 * However, we just ignore that since those 1) shouldn't exist and
		 * 2) people must be checking NativeVotes_IsVoteInProgress() beforehand anyway.
		 */
		g_NextVote = GetGameTime() + fVoteDelay + max_time;
	}
	
	g_fStartTime = GetGameTime();
	g_nVoteTime = max_time;
	g_TimeLeft = max_time;
	
	new clientCount = 0;
	
	for (new i = 0; i < num_clients; i++)
	{
		if (clients[i] < 1 || clients[i] > MaxClients)
		{
			continue;
		}
		
		g_ClientVotes[clients[i]] = VOTE_PENDING;
		clientCount++;
	}
	
	g_Clients = clientCount;
	
	Game_UpdateVoteCounts(g_Items, g_Votes, clientCount); // Same things as BuildVoteLeaders, but for game internals
	
	Game_DoClientVote(client, num_clients, vote);
	
	StartVoting();
	
	return true;
}

bool:Handler_IsClientInVotePool(client)
{
	if (client < 1
		|| client > MaxClients
		|| g_CurVote == INVALID_HANDLE)
	{
		return false;
	}

	return (g_ClientVotes[client] > VOTE_NOT_VOTING);
}

bool:Handler_GetClientVoteChoice(client, &item)
{
	if (!Handler_IsClientInVotePool(client)
	|| g_ClientVotes[client] == VOTE_PENDING)
	{
		return false;
	}
	
	item = g_ClientVotes[client];
	
	return true;
}

bool:Handler_RedrawToClient(client, bool:revotes)
{
	if (!Handler_IsClientInVotePool(client))
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

bool:Handler_InitializeVoting(Handle:vote, time, flags)
{
	if (Handler_IsVoteInProgress())
	{
		return false;
	}
	
	Handler_InternalReset();
	
	/* Mark all clients as not voting */
	for (new i = 1; i <= MaxClients; i++)
	{
		g_ClientVotes[i] = VOTE_NOT_VOTING;
		g_bRevoting[i] = false;
	}
	
	g_Items = Data_GetItemCount();
	
	if (GetArraySize(g_hVotes) < g_Items)
	{
		/* Only clear the items we need to... */
		for (new i = 0; i < GetArraySize(g_hVotes); i++)
		{
			SetArrayCell(g_hVotes, i, 0);
		}
		ResizeArray(g_hVotes, g_Items);
	}
	
	// Check the vote type and adjust the argument if valid
	NativeVotesType:voteType = Data_GetVoteType(vote);
	
	switch(voteType)
	{
		case NativeVotesType_Kick, NativeVotesType_KickIdle, NativeVotesType_KickScamming, NativeVotesType_KickCheating:
		{
			new userid = Data_GetTarget();
			if (userid > 0)
			{
				new client = GetClientOfUserId(userid);
				if (IsClientInGame(client))
				{
					decl String:name[MAX_NAME_LENGTH];
					GetClientName(client, name, MAX_NAME_LENGTH);
					Data_SetArgument(vote, name);
				}
			}
		}
	}
	
	g_bWasCancelled = false;
	g_hCurVote = vote;
	g_VoteTime = time;
	g_VoteFlags = flags;
	
	return true;
}

StartVoting()
{
	if (g_hCurVote == INVALID_HANDLE)
	{
		return;
	}
	
	g_bStarted = true;
	
	// OnVoteStart(g_hCurVote);
	
	g_DisplayTimer = CreateTimer(1.0, VoteTimer, NULL, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	/* By now we know how many clients were set.
	* If ther eare none, we should end IMMEDIATELY.
	*/
	if (g_Clients == 0)
	{
		EndVoting();
	}
	
	/* In Source games, the person who started a vote for something automatically votes yes.
	*/
	new initiator = Data_GetInitiator(g_hCurVote);
	new userid;
	
	switch(Data_GetVoteType(g_hCurVote))
	{
		case NativeVotesType_Custom_Mult, NativeVotesType_NextLevelMult:
		{
			break;
		}
		
		case NativeVotesType_Kick, NativeVotesType_KickIdle, NativeVotesType_KickScamming, NativeVotesType_KickCheating:
		{
			OnVoteSelect(g_hCurVote, initiator, NATIVEVOTES_VOTE_YES);
			new userid = Data_GetTarget(g_hCurVote);
			if (userid > 0)
			{
				new client = GetClientOfUserId(userid);
				if (IsClientConnected(client) && Handler_IsClientInVotePool(client))
				{
					OnVoteSelect(g_hCurVote, client, NATIVEVOTES_VOTE_NO);
				}
			}
		}
		
		default:
		{
			OnVoteSelect(g_hCurVote, initiator, NATIVEVOTES_VOTE_YES);
		}
	}
	
	g_TotalClients = g_Clients;
}

DecrementPlayerCount()
{
	g_Clients--;
	
	if (g_bStarted && g_Clients == 0)
	{
		EndVoting();
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

EndVoting()
{
	/* Set when the next delay ends.  We ignore cancellation because a vote
	 * was, at one point, displayed, which is all that counts.  However, we
	 * do recalculate the time just in case the vote had no time limit.
	 */
	new Float:fVoteDelay = GetConVarFloat(g_Cvar_VoteDelay);
	if (fVoteDelay < 1.0)
	{
		g_NextVote = 0.0;
	}
	else
	{
		g_NextVote = GetGameTime() + fVoteDelay;
	}
	
	if (g_DisplayTimer != INVALID_HANDLE)
	{
		KillTimer(g_DisplayTimer);
	}
	
	if (g_bCancelled)
	{
		/* If we were cancelled, don't bother tabulating anything.
		 * Reset just in case someone tries to redraw, which means
		 * we need to save our states.
		 */
		new Handle:vote = g_hCurVote;
		InternalReset();
		OnVoteCancel(vote, NativeVotesFail_Generic);
		OnVoteEnd(vote, MenuEnd_Cancelled);
		return;
	}
	
	// Vote counting logic
	
}

OnVoteSelect(Handle:vote, client, item)
{
	if (Handler_IsVoteInProgress() && g_ClientVotes[client] == VOTE_PENDING)
	{
		/* Check by our item count, NOT the vote array size */
		if (item < g_Items)
		{
			Game_ClientSelectedItem(vote, client, item);
			g_ClientVotes[client] = item;
			SetArrayCell(g_hVotes, item, GetArrayCell(g_hVotes, item) + 1);
			g_NumVotes++;
			
			if (GetConVarBool(g_Cvar_VoteChat) || GetConVarBool(g_Cvar_VoteConsole) || GetConVarBool(g_Cvar_VoteClientConsole))
			{
				static String:buffer[1024];
				decl String:choice[128];
				decl String:name[MAX_NAME_LENGTH];
				Data_GetItemDisplay(item, choice, sizeof(choice));
				
				GetClientName(client, name, MAX_NAME_LENGTH);
				
				if (GetConVarBool(g_Cvar_VoteConsole))
				{
					PrintToServer("[NV] %T", "Voted For", LANG_SERVER, name, choice);
				}
				
				if (GetConVarBool(g_Cvar_VoteChat) || GetConVarBool(g_Cvar_VoteClientConsole))
				{
					decl String:phrase[30];
					
					if (g_bRevoting[client])
					{
						strcopy(phrase, sizeof(phrase), "Changed Vote");
					}
					else
					{
						strcopy(phrase, sizeof(phrase), "Voted For");
					}
					
					if (GetConVarBool(g_Cvar_VoteChat))
					{
						PrintToChatAll("[NV] %t", phrase, name, choice);
					}

					if (GetConVarBool(g_Cvar_VoteClientConsole))
					{
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientInGame(i) && !IsFakeClient(i))
							{
								PrintToConsole(i, "[NV] %t", phrase, name, choice);
							}
						}
					}
				}
			}
			Game_UpdateVoteCounts(g_hCurVote, g_Items, g_Votes, g_TotalClients);
			BuildVoteLeaders();
			DrawHintProgress();
		}
		
		Vote_OnVoteSelect(g_hCurVote, client, item);
		DecrementPlayerCount();
	}
}

InternalReset()
{
	g_Clients = 0;
	g_Items = 0;
	g_bStarted = false;
	g_hCurVote = INVALID_HANDLE;
	g_NumVotes = 0;
	g_bCancelled = false;
	
	g_LeaderList[0] = '\0';
	
	g_TotalClients = 0;
	
	if (g_DisplayTimer != INVALID_HANDLE)
	{
		KillTimer(g_DisplayTimer);
	}
	g_DisplayTimer = INVALID_HANDLE;
}

Handler_CancelVoting()
{
	if (g_bCancelled || g_hCurVote == INVALID_HANDLE)
	{
		return;
	}
	g_bCancelled = true;
	g_bWasCancelled = true;
	
	Game_CancelVote(g_hCurVote);
	EndVoting();
}

Handle:Handler_GetCurrentVote()
{
	return g_hCurVote;
}

bool:Handler_IsCancelling()
{
	return g_bCancelled;
}

bool:Handler_WasCancelled()
{
	return g_bWasCancelled;
}

DrawHintProgress()
{
	if (!GetConVarBool(g_Cvar_VoteHintbox))
	{
		return;
	}
	
	static String:buffer[1024];
	
	new Float:fTimeRemaining = (g_fStartTime + g_nVoteTime) - GetGameTime();
	if (fTimeRemaining < 0.0)
	{
		fTimeRemaining = 0.0;
	}
	
	int timeRemaining = RoundFloat(fTimeRemaining);

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
	
	for (new i = 0; i < GetArraySize(g_Votes); i++)
	{
		new voteCount = GetArrayCell(g_Votes, i);
		if (voteCount > 0)
		{
			votes[num_items][VOTEINFO_ITEM_INDEX] = i;
			votes[num_items][VOTEINFO_ITEM_VOTES] = voteCount;
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

