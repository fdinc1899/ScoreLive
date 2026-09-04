package com.scorelive.app.data.database

import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.model.Team
import java.time.LocalDateTime
import java.time.ZoneOffset

fun Match.toEntity(queryDate: String, cachedAtEpochMillis: Long) = CachedMatchEntity(
    id = id,
    sport = sport.name,
    queryDate = queryDate,
    leagueId = league.id,
    leagueName = league.name,
    leagueCountry = league.country,
    leagueFlag = league.countryFlagEmoji,
    homeTeamId = homeTeam.id,
    homeTeamName = homeTeam.name,
    homeTeamShort = homeTeam.shortName,
    awayTeamId = awayTeam.id,
    awayTeamName = awayTeam.name,
    awayTeamShort = awayTeam.shortName,
    homeScore = homeScore,
    awayScore = awayScore,
    status = status.name,
    kickoffEpochSeconds = kickoff.toEpochSecond(ZoneOffset.UTC),
    liveMinute = liveMinute,
    cachedAtEpochMillis = cachedAtEpochMillis,
)

/**
 * @param treatLiveAsStale when the cached row is older than the freshness
 * window, a match that was LIVE at cache time is no longer trustworthy, so it
 * is surfaced without the live badge rather than showing a frozen minute.
 */
fun CachedMatchEntity.toDomain(treatLiveAsStale: Boolean): Match {
    val cachedStatus = runCatching { MatchStatus.valueOf(status) }.getOrDefault(MatchStatus.NOT_STARTED)
    val wasLive = cachedStatus == MatchStatus.LIVE || cachedStatus == MatchStatus.HALF_TIME
    val effectiveStatus = if (treatLiveAsStale && wasLive) MatchStatus.SUSPENDED else cachedStatus

    return Match(
        id = id,
        sport = runCatching { Sport.valueOf(sport) }.getOrDefault(Sport.FOOTBALL),
        league = League(
            id = leagueId,
            name = leagueName,
            country = leagueCountry,
            countryFlagEmoji = leagueFlag,
        ),
        homeTeam = Team(id = homeTeamId, name = homeTeamName, shortName = homeTeamShort),
        awayTeam = Team(id = awayTeamId, name = awayTeamName, shortName = awayTeamShort),
        homeScore = homeScore,
        awayScore = awayScore,
        status = effectiveStatus,
        kickoff = LocalDateTime.ofEpochSecond(kickoffEpochSeconds, 0, ZoneOffset.UTC),
        liveMinute = if (treatLiveAsStale && wasLive) null else liveMinute,
    )
}
