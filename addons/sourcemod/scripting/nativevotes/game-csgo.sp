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
#include "../include/nativevotes.inc"

// User vote to kick user.
#define TRANSLATION_CSGO_VOTE_KICK_IDLE_START			"#SFUI_vote_kick_player_idle"
#define TRANSLATION_CSGO_VOTE_KICK_SCAMMING_START		"#SFUI_vote_kick_player_scamming"
#define TRANSLATION_CSGO_VOTE_KICK_CHEATING_START		"#SFUI_vote_kick_player_cheating"
#define TRANSLATION_CSGO_VOTE_KICK_START				"#SFUI_vote_kick_player_other"
#define TRANSLATION_CSGO_VOTE_KICK_PASSED				"#SFUI_vote_passed_kick_player"

// User vote to restart map.
#define TRANSLATION_CSGO_VOTE_RESTART_START				"#SFUI_vote_restart_game"
#define TRANSLATION_CSGO_VOTE_RESTART_PASSED			"#SFUI_vote_passed_restart_game"

// User vote to change maps.
#define TRANSLATION_CSGO_VOTE_CHANGELEVEL_START			"#SFUI_vote_changelevel"
#define TRANSLATION_CSGO_VOTE_CHANGELEVEL_PASSED		"#SFUI_vote_passed_changelevel"

// User vote to change next level.
#define TRANSLATION_CSGO_VOTE_NEXTLEVEL_SINGLE_START	"#SFUI_vote_nextlevel"
#define TRANSLATION_CSGO_VOTE_NEXTLEVEL_MULTIPLE_START	"#SFUI_vote_nextlevel_choices" // Started by server
#define TRANSLATION_CSGO_VOTE_NEXTLEVEL_EXTEND_PASSED	"#SFUI_vote_passed_nextlevel_extend"
#define TRANSLATION_CSGO_VOTE_NEXTLEVEL_PASSED			"#SFUI_vote_passed_nextlevel"

// User vote to scramble teams.  Can be immediate or end of round.
#define TRANSLATION_CSGO_VOTE_SCRAMBLE_START			"#SFUI_vote_scramble_teams"
#define TRANSLATION_CSGO_VOTE_SCRAMBLE_PASSED 			"#SFUI_vote_passed_scramble_teams"

#define TRANSLATION_CSGO_VOTE_SWAPTEAMS_START			"#SFUI_vote_swap_teams"
#define TRANSLATION_CSGO_VOTE_SWAPTEAMS_PASSED 			"#SFUI_vote_passed_swap_teams"

// While not a vote string, it works just as well.
#define TRANSLATION_CSGO_VOTE_CUSTOM					"#SFUI_Scoreboard_NormalPlayer"

