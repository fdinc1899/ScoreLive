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
