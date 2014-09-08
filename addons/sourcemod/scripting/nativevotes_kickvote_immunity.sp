/**
 * vim: set ts=4 :
 * =============================================================================
 * NativeVotes Kick Vote Immunity
 * Causes TF2 kick votes to fail against people who the current user can't target.
 * 
 * Inspired by psychonic's [TF2] Basic Votekick Immunity
 *
 * NativeVotes Kick Vote Immunity (C)2014 Powerlord (Ross Bemrose).
 * All rights reserved.
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
#undef REQUIRE_PLUGIN
#include <nativevotes>
#pragma semicolon 1

#define VERSION "2.0.0"

new Handle:g_Cvar_Votes;
new Handle:g_Cvar_KickVote;
new Handle:g_Cvar_KickVoteMvM;

new bool:g_bNativeVotes = false;
new bool:g_bRegistered = false;

public Plugin:myinfo = {
	name			= "NativeVotes Kick Vote Immunity",
	author			= "Powerlord",
	description		= "Causes TF2 kick votes to fail against people who the current user can't target.",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=208008"
};

public OnPluginStart()
{
	g_Cvar_Votes = FindConVar("sv_allow_votes");
	g_Cvar_KickVote = FindConVar("sv_vote_issue_kick_allowed");
	g_Cvar_KickVoteMvM = FindConVar("sv_vote_issue_kick_allowed_mvm");

	HookConVarChange(g_Cvar_Votes, Cvar_CheckEnable);
	HookConVarChange(g_Cvar_KickVote, Cvar_CheckEnable);
	HookConVarChange(g_Cvar_KickVoteMvM, Cvar_CheckEnable);
	
	LoadTranslations("common.phrases");
	CreateConVar("nativevotes_kickvote_immunity_version", VERSION, "NativeVotes Kickvote Immunity version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("nativevotes") && GetFeatureStatus(FeatureType_Native, "NativeVotes_DisplayCallVoteFail") == FeatureStatus_Available)
	{
		
		g_bNativeVotes = true;		
		CheckEnable();
	}
}

public OnPluginEnd()
{
	if (g_bNativeVotes)
	{
		UnregisterVoteCommand();
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "nativevotes") && GetFeatureStatus(FeatureType_Native, "NativeVotes_DisplayCallVoteFail") == FeatureStatus_Available)
	{
		g_bNativeVotes = true;
		CheckEnable();
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "nativevotes"))
	{
		g_bNativeVotes = false;
		g_bRegistered = false;
	}
}

RegisterVoteCommand()
{
	if (g_bNativeVotes && !g_bRegistered && GetFeatureStatus(FeatureType_Native, "NativeVotes_DisplayCallVoteFail") == FeatureStatus_Available )
	{
		NativeVotes_RegisterVoteCommand("Kick", KickVoteHandler);
		g_bRegistered = true;
	}
}

UnregisterVoteCommand()
{
	if (g_bNativeVotes && g_bRegistered)
	{
		NativeVotes_UnregisterVoteCommand("Kick", KickVoteHandler);
		g_bRegistered = false;
	}
}

public Cvar_CheckEnable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		CheckEnable();
	}
	else
	{
		CheckDisable();
	}
}

CheckEnable()
{
	if (g_bNativeVotes)
	{
		new bool:bVotes = GetConVarBool(g_Cvar_Votes);
		new bool:bIsMvM = IsMvM();
		if (!g_bRegistered)
		{
			if (bVotes && ((bIsMvM && GetConVarBool(g_Cvar_KickVoteMvM)) || (!bIsMvM && GetConVarBool(g_Cvar_KickVote))))
			{
				LogMessage("Enabling.");
				RegisterVoteCommand();
			}
		}
	}
}

CheckDisable()
{
	if (g_bNativeVotes)
	{
		new bool:bVotes = GetConVarBool(g_Cvar_Votes);
		new bool:bIsMvM = IsMvM();
		if (g_bRegistered)
		{
			if (!bVotes || (bIsMvM && !GetConVarBool(g_Cvar_KickVoteMvM)) || (!bIsMvM && !GetConVarBool(g_Cvar_KickVote)))
			{
				LogMessage("Disabling.");
				UnregisterVoteCommand();
			}
		}
	}
}

stock bool:IsMvM()
{
	return bool:GameRules_GetProp("m_bPlayingMannVsMachine");
}

public Action:KickVoteHandler(client, const String:voteCommand[], const String:voteArgument[], NativeVotesKickType:kickType, target)
{
	if (!CanUserTarget(client, target))
	{
		NativeVotes_DisplayCallVoteFail(client, NativeVotesCallFail_CantKickAdmin);
		PrintToChat(client, "%t \"%N\"", "Unable to target", target);
		return Plugin_Stop;
	}
		
	return Plugin_Continue;
}