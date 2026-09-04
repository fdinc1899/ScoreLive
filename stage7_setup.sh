set -e
cd ~/ScoreLive

mkdir -p app/src/main/java/com/scorelive/app/data/database

# ---- Room entity ----
cat > app/src/main/java/com/scorelive/app/data/database/CachedMatchEntity.kt << 'EOF'
package com.scorelive.app.data.database

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "cached_matches")
data class CachedMatchEntity(
    @PrimaryKey val id: String,
    val sport: String,
    val queryDate: String,
    val leagueId: String,
    val leagueName: String,
    val leagueCountry: String,
    val leagueFlag: String,
    val homeTeamId: String,
    val homeTeamName: String,
    val homeTeamShort: String,
    val awayTeamId: String,
    val awayTeamName: String,
    val awayTeamShort: String,
    val homeScore: Int?,
    val awayScore: Int?,
    val status: String,
    val kickoffEpochSeconds: Long,
    val liveMinute: String?,
    /** When this row was written, used to decide whether the cache is stale. */
    val cachedAtEpochMillis: Long,
)
EOF

# ---- DAO ----
cat > app/src/main/java/com/scorelive/app/data/database/MatchDao.kt << 'EOF'
package com.scorelive.app.data.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction

@Dao
interface MatchDao {

    @Query("SELECT * FROM cached_matches WHERE sport = :sport AND queryDate = :queryDate ORDER BY kickoffEpochSeconds ASC")
    suspend fun getMatches(sport: String, queryDate: String): List<CachedMatchEntity>

    @Query("SELECT * FROM cached_matches WHERE id = :id LIMIT 1")
    suspend fun getMatchById(id: String): CachedMatchEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(matches: List<CachedMatchEntity>)

    @Query("DELETE FROM cached_matches WHERE sport = :sport AND queryDate = :queryDate")
    suspend fun clear(sport: String, queryDate: String)

    @Transaction
    suspend fun replaceAll(sport: String, queryDate: String, matches: List<CachedMatchEntity>) {
        clear(sport, queryDate)
        insertAll(matches)
    }

    /** Drops rows older than the given cut-off so the cache cannot grow forever. */
    @Query("DELETE FROM cached_matches WHERE cachedAtEpochMillis < :cutoffEpochMillis")
    suspend fun deleteOlderThan(cutoffEpochMillis: Long)
}
EOF

# ---- Database ----
cat > app/src/main/java/com/scorelive/app/data/database/ScoreLiveDatabase.kt << 'EOF'
package com.scorelive.app.data.database

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [CachedMatchEntity::class], version = 1, exportSchema = false)
abstract class ScoreLiveDatabase : RoomDatabase() {
    abstract fun matchDao(): MatchDao
}
EOF

# ---- Entity <-> domain donusumu ----
cat > app/src/main/java/com/scorelive/app/data/database/CachedMatchMapper.kt << 'EOF'
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
EOF

# ---- Database DI modulu ----
cat > app/src/main/java/com/scorelive/app/di/DatabaseModule.kt << 'EOF'
package com.scorelive.app.di

import android.content.Context
import androidx.room.Room
import com.scorelive.app.data.database.MatchDao
import com.scorelive.app.data.database.ScoreLiveDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): ScoreLiveDatabase =
        Room.databaseBuilder(context, ScoreLiveDatabase::class.java, "scorelive.db")
            .fallbackToDestructiveMigration()
            .build()

    @Provides
    @Singleton
    fun provideMatchDao(database: ScoreLiveDatabase): MatchDao = database.matchDao()
}
EOF

# ---- Repository: agdan cek, cache'e yaz; hata olursa cache'ten oku ----
cat > app/src/main/java/com/scorelive/app/data/repository/RemoteSportsRepositoryImpl.kt << 'EOF'
package com.scorelive.app.data.repository

import com.scorelive.app.data.api.SportsApi
import com.scorelive.app.data.database.MatchDao
import com.scorelive.app.data.database.toDomain
import com.scorelive.app.data.database.toEntity
import com.scorelive.app.data.mapper.toMatches
import com.scorelive.app.domain.model.Match
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

    override suspend fun getMatchDetails(matchId: String): Result<Match> {
        val cached = matchDao.getMatchById(matchId)
        return if (cached != null) {
            val isStale = System.currentTimeMillis() - cached.cachedAtEpochMillis > LIVE_FRESHNESS_WINDOW_MILLIS
            Result.success(cached.toDomain(treatLiveAsStale = isStale))
        } else {
            Result.failure(NoSuchElementException("Mac bulunamadi."))
        }
    }
}
EOF

git add .
git commit -m "Stage 7: Room cache with offline fallback and staleness guard"
git push
echo "TAMAMLANDI"
