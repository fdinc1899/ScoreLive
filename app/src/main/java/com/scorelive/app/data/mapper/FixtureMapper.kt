package com.scorelive.app.data.mapper

import com.scorelive.app.data.api.EventDto
import com.scorelive.app.data.api.StageDto
import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.model.Team
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

private val esdFormatter = DateTimeFormatter.ofPattern("yyyyMMddHHmmss")

/** Epr: 0 = scheduled, 1 = in progress, 2 = finished. Eps carries the label. */
private fun mapStatus(progress: Int?, statusText: String?): MatchStatus {
    val text = statusText?.uppercase().orEmpty()
    return when {
        text == "HT" -> MatchStatus.HALF_TIME
        text.startsWith("POSTP") -> MatchStatus.POSTPONED
        text.startsWith("CANC") -> MatchStatus.CANCELLED
        text.startsWith("ABD") || text.startsWith("SUSP") -> MatchStatus.SUSPENDED
        progress == 1 -> MatchStatus.LIVE
        progress == 2 || text == "FT" || text == "AET" || text == "AP" -> MatchStatus.FINISHED
        else -> MatchStatus.NOT_STARTED
    }
}

private fun countryFlagEmoji(countryCode: String?): String {
    val code = countryCode?.takeIf { it.length >= 2 }?.take(2)?.uppercase() ?: return ""
    // Only ISO-3166 alpha-2 codes map cleanly to regional indicator symbols.
    if (code.any { it !in 'A'..'Z' }) return ""
    val base = 0x1F1E6
    val first = base + (code[0] - 'A')
    val second = base + (code[1] - 'A')
    return String(Character.toChars(first)) + String(Character.toChars(second))
}

private fun shortNameOf(name: String, abbreviation: String?): String {
    if (!abbreviation.isNullOrBlank()) return abbreviation.take(3).uppercase()
    val parts = name.split(" ").filter { it.isNotBlank() }
    return if (parts.size >= 2) {
        parts.take(3).joinToString("") { it.take(1) }.uppercase()
    } else {
        name.take(3).uppercase()
    }
}

fun StageDto.toMatches(sport: Sport): List<Match> {
    val league = League(
        id = stageId ?: (stageName ?: "unknown"),
        name = stageName ?: "Bilinmeyen Lig",
        country = countryName ?: "",
        countryFlagEmoji = countryFlagEmoji(countryCode),
    )
    return events.orEmpty().mapNotNull { it.toMatch(league, sport) }
}

private fun EventDto.toMatch(league: League, sport: Sport): Match? {
    val id = eventId ?: return null
    val home = homeTeams?.firstOrNull() ?: return null
    val away = awayTeams?.firstOrNull() ?: return null
    val homeName = home.name ?: return null
    val awayName = away.name ?: return null

    val kickoff = try {
        LocalDateTime.parse(startDate.toString(), esdFormatter)
    } catch (e: Exception) {
        LocalDateTime.now()
    }

    val status = mapStatus(progress, statusText)

    return Match(
        id = id,
        sport = sport,
        league = league,
        homeTeam = Team(
            id = home.id ?: "",
            name = homeName,
            shortName = shortNameOf(homeName, home.abbreviation),
        ),
        awayTeam = Team(
            id = away.id ?: "",
            name = awayName,
            shortName = shortNameOf(awayName, away.abbreviation),
        ),
        homeScore = homeScore?.toIntOrNull(),
        awayScore = awayScore?.toIntOrNull(),
        status = status,
        kickoff = kickoff,
        liveMinute = if (status == MatchStatus.LIVE) statusText else null,
    )
}
