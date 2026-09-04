package com.scorelive.app.data.api

import retrofit2.http.GET
import retrofit2.http.Query

interface SportsApi {

    /**
     * Fixtures for a given date (yyyy-MM-dd). Endpoint path is intentionally
     * relative so a different provider can be swapped in by changing only the
     * base URL in local.properties.
     */
    @GET("fixtures")
    suspend fun getFixturesByDate(
        @Query("date") date: String,
        @Query("timezone") timezone: String = "Europe/Istanbul",
    ): FixturesResponseDto
}
