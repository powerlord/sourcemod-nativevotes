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

#if defined _nativevotes_vote_included
 #endinput
#endif

#define _nativevotes_vote_included

#include <sourcemod>
// Temporary, for auto-complete
//#include "../include/nativevotes.inc"

// User vote to kick user.
#define TRANSLATION_TF2_VOTE_KICK_IDLE_START			"#TF_vote_kick_player_idle"
#define TRANSLATION_TF2_VOTE_KICK_SCAMMING_START		"#TF_vote_kick_player_scamming"
#define TRANSLATION_TF2_VOTE_KICK_CHEATING_START		"#TF_vote_kick_player_cheating"
#define TRANSLATION_TF2_VOTE_KICK_START					"#TF_vote_kick_player_other"
#define TRANSLATION_TF2_VOTE_KICK_PASSED				"#TF_vote_passed_kick_player"

// User vote to restart map.
#define TRANSLATION_TF2_VOTE_RESTART_START				"#TF_vote_restart_game"
#define TRANSLATION_TF2_VOTE_RESTART_PASSED				"#TF_vote_passed_restart_game"

// User vote to change maps.
#define TRANSLATION_TF2_VOTE_CHANGELEVEL_START			"#TF_vote_changelevel"
#define TRANSLATION_TF2_VOTE_CHANGELEVEL_PASSED			"#TF_vote_passed_changelevel"

// User vote to change next level.
#define TRANSLATION_TF2_VOTE_NEXTLEVEL_SINGLE_START		"#TF_vote_nextlevel"
#define TRANSLATION_TF2_VOTE_NEXTLEVEL_MULTIPLE_START	"#TF_vote_nextlevel_choices" // Started by server
#define TRANSLATION_TF2_VOTE_NEXTLEVEL_EXTEND_PASSED	"#TF_vote_passed_nextlevel_extend"
#define TRANSLATION_TF2_VOTE_NEXTLEVEL_PASSED			"#TF_vote_passed_nextlevel"

// User vote to scramble teams.  Can be immediate or end of round.
#define TRANSLATION_TF2_VOTE_SCRAMBLE_IMMEDIATE_START	"#TF_vote_scramble_teams"
#define TRANSLATION_TF2_VOTE_SCRAMBLE_ROUNDEND_START	"#TF_vote_should_scramble_round"
#define TRANSLATION_TF2_VOTE_SCRAMBLE_PASSED 			"#TF_vote_passed_scramble_teams"

// User vote to change MvM mission
#define TRANSLATION_TF2_VOTE_CHANGEDIFFICULTY_START		"#TF_vote_changechallenge"
#define TRANSLATION_TF2_VOTE_CHANGEDIFFICULTY_PASSED	"#TF_vote_passed_changechallenge"

// While not a vote string, it works just as well.
#define TRANSLATION_TF2_VOTE_CUSTOM						"#TF_playerid_noteam"

#define VOTE_PREFIX										"option"

new bool:g_OptionsSent = false;

bool:Game_CheckVoteType(NativeVotesType:voteType)
{
	switch(voteType)
	{
		case NativeVotesType_ChgDifficulty, NativeVotesType_Custom_YesNo, NativeVotesType_Restart,
		NativeVotesType_ChangeLevel, NativeVotesType_Kick, NativeVotesType_KickIdle,
		NativeVotesType_KickScamming, NativeVotesType_KickCheating, NativeVotesType_NextLevel,
		NativeVotesType_NextLevelMult, NativeVotesType_ScrambleNow, NativeVotesType_ScrambleEnd,
		NativeVotesType_Custom_Mult:
		{
			return true;
		}
		
		default:
		{
			return false;
		}
	}
	
	return false;
}

bool:Game_CheckVotePassType(NativeVotesPass:passType)
{
	switch(passType)
	{
		case NativeVotesPass_ChgDifficulty, NativeVotesPass_Custom, NativeVotesPass_Restart,
		NativeVotesPass_ChangeLevel, NativeVotesPass_Kick, NativeVotesPass_KickIdle,
		NativeVotesPass_KickScamming, NativeVotesPass_KickCheating, NativeVotesPass_NextLevel,
		NativeVotesPass_Extend, NativeVotesPass_ScrambleNow, NativeVotesPass_ScrambleRound:
		{
			return true;
		}
		
		default:
		{
			return false;
		}
	}
	
	return false;
}

Game_GetMaxItems()
{
	return 5;
}

bool:Game_ParseVote(const String:vote[], &item)
{
	if (strlen(vote) != 7)
	{
		item = -1;
		return false;
	}
	
	item = StringToInt(vote[6]);
	
	// Valid options are 1-5, 0 means we had an error
	if (item == 0)
	{
		item = -1;
		return false;
	}
	
	item--;
	return true;
}

Game_ClientSelectedItem(Handle:vote, client, item)
{
	new Handle:castEvent = CreateEvent("vote_cast");
	
	SetEventInt(castEvent, "team", Data_GetTeam(vote));
	SetEventInt(castEvent, "entityid", client);
	SetEventInt(castEvent, "vote_option", item);
	FireEvent(castEvent);
	
	CloseHandle(castEvent);
}

Game_DisplayVote(Handle:vote, clients[], num_clients)
{
	
	if (!Data_GetOptionsSent(vote))
	{
		// This vote never sent its options
		new Handle:optionsEvent = CreateEvent("vote_options");
		
		new maxCount = Data_GetItemCount(vote);
		
		for (new i = 0; i < maxCount; i++)
		{
			decl String:option[8];
			Format(option, sizeof(option), "%s%d", VOTE_PREFIX, i+1);
			
			decl String:display[64];
			Data_GetItemDisplay(vote, i, display, sizeof(display));
			SetEventString(optionsEvent, option, display);
		}
		SetEventInt(optionsEvent, "count", maxCount);
		FireEvent(optionsEvent);
		
		Data_SetOptionsSent(vote, true);
	}
	
	decl String:translation[64];
	new bool:b_YesNo = true;
	
	new NativeVotesType:voteType = Data_GetType(vote);
	
	switch(voteType)
	{
		case NativeVotesType_Custom_Mult:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_CUSTOM);
			b_YesNo = false;
		}
		
		case NativeVotesType_ChgDifficulty:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_CHANGEDIFFICULTY_START);
		}
		
		case NativeVotesType_Restart:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_RESTART_START);
		}
		
		case NativeVotesType_Kick:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_KICK_START);
		}
		
		case NativeVotesType_KickIdle:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_KICK_IDLE_START);
		}
		
		case NativeVotesType_KickScamming:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_KICK_SCAMMING_START);
		}
		
		case NativeVotesType_KickCheating:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_KICK_CHEATING_START);
		}
		
		case NativeVotesType_ChangeLevel:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_CHANGELEVEL_START);
		}
		
		case NativeVotesType_NextLevel:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_NEXTLEVEL_SINGLE_START);
		}
		
		case NativeVotesType_NextLevelMult:
		{
			
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_NEXTLEVEL_MULTIPLE_START);
			b_YesNo = false;
		}
		
		case NativeVotesType_ScrambleNow:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_SCRAMBLE_IMMEDIATE_START);
		}
		
		case NativeVotesType_ScrambleEnd:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_SCRAMBLE_ROUNDEND_START);
		}
		
		default:
		{
			strcopy(translation, sizeof(translation), TRANSLATION_TF2_VOTE_CUSTOM);
		}

	}
	
	decl String:argument[64];
	Data_GetArgument(vote, argument, sizeof(argument));
	new Handle:voteStart = StartMessage("VoteStart", clients, num_clients, USERMSG_RELIABLE);
	BfWriteByte(voteStart, Data_GetTeam(vote));
	BfWriteByte(voteStart, Data_GetInitiator(vote));
	BfWriteString(voteStart, translation);
	BfWriteString(voteStart, argument);
	BfWriteBool(voteStart, b_YesNo);
	EndMessage();
	
}

Game_DisplayVotePass(Handle:vote, const String:param1[])
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
	
	Game_DisplayVotePassEx(vote, passType, param1);
}

Game_DisplayVotePassEx(Handle:vote, NativeVotesPassType:passType, const String:param1[])
{
	decl String:translation[64];
	Game_VotePassToTranslation(passType, translation, sizeof(translation));
	
	new Handle:bf = StartMessageAll("VotePass", USERMSG_RELIABLE);
	BfWriteByte(bf, Data_GetTeam(vote));
	BfWriteString(bf, translation);
	BfWriteString(bf, param1);
	EndMessage();
	
	CloseHandle(bf);
}

stock Game_VotePassToTranslation(NativeVotesPassType:passType, String:buffer[], maxlength)
{
	switch(passType)
	{

		case NativeVotesPass_Custom:
		{
			strcopy(buffer, maxlength, TRANSLATION_TF2_VOTE_CUSTOM);
		}
		
		case NativeVotesPass_ChgDifficulty:
		{
			strcopy(buffer, maxlength, TRANSLATION_TF2_VOTE_CHANGEDIFFICULTY_PASSED);
		}
		
		case NativeVotesPass_Restart:
		{
			strcopy(buffer, maxlength, TRANSLATION_TF2_VOTE_RESTART_PASSED);
		}
		
		case NativeVotesPass_Kick:
		{
			strcopy(buffer, maxlength, TRANSLATION_TF2_VOTE_KICK_PASSED);
		}
		
		case NativeVotesPass_ChangeLevel:
		{
			strcopy(buffer, maxlength, TRANSLATION_TF2_VOTE_CHANGELEVEL_PASSED);
		}
		
		case NativeVotesPass_NextLevel:
		{
			strcopy(buffer, maxlength, TRANSLATION_TF2_VOTE_NEXTLEVEL_PASSED);
		}
		
		case NativeVotesPass_Extend:
		{
			strcopy(buffer, maxlength, TRANSLATION_TF2_VOTE_NEXTLEVEL_EXTEND_PASSED);
		}
		
		case NativeVotesPass_Scramble:
		{
			strcopy(buffer, maxlength, TRANSLATION_TF2_VOTE_SCRAMBLE_PASSED);
		}
	}
}

Game_DisplayVoteFail(Handle:vote, NativeVotesFailType:reason)
{
	new Handle:bf = StartMessageAll("VoteFail", USERMSG_RELIABLE);
	
	BfWriteByte(bf, Data_GetTeam(vote));
	BfWriteByte(bf, _:reason);
	EndMessage();
	
	CloseHandle(bf);
}

Game_DisplayVoteFailOne(Handle:vote, client, NativeVotesFailType:reason)
{
	new Handle:bf = StartMessageOne("VoteFail", client, USERMSG_RELIABLE);
	
	BfWriteByte(bf, Data_GetTeam(vote));
	BfWriteByte(bf, reason);
	EndMessage();
	
	CloseHandle(bf);
}

stock Game_DisplayCallVoteFail(client, NativeVotesCallFailType:reason, param1)
{
	new Handle:bf = StartMessageOne("CallVoteFail", client, USERMSG_RELIABLE);
	
	BfWriteByte(bf, reason);
	BfWriteShort(bf, param1);
	EndMessage();
	
	CloseHandle(bf);
}