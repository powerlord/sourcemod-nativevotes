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
 
//#include <menus>
 
#if defined _nativevotes_included
 #endinput
#endif
#define _nativevotes_included

#define NATIVEVOTES_EXTEND 			"Extend current Map" /** Defined in TF2, but doesn't appear to be localized */

#define NATIVEVOTES_ALL_TEAMS		-1 // Defined by TF2, may be the same in L4D/L4D2
#define NATIVEVOTES_SERVER_INDEX 	99 // Defined by TF2, may be the same in L4D/L4D2

#define NATIVEVOTES_VOTE_YES	0		/**< Vote was yes */
#define NATIVEVOTES_VOTE_NO		1		/**< Vote was no */

/*
The following MenuActions are supported.  Arguments are also listed, as they differ slightly from the default
MenuAction_Start		A menu has been started (nothing passed). Identical to MenuAction_VoteStart.
MenuAction_Select		An item was selected (param1=client, param2=item). For subplugin support.
MenuAction_End			A vote has fully ended and the vote object is ready to be cleaned up (nothing passed)
						Note: Unlike standard menus MenuAction_End, nothing is passed here.  Check MenuAction_VoteEnd or MenuAction_VoteCancel instead.
MenuAction_VoteEnd		A vote sequence has succeeded (param1=chosen item) 
						This is not called if NativeVotes_SetResultCallback has been used on the vote.
MenuAction_VoteStart	A vote sequence has started (nothing passed).  Use this instead of MenuAction_Start
MenuAction_VoteCancel	A vote sequence has been cancelled (param1=NativeVotes_FailType reason)
*/

#define NATIVEVOTES_ACTIONS_DEFAULT		MenuAction_VoteCancel|MenuAction_VoteEnd|MenuAction_End

/**
 * Vote types. These are mapped to translation strings and pass strings by VoteStart and VotePass handlers
 */
enum NativesVotesType
{
	NativeVotesType_Custom_YesNo,	/**< Yes/No, argument is vote text. */
	NativeVotesType_Custom_Mult,	/**< TF2/CS:GO: Multiple-choice, argument is vote text. */
	NativeVotesType_ChgCampaign,	/**< L4D/L4D2: Yes/No, argument is campaign name */
	NativeVotesType_ChgDifficulty,	/**< L4D/L4D2/TF2: Yes/No, argument is difficulty number in L4D/L4D2 and mission name in TF2 */
	NativeVotesType_ReturnToLobby,	/**< L4D/L4D2: Yes/No, argument ignored */
	NativeVotesType_Alltalk,		/**< L4D2: Yes/No, argument ignored (handled internally by extension) */
	NativeVotesType_Restart,		/**< Yes/No, argument ignored */
	NativeVotesType_Kick,			/**< Yes/No, argument is player userid */
	NativeVotesType_KickIdle,		/**< TF2/CS:GO: Yes/No, argument is player userid */
	NativeVotesType_KickScamming,	/**< TF2/CS:GO: Yes/No, argument is player userid */
	NativeVotesType_KickCheating,	/**< TF2/CS:GO: Yes/No, argument is player userid */
	NativeVotesType_ChangeLevel,	/**< Yes/No, argument is level number in L4D/L4D2 or map name in TF2 */
	NativeVotesType_NextLevel,		/**< TF2/CS:GO: Yes/No, argument is map name */
	NativeVotesType_NextLevelMult,	/**< TF2/CS:GO: Multiple-choice, argument ignored */
	NativeVotesType_ScrambleNow,	/**< TF2/CS:GO: Yes/No, argument ignored */
	NativeVotesType_ScrambleEnd,	/**< TF2: Yes/No, argument ignored */
	NativeVotesType_SwapTeams		/**< CS:GO: Yes/No, argument ignored */
}

enum NativeVotesPassType
{
	NativeVotesPass_Custom,				/**< Argument is custom pass message */
	NativeVotesPass_ChgCampaign,		/**< L4D/L4D2: Argument is campaign name */
	NativeVotesPass_ChgDifficulty,		/**< L4D/L4D2/TF2: Argument is difficulty number in L4D/L4D2 and mission name in TF2 */
	NativeVotesPass_ReturnToLobby,      /**< L4D/L4D2: Argument ignored */
	NativeVotesPass_AlltalkOn,			/**< L4D2: Argument ignored */
	NativeVotesPass_AlltalkOff,			/**< L4D2: Argument ignored */
	NativeVotesPass_Restart,			/**< Argument ignored */
	NativeVotesPass_Kick,				/**< Argument is player userid */
	NativeVotesPass_KickIdle,			/**< TF2/CS:GO: Argument is player userid */
	NativeVotesPass_KickScamming,		/**< TF2/CS:GO: Argument is player userid */
	NativeVotesPass_KickCheating,		/**< TF2/CS:GO: Argument is player userid */
	NativeVotesPass_ChangeLevel,		/**< Argument is level number in L4D/L4D2 or map name in TF2/CS:GO */
	NativeVotesPass_NextLevel,			/**< TF2/CS:GO: Argument is map name */
	NativeVotesPass_Extend,				/**< TF2/CS:GO: Argument ignored */
	NativeVotesPass_Scramble,			/**< TF2/CS:GO: Argument ignored */
	NativeVotesPass_SwapTeams			/**< CS:GO: Argument ignored */
}

/**
 * Reasons a vote was canceled.  Not used for L4D/L4D2, as they don't care
 */
enum NativeVotesFailType
{
	NativeVotesFail_Generic = 0,		/**< Vote was generically cancelled. */
	NativeVotesFail_Loses = 3,			/**< No votes outnumbered Yes votes */
	NativeVotesFail_NotEnoughVotes = 4,	/**< Vote did not receive enough votes. */
}

/**
 * Reasons a callvote command failed.  Not used for L4D/L4D2, as they don't care
 */
enum NativeVotesCallFailType
{
	NativeVotesCallFail_Loading = 1,		/**< Players are still loading. */
	NativeVotesCallFail_Recent = 2,			/**< You can't call another vote yet: Argument is seconds until you can call another vote. */
	NativeVotesCallFail_Disabled = 5,		/**< Server has disabled that issue. */
	NativeVotesCallFail_MapNotFound = 6,	/**< Server does not have that map. */
	NativeVotesCallFail_SpecifyMap = 7,		/**< You must specify a map. */
	NativeVotesCallFail_Failed = 8,			/**< This vote failed recently. */
	NativeVotesCallFail_WrongTeam = 9,		/**< Team can't call this vote. */
	NativeVotesCallFail_Waiting = 10,		/**< Vote can't be called during Waiting For Players. */
	NativeVotesCallFail_Unknown = 11,		/**< Unknown, buggy in TF2. */
	NativeVotesCallFail_CantKickAdmin = 12,	/**< Can't kick server admin. */
	NativeVotesCallFail_ScramblePending = 13,	/**< Team Scramble is pending.. */
	NativeVotesCallFail_Spectators = 14,		/**< Spectators aren't allowed to call votes. */
	NativeVotesCallFail_LevelSet = 15,		/**< Next level already set. */
	
}

/*
 * Is a specific vote type supported by this game?
 * 
 * @param voteType			Vote type
 */
native bool:NativeVotes_IsVoteTypeSupported(NativesVotesType:voteType);

/**
 * Creates a new, empty vote.
 * 
 * @param handler			Function which will receive vote actions.
 * @param voteType			Vote type, cannot be changed after set
 * @param actions			Optionally set which actions to receive.  Start, 
 *							Cancel, and End will always be received regardless
 *							of whether they are set or not.  They are also
 *							the only default actions.
 * @return					A new vote Handle on INVALID_HANDLE if a vote type is unsupported by this game.
 */
native Handle:NativeVotes_Create(MenuHandler:handler, NativesVotesType:voteType,
							MenuAction:actions=NATIVEVOTES_ACTIONS_DEFAULT);

/**
 * Frees all handles related to a vote.
 * 
 * @param vote				Vote handle
 * @noreturn
 */
native Handle:NativeVotes_Close(Handle:vote);

/**
 * Broadcasts a vote to a list of clients.  The most selected item will be 
 * returned through BuiltinVoteAction_End.  On a tie, a random item will be returned 
 * from a list of the tied items.
 *
 * Note that BuiltinVoteAction_End and BuiltinVoteAction_Start are both
 * default callbacks and do not need to be enabled.
 *
 * @param vote				Vote Handle.
 * @param clients			Array of clients to broadcast to.
 * @param numClients		Number of clients in the array.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if a vote is already in progress.
 * @error					Invalid Handle, or a vote is already in progress.
 */
native bool:NativeVotes_Display(Handle:vote, clients[], numClients, time);

/**
 * Sends a vote menu to all clients.  See DisplayBuiltinVote() for more information.
 *
 * @param vote				Vote Handle.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle.
 */
stock bool:NativeVotes_DisplayToAll(Handle:vote, time)
{
	new total;
	decl players[MaxClients];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Sends a vote menu to a single team.  See DisplayBuiltinVote() for more information.
 *
 * @param vote				Vote Handle.
 * @param team				Team to send vote to. 1 = spectators, 2 = RED/Survivors, 3 = BLU/Infected
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle.
 */
stock bool:NativeVotes_DisplayToTeam(Handle:vote, team, time)
{
	NativeVotes_SetTeam(vote, team);

	new total;
	decl players[MaxClients];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) != team))
		{
			continue;
		}
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Sends a vote menu to all clients who are not spectators or waiting to choose a team.  See DisplayBuiltinVote() for more information.
 *
 * @param vote				Vote Handle.
 * @param time				Maximum time to leave menu on the screen.
 * @return					True on success, false if this menu already has a vote session
 *							in progress.
 * @error					Invalid Handle.
 */
stock bool:NativeVotes_DisplayToAllNonSpectators(Handle:vote, time)
{
	new total;
	decl players[MaxClients];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) < 2))
		{
			continue;
		}
		players[total++] = i;
	}
	
	return NativeVotes_Display(vote, players, total, time);
}

/**
 * Appends a new item to the end of a vote.  Only valid for Multiple Choice votes
 *
 * @param vote				BuiltinVote Handle.
 * @param info				Item information string.
 * @return					True on success, false on failure.
 * @error					Invalid Handle, item limit reached, or if the vote is not multiple choice.
 */
native bool:NativeVotes_AddItem(Handle:vote, const String:info[], const String:display[]);

/**
 * Inserts an item into the menu before a certain position; the new item will
 * be at the given position and all next items pushed forward.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @param info				Item information string.
 * @return					True on success, false on failure.
 * @error					Invalid Handle or vote position, or if the vote is not multiple choice.
 */
native bool:NativeVotes_InsertItem(Handle:vote, position, const String:info[], const String:display[]);

/**
 * Removes an item from the menu.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @return					True on success, false on failure.
 * @error					Invalid Handle or vote position,  or if the vote is not multiple choice.
 */
native bool:NativeVotes_RemoveItem(Handle:vote, position);

/**
 * Removes all items from a vote.
 *
 * @param vote				Vote Handle.
 * @noreturn
 * @error					Invalid Handle or vote position, or if the vote is not multiple choice.
 */
native NativeVotes_RemoveAllItems(Handle:vote);

/**
 * Retrieves information about a vote item.
 *
 * @param vote				Vote Handle.
 * @param position			Position, starting from 0.
 * @param infoBuf			Info buffer.
 * @param infoBufLen		Maximum length of the info buffer.
 * @return					True on success, false if position is invalid.
 * @error					Invalid Handlem
 */
native bool:NativeVotes_GetItem(Handle:vote, 
						position, 
						String:infoBuf[], 
						infoBufLen,
						String:dispBuf[]="",
						dispBufLen=0);
						
/**
 * Returns the number of items in a vote.
 *
 * @param vote				Vote Handle.
 * @return					Number of items in the vote.
 * @error					Invalid Handle.
 */
native NativeVotes_GetItemCount(Handle:vote);

/**
 * Sets the vote's argument for votes that support arguments
 *
 * @param vote				Vote Handle.
 * @param argument			Argument string. See vote types for what each argument stands for.
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_SetArgument(Handle:vote, const String:argument[]);

/**
 * Returns the text of a vote's argument if set.
 *
 * @param vote				Vote Handle.
 * @param buffer			Buffer to store argument.
 * @param maxlength			Maximum length of the buffer.
 * @return					Number of bytes written.
 * @error					Invalid Handle.
 */
native NativeVotes_GetArgument(Handle:vote, String:buffer[], maxlength);

/**
 * Returns whether a vote is in progress.
 *
 * @return					True if a BuiltinVote is in progress, false otherwise.
 */
native bool:NativeVotes_IsVoteInProgress();

/**
 * Returns a style's maximum items
 * 
 * @return Maximum items
 */
native NativeVotes_GetMaxItems();

/**
 * Sets a vote's option flags.
 *
 * If a certain bit is not supported, it will be stripped before being set.
 * 
 * NOTE: This is currently unused, but reserved for future use.
 *
 * @param menu				Builtin Vote Handle.
 * @param flags				A new bitstring of VOTEFLAG bits.
 * @noreturn
 * @error					Invalid Handle.
 */
native NativeVotes_SetOptionFlags(Handle:vote, flags);

/**
 * Retrieves a menu's option flags.
 *
 * NOTE: This is currently unused, but reserved for future use.
 *
 * @param vote				Builtin Vote Handle.
 * @return					A bitstring of VOTEFLAG bits.
 * @error					Invalid Handle.
 */
native NativeVotes_GetOptionFlags(Handle:vote);

/**
 * Cancels the vote in progress.
 *
 * @noreturn
 * @error					If no vote is in progress.
 */
native NativeVotes_Cancel();

/**
 * Callback for when a vote has ended and results are available.
 * 
 * Unfortunately, due to limitations on function calling in plugins, this is slightly
 * different than VoteHandler and BuiltinVotes_VoteHandler is.
 * 
 * @param vote				The vote being voted on.
 * @param num_votes			Number of votes tallied in total.
 * @param num_clients		Number of clients who could vote.
 * @param client_info		ADT Array of num_clients 2-element arrays.
 * 							Use VOTEINFO_CLIENT_ defines on inner arrays.
 * @param num_items			Number of unique items that were selected.
 * @param item_info			ADT Array of num_items 2-element arrays, sorted by count.
 * 							Use VOTEINFO_ITEM defines on inner arrays.
 * @noreturn
 */
functag public NativeVotes_VoteHandler(Handle:vote,
						   num_votes, 
						   num_clients,
						   const client_indexes[],
						   const client_votes[],
						   num_items,
						   const item_indexes[],
						   const item_votes[]);

/**
 * Sets an advanced vote handling callback.  If this callback is set,
 * BuiltinVoteAction_VoteEnd will not be called.
 *
 * @param vote				NativeVotes Handle.
 * @param callback			Callback function.
 * @noreturn
 * @error					Invalid Handle or callback.
 */
native NativeVotes_SetResultCallback(Handle:vote, NativeVotes_VoteHandler:callback);

/**
 * Returns the number of seconds you should "wait" before displaying
 * a public vote.  This number is the time remaining until
 * (last_vote + sm_vote_delay).
 *
 * @return					Number of seconds to wait, or 0 for none.
 */
native NativeVotes_CheckVoteDelay();

/**
 * Returns whether a client is in the pool of clients allowed 
 * to participate in the current vote.  This is determined by 
 * the client list passed to NativeVotes_Display().
 *
 * @param client			Client index.
 * @return					True if client is allowed to vote, false otherwise.
 * @error					If no vote is in progress or client index is invalid.
 */
native bool:NativeVotes_IsClientInVotePool(client);

/**
 * Redraws the current vote to a client in the voting pool.
 *
 * @param client			Client index.
 * @param revotes			True to allow revotes, false otherwise.
 * @return					True on success, false if the client is in the vote pool 
 *							but cannot vote again.
 * @error					No vote in progress, client is not in the voting pool, 
 *							or client index is invalid.
 */
native bool:NativeVotes_RedrawClientVote(client, bool:revotes=true);

/**
 * Retrieve the vote type
 * 
 * @param vote				NativeVotes Handle.
 * @return					The built in vote type
 * @error					Invalid Handle
 */
native NativesVotesType:NativeVotes_GetType(Handle:vote);

/**
 * Set the team this vote is for, or NATIVEVOTES_ALL_TEAMS for all teams.
 * 
 * Defaults to NATIVEVOTES_ALL_TEAMS if not explicitly set.
 * 
 * @param vote				NativeVotes Handle.
 * @param team				Team number this vote is for
 * @noreturn
 * @error					Invalid Handle
 */
native NativeVotes_SetTeam(Handle:vote, team);

/**
 * Retrieve the team this vote is for
 * 
 * @param vote				NativeVotes Handle.
 * @return					Team index or BUILTINVOTES_ALL_TEAMS for all teams.
 * @error					Invalid Handle
 */
native NativeVotes_GetTeam(Handle:vote);

/**
 * Set the player who initiated the vote.
 * Use NATIVEVOTES_SERVER_INDEX if initiated by the server itself.
 * 
 * Defaults to NATIVEVOTES_SERVER_INDEX if not explicitly set.
 * 
 * @param vote				NativeVotes Handle.
 * @param client			Client who initiated the vote
 * @noreturn
 * @error					Invalid Handle
 */
native NativeVotes_SetInitiator(Handle:vote, client);

/**
 * Retrieve the client index who initiated the vote or NATIVEVOTES_SERVER_INDEX if 
 * initiated by the server itself.
 * 
 * @param					Vote handle
 * @return					Client index or NATIVEVOTES_SERVER_INDEX
 * @error					Invalid Handle
 */
native NativeVotes_GetInitiator(Handle:vote);

/**
 * Display vote passed screen
 *
 * You MUST call one of NativeVotes_DisplayPass, NativeVotes_DisplayPassEx,
 * or NativeVotes_DisplayFail to hide the vote screen for users who didn't vote,
 * and to clear out their selection for the next vote.
 * 
 * @param vote				Vote handle
 * @param param1			Normally the item that won the vote. Also used for custom vote winners
 */
native NativeVotes_DisplayPass(Handle:vote, String:param1[]="");

/**
 * Display vote passed screen with a custom type.
 *
 * A sample usage of this would be if Extend won an RTV vote: NativeVotes_DisplayPassEx(vote, NativeVotesPass_Extend, map);
 *
 * You MUST call one of NativeVotes_DisplayPass, NativeVotes_DisplayPassEx,
 * or NativeVotes_DisplayFail to hide the vote screen for users who didn't vote,
 * and to clear out their selection for the next vote.
 * 
 * #param vote				Vote handle
 * @param passType			The pass screen to display
 * @param param1			Normally the item that won the vote. Also used for custom vote winners
 */
native NativeVotes_DisplayPassEx(Handle:vote, NativeVotesPassType:passType, String:param1[]="");

/**
 * Display failure screen.
 *
 * You MUST call one of NativeVotes_DisplayPass, NativeVotes_DisplayPassEx,
 * or NativeVotes_DisplayFail to hide the vote screen for users who didn't vote,
 * and to clear out their selection for the next vote.
 * 
 * @param reason			Vote failure reason from BuiltinVoteFailed enum
 */
native NativeVotes_DisplayFail(Handle:vote, NativeVotesFailType:reason=NativeVotesFail_Generic);

/**
 * Quick stock to determine whether voting is allowed.  This doesn't let you 
 * fine-tune a reason for not voting, so it's not recommended for lazily 
 * telling clients that voting isn't allowed.
 * 
 * @return				True if voting is allowed, false if voting is in progress
 *						or the cooldown is active.
 */
stock bool:NativeVotes_IsNewVoteAllowed()
{
	if (NativeVotes_IsVoteInProgress() || NativeVotes_CheckVoteDelay() != 0)
	{
		return false;
	}
	
	return true;
}

/**
 * Retrieves voting information from BuiltinVoteAction_VoteEnd.
 *
 * @param param2		Second parameter of BuiltinVoteAction_VoteEnd.
 * @param winningVotes	Number of votes received by the winning option.
 * @param totalVotes	Number of total votes received.
 * @noreturn
 */
stock NativeVotes_GetInfo(param2, &winningVotes, &totalVotes)
{
	winningVotes = param2 & 0xFFFF;
	totalVotes = param2 >> 16;
}

/**
 * Do not edit below this line!
 */
public SharedPlugin:__pl_nativevotes = 
{
	name = "NativeVotes",
	file = "nativevotes.smx",
#if defined REQUIRE_PLUGINS
	required = 1,
#else
	required = 0,
#endif
};

public __pl_nativevotes_SetNTVOptional()
{
	MarkNativeAsOptional("NativeVotes_Create");
	MarkNativeAsOptional("NativeVotes_Display");
	MarkNativeAsOptional("NativeVotes_AddItem");
	MarkNativeAsOptional("NativeVotes_InsertItem");
	MarkNativeAsOptional("NativeVotes_RemoveItem");
	MarkNativeAsOptional("NativeVotes_RemoveAllItems");
	MarkNativeAsOptional("NativeVotes_GetItem");
	MarkNativeAsOptional("NativeVotes_GetItemCount");
	MarkNativeAsOptional("NativeVotes_SetArgument");
	MarkNativeAsOptional("NativeVotes_GetArgument");
	MarkNativeAsOptional("NativeVotes_IsVoteInProgress");
	MarkNativeAsOptional("NativeVotes_GetMaxItems");
	MarkNativeAsOptional("NativeVotes_SetOptionFlags");
	MarkNativeAsOptional("NativeVotes_GetOptionFlags");
	MarkNativeAsOptional("NativeVotes_SetResultCallback");
	MarkNativeAsOptional("NativeVotes_CheckVoteDelay");
	MarkNativeAsOptional("NativeVotes_IsClientInVotePool");
	MarkNativeAsOptional("NativeVotes_RedrawClientVote");
	MarkNativeAsOptional("NativeVotes_GetType");
	MarkNativeAsOptional("NativeVotes_SetTeam");
	MarkNativeAsOptional("NativeVotes_GetTeam");
	MarkNativeAsOptional("NativeVotes_SetInitiator");
	MarkNativeAsOptional("NativeVotes_GetInitiator");
	MarkNativeAsOptional("NativeVotes_DisplayPass");
	MarkNativeAsOptional("NativeVotes_DisplayPassEx");
	MarkNativeAsOptional("NativeVotes_DisplayFail");
}
