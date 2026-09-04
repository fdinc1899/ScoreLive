package com.scorelive.app.data.api

import retrofit2.http.GET
import retrofit2.http.Query

interface SportsApi {

    /**
     * @param category soccer | basketball | tennis | hockey | cricket
     * @param date yyyyMMdd
     * @param timezone hours offset from UTC (Turkey = 3)
     */
    @GET("matches/v2/list-by-date")
    suspend fun getMatchesByDate(
        @Query("Category") category: String,
        @Query("Date") date: String,
        @Query("Timezone") timezone: Int = 3,
    ): MatchesResponseDto

    @GET("matches/v2/list-live")
    suspend fun getLiveMatches(
        @Query("Category") category: String,
        @Query("Timezone") timezone: Int = 3,
    ): MatchesResponseDto

    /** League table for the competition a given fixture belongs to. */
    @GET("matches/v2/get-table")
    suspend fun getTable(
        @Query("Category") category: String,
        @Query("Eid") eventId: String,
    ): TableResponseDto
}
