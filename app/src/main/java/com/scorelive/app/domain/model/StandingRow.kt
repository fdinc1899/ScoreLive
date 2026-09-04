package com.scorelive.app.domain.model

data class StandingRow(
    val rank: Int,
    val teamId: String,
    val teamName: String,
    val played: Int,
    val won: Int,
    val drawn: Int,
    val lost: Int,
    val goalsFor: Int,
    val goalsAgainst: Int,
    val points: Int,
) {
    val goalDifference: Int get() = goalsFor - goalsAgainst
}
