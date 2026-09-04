package com.scorelive.app.data.repository

import com.scorelive.app.data.api.SportsApi
import com.scorelive.app.data.database.MatchDao
import com.scorelive.app.data.database.toDomain
import com.scorelive.app.data.database.toEntity
import com.scorelive.app.data.mapper.toMatches
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.repository.SportsRepository
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit
import javax.inject.Inject

private val apiDateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyyMMdd")

/** Cached scores older than this are shown, but never presented as live. */
private val LIVE_FRESHNESS_WINDOW_MILLIS = TimeUnit.MINUTES.toMillis(2)

/** Rows older than this are pruned on each successful refresh. */
private val CACHE_RETENTION_MILLIS = TimeUnit.DAYS.toMillis(3)

class RemoteSportsRepositoryImpl @Inject constructor(
    private val api: SportsApi,
    private val matchDao: MatchDao,
) : SportsRepository {

    private fun categoryFor(sport: Sport): String? = when (sport) {
        Sport.FOOTBALL -> "soccer"
        Sport.BASKETBALL -> "basketball"
        Sport.TENNIS -> "tennis"
        Sport.VOLLEYBALL -> null
        Sport.MOTORSPORT -> null
    }

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        val category = categoryFor(sport) ?: return Result.success(emptyList())
        val queryDate = apiDateFormatter.format(date)

        return try {
            val response = api.getMatchesByDate(category = category, date = queryDate)
            val matches = response.stages.orEmpty().flatMap { it.toMatches(sport) }

            val now = System.currentTimeMillis()
            matchDao.replaceAll(
                sport = sport.name,
                queryDate = queryDate,
                matches = matches.map { it.toEntity(queryDate, now) },
            )
            matchDao.deleteOlderThan(now - CACHE_RETENTION_MILLIS)

            Result.success(matches)
        } catch (networkError: Exception) {
            // Offline or API failure: fall back to whatever was cached last.
            val cached = matchDao.getMatches(sport.name, queryDate)
            if (cached.isEmpty()) {
                Result.failure(networkError)
            } else {
                val now = System.currentTimeMillis()
                Result.success(
                    cached.map { entity ->
                        val isStale = now - entity.cachedAtEpochMillis > LIVE_FRESHNESS_WINDOW_MILLIS
                        entity.toDomain(treatLiveAsStale = isStale)
                    }
                )
            }
        }
    }

    override suspend fun getLiveMatches(sport: Sport): Result<List<Match>> {
        val category = categoryFor(sport) ?: return Result.success(emptyList())
        return try {
            val response = api.getLiveMatches(category = category)
            Result.success(response.stages.orEmpty().flatMap { it.toMatches(sport) })
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getMatchDetails(matchId: String): Result<Match> {
        val cached = matchDao.getMatchById(matchId)
        return if (cached != null) {
            val isStale = System.currentTimeMillis() - cached.cachedAtEpochMillis > LIVE_FRESHNESS_WINDOW_MILLIS
            Result.success(cached.toDomain(treatLiveAsStale = isStale))
        } else {
            Result.failure(NoSuchElementException("Mac bulunamadi."))
        }
    }

    /**
     * The provider has no free-text search endpoint on this plan, so search
     * filters today's fixtures locally. This costs one request and keeps the
     * behaviour predictable within the 500/month budget.
     */
    override suspend fun search(query: String, sport: Sport): Result<List<Match>> {
        if (query.isBlank()) return Result.success(emptyList())
        return getMatches(sport, LocalDate.now()).map { matches ->
            val needle = query.trim().lowercase()
            matches.filter { match ->
                match.homeTeam.name.lowercase().contains(needle) ||
                    match.awayTeam.name.lowercase().contains(needle) ||
                    match.league.name.lowercase().contains(needle) ||
                    match.league.country.lowercase().contains(needle)
            }
        }
    }
}
