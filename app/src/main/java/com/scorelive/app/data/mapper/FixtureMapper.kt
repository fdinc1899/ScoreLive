package com.scorelive.app.data.mapper

import com.scorelive.app.data.api.FixtureItemDto
import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.model.Team
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.ZoneId

/** API status codes documented by API-Football v3. */
private fun mapStatus(short: String?): MatchStatus = when (short) {
    "TBD", "NS" -> MatchStatus.NOT_STARTED
    "1H", "2H", "ET", "P", "BT", "LIVE" -> MatchStatus.LIVE
    "HT" -> MatchStatus.HALF_TIME
    "FT", "AET", "PEN" -> MatchStatus.FINISHED
    "PST" -> MatchStatus.POSTPONED
    "CANC", "ABD" -> MatchStatus.CANCELLED
    "SUSP", "INT" -> MatchStatus.SUSPENDED
    else -> MatchStatus.NOT_STARTED
}

private fun shortNameOf(name: String): String =
    name.split(" ").let { parts ->
        if (parts.size >= 2) parts.take(2).joinToString("") { it.take(1) } else name.take(3)
    }.uppercase()

fun FixtureItemDto.toDomain(): Match? {
    val fixtureId = fixture?.id ?: return null
    val home = teams?.home ?: return null
    val away = teams?.away ?: return null
    val homeName = home.name ?: return null
    val awayName = away.name ?: return null

    val kickoff: LocalDateTime = try {
        OffsetDateTime.parse(fixture.date).atZoneSameInstant(ZoneId.systemDefault()).toLocalDateTime()
    } catch (e: Exception) {
        LocalDateTime.now()
    }

    val status = mapStatus(fixture.status?.short)
    val elapsed = fixture.status?.elapsed

    return Match(
        id = fixtureId.toString(),
        sport = Sport.FOOTBALL,
        league = League(
            id = (league?.id ?: 0L).toString(),
            name = league?.name ?: "Bilinmeyen Lig",
            country = league?.country ?: "",
            countryFlagEmoji = "",
            logoUrl = league?.logo,
        ),
        homeTeam = Team(
            id = (home.id ?: 0L).toString(),
            name = homeName,
            shortName = shortNameOf(homeName),
            logoUrl = home.logo,
        ),
        awayTeam = Team(
            id = (away.id ?: 0L).toString(),
            name = awayName,
            shortName = shortNameOf(awayName),
            logoUrl = away.logo,
        ),
        homeScore = goals?.home,
        awayScore = goals?.away,
        status = status,
        kickoff = kickoff,
        liveMinute = if (status == MatchStatus.LIVE && elapsed != null) "$elapsed'" else null,
    )
}
