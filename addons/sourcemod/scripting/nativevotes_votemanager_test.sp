/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes VoteManager Test
 * Test the VoteManger functionality of NativeVotes
 *
 * NativeVotes VoteManager Test (C)2014 Powerlord (Ross Bemrose). All rights
 * reserved.
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
#include <nativevotes> // Not optional

#pragma semicolon 1

#define VERSION "1.1.0"

new Handle:g_Cvar_Enabled;


public Plugin:myinfo = {
	name			= "NativeVotes VoteManager Test",
	author			= "Powerlord",
	description		= "Test the VoteManger functionality of NativeVotes",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=208008"
};

public OnPluginStart()
{
	CreateConVar("nativevotes_votemanagertest_version", VERSION, "NativeVotes VoteManager Test version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("nativevotes_votemanagertest_enable", "1", "Enable NativeVotes VoteManager Test?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookConVarChange(g_Cvar_Enabled, EnabledChanged);
}

public OnAllPluginsLoaded()
{
	if (GetConVarBool(g_Cvar_Enabled))
	{
		NativeVotes_RegisterVoteCommand("VoteTest", CallVoteTestHandler);
		NativeVotes_RegisterVoteCommand("Kick", CallKickVoteHandler);
		NativeVotes_RegisterVoteCommand("AdminVoteTest", CallVoteAdminTestHandler, CallVoteAdminVisHandler);
	}
}

public OnPluginEnd()
{
	NativeVotes_UnregisterVoteCommand("VoteTest", CallVoteTestHandler);
	NativeVotes_UnregisterVoteCommand("Kick", CallKickVoteHandler);
	NativeVotes_UnregisterVoteCommand("AdminVoteTest", CallVoteAdminTestHandler, CallVoteAdminVisHandler);
}

public EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		NativeVotes_RegisterVoteCommand("VoteTest", CallVoteTestHandler);
		NativeVotes_RegisterVoteCommand("Kick", CallKickVoteHandler);
		NativeVotes_RegisterVoteCommand("AdminVoteTest", CallVoteAdminTestHandler, CallVoteAdminVisHandler);
	}
	else
	{
		NativeVotes_UnregisterVoteCommand("VoteTest", CallVoteTestHandler);
		NativeVotes_UnregisterVoteCommand("Kick", CallKickVoteHandler);
		NativeVotes_UnregisterVoteCommand("AdminVoteTest", CallVoteAdminTestHandler, CallVoteAdminVisHandler);
	}
}

public Action:CallVoteTestHandler(client, const String:voteCommand[], const String:voteArgument[], NativeVotesKickType:kickType, target)
{
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);

	ReplyToCommand(client, "Attempted to call VoteTest");
	
	SetCmdReplySource(old);

	return Plugin_Handled;
}

public Action:CallVoteAdminVisHandler(client, const String:voteCommand[])
{
	if (CheckCommandAccess(client, "adminvotetest", ADMFLAG_VOTE, true))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action:CallVoteAdminTestHandler(client, const String:voteCommand[], const String:voteArgument[], NativeVotesKickType:kickType, target)
{
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);

	ReplyToCommand(client, "Attempted to call AdminVoteTest");
	
	SetCmdReplySource(old);
	
	return Plugin_Handled;
}

public Action:CallKickVoteHandler(client, const String:voteCommand[], const String:voteArgument[], NativeVotesKickType:kickType, target)
{
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	new targetClient = GetClientOfUserId(target);
	
	decl String:sKickType[32];
	new NativeVotesType:voteType = GetKickVoteTypeFromKickType(kickType, sKickType, sizeof(sKickType));
	
	if (voteType == NativeVotesType_None)
	{
		ReplyToCommand(client, "No kick type found");
		return Plugin_Handled;
	}
	
	if (targetClient == 0)
	{
		NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_PlayerNotFound, target);
		ReplyToCommand(client, "Attempted to call Kick (%s) vote on unknown userid %d", sKickType, target);
		return Plugin_Handled;
	}
	
	if (!CanUserTarget(client, targetClient))
	{
		NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_CantKickAdmin, target);
		ReplyToCommand(client, "Attempted to call Kick (%s) vote on %N, but they have a higher immunity level than you.", sKickType, targetClient);
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "Calling Kick (%s) vote on %N", sKickType, targetClient);
	
	new Handle:vote = NativeVotes_Create(KickVoteHandler, voteType);
	NativeVotes_SetInitiator(vote, client);
	NativeVotes_SetTarget(vote, targetClient);
	NativeVotes_DisplayToAll(vote, 20);
	
	SetCmdReplySource(old);
	
	return Plugin_Handled;
}

public KickVoteHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			NativeVotes_Close(menu);
		}
		
		case MenuAction_VoteEnd:
		{
			new target = NativeVotes_GetTarget(menu);
			
			if (param1 == NATIVEVOTES_VOTE_YES)
			{
				if (target == 0)
				{
					NativeVotes_DisplayFail(menu, NativeVotesFail_Generic);
					PrintToChatAll("User disconnected before kick.");
				}
				decl String:name[MAX_NAME_LENGTH+1];
				GetClientName(target, name, sizeof(name));
				NativeVotes_DisplayPass(menu, name);
				PrintToChatAll("Kick vote on %N passed.", target);
			}
			else
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_Loses);
				PrintToChatAll("Kick vote failed.");
			}
		}
		
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
				PrintToChatAll("Kick vote had no votes.");
			}
			else
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_Generic);
				PrintToChatAll("Kick vote was cancelled.");
			}
		}
	}
}

NativeVotesType:GetKickVoteTypeFromKickType(NativeVotesKickType:kickType, String:sKickType[], maxlength)
{
	new NativeVotesType:voteType;

	switch (kickType)
	{
		case NativeVotesKickType_Generic:
		{
			strcopy(sKickType, maxlength, "Generic");
			voteType = NativeVotesType_Kick;
		}
		
		case NativeVotesKickType_Idle:
		{
			strcopy(sKickType, maxlength, "Idle");
			voteType = NativeVotesType_KickIdle;
		}
		
		case NativeVotesKickType_Scamming:
		{
			strcopy(sKickType, maxlength, "Scamming");
			voteType = NativeVotesType_KickScamming;
		}
		
		case NativeVotesKickType_Cheating:
		{
			strcopy(sKickType, maxlength, "Cheating");
			voteType = NativeVotesType_KickCheating;
		}
		
		default:
		{
			strcopy(sKickType, maxlength, "");
			voteType = NativeVotesType_None;
		}
	}
	
	return voteType;
}