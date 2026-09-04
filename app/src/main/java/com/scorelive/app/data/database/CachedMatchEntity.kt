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
