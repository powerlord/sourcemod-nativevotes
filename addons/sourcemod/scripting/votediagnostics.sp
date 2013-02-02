/* Sniff TF2 vote events, user messages, and commands */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// SourceMod 1.4 compatibility shim
#if !defined SOURCE_SDK_CSGO
	#define SOURCE_SDK_CSGO					80		/**< Engine released after CS:GO (no SDK yet) */
#endif

#define LOGFILE "vote_diagnostics.txt"

new g_GameVersion = SOURCE_SDK_UNKNOWN;
new g_VoteController;

#define MAX_ARG_SIZE 65

public Plugin:myinfo = 
{
	name = "TF Vote Sniffer",
	author = "Powerlord",
	description = "Sniff voting events and usermessages",
	version = "1.2",
	url = "http://www.sourcemod.net/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (!Game_IsGameSupported())
	{
		strcopy(error, err_max, "Unsupported game");
		return APLRes_Failure;
	}

	// Necessary for SourceMod 1.4 support
	MarkNativeAsOptional("GetUserMessageType");

	return APLRes_Success;
}


bool:Game_IsGameSupported()
{
	// Guess which game we're using.
	g_GameVersion = GuessSDKVersion(); // This value won't change
	
	switch(g_GameVersion)
	{
		case SOURCE_SDK_EPISODE2VALVE:
		{
			decl String:gameFolder[8];
			GetGameFolderName(gameFolder, PLATFORM_MAX_PATH);
			if (StrEqual(gameFolder, "tf", false) || StrEqual(gameFolder, "tf_beta", false))
			{
				return true;
			}
			else
			{
				// Fail for HL2:MP, DoD:S, and CS:S (on 1.4; CSS is its own engine on 1.5)
				return false;
			}
		}
		
		case SOURCE_SDK_LEFT4DEAD, SOURCE_SDK_LEFT4DEAD2, SOURCE_SDK_CSGO:
		{
			return true;
		}
	}

	return false;
}

public OnPluginStart()
{
	switch (g_GameVersion)
	{
		case SOURCE_SDK_EPISODE2VALVE, SOURCE_SDK_CSGO:
		{
			HookEventEx("vote_cast", TF2CSGO_EventVoteCast);
			HookEventEx("vote_options", TF2CSGO_EventVoteOptions);
			
			HookUserMessage(GetUserMessageId("VoteSetup"), TF2CSGO_MessageVoteSetup);
			HookUserMessage(GetUserMessageId("VoteStart"), TF2CSGO_MessageVoteStart);
			HookUserMessage(GetUserMessageId("VotePass"), TF2CSGO_MessageVotePass);
			HookUserMessage(GetUserMessageId("VoteFailed"), TF2CSGO_MessageVoteFail);
			HookUserMessage(GetUserMessageId("CallVoteFailed"), TF2CSGO_MessageCallVoteFailed);
		}
		
		case SOURCE_SDK_LEFT4DEAD:
		{
			HookEventEx("vote_changed", L4DL4D2_EventVoteChanged);
			HookEventEx("vote_ended", L4D_EventVoteEnded);
			HookEventEx("vote_started", L4D_EventVoteStarted);
			HookEventEx("vote_passed", L4D_EventVotePassed);
			HookEventEx("vote_failed", L4D_EventVoteFailed);
			HookEventEx("vote_cast_yes", L4D_EventVoteYes);
			HookEventEx("vote_cast_no", L4D_EventVoteNo);
		}
		
		case SOURCE_SDK_LEFT4DEAD2:
		{
			HookEventEx("vote_changed", L4DL4D2_EventVoteChanged);
			HookUserMessage(GetUserMessageId("VoteRegistered"), L4D2_MessageVoteRegistered);

			HookUserMessage(GetUserMessageId("VoteStart"), L4D2_MessageVoteStart);
			HookUserMessage(GetUserMessageId("VotePass"), L4D2_MessageVotePass);
			HookUserMessage(GetUserMessageId("VoteFail"), L4D2_MessageVoteFail);
		}
	}
	
	AddCommandListener(CommandVote, "vote");
	AddCommandListener(CommandVote, "Vote");
	AddCommandListener(CommandCallVote, "callvote");
	
	new String:gameName[10];
	GetGameFolderName(gameName, sizeof(gameName));
	
	LogToFile(LOGFILE, "Game: %s", gameName);
}

public OnConfigsExecuted()
{
	// This is done every map for safety reasons... it usually doesn't change
	g_VoteController = EntIndexToEntRef(FindEntityByClassname(-1, "vote_controller"));
	if (g_VoteController == INVALID_ENT_REFERENCE)
	{
		LogError("Could not find Vote Controller.");
	}
}

/*
"vote_changed"
{
		"yesVotes"              "byte"
		"noVotes"               "byte"
		"potentialVotes"        "byte"
}
*/
public L4DL4D2_EventVoteChanged(Handle:event, const String:name[], bool:dontBroadcast)
{
	new yesVotes = GetEventInt(event, "yesVotes");
	new noVotes = GetEventInt(event, "noVotes");
	new potentialVotes = GetEventInt(event, "potentialVotes");
	LogMessage("Vote Changed event: yesVotes: %d, noVotes: %d, potentialVotes: %d",
		yesVotes, noVotes, potentialVotes);
	
}

/*
 "vote_started"
{
		"issue"                 "string"
		"param1"                "string"
		"team"                  "byte"
		"initiator"             "long" // entity id of the player who initiated the vote
}
*/
public L4D_EventVoteStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:issue[MAX_ARG_SIZE];
	decl String:param1[MAX_ARG_SIZE];
	GetEventString(event, "issue", issue, sizeof(issue));
	GetEventString(event, "param1", param1, sizeof(param1));
	new team = GetEventInt(event, "team");
	new initiator = GetEventInt(event, "initiator");
	LogToFile(LOGFILE, "Vote Start Event: issue: \"%s\", param1: \"%s\", team: %d, initiator: %d", issue, param1, team, initiator);
	
	LogToFile(LOGFILE, "Active Index for issue %s: %d", issue, GetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex"));
}

/*
"vote_ended"
{
}
*/
public L4D_EventVoteEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogToFile(LOGFILE, "Vote Ended Event");
}

/*
"vote_passed"
{
		"details"               "string"
		"param1"                "string"
		"team"                  "byte"
}
*/
public L4D_EventVotePassed(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:details[MAX_ARG_SIZE];
	decl String:param1[MAX_ARG_SIZE];
	GetEventString(event, "details", details, sizeof(details));
	GetEventString(event, "param1", param1, sizeof(param1));
	new team = GetEventInt(event, "team");
	LogToFile(LOGFILE, "Vote Passed event: details: %s, param1: %s, team: %d", details, param1, team);
}

/*
"vote_failed"
{
		"team"                  "byte"
}
*/
public L4D_EventVoteFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	LogToFile(LOGFILE, "Vote Failed event: team: %d", team);
}

/*
"vote_cast_yes"
{
		"team"                  "byte"
		"entityid"              "long"  // entity id of the voter
}
*/
public L4D_EventVoteYes(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	new client = GetEventInt(event, "entityid");
	LogToFile(LOGFILE, "Vote Cast Yes event: team: %d, client: %N", team, client);
}

/*
"vote_cast_no"
{
		"team"                  "byte"
		"entityid"              "long"  // entity id of the voter
}
*/
public L4D_EventVoteNo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	new client = GetEventInt(event, "entityid");
	LogToFile(LOGFILE, "Vote Cast No event: team: %d, client: %N", team, client);
}

/*
VoteStart Structure
	- Byte      Team index or -1 for all
	- Byte      Initiator client index (or 99 for Server?)
	- String    Vote issue phrase
	- String    Vote issue phrase argument
	- String    Initiator name

*/
public Action:L4D2_MessageVoteStart(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new String:issue[MAX_ARG_SIZE];
	new String:param1[MAX_ARG_SIZE];
	new String:initiatorName[MAX_NAME_LENGTH];

	new team = BfReadByte(message);
	new initiator = BfReadByte(message);
	
	BfReadString(message, issue, MAX_ARG_SIZE);
	BfReadString(message, param1, MAX_ARG_SIZE);
	BfReadString(message, initiatorName, MAX_NAME_LENGTH);

	LogToFile(LOGFILE, "VoteStart Usermessage: team: %d, initiator: %d, issue: %s, param1: %s, player count: %d, initiatorName: %s", team, initiator, issue, param1, playersNum, initiatorName);
	LogToFile(LOGFILE, "Active Index for issue %s: %d", issue, GetEntProp(g_VoteController, Prop_Send, "m_activeIssueIndex"));

	return Plugin_Continue;
}

/*
VotePass Structure
	- Byte      Team index or -1 for all
	- String    Vote issue pass phrase
	- String    Vote issue pass phrase argument

*/
public Action:L4D2_MessageVotePass(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new String:issue[MAX_ARG_SIZE];
	new String:param1[MAX_ARG_SIZE];
	new team = BfReadByte(message);
	
	BfReadString(message, issue, MAX_ARG_SIZE);
	BfReadString(message, param1, MAX_ARG_SIZE);
	
	LogToFile(LOGFILE, "VotePass Usermessage: team: %d, issue: %s, param1: %s", team, issue, param1);
	return Plugin_Continue;
}

/*
VoteFail Structure
	- Byte      Team index or -1 for all

*/  
public Action:L4D2_MessageVoteFail(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new team = BfReadByte(message);
	
	LogToFile(LOGFILE, "VoteFail Usermessage: team: %d", team);
	return Plugin_Continue;
}

/*
VoteRegistered Structure
	- Byte      Choice voted for, 0 = No, 1 = Yes

*/  
public Action:L4D2_MessageVoteRegistered(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new choice = BfReadByte(message);
	
	LogToFile(LOGFILE, "VoteRegistered Usermessage: choice: %d", choice);
	return Plugin_Continue;
}

/*
"vote_cast"
{
		"vote_option"   "byte"  // which option the player voted on
		"team"                  "short"
		"entityid"              "long"  // entity id of the voter
}
*/
public TF2CSGO_EventVoteCast(Handle:event, const String:name[], bool:dontBroadcast)
{
	new vote_option = GetEventInt(event, "vote_option");
	new team = GetEventInt(event, "team");
	new entityid = GetEventInt(event, "entityid");
	LogToFile(LOGFILE, "Vote Cast event: vote_option: %d, team: %d, client: %N", vote_option, team, entityid);
}

/*
"vote_options"
{
		"count"                 "byte"  // Number of options - up to MAX_VOTE_OPTIONS
		"option1"               "string"
		"option2"               "string"
		"option3"               "string"
		"option4"               "string"
		"option5"               "string"
}
*/
public TF2CSGO_EventVoteOptions(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:option1[MAX_ARG_SIZE];
	decl String:option2[MAX_ARG_SIZE];
	decl String:option3[MAX_ARG_SIZE];
	decl String:option4[MAX_ARG_SIZE];
	decl String:option5[MAX_ARG_SIZE];
	
	new count = GetEventInt(event, "count");
	GetEventString(event, "option1", option1, sizeof(option1));
	GetEventString(event, "option2", option2, sizeof(option2));
	GetEventString(event, "option3", option3, sizeof(option3));
	GetEventString(event, "option4", option4, sizeof(option4));
	GetEventString(event, "option5", option5, sizeof(option5));
	LogToFile(LOGFILE, "Vote Options event: count: %d, option1: %s, option2: %s, option3: %s, option4: %s, option5: %s", 
		count, option1, option2, option3, option4, option5);
}

/*
VoteSetup
	- Byte		Option count
	* String 	(multiple strings, presumably the vote options. put "  (Disabled)" without the quotes after the option text to disable one of  the options?)
 
message CCSUsrMsg_VoteSetup
{
	repeated string potential_issues = 1;
}	 
*/
public Action:TF2CSGO_MessageVoteSetup(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new String:options[1025];
	new count;
	
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		count = PbGetRepeatedFieldCount(message, "potential_issues");
		for(new i = 0; i < count; i++)
		{
			decl String:option[MAX_ARG_SIZE];
			PbReadRepeatedString(message, "potential_issues", i, option, MAX_ARG_SIZE);
			StrCat(options, MAX_ARG_SIZE, option);
			StrCat(options, MAX_ARG_SIZE, " ");
		}
	}
	else
	{
		count = BfReadByte(message);
		for (new i = 0; i < count; i++)
		{
			decl String:option[MAX_ARG_SIZE];
			BfReadString(message, option, MAX_ARG_SIZE);
			StrCat(options, MAX_ARG_SIZE, option);
			StrCat(options, MAX_ARG_SIZE, " ");
		}
	}

	LogToFile(LOGFILE, "VoteSetup Usermessage: count: %d, options: %s", count, options);
	
	return Plugin_Continue;
}

/*
VoteStart Structure
	- Byte      Team index or -1 for all
	- Byte      Initiator client index or 99 for Server
	- String    Vote issue phrase
	- String    Vote issue phrase argument
	- Bool      false for Yes/No, true for Multiple choice

message CCSUsrMsg_VoteStart
{
	optional int32 team = 1;
	optional int32 ent_idx = 2;
	optional int32 vote_type = 3;
	optional string disp_str = 4;
	optional string details_str = 5;
	optional string other_team_str = 6;
	optional bool is_yes_no_vote = 7;

}
*/
public Action:TF2CSGO_MessageVoteStart(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new String:issue[MAX_ARG_SIZE];
	new String:otherTeamIssue[MAX_ARG_SIZE];
	new String:param1[MAX_ARG_SIZE];
	new team;
	new initiator;
	new multipleChoice;
	new voteType;
	
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		team = PbReadInt(message, "team");
		initiator = PbReadInt(message, "ent_idx");
		PbReadString(message, "disp_str", issue, MAX_ARG_SIZE);
		PbReadString(message, "details_str", param1, MAX_ARG_SIZE);
		multipleChoice = PbReadBool(message, "is_yes_no_vote");
		PbReadString(message, "other_team_str", otherTeamIssue, MAX_ARG_SIZE);
		voteType = PbReadInt(message, "vote_type");
	}
	else
	{
		team = BfReadByte(message);
		initiator = BfReadByte(message);
		BfReadString(message, issue, MAX_ARG_SIZE);
		BfReadString(message, param1, MAX_ARG_SIZE);
		multipleChoice = BfReadBool(message);
	}

	LogToFile(LOGFILE, "VoteStart Usermessage: team: %d, initiator: %d, issue: %s, otherTeamIssue: %s, param1: %s, multipleChoice: %d, player count: %d, voteType: %d", team, initiator, issue, otherTeamIssue, param1, multipleChoice, playersNum, voteType);
	LogToFile(LOGFILE, "Active Index for issue %s: %d", issue, GetEntProp(g_VoteController, Prop_Send, "m_iActiveIssueIndex"));

	return Plugin_Continue;
}

/*
VotePass Structure
	- Byte      Team index or -1 for all
	- String    Vote issue pass phrase
	- String    Vote issue pass phrase argument

message CCSUsrMsg_VotePass
{
	optional int32 team = 1;
	optional int32 vote_type = 2;
	optional string disp_str= 3;
	optional string details_str = 4;
}
*/
public Action:TF2CSGO_MessageVotePass(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new String:issue[MAX_ARG_SIZE];
	new String:param1[MAX_ARG_SIZE];
	new team;
	new voteType;

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		team = PbReadInt(message, "team");
		PbReadString(message, "disp_str", issue, MAX_ARG_SIZE);
		PbReadString(message, "details_str", param1, MAX_ARG_SIZE);
		voteType = PbReadInt(message, "vote_type");
	}
	else
	{
		team = BfReadByte(message);
		BfReadString(message, issue, MAX_ARG_SIZE);
		BfReadString(message, param1, MAX_ARG_SIZE);
	}
	
	LogToFile(LOGFILE, "VotePass Usermessage: team: %d, issue: %s, param1: %s, voteType: %d", team, issue, param1, voteType);
	return Plugin_Continue;
}

/*
VoteFailed Structure
	- Byte      Team index or -1 for all
	- Byte      Failure reason code (0, 3-4)

message CCSUsrMsg_VoteFailed
{
	optional int32 team = 1;
	optional int32 reason = 2;	
}
*/  
public Action:TF2CSGO_MessageVoteFail(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new team;
	new reason;
	
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		team = PbReadInt(message, "team");
		reason = PbReadInt(message, "reason");
	}
	else
	{
		team = BfReadByte(message);
		reason = BfReadByte(message);
	}
	
	LogToFile(LOGFILE, "VoteFail Usermessage: team: %d, reason: %d", team, reason);
	return Plugin_Continue;
}

/*
CallVoteFailed
    - Byte		Failure reason code (1-2, 5-15)
    - Short		Time until new vote allowed for code 2

message CCSUsrMsg_CallVoteFailed
{
	optional int32 reason = 1;
	optional int32 time = 2;
}
*/
public Action:TF2CSGO_MessageCallVoteFailed(UserMsg:msg_id, Handle:message, const players[], playersNum, bool:reliable, bool:init)
{
	new reason;
	new time;
	
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		reason = PbReadInt(message, "reason");
		time = PbReadInt(message, "time");
	}
	else
	{
		reason = BfReadByte(message);
		time = BfReadShort(message);
	}
	
	LogToFile(LOGFILE, "CallVoteFailed Usermessage: reason: %d, time: %d", reason, time);
	return Plugin_Continue;
}

/*
Vote command
    - String		option1 through option5 (for TF2/CS:GO); Yes or No (for L4D/L4D2)
 */
public Action:CommandVote(client, const String:command[], argc)
{
	decl String:vote[MAX_ARG_SIZE];
	GetCmdArg(1, vote, sizeof(vote));
	
	LogToFile(LOGFILE, "%N used vote command: %s %s", client, command, vote);
	return Plugin_Continue;
}

/*
callvote command
	- String		Vote type (Valid types are sent in the VoteSetup message)
	- String		target (or type - target for Kick)
*/
public Action:CommandCallVote(client, const String:command[], argc)
{
	decl String:args[255];
	GetCmdArgString(args, sizeof(args));
	
	LogToFile(LOGFILE, "callvote command: client: %N, command: %s", client, args);
	return Plugin_Continue;
}
