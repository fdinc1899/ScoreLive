package com.scorelive.app.di

import com.scorelive.app.data.repository.FavoritesRepositoryImpl
import com.scorelive.app.data.repository.RemoteSportsRepositoryImpl
import com.scorelive.app.domain.repository.FavoritesRepository
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

    @Binds
    abstract fun bindFavoritesRepository(impl: FavoritesRepositoryImpl): FavoritesRepository
}
