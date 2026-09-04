set -e
cd ~/ScoreLive

mkdir -p app/src/main/java/com/scorelive/app/data/api
mkdir -p app/src/main/java/com/scorelive/app/data/mapper

# ---- local.properties: API bilgileri (git'e girmez) ----
cat > local.properties << 'EOF'
sdk.dir=/opt/android-sdk
SPORTS_API_KEY=c66a5280a7msh44574b92ec5736dp135db5jsna7fd41ed65f6
SPORTS_API_HOST=api-football186.p.rapidapi.com
SPORTS_API_BASE_URL=https://api-football186.p.rapidapi.com/
EOF

# ---- build.gradle.kts: HOST alanini ekle ----
python3 - << 'PYEOF'
import re
p = "app/build.gradle.kts"
s = open(p).read()
if "SPORTS_API_HOST" not in s:
    anchor = '''        buildConfigField(
            "String",
            "SPORTS_API_BASE_URL",'''
    add = '''        buildConfigField(
            "String",
            "SPORTS_API_HOST",
            "\\\\"${localProperties.getProperty("SPORTS_API_HOST", "")}\\\\""
        )
'''
    s = s.replace(anchor, add + anchor, 1)
    open(p, "w").write(s)
    print("HOST alani eklendi")
else:
    print("HOST alani zaten var")
PYEOF

# ---- codemagic.yaml: API bilgilerini build sirasinda enjekte et ----
python3 - << 'PYEOF'
p = "codemagic.yaml"
s = open(p).read()
if "SPORTS_API_HOST" not in s:
    s = s.replace(
        'echo "SPORTS_API_BASE_URL=${SPORTS_API_BASE_URL:-https://api.example.com/}" >> local.properties',
        'echo "SPORTS_API_BASE_URL=${SPORTS_API_BASE_URL:-https://api-football186.p.rapidapi.com/}" >> local.properties\n          echo "SPORTS_API_HOST=${SPORTS_API_HOST:-api-football186.p.rapidapi.com}" >> local.properties'
    )
    s = s.replace(
        'echo "SPORTS_API_KEY=${SPORTS_API_KEY:-}" >> local.properties',
        'echo "SPORTS_API_KEY=${SPORTS_API_KEY:-c66a5280a7msh44574b92ec5736dp135db5jsna7fd41ed65f6}" >> local.properties'
    )
    open(p, "w").write(s)
    print("codemagic.yaml guncellendi")
else:
    print("codemagic.yaml zaten guncel")
PYEOF

# ---- DTO'lar (API-Football v3 semasi) ----
cat > app/src/main/java/com/scorelive/app/data/api/FixtureDtos.kt << 'EOF'
package com.scorelive.app.data.api

import com.google.gson.annotations.SerializedName

data class FixturesResponseDto(
    @SerializedName("response") val response: List<FixtureItemDto>? = null,
    @SerializedName("errors") val errors: Any? = null,
    @SerializedName("results") val results: Int? = null,
)

data class FixtureItemDto(
    @SerializedName("fixture") val fixture: FixtureDto? = null,
    @SerializedName("league") val league: LeagueDto? = null,
    @SerializedName("teams") val teams: TeamsDto? = null,
    @SerializedName("goals") val goals: GoalsDto? = null,
)

data class FixtureDto(
    @SerializedName("id") val id: Long? = null,
    @SerializedName("date") val date: String? = null,
    @SerializedName("status") val status: StatusDto? = null,
)

data class StatusDto(
    @SerializedName("short") val short: String? = null,
    @SerializedName("elapsed") val elapsed: Int? = null,
)

data class LeagueDto(
    @SerializedName("id") val id: Long? = null,
    @SerializedName("name") val name: String? = null,
    @SerializedName("country") val country: String? = null,
    @SerializedName("logo") val logo: String? = null,
    @SerializedName("flag") val flag: String? = null,
)

data class TeamsDto(
    @SerializedName("home") val home: TeamDto? = null,
    @SerializedName("away") val away: TeamDto? = null,
)

data class TeamDto(
    @SerializedName("id") val id: Long? = null,
    @SerializedName("name") val name: String? = null,
    @SerializedName("logo") val logo: String? = null,
)

data class GoalsDto(
    @SerializedName("home") val home: Int? = null,
    @SerializedName("away") val away: Int? = null,
)
EOF

# ---- Retrofit servis ----
cat > app/src/main/java/com/scorelive/app/data/api/SportsApi.kt << 'EOF'
package com.scorelive.app.data.api

import retrofit2.http.GET
import retrofit2.http.Query

interface SportsApi {

    /**
     * Fixtures for a given date (yyyy-MM-dd). Endpoint path is intentionally
     * relative so a different provider can be swapped in by changing only the
     * base URL in local.properties.
     */
    @GET("fixtures")
    suspend fun getFixturesByDate(
        @Query("date") date: String,
        @Query("timezone") timezone: String = "Europe/Istanbul",
    ): FixturesResponseDto
}
EOF

# ---- DTO -> domain donusturucu ----
cat > app/src/main/java/com/scorelive/app/data/mapper/FixtureMapper.kt << 'EOF'
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
EOF

# ---- Gercek repository ----
cat > app/src/main/java/com/scorelive/app/data/repository/RemoteSportsRepositoryImpl.kt << 'EOF'
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
EOF

# ---- Network DI modulu ----
cat > app/src/main/java/com/scorelive/app/di/NetworkModule.kt << 'EOF'
package com.scorelive.app.di

import com.scorelive.app.BuildConfig
import com.scorelive.app.data.api.SportsApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(20, TimeUnit.SECONDS)
        .addInterceptor { chain ->
            // Credentials come from BuildConfig (populated from local.properties),
            // never hard-coded here and never written to logs.
            val request = chain.request().newBuilder()
                .addHeader("x-rapidapi-key", BuildConfig.SPORTS_API_KEY)
                .addHeader("x-rapidapi-host", BuildConfig.SPORTS_API_HOST)
                .build()
            chain.proceed(request)
        }
        .build()

    @Provides
    @Singleton
    fun provideRetrofit(client: OkHttpClient): Retrofit = Retrofit.Builder()
        .baseUrl(BuildConfig.SPORTS_API_BASE_URL)
        .client(client)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    @Provides
    @Singleton
    fun provideSportsApi(retrofit: Retrofit): SportsApi = retrofit.create(SportsApi::class.java)
}
EOF

# ---- Repository binding: gercek repo'ya gec ----
cat > app/src/main/java/com/scorelive/app/di/RepositoryModule.kt << 'EOF'
package com.scorelive.app.di

import com.scorelive.app.data.repository.RemoteSportsRepositoryImpl
import com.scorelive.app.domain.repository.SportsRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

/**
 * Swap RemoteSportsRepositoryImpl for MockSportsRepositoryImpl here to run
 * the app entirely offline against static development data.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    abstract fun bindSportsRepository(impl: RemoteSportsRepositoryImpl): SportsRepository
}
EOF

# ---- HomeScreen: hata durumunda mesaji ve Tekrar Dene butonunu goster ----
python3 - << 'PYEOF'
p = "app/src/main/java/com/scorelive/app/presentation/home/HomeScreen.kt"
s = open(p).read()
s = s.replace(
    'uiState.errorMessage != null -> EmptyView(message = uiState.errorMessage ?: "Veriler yuklenemedi.")',
    'uiState.errorMessage != null -> ErrorView(\n                message = uiState.errorMessage ?: "Veriler yuklenemedi.",\n                onRetry = viewModel::retry,\n            )'
)
s = s.replace(
    "import com.scorelive.app.ui.components.EmptyView",
    "import com.scorelive.app.ui.components.EmptyView\nimport com.scorelive.app.ui.components.ErrorView"
)
open(p, "w").write(s)
print("HomeScreen guncellendi")
PYEOF

# ---- HomeViewModel: retry fonksiyonu ekle ----
python3 - << 'PYEOF'
p = "app/src/main/java/com/scorelive/app/presentation/home/HomeViewModel.kt"
s = open(p).read()
if "fun retry()" not in s:
    s = s.replace(
        "    private fun loadMatches() {",
        "    fun retry() {\n        loadMatches()\n    }\n\n    private fun loadMatches() {"
    )
    open(p, "w").write(s)
    print("HomeViewModel guncellendi")
PYEOF

# ---- Internet izni zaten manifest'te var, kontrol et ----
grep -q "android.permission.INTERNET" app/src/main/AndroidManifest.xml && echo "INTERNET izni mevcut"

git add .
git commit -m "Stage 6: Retrofit network layer, real API repository, DI wiring"
git push
echo "TAMAMLANDI"
