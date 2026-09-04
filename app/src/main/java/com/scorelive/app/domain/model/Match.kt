package com.scorelive.app.domain.model

import java.time.LocalDateTime

data class Match(
    val id: String,
    val sport: Sport,
    val league: League,
    val homeTeam: Team,
    val awayTeam: Team,
    val homeScore: Int?,
    val awayScore: Int?,
    val status: MatchStatus,
    val kickoff: LocalDateTime,
    val liveMinute: String? = null,
    val quarterScores: List<QuarterScore>? = null,
    val isFavorite: Boolean = false,
)
