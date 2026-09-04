set -e
cd ~/ScoreLive

mkdir -p app/src/main/java/com/scorelive/app/data/preferences

# ---- Repository sozlesmesine canli maclar + arama ekle ----
cat > app/src/main/java/com/scorelive/app/domain/repository/SportsRepository.kt << 'EOF'
package com.scorelive.app.domain.repository

import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import java.time.LocalDate

interface SportsRepository {
    suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>>
    suspend fun getLiveMatches(sport: Sport): Result<List<Match>>
    suspend fun getMatchDetails(matchId: String): Result<Match>
    suspend fun search(query: String, sport: Sport): Result<List<Match>>
}
EOF

# ---- API: canli maclar endpoint'i ----
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
}
EOF

# ---- Repository implementasyonu ----
cat > app/src/main/java/com/scorelive/app/data/repository/RemoteSportsRepositoryImpl.kt << 'EOF'
package com.scorelive.app.data.repository

import com.scorelive.app.data.api.SportsApi
import com.scorelive.app.data.database.MatchDao
import com.scorelive.app.data.database.toDomain
import com.scorelive.app.data.database.toEntity
import com.scorelive.app.data.mapper.toMatches
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.repository.SportsRepository
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit
import javax.inject.Inject

private val apiDateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyyMMdd")

/** Cached scores older than this are shown, but never presented as live. */
private val LIVE_FRESHNESS_WINDOW_MILLIS = TimeUnit.MINUTES.toMillis(2)

/** Rows older than this are pruned on each successful refresh. */
private val CACHE_RETENTION_MILLIS = TimeUnit.DAYS.toMillis(3)

class RemoteSportsRepositoryImpl @Inject constructor(
    private val api: SportsApi,
    private val matchDao: MatchDao,
) : SportsRepository {

    private fun categoryFor(sport: Sport): String? = when (sport) {
        Sport.FOOTBALL -> "soccer"
        Sport.BASKETBALL -> "basketball"
        Sport.TENNIS -> "tennis"
        Sport.VOLLEYBALL -> null
        Sport.MOTORSPORT -> null
    }

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        val category = categoryFor(sport) ?: return Result.success(emptyList())
        val queryDate = apiDateFormatter.format(date)

        return try {
            val response = api.getMatchesByDate(category = category, date = queryDate)
            val matches = response.stages.orEmpty().flatMap { it.toMatches(sport) }

            val now = System.currentTimeMillis()
            matchDao.replaceAll(
                sport = sport.name,
                queryDate = queryDate,
                matches = matches.map { it.toEntity(queryDate, now) },
            )
            matchDao.deleteOlderThan(now - CACHE_RETENTION_MILLIS)

            Result.success(matches)
        } catch (networkError: Exception) {
            // Offline or API failure: fall back to whatever was cached last.
            val cached = matchDao.getMatches(sport.name, queryDate)
            if (cached.isEmpty()) {
                Result.failure(networkError)
            } else {
                val now = System.currentTimeMillis()
                Result.success(
                    cached.map { entity ->
                        val isStale = now - entity.cachedAtEpochMillis > LIVE_FRESHNESS_WINDOW_MILLIS
                        entity.toDomain(treatLiveAsStale = isStale)
                    }
                )
            }
        }
    }

    override suspend fun getLiveMatches(sport: Sport): Result<List<Match>> {
        val category = categoryFor(sport) ?: return Result.success(emptyList())
        return try {
            val response = api.getLiveMatches(category = category)
            Result.success(response.stages.orEmpty().flatMap { it.toMatches(sport) })
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getMatchDetails(matchId: String): Result<Match> {
        val cached = matchDao.getMatchById(matchId)
        return if (cached != null) {
            val isStale = System.currentTimeMillis() - cached.cachedAtEpochMillis > LIVE_FRESHNESS_WINDOW_MILLIS
            Result.success(cached.toDomain(treatLiveAsStale = isStale))
        } else {
            Result.failure(NoSuchElementException("Mac bulunamadi."))
        }
    }

    /**
     * The provider has no free-text search endpoint on this plan, so search
     * filters today's fixtures locally. This costs one request and keeps the
     * behaviour predictable within the 500/month budget.
     */
    override suspend fun search(query: String, sport: Sport): Result<List<Match>> {
        if (query.isBlank()) return Result.success(emptyList())
        return getMatches(sport, LocalDate.now()).map { matches ->
            val needle = query.trim().lowercase()
            matches.filter { match ->
                match.homeTeam.name.lowercase().contains(needle) ||
                    match.awayTeam.name.lowercase().contains(needle) ||
                    match.league.name.lowercase().contains(needle) ||
                    match.league.country.lowercase().contains(needle)
            }
        }
    }
}
EOF

# ---- Mock repo'yu yeni sozlesmeye uydur ----
python3 - << 'PYEOF'
p = "app/src/main/java/com/scorelive/app/data/repository/MockSportsRepositoryImpl.kt"
s = open(p).read()
if "getLiveMatches" not in s:
    addition = '''
    override suspend fun getLiveMatches(sport: Sport): Result<List<Match>> {
        val live = buildAllMatches().filter {
            it.sport == sport && it.status == MatchStatus.LIVE
        }
        return Result.success(live)
    }

    override suspend fun search(query: String, sport: Sport): Result<List<Match>> {
        if (query.isBlank()) return Result.success(emptyList())
        val needle = query.trim().lowercase()
        return Result.success(
            buildAllMatches().filter { match ->
                match.sport == sport && (
                    match.homeTeam.name.lowercase().contains(needle) ||
                        match.awayTeam.name.lowercase().contains(needle) ||
                        match.league.name.lowercase().contains(needle)
                    )
            }
        )
    }
'''
    idx = s.rfind("}")
    s = s[:idx] + addition + s[idx:]
    open(p, "w").write(s)
    print("Mock repo guncellendi")
PYEOF

# ---- Canli sayfasi ----
cat > app/src/main/java/com/scorelive/app/presentation/live/LiveViewModel.kt << 'EOF'
package com.scorelive.app.presentation.live

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.scorelive.app.domain.model.Favorite
import com.scorelive.app.domain.model.FavoriteType
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.repository.FavoritesRepository
import com.scorelive.app.domain.repository.SportsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LiveUiState(
    val selectedSport: Sport = Sport.FOOTBALL,
    val matches: List<Match> = emptyList(),
    val favoriteMatchIds: Set<String> = emptySet(),
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
)

@HiltViewModel
class LiveViewModel @Inject constructor(
    private val sportsRepository: SportsRepository,
    private val favoritesRepository: FavoritesRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(LiveUiState())
    val uiState: StateFlow<LiveUiState> = _uiState.asStateFlow()

    init {
        load()
        viewModelScope.launch {
            favoritesRepository.observeFavoriteIds(FavoriteType.MATCH).collect { ids ->
                _uiState.value = _uiState.value.copy(favoriteMatchIds = ids)
            }
        }
    }

    fun onSportSelected(sport: Sport) {
        _uiState.value = _uiState.value.copy(selectedSport = sport)
        load()
    }

    fun onFavoriteToggle(match: Match) {
        viewModelScope.launch {
            favoritesRepository.toggle(
                Favorite(
                    type = FavoriteType.MATCH,
                    targetId = match.id,
                    label = match.homeTeam.name + " - " + match.awayTeam.name,
                )
            )
        }
    }

    fun refresh() = load()

    private fun load() {
        val sport = _uiState.value.selectedSport
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            sportsRepository.getLiveMatches(sport)
                .onSuccess { matches ->
                    _uiState.value = _uiState.value.copy(matches = matches, isLoading = false)
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

cat > app/src/main/java/com/scorelive/app/presentation/live/LiveScreen.kt << 'EOF'
package com.scorelive.app.presentation.live

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.ui.components.EmptyView
import com.scorelive.app.ui.components.ErrorView
import com.scorelive.app.ui.components.LeagueHeader
import com.scorelive.app.ui.components.LoadingView
import com.scorelive.app.ui.components.MatchCard
import com.scorelive.app.ui.components.SportSelector

@Composable
fun LiveScreen(
    onMatchClick: (String) -> Unit = {},
    viewModel: LiveViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        Text(
            text = "\uD83D\uDD34 Canli Maclar",
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier.padding(16.dp),
        )

        SportSelector(
            selectedSport = uiState.selectedSport,
            onSportSelected = viewModel::onSportSelected,
        )

        Spacer(modifier = Modifier.height(8.dp))

        when {
            uiState.isLoading -> LoadingView(modifier = Modifier.fillMaxSize())
            uiState.errorMessage != null -> ErrorView(
                message = uiState.errorMessage ?: "Veriler yuklenemedi.",
                onRetry = viewModel::refresh,
            )
            uiState.matches.isEmpty() -> EmptyView(
                message = "Su anda devam eden mac yok.",
                modifier = Modifier.fillMaxSize(),
            )
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
                                match = match.copy(isFavorite = match.id in uiState.favoriteMatchIds),
                                onClick = { onMatchClick(match.id) },
                                onFavoriteToggle = { viewModel.onFavoriteToggle(match) },
                            )
                        }
                    }
                }
            }
        }
    }
}
EOF

# ---- Arama ekrani ----
cat > app/src/main/java/com/scorelive/app/presentation/search/SearchViewModel.kt << 'EOF'
package com.scorelive.app.presentation.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.repository.SportsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SearchUiState(
    val query: String = "",
    val results: List<Match> = emptyList(),
    val isLoading: Boolean = false,
    val hasSearched: Boolean = false,
    val errorMessage: String? = null,
)

@HiltViewModel
class SearchViewModel @Inject constructor(
    private val sportsRepository: SportsRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null

    fun onQueryChanged(query: String) {
        _uiState.value = _uiState.value.copy(query = query)
        searchJob?.cancel()
        if (query.isBlank()) {
            _uiState.value = _uiState.value.copy(results = emptyList(), hasSearched = false)
            return
        }
        // Debounce so typing doesn't burn through the monthly request budget.
        searchJob = viewModelScope.launch {
            delay(500)
            runSearch(query)
        }
    }

    private suspend fun runSearch(query: String) {
        _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
        sportsRepository.search(query, Sport.FOOTBALL)
            .onSuccess { results ->
                _uiState.value = _uiState.value.copy(
                    results = results,
                    isLoading = false,
                    hasSearched = true,
                )
            }
            .onFailure { error ->
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    hasSearched = true,
                    errorMessage = error.message ?: "Arama yapilamadi.",
                )
            }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/presentation/search/SearchScreen.kt << 'EOF'
package com.scorelive.app.presentation.search

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.scorelive.app.ui.components.EmptyView
import com.scorelive.app.ui.components.LoadingView
import com.scorelive.app.ui.components.MatchCard

@Composable
fun SearchScreen(
    onMatchClick: (String) -> Unit = {},
    viewModel: SearchViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        OutlinedTextField(
            value = uiState.query,
            onValueChange = viewModel::onQueryChanged,
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            label = { Text("Takim, lig veya ulke ara") },
            leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
            singleLine = true,
        )

        when {
            uiState.isLoading -> LoadingView(modifier = Modifier.fillMaxSize())
            uiState.errorMessage != null -> EmptyView(
                message = uiState.errorMessage ?: "Arama yapilamadi.",
                modifier = Modifier.fillMaxSize(),
            )
            !uiState.hasSearched -> EmptyView(
                message = "Bugunun maclari icinde takim, lig veya ulke arayin.",
                modifier = Modifier.fillMaxSize(),
            )
            uiState.results.isEmpty() -> EmptyView(
                message = "Sonuc bulunamadi.",
                modifier = Modifier.fillMaxSize(),
            )
            else -> LazyColumn(modifier = Modifier.fillMaxSize()) {
                item {
                    Text(
                        text = "MACLAR",
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    )
                }
                items(uiState.results, key = { it.id }) { match ->
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
EOF

# ---- Tema tercihi: DataStore ----
cat > app/src/main/java/com/scorelive/app/data/preferences/SettingsDataStore.kt << 'EOF'
package com.scorelive.app.data.preferences

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.scorelive.app.ui.theme.ThemeMode
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore by preferencesDataStore(name = "scorelive_settings")
private val THEME_MODE_KEY = stringPreferencesKey("theme_mode")

@Singleton
class SettingsDataStore @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    val themeMode: Flow<ThemeMode> = context.dataStore.data.map { prefs ->
        runCatching { ThemeMode.valueOf(prefs[THEME_MODE_KEY] ?: ThemeMode.SYSTEM.name) }
            .getOrDefault(ThemeMode.SYSTEM)
    }

    suspend fun setThemeMode(mode: ThemeMode) {
        context.dataStore.edit { prefs -> prefs[THEME_MODE_KEY] = mode.name }
    }
}
EOF

# ---- Ayarlar ekrani ----
cat > app/src/main/java/com/scorelive/app/presentation/settings/SettingsViewModel.kt << 'EOF'
package com.scorelive.app.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.scorelive.app.data.preferences.SettingsDataStore
import com.scorelive.app.ui.theme.ThemeMode
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore,
) : ViewModel() {

    private val _themeMode = MutableStateFlow(ThemeMode.SYSTEM)
    val themeMode: StateFlow<ThemeMode> = _themeMode.asStateFlow()

    init {
        viewModelScope.launch {
            settingsDataStore.themeMode.collect { _themeMode.value = it }
        }
    }

    fun onThemeSelected(mode: ThemeMode) {
        viewModelScope.launch { settingsDataStore.setThemeMode(mode) }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/presentation/settings/SettingsScreen.kt << 'EOF'
package com.scorelive.app.presentation.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.scorelive.app.core.config.AppConfig
import com.scorelive.app.ui.theme.ThemeMode

@Composable
fun SettingsScreen(viewModel: SettingsViewModel = hiltViewModel()) {
    val themeMode by viewModel.themeMode.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
    ) {
        SectionTitle("Tema")
        ThemeMode.entries.forEach { mode ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { viewModel.onThemeSelected(mode) }
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                RadioButton(selected = themeMode == mode, onClick = { viewModel.onThemeSelected(mode) })
                Text(text = themeLabel(mode), style = MaterialTheme.typography.bodyLarge)
            }
        }

        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

        SectionTitle("Hakkinda")
        InfoRow(AppConfig.APP_NAME, AppConfig.APP_TAGLINE)
        InfoRow("Surum", "0.1.0")
        InfoRow("Veri kaynagi", "LiveScore API")

        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

        SectionTitle("Bildirimler")
        Text(
            text = "Bildirim ayarlari sonraki asamada eklenecek.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
        )
    }
}

@Composable
private fun SectionTitle(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleMedium,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
    )
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
    ) {
        Text(text = label, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private fun themeLabel(mode: ThemeMode): String = when (mode) {
    ThemeMode.SYSTEM -> "Sistem"
    ThemeMode.LIGHT -> "Acik"
    ThemeMode.DARK -> "Koyu"
}
EOF

# ---- MainActivity: temayi DataStore'dan oku ----
cat > app/src/main/java/com/scorelive/app/MainActivity.kt << 'EOF'
package com.scorelive.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.rememberNavController
import com.scorelive.app.navigation.ScoreLiveNavHost
import com.scorelive.app.presentation.settings.SettingsViewModel
import com.scorelive.app.ui.components.BottomNavigationBar
import com.scorelive.app.ui.theme.ScoreLiveTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ScoreLiveApp()
        }
    }
}

@Composable
private fun ScoreLiveApp(settingsViewModel: SettingsViewModel = hiltViewModel()) {
    val themeMode by settingsViewModel.themeMode.collectAsState()

    ScoreLiveTheme(themeMode = themeMode) {
        val navController = rememberNavController()
        Surface {
            Scaffold(
                bottomBar = { BottomNavigationBar(navController) },
            ) { innerPadding ->
                Box(modifier = Modifier.padding(innerPadding)) {
                    ScoreLiveNavHost(navController)
                }
            }
        }
    }
}
EOF

# ---- NavHost: yeni ekran parametrelerini bagla ----
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
    val openMatch: (String) -> Unit = { matchId ->
        navController.navigate(MatchDetailRoutes.route(matchId))
    }

    NavHost(navController = navController, startDestination = Destination.Home.route) {
        composable(Destination.Home.route) { HomeScreen(onMatchClick = openMatch) }
        composable(Destination.Live.route) { LiveScreen(onMatchClick = openMatch) }
        composable(Destination.Favorites.route) { FavoritesScreen() }
        composable(Destination.Search.route) { SearchScreen(onMatchClick = openMatch) }
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

git add .
git commit -m "Stage 9: live screen, search, settings with persisted theme"
git push
echo "TAMAMLANDI"
