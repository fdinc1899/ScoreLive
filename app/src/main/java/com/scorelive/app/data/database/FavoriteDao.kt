package com.scorelive.app.data.database

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface FavoriteDao {

    @Query("SELECT * FROM favorites ORDER BY addedAtEpochMillis DESC")
    fun observeAll(): Flow<List<FavoriteEntity>>

    @Query("SELECT * FROM favorites WHERE type = :type")
    suspend fun getByType(type: String): List<FavoriteEntity>

    @Query("SELECT targetId FROM favorites WHERE type = :type")
    fun observeIdsByType(type: String): Flow<List<String>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(favorite: FavoriteEntity)

    @Query("DELETE FROM favorites WHERE key = :key")
    suspend fun deleteByKey(key: String)

    @Query("SELECT EXISTS(SELECT 1 FROM favorites WHERE key = :key)")
    suspend fun exists(key: String): Boolean
}
