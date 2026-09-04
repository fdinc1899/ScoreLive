package com.scorelive.app.data.mapper

import com.scorelive.app.data.api.TableDto
import com.scorelive.app.data.api.TableResponseDto
import com.scorelive.app.domain.model.StandingRow

private fun TableDto.collectTeams(): List<StandingRow> {
    val direct = teams.orEmpty().mapNotNull { it.toStandingRow() }
    val fromNested = nested.orEmpty().flatMap { it.collectTeams() }
    return direct + fromNested
}

private fun com.scorelive.app.data.api.TableTeamDto.toStandingRow(): StandingRow? {
    val name = teamName ?: return null
    return StandingRow(
        rank = rank ?: 0,
        teamId = teamId ?: "",
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
    stages.orEmpty()
        .flatMap { stage ->
            stage.leagueTable?.tables.orEmpty().flatMap { group ->
                group.tables.orEmpty().flatMap { it.collectTeams() }
            }
        }
        .sortedBy { if (it.rank == 0) Int.MAX_VALUE else it.rank }
