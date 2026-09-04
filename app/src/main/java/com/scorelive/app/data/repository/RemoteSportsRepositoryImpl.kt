package com.scorelive.app.data.repository

import com.scorelive.app.data.api.SportsApi
import com.scorelive.app.data.mapper.toMatches
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.repository.SportsRepository
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.inject.Inject

private val apiDateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyyMMdd")

class RemoteSportsRepositoryImpl @Inject constructor(
    private val api: SportsApi,
) : SportsRepository {

    // Details are served from the last fetched list so opening a match costs
    // no extra request against the 500/month free tier budget.
    private var lastFetched: List<Match> = emptyList()

    private fun categoryFor(sport: Sport): String? = when (sport) {
        Sport.FOOTBALL -> "soccer"
        Sport.BASKETBALL -> "basketball"
        Sport.TENNIS -> "tennis"
        Sport.VOLLEYBALL -> null
        Sport.MOTORSPORT -> null
    }

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        val category = categoryFor(sport) ?: return Result.success(emptyList())
        return try {
            val response = api.getMatchesByDate(
                category = category,
                date = apiDateFormatter.format(date),
            )
            val matches = response.stages.orEmpty().flatMap { it.toMatches(sport) }
            lastFetched = matches
            Result.success(matches)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getMatchDetails(matchId: String): Result<Match> {
        val match = lastFetched.find { it.id == matchId }
        return if (match != null) {
            Result.success(match)
        } else {
            Result.failure(NoSuchElementException("Mac bulunamadi."))
        }
    }
}
