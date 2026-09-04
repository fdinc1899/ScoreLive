package com.scorelive.app.data.api

import com.google.gson.annotations.SerializedName

/**
 * Response shape for livescore6 matches/v2/get-table. The provider nests the
 * ranked rows under a list of table groups (a league can have several, e.g.
 * cup group stages), so both levels are modelled.
 */
data class TableResponseDto(
    @SerializedName("Stages") val stages: List<TableStageDto>? = null,
)

data class TableStageDto(
    @SerializedName("Snm") val stageName: String? = null,
    @SerializedName("Cnm") val countryName: String? = null,
    @SerializedName("LeagueTable") val leagueTable: LeagueTableDto? = null,
)

data class LeagueTableDto(
    @SerializedName("L") val tables: List<TableGroupDto>? = null,
)

data class TableGroupDto(
    @SerializedName("Tables") val tables: List<TableDto>? = null,
)

data class TableDto(
    @SerializedName("Tables") val nested: List<TableDto>? = null,
    @SerializedName("team") val teams: List<TableTeamDto>? = null,
)

data class TableTeamDto(
    @SerializedName("Tid") val teamId: String? = null,
    @SerializedName("Tnm") val teamName: String? = null,
    @SerializedName("rnk") val rank: Int? = null,
    @SerializedName("pld") val played: Int? = null,
    @SerializedName("win") val won: Int? = null,
    @SerializedName("drw") val drawn: Int? = null,
    @SerializedName("lst") val lost: Int? = null,
    @SerializedName("gf") val goalsFor: Int? = null,
    @SerializedName("ga") val goalsAgainst: Int? = null,
    @SerializedName("pts") val points: Int? = null,
)
