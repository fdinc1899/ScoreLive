set -e
cd ~/ScoreLive

# temizlik: yanlislikla eklenen script dosyalarini repodan cikar
git rm --cached stage3_setup.sh 2>/dev/null || true
rm -f stage3_setup.sh stage2_setup.sh

mkdir -p app/src/main/java/com/scorelive/app/presentation/matchdetail

cat > app/src/main/java/com/scorelive/app/domain/repository/SportsRepository.kt << 'EOF'
package com.scorelive.app.domain.repository

import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import java.time.LocalDate

interface SportsRepository {
    suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>>
    suspend fun getMatchDetails(matchId: String): Result<Match>
}
EOF

cat > app/src/main/java/com/scorelive/app/data/repository/MockSportsRepositoryImpl.kt << 'EOF'
package com.scorelive.app.data.repository

import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.model.Team
import com.scorelive.app.domain.repository.SportsRepository
import java.time.LocalDate
import javax.inject.Inject

/**
 * Development-only repository returning static data so the UI is fully
 * navigable before Stage 6 wires up the real Sports API. UI copy never
 * implies this is live data.
 */
class MockSportsRepositoryImpl @Inject constructor() : SportsRepository {

    private val superLig = League("tr-superlig", "Trendyol Super Lig", "Turkiye", "\ud83c\uddf9\ud83c\uddf7")
    private val premierLeague = League("en-premier", "Premier League", "Ingiltere", "\ud83c\udff4")

    private fun team(id: String, name: String, shortName: String) = Team(id, name, shortName)

    private val basaksehir = team("t1", "Basaksehir", "BSK")
    private val galatasaray = team("t2", "Galatasaray", "GS")
    private val fenerbahce = team("t3", "Fenerbahce", "FB")
    private val trabzonspor = team("t4", "Trabzonspor", "TS")
    private val besiktas = team("t5", "Besiktas", "BJK")
    private val antalyaspor = team("t6", "Antalyaspor", "ANT")
    private val manCity = team("t7", "Manchester City", "MCI")
    private val liverpool = team("t8", "Liverpool", "LIV")
    private val arsenal = team("t9", "Arsenal", "ARS")
    private val chelsea = team("t10", "Chelsea", "CHE")

    private fun buildMockMatches(): List<Match> {
        val today = LocalDate.now()
        return listOf(
            Match(
                id = "m1",
                league = superLig,
                homeTeam = basaksehir,
                awayTeam = galatasaray,
                homeScore = 1,
                awayScore = 2,
                status = MatchStatus.LIVE,
                kickoff = today.atTime(19, 0),
                liveMinute = "67'",
            ),
            Match(
                id = "m2",
                league = superLig,
                homeTeam = fenerbahce,
                awayTeam = trabzonspor,
                homeScore = null,
                awayScore = null,
                status = MatchStatus.NOT_STARTED,
                kickoff = today.atTime(20, 0),
            ),
            Match(
                id = "m3",
                league = superLig,
                homeTeam = besiktas,
                awayTeam = antalyaspor,
                homeScore = 3,
                awayScore = 1,
                status = MatchStatus.FINISHED,
                kickoff = today.atTime(17, 0),
            ),
            Match(
                id = "m4",
                league = premierLeague,
                homeTeam = manCity,
                awayTeam = liverpool,
                homeScore = 0,
                awayScore = 0,
                status = MatchStatus.LIVE,
                kickoff = today.atTime(19, 30),
                liveMinute = "34'",
            ),
            Match(
                id = "m5",
                league = premierLeague,
                homeTeam = arsenal,
                awayTeam = chelsea,
                homeScore = null,
                awayScore = null,
                status = MatchStatus.NOT_STARTED,
                kickoff = today.atTime(22, 0),
            ),
        )
    }

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        if (sport != Sport.FOOTBALL || date != LocalDate.now()) {
            return Result.success(emptyList())
        }
        return Result.success(buildMockMatches())
    }

    override suspend fun getMatchDetails(matchId: String): Result<Match> {
        val match = buildMockMatches().find { it.id == matchId }
        return if (match != null) {
            Result.success(match)
        } else {
            Result.failure(NoSuchElementException("Mac bulunamadi."))
        }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/navigation/Destination.kt << 'EOF'
package com.scorelive.app.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FiberManualRecord
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.ui.graphics.vector.ImageVector

sealed class Destination(val route: String, val label: String, val icon: ImageVector) {
    data object Home : Destination("home", "Ana Sayfa", Icons.Filled.Home)
    data object Live : Destination("live", "Canli", Icons.Filled.FiberManualRecord)
    data object Favorites : Destination("favorites", "Favoriler", Icons.Filled.Star)
    data object Search : Destination("search", "Ara", Icons.Filled.Search)
    data object Settings : Destination("settings", "Ayarlar", Icons.Filled.Settings)

    companion object {
        val bottomNavItems = listOf(Home, Live, Favorites, Search, Settings)
    }
}

object MatchDetailRoutes {
    const val ARG_MATCH_ID = "matchId"
    const val ROUTE_PATTERN = "match_detail/{$ARG_MATCH_ID}"
    fun route(matchId: String) = "match_detail/$matchId"
}
EOF

cat > app/src/main/java/com/scorelive/app/navigation/ScoreLiveNavHost.kt << 'EOF'
package com.scorelive.app.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.scorelive.app.presentation.favorites.FavoritesScreen
import com.scorelive.app.presentation.home.HomeScreen
import com.scorelive.app.presentation.live.LiveScreen
import com.scorelive.app.presentation.matchdetail.MatchDetailScreen
import com.scorelive.app.presentation.search.SearchScreen
import com.scorelive.app.presentation.settings.SettingsScreen

@Composable
fun ScoreLiveNavHost(navController: NavHostController) {
    NavHost(navController = navController, startDestination = Destination.Home.route) {
        composable(Destination.Home.route) {
            HomeScreen(onMatchClick = { matchId ->
                navController.navigate(MatchDetailRoutes.route(matchId))
            })
        }
        composable(Destination.Live.route) { LiveScreen() }
        composable(Destination.Favorites.route) { FavoritesScreen() }
        composable(Destination.Search.route) { SearchScreen() }
        composable(Destination.Settings.route) { SettingsScreen() }
        composable(
            route = MatchDetailRoutes.ROUTE_PATTERN,
            arguments = listOf(navArgument(MatchDetailRoutes.ARG_MATCH_ID) { type = NavType.StringType }),
        ) {
            MatchDetailScreen(onBack = { navController.popBackStack() })
        }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/presentation/home/HomeScreen.kt << 'EOF'
package com.scorelive.app.presentation.home

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SportsScore
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.scorelive.app.core.config.AppConfig
import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.ui.components.DateSelector
import com.scorelive.app.ui.components.EmptyView
import com.scorelive.app.ui.components.LeagueHeader
import com.scorelive.app.ui.components.LoadingView
import com.scorelive.app.ui.components.MatchCard
import com.scorelive.app.ui.components.SportSelector

@Composable
fun HomeScreen(
    onMatchClick: (String) -> Unit = {},
    viewModel: HomeViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.SportsScore, contentDescription = null)
            Text(
                text = AppConfig.APP_NAME,
                modifier = Modifier
                    .padding(start = 8.dp)
                    .weight(1f),
                style = MaterialTheme.typography.headlineSmall,
            )
            IconButton(onClick = { }) {
                Icon(Icons.Filled.Search, contentDescription = "Ara")
            }
            IconButton(onClick = { }) {
                Icon(Icons.Filled.Notifications, contentDescription = "Bildirimler")
            }
        }

        SportSelector(
            selectedSport = uiState.selectedSport,
            onSportSelected = viewModel::onSportSelected,
        )

        Spacer(modifier = Modifier.height(8.dp))

        DateSelector(
            selectedDate = uiState.selectedDate,
            onDateSelected = viewModel::onDateSelected,
            onCalendarClick = { },
        )

        Spacer(modifier = Modifier.height(8.dp))

        when {
            uiState.isLoading -> LoadingView(modifier = Modifier.fillMaxSize())
            uiState.errorMessage != null -> EmptyView(message = uiState.errorMessage ?: "Veriler yuklenemedi.")
            uiState.matches.isEmpty() -> EmptyView(message = "Bu tarihte mac bulunamadi.")
            else -> {
                val grouped: Map<League, List<Match>> = uiState.matches.groupBy { it.league }
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    grouped.forEach { (league, matches) ->
                        item {
                            LeagueHeader(
                                countryFlagEmoji = league.countryFlagEmoji,
                                countryName = league.country,
                                leagueName = league.name,
                            )
                        }
                        items(matches, key = { it.id }) { match ->
                            MatchCard(
                                match = match,
                                onClick = { onMatchClick(match.id) },
                                onFavoriteToggle = { },
                            )
                        }
                    }
                }
            }
        }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/presentation/matchdetail/MatchDetailViewModel.kt << 'EOF'
package com.scorelive.app.presentation.matchdetail

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.scorelive.app.domain.model.Match
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
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
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
}
EOF

cat > app/src/main/java/com/scorelive/app/presentation/matchdetail/MatchDetailScreen.kt << 'EOF'
package com.scorelive.app.presentation.matchdetail

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.ui.components.EmptyView
import com.scorelive.app.ui.components.LoadingView
import com.scorelive.app.ui.components.ScoreDisplay
import com.scorelive.app.ui.components.TeamLogo
import java.time.format.DateTimeFormatter

private val detailTabs = listOf("Ozet", "Canli", "Istatistik", "Kadro", "Puan Durumu")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MatchDetailScreen(
    onBack: () -> Unit,
    viewModel: MatchDetailViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("Mac Detayi") },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(Icons.Filled.ArrowBack, contentDescription = "Geri")
                }
            },
        )

        val match = uiState.match
        when {
            uiState.isLoading -> LoadingView(modifier = Modifier.fillMaxSize())
            match == null -> EmptyView(message = uiState.errorMessage ?: "Mac bulunamadi.")
            else -> MatchDetailContent(match)
        }
    }
}

@Composable
private fun MatchDetailContent(match: Match) {
    var selectedTab by remember { mutableIntStateOf(0) }
    val timeFormatter = DateTimeFormatter.ofPattern("HH:mm")
    val isLive = match.status == MatchStatus.LIVE || match.status == MatchStatus.HALF_TIME

    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    TeamLogo(match.homeTeam.shortName, sizeDp = 56.dp)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(match.homeTeam.name, style = MaterialTheme.typography.bodyMedium)
                }

                ScoreDisplay(match.homeScore, match.awayScore)

                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    TeamLogo(match.awayTeam.shortName, sizeDp = 56.dp)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(match.awayTeam.name, style = MaterialTheme.typography.bodyMedium)
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = if (isLive) {
                    "\ud83d\udd34 " + (match.liveMinute ?: "CANLI")
                } else {
                    statusLabel(match.status) + " - " + timeFormatter.format(match.kickoff)
                },
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = if (isLive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }

        TabRow(selectedTabIndex = selectedTab) {
            detailTabs.forEachIndexed { index, title ->
                Tab(
                    selected = selectedTab == index,
                    onClick = { selectedTab = index },
                    text = { Text(title) },
                )
            }
        }

        when (selectedTab) {
            0 -> EmptyView(message = "Bu mac icin ozet bilgisi henuz eklenmedi.", modifier = Modifier.fillMaxSize())
            1 -> EmptyView(message = "Canli olaylar Asama 8'de eklenecek.", modifier = Modifier.fillMaxSize())
            2 -> EmptyView(message = "Istatistikler Asama 9'da eklenecek.", modifier = Modifier.fillMaxSize())
            3 -> EmptyView(message = "Kadro bilgisi Asama 12-13'te eklenecek.", modifier = Modifier.fillMaxSize())
            4 -> EmptyView(message = "Puan durumu Asama 11'de eklenecek.", modifier = Modifier.fillMaxSize())
        }
    }
}

private fun statusLabel(status: MatchStatus): String = when (status) {
    MatchStatus.NOT_STARTED -> "Baslamadi"
    MatchStatus.LIVE -> "Canli"
    MatchStatus.HALF_TIME -> "Devre Arasi"
    MatchStatus.FINISHED -> "Mac Sonucu"
    MatchStatus.POSTPONED -> "Ertelendi"
    MatchStatus.CANCELLED -> "Iptal Edildi"
    MatchStatus.SUSPENDED -> "Tatil Edildi"
}
EOF

git add .
git commit -m "Stage 4: match detail screen with tabs, navigation wiring"
git push
echo "TAMAMLANDI"
