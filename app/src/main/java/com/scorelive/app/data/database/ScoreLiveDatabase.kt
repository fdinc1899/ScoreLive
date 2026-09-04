package com.scorelive.app.data.database

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [CachedMatchEntity::class], version = 1, exportSchema = false)
abstract class ScoreLiveDatabase : RoomDatabase() {
    abstract fun matchDao(): MatchDao
}
