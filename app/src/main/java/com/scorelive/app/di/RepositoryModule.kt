package com.scorelive.app.di

import com.scorelive.app.data.repository.MockSportsRepositoryImpl
import com.scorelive.app.domain.repository.SportsRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    abstract fun bindSportsRepository(impl: MockSportsRepositoryImpl): SportsRepository
}
