set -e
cd ~/ScoreLive

# ---- Mapper: bayrak eslesmesini duzelt, kisaltmalari 3 karakterle sinirla ----
cat > app/src/main/java/com/scorelive/app/data/mapper/FixtureMapper.kt << 'EOF'
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

/**
 * The provider sends its own country codes (ENG, ESP, GER...) rather than
 * ISO-3166 alpha-2, so a direct regional-indicator conversion produces the
 * wrong flag. Map by country name instead, which the provider sends in English.
 */
private val flagsByCountry: Map<String, String> = mapOf(
    "TURKEY" to "\uD83C\uDDF9\uD83C\uDDF7",
    "TURKIYE" to "\uD83C\uDDF9\uD83C\uDDF7",
    "ENGLAND" to "\uD83C\uDFF4\uDB40\uDC67\uDB40\uDC62\uDB40\uDC65\uDB40\uDC6E\uDB40\uDC67\uDB40\uDC7F",
    "SCOTLAND" to "\uD83C\uDFF4\uDB40\uDC67\uDB40\uDC62\uDB40\uDC73\uDB40\uDC63\uDB40\uDC74\uDB40\uDC7F",
    "WALES" to "\uD83C\uDFF4\uDB40\uDC67\uDB40\uDC62\uDB40\uDC77\uDB40\uDC6C\uDB40\uDC73\uDB40\uDC7F",
    "SPAIN" to "\uD83C\uDDEA\uD83C\uDDF8",
    "GERMANY" to "\uD83C\uDDE9\uD83C\uDDEA",
    "ITALY" to "\uD83C\uDDEE\uD83C\uDDF9",
    "FRANCE" to "\uD83C\uDDEB\uD83C\uDDF7",
    "PORTUGAL" to "\uD83C\uDDF5\uD83C\uDDF9",
    "NETHERLANDS" to "\uD83C\uDDF3\uD83C\uDDF1",
    "BELGIUM" to "\uD83C\uDDE7\uD83C\uDDEA",
    "AUSTRIA" to "\uD83C\uDDE6\uD83C\uDDF9",
    "SWITZERLAND" to "\uD83C\uDDE8\uD83C\uDDED",
    "GREECE" to "\uD83C\uDDEC\uD83C\uDDF7",
    "RUSSIA" to "\uD83C\uDDF7\uD83C\uDDFA",
    "UKRAINE" to "\uD83C\uDDFA\uD83C\uDDE6",
    "POLAND" to "\uD83C\uDDF5\uD83C\uDDF1",
    "DENMARK" to "\uD83C\uDDE9\uD83C\uDDF0",
    "SWEDEN" to "\uD83C\uDDF8\uD83C\uDDEA",
    "NORWAY" to "\uD83C\uDDF3\uD83C\uDDF4",
    "CROATIA" to "\uD83C\uDDED\uD83C\uDDF7",
    "SERBIA" to "\uD83C\uDDF7\uD83C\uDDF8",
    "ROMANIA" to "\uD83C\uDDF7\uD83C\uDDF4",
    "CZECH REPUBLIC" to "\uD83C\uDDE8\uD83C\uDDFF",
    "BRAZIL" to "\uD83C\uDDE7\uD83C\uDDF7",
    "ARGENTINA" to "\uD83C\uDDE6\uD83C\uDDF7",
    "USA" to "\uD83C\uDDFA\uD83C\uDDF8",
    "UNITED STATES" to "\uD83C\uDDFA\uD83C\uDDF8",
    "MEXICO" to "\uD83C\uDDF2\uD83C\uDDFD",
    "JAPAN" to "\uD83C\uDDEF\uD83C\uDDF5",
    "SOUTH KOREA" to "\uD83C\uDDF0\uD83C\uDDF7",
    "CHINA" to "\uD83C\uDDE8\uD83C\uDDF3",
    "AUSTRALIA" to "\uD83C\uDDE6\uD83C\uDDFA",
    "SAUDI ARABIA" to "\uD83C\uDDF8\uD83C\uDDE6",
    "EUROPE" to "\uD83C\uDDEA\uD83C\uDDFA",
    "WORLD" to "\uD83C\uDF0D",
    "INTERNATIONAL" to "\uD83C\uDF0D",
)

private fun countryFlagEmoji(countryName: String?): String =
    flagsByCountry[countryName?.trim()?.uppercase()] ?: "\u26BD"

private fun shortNameOf(name: String, abbreviation: String?): String {
    // Keep to 3 characters so the circular badge never wraps onto two lines.
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
        countryFlagEmoji = countryFlagEmoji(countryName),
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
EOF

# ---- TeamLogo: tek satirda kalmasini garantile ----
cat > app/src/main/java/com/scorelive/app/ui/components/TeamLogo.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun TeamLogo(shortName: String, modifier: Modifier = Modifier, sizeDp: Dp = 28.dp) {
    Box(
        modifier = modifier
            .size(sizeDp)
            .background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = shortName.take(3).uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onPrimaryContainer,
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Clip,
        )
    }
}
EOF

git add .
git commit -m "Fix: correct country flags by name, keep team badges on one line"
git push
echo "TAMAMLANDI"
