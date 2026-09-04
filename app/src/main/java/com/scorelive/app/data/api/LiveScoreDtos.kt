package com.scorelive.app.data.api

import com.google.gson.annotations.SerializedName

/**
 * Response shape for livescore6 matches/v2/list-by-date.
 * Field names are the provider's short codes; they are mapped to readable
 * domain models in FixtureMapper so the rest of the app never sees them.
 */
data class MatchesResponseDto(
    @SerializedName("Ts") val timestamp: Long? = null,
    @SerializedName("Stages") val stages: List<StageDto>? = null,
)

data class StageDto(
    @SerializedName("Sid") val stageId: String? = null,
    @SerializedName("Snm") val stageName: String? = null,
    @SerializedName("Cnm") val countryName: String? = null,
    @SerializedName("Ccd") val countryCode: String? = null,
    @SerializedName("Events") val events: List<EventDto>? = null,
)

data class EventDto(
    @SerializedName("Eid") val eventId: String? = null,
    @SerializedName("Epr") val progress: Int? = null,
    @SerializedName("Eps") val statusText: String? = null,
    @SerializedName("Esd") val startDate: Long? = null,
    @SerializedName("Tr1") val homeScore: String? = null,
    @SerializedName("Tr2") val awayScore: String? = null,
    @SerializedName("T1") val homeTeams: List<EventTeamDto>? = null,
    @SerializedName("T2") val awayTeams: List<EventTeamDto>? = null,
)

data class EventTeamDto(
    @SerializedName("ID") val id: String? = null,
    @SerializedName("Nm") val name: String? = null,
    @SerializedName("Abr") val abbreviation: String? = null,
    @SerializedName("Img") val image: String? = null,
)
