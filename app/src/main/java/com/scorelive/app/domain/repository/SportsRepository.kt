package com.scorelive.app.domain.repository

import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.model.StandingRow
import java.time.LocalDate

interface SportsRepository {
    suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>>
    suspend fun getLiveMatches(sport: Sport): Result<List<Match>>
    suspend fun getMatchDetails(matchId: String): Result<Match>
    suspend fun search(query: String, sport: Sport): Result<List<Match>>
    suspend fun getStandings(matchId: String, sport: Sport): Result<List<StandingRow>>
}
