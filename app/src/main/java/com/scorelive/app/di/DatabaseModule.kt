package com.scorelive.app.di

import android.content.Context
import androidx.room.Room
import com.scorelive.app.data.database.FavoriteDao
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

    @Provides
    @Singleton
    fun provideFavoriteDao(database: ScoreLiveDatabase): FavoriteDao = database.favoriteDao()
}
