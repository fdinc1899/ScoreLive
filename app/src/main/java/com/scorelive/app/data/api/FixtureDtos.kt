package com.scorelive.app.data.api

import com.google.gson.annotations.SerializedName

data class FixturesResponseDto(
    @SerializedName("response") val response: List<FixtureItemDto>? = null,
    @SerializedName("errors") val errors: Any? = null,
    @SerializedName("results") val results: Int? = null,
)

data class FixtureItemDto(
    @SerializedName("fixture") val fixture: FixtureDto? = null,
    @SerializedName("league") val league: LeagueDto? = null,
    @SerializedName("teams") val teams: TeamsDto? = null,
    @SerializedName("goals") val goals: GoalsDto? = null,
)

data class FixtureDto(
    @SerializedName("id") val id: Long? = null,
    @SerializedName("date") val date: String? = null,
    @SerializedName("status") val status: StatusDto? = null,
)

data class StatusDto(
    @SerializedName("short") val short: String? = null,
    @SerializedName("elapsed") val elapsed: Int? = null,
)

data class LeagueDto(
    @SerializedName("id") val id: Long? = null,
    @SerializedName("name") val name: String? = null,
    @SerializedName("country") val country: String? = null,
    @SerializedName("logo") val logo: String? = null,
    @SerializedName("flag") val flag: String? = null,
)

data class TeamsDto(
    @SerializedName("home") val home: TeamDto? = null,
    @SerializedName("away") val away: TeamDto? = null,
)

data class TeamDto(
    @SerializedName("id") val id: Long? = null,
    @SerializedName("name") val name: String? = null,
    @SerializedName("logo") val logo: String? = null,
)

data class GoalsDto(
    @SerializedName("home") val home: Int? = null,
    @SerializedName("away") val away: Int? = null,
)
