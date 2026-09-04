package com.scorelive.app.data.database

import androidx.room.Entity
import androidx.room.PrimaryKey

/** type: MATCH | TEAM | LEAGUE. Composite id keeps the three namespaces apart. */
@Entity(tableName = "favorites")
data class FavoriteEntity(
    @PrimaryKey val key: String,
    val type: String,
    val targetId: String,
    val label: String,
    val addedAtEpochMillis: Long,
)
