package com.scorelive.app.domain.repository

import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import java.time.LocalDate

interface SportsRepository {
    suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>>
}
