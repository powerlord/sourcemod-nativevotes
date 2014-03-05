/**
 * vim: set ts=4 :
 * =============================================================================
 * Vote Failed
 * Send Vote Failed commands for TF2 and CS:GO
 * Used to test the VoteFailed and CallVoteFailed usermessages
 *
 * Vote Failed (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
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
#pragma semicolon 1

#define VERSION "1.0.0"

new g_bUserBuf = false;

new Handle:g_Cvar_Enabled;

public Plugin:myinfo = {
	name			= "Vote Failed / Call Vote Failed displayer",
	author			= "Powerlord",
	description		= "Used to display specific vote failed and call vote failed messages to a user",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=208008"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("votefailed_version", VERSION, "Vote Failed version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("votefailed_enable", "1", "Enable Vote Failed?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_bUserBuf = (GetUserMessageType() == UM_Protobuf);
	
	RegAdminCmd("votefail", Cmd_VoteFailed, ADMFLAG_GENERIC, "Show Call Vote Fail dialog to user");
	RegAdminCmd("callvotefail", Cmd_CallVoteFailed, ADMFLAG_GENERIC, "Show Call Vote Fail dialog to user");
}

public Action:Cmd_VoteFailed(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		ReplyToCommand(client, "Requires at least one argument");
		return Plugin_Handled;
	}
	
	decl String:sReason[5];
	GetCmdArg(1, sReason, sizeof(sReason));
	
	new reason = StringToInt(sReason);
	
	new Handle:voteFailed = StartMessageOne("VoteFailed", client, USERMSG_RELIABLE);
	
	if(g_bUserBuf)
	{
		PbSetInt(voteFailed, "team", -1);
		PbSetInt(voteFailed, "reason", _:reason);
	}
	else
	{
		BfWriteByte(voteFailed, -1);
		BfWriteByte(voteFailed, _:reason);
	}
	EndMessage();

	return Plugin_Handled;
}

public Action:Cmd_CallVoteFailed(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		ReplyToCommand(client, "Requires at least one argument");
		return Plugin_Handled;
	}
	
	decl String:sReason[5];
	GetCmdArg(1, sReason, sizeof(sReason));
	
	new reason = StringToInt(sReason);
	new time = 0;
	
	if (args > 1)
	{
		decl String:sTime[10];
		GetCmdArg(2, sTime, sizeof(sTime));
		time = StringToInt(sTime);
	}
	
	new Handle:callVoteFail = StartMessageOne("CallVoteFailed", client, USERMSG_RELIABLE);
	if(g_bUserBuf)
	{
		PbSetInt(callVoteFail, "reason", _:reason);
		PbSetInt(callVoteFail, "time", time);
	}
	else
	{
		BfWriteByte(callVoteFail, _:reason);
		BfWriteShort(callVoteFail, time);
	}
	EndMessage();
	
	return Plugin_Handled;
}
