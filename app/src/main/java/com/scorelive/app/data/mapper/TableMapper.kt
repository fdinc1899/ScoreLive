package com.scorelive.app.data.mapper

import com.scorelive.app.data.api.TableResponseDto
import com.scorelive.app.data.api.TableTeamDto
import com.scorelive.app.domain.model.StandingRow

private fun TableTeamDto.toStandingRow(): StandingRow? {
    val name = teamName ?: return null
    return StandingRow(
        rank = rank ?: 0,
        teamId = teamId ?: name,
        teamName = name,
        played = played ?: 0,
        won = won ?: 0,
        drawn = drawn ?: 0,
        lost = lost ?: 0,
        goalsFor = goalsFor ?: 0,
        goalsAgainst = goalsAgainst ?: 0,
        points = points ?: 0,
    )
}

fun TableResponseDto.toStandings(): List<StandingRow> =
    leagueTable?.groups.orEmpty()
        .flatMap { group -> group.tables.orEmpty() }
        .flatMap { table -> table.teams.orEmpty() }
        .mapNotNull { it.toStandingRow() }
        .sortedBy { if (it.rank == 0) Int.MAX_VALUE else it.rank }
