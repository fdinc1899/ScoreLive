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
