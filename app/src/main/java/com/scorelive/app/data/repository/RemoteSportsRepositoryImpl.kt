package com.scorelive.app.data.repository

import com.scorelive.app.data.api.SportsApi
import com.scorelive.app.data.mapper.toDomain
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.repository.SportsRepository
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.inject.Inject

private val apiDateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

class RemoteSportsRepositoryImpl @Inject constructor(
    private val api: SportsApi,
) : SportsRepository {

    // Details are served from the already-fetched list to stay within the
    // free tier's 100 requests/day budget.
    private var lastFetched: List<Match> = emptyList()

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        if (sport != Sport.FOOTBALL) {
            return Result.success(emptyList())
        }
        return try {
            val response = api.getFixturesByDate(apiDateFormatter.format(date))
            val matches = response.response.orEmpty().mapNotNull { it.toDomain() }
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
