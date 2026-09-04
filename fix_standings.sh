set -e
cd ~/ScoreLive

# ---- DTO'lar: gercek yapiya gore (kokte Stages sarmalayicisi yok) ----
cat > app/src/main/java/com/scorelive/app/data/api/TableDtos.kt << 'EOF'
package com.scorelive.app.data.api

import com.google.gson.annotations.SerializedName

/**
 * Response shape for livescore6 matches/v2/get-table. The competition object
 * is the root; ranked rows live under LeagueTable.L[].Tables[].team[].
 * A competition can expose several tables (cup groups), so every level is a list.
 */
data class TableResponseDto(
    @SerializedName("Sid") val stageId: String? = null,
    @SerializedName("Snm") val stageName: String? = null,
    @SerializedName("Cnm") val countryName: String? = null,
    @SerializedName("LeagueTable") val leagueTable: LeagueTableDto? = null,
)

data class LeagueTableDto(
    @SerializedName("L") val groups: List<TableGroupDto>? = null,
)

data class TableGroupDto(
    @SerializedName("Tables") val tables: List<TableDto>? = null,
)

data class TableDto(
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
    @SerializedName("gd") val goalDifference: Int? = null,
    @SerializedName("pts") val points: Int? = null,
)
EOF

# ---- Mapper ----
cat > app/src/main/java/com/scorelive/app/data/mapper/TableMapper.kt << 'EOF'
package com.scorelive.app.data.mapper

import com.scorelive.app.data.api.TableResponseDto
import com.scorelive.app.data.api.TableTeamDto
import com.scorelive.app.domain.model.StandingRow

private fun TableTeamDto.toStandingRow(): StandingRow? {
    val name = teamName ?: return null
    return StandingRow(
        rank = rank ?: 0,
        teamId = teamId ?: name,
        teamName = name,
        played = played ?: 0,
        won = won ?: 0,
        drawn = drawn ?: 0,
        lost = lost ?: 0,
        goalsFor = goalsFor ?: 0,
        goalsAgainst = goalsAgainst ?: 0,
        points = points ?: 0,
    )
}

fun TableResponseDto.toStandings(): List<StandingRow> =
    leagueTable?.groups.orEmpty()
        .flatMap { group -> group.tables.orEmpty() }
        .flatMap { table -> table.teams.orEmpty() }
        .mapNotNull { it.toStandingRow() }
        .sortedBy { if (it.rank == 0) Int.MAX_VALUE else it.rank }
EOF

git add .
git commit -m "Fix: match real get-table response shape (no Stages wrapper)"
git push
echo "TAMAMLANDI"
