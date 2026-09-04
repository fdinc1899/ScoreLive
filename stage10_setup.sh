set -e
cd ~/ScoreLive

# ---- Domain: puan durumu satiri ----
cat > app/src/main/java/com/scorelive/app/domain/model/StandingRow.kt << 'EOF'
package com.scorelive.app.domain.model

data class StandingRow(
    val rank: Int,
    val teamId: String,
    val teamName: String,
    val played: Int,
    val won: Int,
    val drawn: Int,
    val lost: Int,
    val goalsFor: Int,
    val goalsAgainst: Int,
    val points: Int,
) {
    val goalDifference: Int get() = goalsFor - goalsAgainst
}
EOF

# ---- API: puan durumu endpoint'i ----
cat > app/src/main/java/com/scorelive/app/data/api/SportsApi.kt << 'EOF'
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
EOF

# ---- Puan durumu DTO'lari ----
cat > app/src/main/java/com/scorelive/app/data/api/TableDtos.kt << 'EOF'
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
EOF

# ---- Mapper ----
cat > app/src/main/java/com/scorelive/app/data/mapper/TableMapper.kt << 'EOF'
package com.scorelive.app.data.mapper

import com.scorelive.app.data.api.TableDto
import com.scorelive.app.data.api.TableResponseDto
import com.scorelive.app.domain.model.StandingRow

private fun TableDto.collectTeams(): List<StandingRow> {
    val direct = teams.orEmpty().mapNotNull { it.toStandingRow() }
    val fromNested = nested.orEmpty().flatMap { it.collectTeams() }
    return direct + fromNested
}

private fun com.scorelive.app.data.api.TableTeamDto.toStandingRow(): StandingRow? {
    val name = teamName ?: return null
    return StandingRow(
        rank = rank ?: 0,
        teamId = teamId ?: "",
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
    stages.orEmpty()
        .flatMap { stage ->
            stage.leagueTable?.tables.orEmpty().flatMap { group ->
                group.tables.orEmpty().flatMap { it.collectTeams() }
            }
        }
        .sortedBy { if (it.rank == 0) Int.MAX_VALUE else it.rank }
EOF

# ---- Repository sozlesmesi ----
cat > app/src/main/java/com/scorelive/app/domain/repository/SportsRepository.kt << 'EOF'
package com.scorelive.app.domain.repository

import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.model.StandingRow
import java.time.LocalDate

interface SportsRepository {
    suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>>
    suspend fun getLiveMatches(sport: Sport): Result<List<Match>>
    suspend fun getMatchDetails(matchId: String): Result<Match>
    suspend fun search(query: String, sport: Sport): Result<List<Match>>
    suspend fun getStandings(matchId: String, sport: Sport): Result<List<StandingRow>>
}
EOF

# ---- Remote repo: getStandings ekle ----
python3 - << 'PYEOF'
p = "app/src/main/java/com/scorelive/app/data/repository/RemoteSportsRepositoryImpl.kt"
s = open(p).read()

s = s.replace(
    "import com.scorelive.app.data.mapper.toMatches",
    "import com.scorelive.app.data.mapper.toMatches\nimport com.scorelive.app.data.mapper.toStandings"
)
s = s.replace(
    "import com.scorelive.app.domain.model.Sport",
    "import com.scorelive.app.domain.model.Sport\nimport com.scorelive.app.domain.model.StandingRow"
)

addition = '''
    override suspend fun getStandings(matchId: String, sport: Sport): Result<List<StandingRow>> {
        val category = categoryFor(sport) ?: return Result.success(emptyList())
        return try {
            val response = api.getTable(category = category, eventId = matchId)
            Result.success(response.toStandings())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
'''
idx = s.rfind("}")
s = s[:idx] + addition + s[idx:]
open(p, "w").write(s)
print("Remote repo guncellendi")
PYEOF

# ---- Mock repo: getStandings ----
python3 - << 'PYEOF'
p = "app/src/main/java/com/scorelive/app/data/repository/MockSportsRepositoryImpl.kt"
s = open(p).read()
if "getStandings" not in s:
    s = s.replace(
        "import com.scorelive.app.domain.model.Sport",
        "import com.scorelive.app.domain.model.Sport\nimport com.scorelive.app.domain.model.StandingRow"
    )
    addition = '''
    override suspend fun getStandings(matchId: String, sport: Sport): Result<List<StandingRow>> =
        Result.success(emptyList())
'''
    idx = s.rfind("}")
    s = s[:idx] + addition + s[idx:]
    open(p, "w").write(s)
    print("Mock repo guncellendi")
PYEOF

# ---- MatchDetailViewModel: puan durumunu yukle ----
cat > app/src/main/java/com/scorelive/app/presentation/matchdetail/MatchDetailViewModel.kt << 'EOF'
package com.scorelive.app.presentation.matchdetail

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.StandingRow
import com.scorelive.app.domain.repository.SportsRepository
import com.scorelive.app.navigation.MatchDetailRoutes
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MatchDetailUiState(
    val match: Match? = null,
    val standings: List<StandingRow> = emptyList(),
    val isLoading: Boolean = true,
    val isLoadingStandings: Boolean = false,
    val standingsLoaded: Boolean = false,
    val errorMessage: String? = null,
    val standingsError: String? = null,
)

@HiltViewModel
class MatchDetailViewModel @Inject constructor(
    private val sportsRepository: SportsRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val matchId: String = checkNotNull(savedStateHandle[MatchDetailRoutes.ARG_MATCH_ID])

    private val _uiState = MutableStateFlow(MatchDetailUiState())
    val uiState: StateFlow<MatchDetailUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            sportsRepository.getMatchDetails(matchId)
                .onSuccess { match ->
                    _uiState.value = _uiState.value.copy(match = match, isLoading = false)
                }
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        errorMessage = error.message ?: "Veriler yuklenemedi.",
                    )
                }
        }
    }

    /** Standings cost a request, so they are only fetched when the tab opens. */
    fun loadStandingsIfNeeded() {
        val state = _uiState.value
        val match = state.match ?: return
        if (state.standingsLoaded || state.isLoadingStandings) return

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingStandings = true, standingsError = null)
            sportsRepository.getStandings(matchId, match.sport)
                .onSuccess { rows ->
                    _uiState.value = _uiState.value.copy(
                        standings = rows,
                        isLoadingStandings = false,
                        standingsLoaded = true,
                    )
                }
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoadingStandings = false,
                        standingsLoaded = true,
                        standingsError = error.message ?: "Puan durumu yuklenemedi.",
                    )
                }
        }
    }
}
EOF

# ---- Puan durumu tablosu bileseni ----
cat > app/src/main/java/com/scorelive/app/ui/components/StandingsTable.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.scorelive.app.domain.model.StandingRow

@Composable
fun StandingsTable(rows: List<StandingRow>, modifier: Modifier = Modifier) {
    LazyColumn(modifier = modifier.fillMaxSize()) {
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 8.dp),
            ) {
                Cell("#", width = 24, bold = true)
                Cell("Takim", weightCell = true, bold = true)
                Cell("O", width = 26, bold = true)
                Cell("G", width = 26, bold = true)
                Cell("B", width = 26, bold = true)
                Cell("M", width = 26, bold = true)
                Cell("AV", width = 32, bold = true)
                Cell("P", width = 30, bold = true)
            }
            HorizontalDivider()
        }
        items(rows, key = { it.teamId + it.rank }) { row ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 6.dp),
            ) {
                Cell(row.rank.toString(), width = 24)
                Cell(row.teamName, weightCell = true)
                Cell(row.played.toString(), width = 26)
                Cell(row.won.toString(), width = 26)
                Cell(row.drawn.toString(), width = 26)
                Cell(row.lost.toString(), width = 26)
                Cell(row.goalDifference.toString(), width = 32)
                Cell(row.points.toString(), width = 30, bold = true)
            }
        }
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.Cell(
    text: String,
    width: Int? = null,
    weightCell: Boolean = false,
    bold: Boolean = false,
) {
    val modifier = when {
        weightCell -> Modifier.weight(1f)
        width != null -> Modifier.width(width.dp)
        else -> Modifier
    }
    Text(
        text = text,
        modifier = modifier,
        style = MaterialTheme.typography.bodySmall,
        fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        textAlign = if (weightCell) TextAlign.Start else TextAlign.Center,
    )
}
EOF

# ---- MatchDetailScreen: Puan Durumu sekmesini bagla ----
python3 - << 'PYEOF'
p = "app/src/main/java/com/scorelive/app/presentation/matchdetail/MatchDetailScreen.kt"
s = open(p).read()

s = s.replace(
    "import com.scorelive.app.ui.components.ScoreDisplay",
    "import com.scorelive.app.ui.components.ScoreDisplay\nimport com.scorelive.app.ui.components.StandingsTable"
)

# icerik fonksiyonuna uiState'i gecir
s = s.replace(
    "            else -> MatchDetailContent(match)",
    "            else -> MatchDetailContent(\n                match = match,\n                uiState = uiState,\n                onStandingsTabOpened = viewModel::loadStandingsIfNeeded,\n            )"
)
s = s.replace(
    "private fun MatchDetailContent(match: Match) {",
    "private fun MatchDetailContent(\n    match: Match,\n    uiState: MatchDetailUiState,\n    onStandingsTabOpened: () -> Unit,\n) {"
)

# Puan Durumu sekmesi icerigi
s = s.replace(
    '            4 -> EmptyView(message = "Puan durumu Asama 11\'de eklenecek.", modifier = Modifier.fillMaxSize())',
    '''            4 -> {
                LaunchedEffect(Unit) { onStandingsTabOpened() }
                when {
                    uiState.isLoadingStandings -> LoadingView(modifier = Modifier.fillMaxSize())
                    uiState.standingsError != null -> EmptyView(
                        message = uiState.standingsError ?: "Puan durumu yuklenemedi.",
                        modifier = Modifier.fillMaxSize(),
                    )
                    uiState.standings.isEmpty() -> EmptyView(
                        message = "Bu mac icin puan durumu bulunamadi.",
                        modifier = Modifier.fillMaxSize(),
                    )
                    else -> StandingsTable(rows = uiState.standings)
                }
            }'''
)

s = s.replace(
    "import androidx.compose.runtime.collectAsState",
    "import androidx.compose.runtime.LaunchedEffect\nimport androidx.compose.runtime.collectAsState"
)

open(p, "w").write(s)
print("MatchDetailScreen guncellendi")
PYEOF

git add .
git commit -m "Stage 10: league standings on match detail"
git push
echo "TAMAMLANDI"
