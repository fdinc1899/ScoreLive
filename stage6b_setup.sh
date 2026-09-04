set -e
cd ~/ScoreLive

# ---- local.properties: LiveScore API bilgileri ----
cat > local.properties << 'EOF'
sdk.dir=/opt/android-sdk
SPORTS_API_KEY=c66a5280a7msh44574b92ec5736dp135db5jsna7fd41ed65f6
SPORTS_API_HOST=livescore6.p.rapidapi.com
SPORTS_API_BASE_URL=https://livescore6.p.rapidapi.com/
EOF

# ---- codemagic.yaml: build sirasinda ayni degerleri enjekte et ----
cat > codemagic.yaml << 'EOF'
workflows:
  android-debug:
    name: ScoreLive Debug APK
    max_build_duration: 30
    environment:
      vars:
        PACKAGE_NAME: "com.scorelive.app"
      java: 17
    scripts:
      - name: Set up local.properties
        script: |
          echo "sdk.dir=$ANDROID_SDK_ROOT" > local.properties
          echo "SPORTS_API_KEY=${SPORTS_API_KEY:-c66a5280a7msh44574b92ec5736dp135db5jsna7fd41ed65f6}" >> local.properties
          echo "SPORTS_API_HOST=${SPORTS_API_HOST:-livescore6.p.rapidapi.com}" >> local.properties
          echo "SPORTS_API_BASE_URL=${SPORTS_API_BASE_URL:-https://livescore6.p.rapidapi.com/}" >> local.properties
      - name: Generate Gradle wrapper
        script: |
          gradle wrapper --gradle-version 8.9
      - name: Build debug APK
        script: |
          ./gradlew assembleDebug --stacktrace
    artifacts:
      - app/build/outputs/**/*.apk
EOF

# ---- DTO'lar: LiveScore (apidojo) semasi ----
rm -f app/src/main/java/com/scorelive/app/data/api/FixtureDtos.kt
cat > app/src/main/java/com/scorelive/app/data/api/LiveScoreDtos.kt << 'EOF'
package com.scorelive.app.data.api

import com.google.gson.annotations.SerializedName

/**
 * Response shape for livescore6 matches/v2/list-by-date.
 * Field names are the provider's short codes; they are mapped to readable
 * domain models in FixtureMapper so the rest of the app never sees them.
 */
data class MatchesResponseDto(
    @SerializedName("Ts") val timestamp: Long? = null,
    @SerializedName("Stages") val stages: List<StageDto>? = null,
)

data class StageDto(
    @SerializedName("Sid") val stageId: String? = null,
    @SerializedName("Snm") val stageName: String? = null,
    @SerializedName("Cnm") val countryName: String? = null,
    @SerializedName("Ccd") val countryCode: String? = null,
    @SerializedName("Events") val events: List<EventDto>? = null,
)

data class EventDto(
    @SerializedName("Eid") val eventId: String? = null,
    @SerializedName("Epr") val progress: Int? = null,
    @SerializedName("Eps") val statusText: String? = null,
    @SerializedName("Esd") val startDate: Long? = null,
    @SerializedName("Tr1") val homeScore: String? = null,
    @SerializedName("Tr2") val awayScore: String? = null,
    @SerializedName("T1") val homeTeams: List<EventTeamDto>? = null,
    @SerializedName("T2") val awayTeams: List<EventTeamDto>? = null,
)

data class EventTeamDto(
    @SerializedName("ID") val id: String? = null,
    @SerializedName("Nm") val name: String? = null,
    @SerializedName("Abr") val abbreviation: String? = null,
    @SerializedName("Img") val image: String? = null,
)
EOF

# ---- Retrofit servis ----
cat > app/src/main/java/com/scorelive/app/data/api/SportsApi.kt << 'EOF'
package com.scorelive.app.data.api

import retrofit2.http.GET
import retrofit2.http.Query

interface SportsApi {

    /**
     * @param category soccer | basketball | tennis | hockey | cricket
     * @param date yyyyMMdd
     * @param timezone hours offset from UTC (Turkey = 3)
     */
    @GET("matches/v2/list-by-date")
    suspend fun getMatchesByDate(
        @Query("Category") category: String,
        @Query("Date") date: String,
        @Query("Timezone") timezone: Int = 3,
    ): MatchesResponseDto
}
EOF

# ---- Mapper ----
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
EOF

# ---- Repository ----
cat > app/src/main/java/com/scorelive/app/data/repository/RemoteSportsRepositoryImpl.kt << 'EOF'
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
EOF

git add .
git commit -m "Stage 6: wire LiveScore API (matches/v2/list-by-date) with correct schema"
git push
echo "TAMAMLANDI"
