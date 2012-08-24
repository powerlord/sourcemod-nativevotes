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

#if defined _nativevotes_data_included
 #endinput
#endif

#define _nativevotes_data_included

#include <sourcemod>

#define INFO_LENGTH 128
#define INFO "item_info"
#define DISPLAY "item_display"

bool:Data_GetItemInfo(Handle:vote, item, String:choice[], choiceSize)
{
	Handle:array = KvGetNum(vote, INFO, INVALID_HANDLE);

	if (array == INVALID_HANDLE || item > GetArraySize(item))
	{
		return false;
	}
	
	GetArrayString(array, item, choice, choiceSize);
}

bool:Data_GetItemDisplay(Handle:vote, item, String:choice[], choiceSize)
{
	Handle:array = KvGetNum(vote, DISPLAY, INVALID_HANDLE);

	if (array == INVALID_HANDLE || item > GetArraySize(item))
	{
		return false;
	}
	
	GetArrayString(array, item, choice, choiceSize);
}

Data_GetTeam(Handle:vote)
{
	return KvGetNum(vote, "team", NATIVEVOTES_ALL_TEAMS);
}

Data_SetTeam(Handle:vote, team)
{
	KvSetNum(vote, "team", team);
}

Data_GetInitiator(Handle:vote)
{
	return KvGetNum(vote, "initiator", NATIVEVOTES_SERVER_INDEX);
}

Data_SetInitiator(Handle:vote, initiator)
{
	KvSetNum(vote, "initiator", initiator);
}

Data_GetArgument(Handle:vote, String:argument[], maxlength)
{
	KvGetString(vote, "argument", argument, maxlength);
}

Data_SetArgument(Handle:vote, const String:argument[])
{
	KvSetString(vote, "argument", argument);
}

NativeVotesType:Data_GetType(Handle:vote)
{
	return NativeVotesType:KvGetNum(vote, "vote_type", _:NativeVotesType_Custom_YesNo);
	
}

Handle:Data_GetHandler(Handle:vote)
{
	if (vote == INVALID_HANDLE)
		return INVALID_HANDLE;
	
	return Handle:KvGetNum(vote, "handler_callback");
}

Handle:Data_GetResultCallback(Handle:vote)
{
	if (vote == INVALID_HANDLE)
		return INVALID_HANDLE;
	
	return Handle:KvGetNum(vote, "result_callback");
}

Handle:Data_CreateVote(NativeVotesType:voteType, MenuAction:actions)
{
	new Handle:handler = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	new Handle:voteResults = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Cell, Param_Array, Param_Array);
	
	new Handle:vote = CreateKeyValues("NativeVote");
	KvSetNum(vote, "handler_callback", _:handler);
	KvSetNum(vote, "vote_type", _:voteType);
	KvSetString(vote, "argument", "");
	KvSetNum(vote, "actions", _:actions);
	KvSetNum(vote, "result_callback", _:voteResults);
	KvSetNum(vote, "initiator", NATIVEVOTES_SERVER_INDEX);
	KvSetNum(vote, "team", NATIVEVOTES_ALL_TEAMS);
	
	KvSetNum(vote, INFO, _:CreateArray(ByteCountToCells(INFO_LENGTH)));
	KvSetNum(vote, DISPLAY, _:CreateArray(ByteCountToCells(INFO_LENGTH)));
	
	return vote;
}

bool:Data_AddItem(Handle:vote, const String:info[], const String:display[])
{
	new Handle:infoArray = Handle:KvGetNum(vote, INFO, _:INVALID_HANDLE);
	new Handle:displayArray = Handle:KvGetNum(vote, DISPLAY, _:INVALID_HANDLE);
	
	if (infoArray == INVALID_HANDLE || displayArray == INVALID_HANDLE ||
		GetArraySize(infoArray) >= Game_GetMaxItems() ||
		GetArraySize(displayArray) >= Game_GetMaxItems())
	{
		return false;
	}
	
	PushArrayString(infoArray, info);
	PushArrayString(displayArray, display);
	
	return true;
}

bool:Data_InsertItem(Handle:vote, position, const String:info[], const String:display[])
{
	new Handle:infoArray = Handle:KvGetNum(vote, INFO, _:INVALID_HANDLE);
	new Handle:displayArray = Handle:KvGetNum(vote, DISPLAY, _:INVALID_HANDLE);
	
	if (infoArray == INVALID_HANDLE || displayArray == INVALID_HANDLE ||
		GetArraySize(infoArray) >= Game_GetMaxItems() ||
		GetArraySize(displayArray) >= Game_GetMaxItems())
	{
		return false;
	}
	
	ShiftArrayUp(infoArray, position);
	ShiftArrayUp(displayArray, position);

	SetArrayString(infoArray, position, info);
	SetArrayString(displayArray, position, display);
	
	return true;
}

Data_CloseVote(Handle:vote)
{
	if (vote == INVALID_HANDLE)
	{
		return;
	}
	
	new Handle:handler = Handle:KvGetNum(vote, "handler_callback", _:INVALID_HANDLE);
	if (handler != INVALID_HANDLE)
	{
		CloseHandle(handler);
	}
	
	new Handle:voteResults = Handle:KvGetNum(vote, "results_callback", _:INVALID_HANDLE);
	if (voteResults != INVALID_HANDLE)
	{
		CloseHandle(voteResults);
	}
	
	new Handle:infoArray = Handle:KvGetNum(vote, INFO, _:INVALID_HANDLE);
	
	if (infoArray != INVALID_HANDLE)
	{
		CloseHandle(infoArray);
	}
	
	new Handle:displayArray = Handle:KvGetNum(vote, DISPLAY, _:INVALID_HANDLE);
	if (displayArray != INVALID_HANDLE)
	{
		CloseHandle(displayArray);
	}
	
	CloseHandle(vote);
}
