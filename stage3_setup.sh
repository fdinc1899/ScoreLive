set -e
cd ~/ScoreLive

mkdir -p app/src/main/java/com/scorelive/app/domain/model
mkdir -p app/src/main/java/com/scorelive/app/domain/repository
mkdir -p app/src/main/java/com/scorelive/app/data/repository
mkdir -p app/src/main/java/com/scorelive/app/di

cat > app/src/main/java/com/scorelive/app/domain/model/Sport.kt << 'EOF'
package com.scorelive.app.domain.model

enum class Sport(val emoji: String, val label: String) {
    FOOTBALL("\u26bd", "Futbol"),
    BASKETBALL("\ud83c\udfc0", "Basketbol"),
    TENNIS("\ud83c\udfbe", "Tenis"),
    VOLLEYBALL("\ud83c\udfd0", "Voleybol"),
    MOTORSPORT("\ud83c\udfce", "Motor Sporlari"),
}
EOF

cat > app/src/main/java/com/scorelive/app/domain/model/MatchStatus.kt << 'EOF'
package com.scorelive.app.domain.model

enum class MatchStatus {
    NOT_STARTED,
    LIVE,
    HALF_TIME,
    FINISHED,
    POSTPONED,
    CANCELLED,
    SUSPENDED,
}
EOF

cat > app/src/main/java/com/scorelive/app/domain/model/Team.kt << 'EOF'
package com.scorelive.app.domain.model

data class Team(
    val id: String,
    val name: String,
    val shortName: String,
    val logoUrl: String? = null,
)
EOF

cat > app/src/main/java/com/scorelive/app/domain/model/League.kt << 'EOF'
package com.scorelive.app.domain.model

data class League(
    val id: String,
    val name: String,
    val country: String,
    val countryFlagEmoji: String,
    val logoUrl: String? = null,
)
EOF

cat > app/src/main/java/com/scorelive/app/domain/model/Match.kt << 'EOF'
package com.scorelive.app.domain.model

import java.time.LocalDateTime

data class Match(
    val id: String,
    val league: League,
    val homeTeam: Team,
    val awayTeam: Team,
    val homeScore: Int?,
    val awayScore: Int?,
    val status: MatchStatus,
    val kickoff: LocalDateTime,
    val liveMinute: String? = null,
    val isFavorite: Boolean = false,
)
EOF

cat > app/src/main/java/com/scorelive/app/domain/repository/SportsRepository.kt << 'EOF'
package com.scorelive.app.domain.repository

import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import java.time.LocalDate

interface SportsRepository {
    suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>>
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

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        if (sport != Sport.FOOTBALL || date != LocalDate.now()) {
            return Result.success(emptyList())
        }

        val today = LocalDate.now()
        return Result.success(
            listOf(
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
        )
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/di/RepositoryModule.kt << 'EOF'
package com.scorelive.app.di

import com.scorelive.app.data.repository.MockSportsRepositoryImpl
import com.scorelive.app.domain.repository.SportsRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    abstract fun bindSportsRepository(impl: MockSportsRepositoryImpl): SportsRepository
}
EOF

cat > app/src/main/java/com/scorelive/app/presentation/home/HomeViewModel.kt << 'EOF'
package com.scorelive.app.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.repository.SportsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

data class HomeUiState(
    val selectedSport: Sport = Sport.FOOTBALL,
    val selectedDate: LocalDate = LocalDate.now(),
    val matches: List<Match> = emptyList(),
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val sportsRepository: SportsRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadMatches()
    }

    fun onSportSelected(sport: Sport) {
        _uiState.value = _uiState.value.copy(selectedSport = sport)
        loadMatches()
    }

    fun onDateSelected(date: LocalDate) {
        _uiState.value = _uiState.value.copy(selectedDate = date)
        loadMatches()
    }

    private fun loadMatches() {
        val sport = _uiState.value.selectedSport
        val date = _uiState.value.selectedDate
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            sportsRepository.getMatches(sport, date)
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

cat > app/src/main/java/com/scorelive/app/ui/components/LoadingView.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

@Composable
fun LoadingView(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        CircularProgressIndicator()
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/ui/components/ErrorView.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@Composable
fun ErrorView(
    message: String = "Veriler yuklenemedi.",
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
        )
        Button(onClick = onRetry, modifier = Modifier.padding(top = 16.dp)) {
            Text("Tekrar Dene")
        }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/ui/components/TeamLogo.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun TeamLogo(shortName: String, modifier: Modifier = Modifier, sizeDp: Dp = 28.dp) {
    Box(
        modifier = modifier
            .size(sizeDp)
            .background(MaterialTheme.colorScheme.primaryContainer, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = shortName.take(3).uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onPrimaryContainer,
        )
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/ui/components/ScoreDisplay.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight

@Composable
fun ScoreDisplay(homeScore: Int?, awayScore: Int?, modifier: Modifier = Modifier) {
    val text = if (homeScore != null && awayScore != null) "$homeScore - $awayScore" else "vs"
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Bold,
        modifier = modifier,
    )
}
EOF

cat > app/src/main/java/com/scorelive/app/ui/components/FavoriteButton.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color

@Composable
fun FavoriteButton(
    isFavorite: Boolean,
    onToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    IconButton(onClick = onToggle, modifier = modifier) {
        Icon(
            imageVector = if (isFavorite) Icons.Filled.Star else Icons.Outlined.StarOutline,
            contentDescription = if (isFavorite) "Favorilerden cikar" else "Favorilere ekle",
            tint = if (isFavorite) Color(0xFFF5C36B) else MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/ui/components/LeagueHeader.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun LeagueHeader(
    countryFlagEmoji: String,
    countryName: String,
    leagueName: String,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(text = countryFlagEmoji + " " + countryName, style = MaterialTheme.typography.labelSmall)
        }
        Text(text = leagueName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/ui/components/MatchCard.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import java.time.format.DateTimeFormatter

private val timeFormatter = DateTimeFormatter.ofPattern("HH:mm")

@Composable
fun MatchCard(
    match: Match,
    onClick: () -> Unit,
    onFavoriteToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val isLive = match.status == MatchStatus.LIVE || match.status == MatchStatus.HALF_TIME

    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        border = if (isLive) BorderStroke(1.5.dp, MaterialTheme.colorScheme.error) else null,
        colors = CardDefaults.cardColors(
            containerColor = if (isLive) {
                MaterialTheme.colorScheme.errorContainer
            } else {
                MaterialTheme.colorScheme.surfaceVariant
            },
        ),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.width(48.dp)) {
                if (isLive) {
                    Text(
                        text = "\ud83d\udd34 " + (match.liveMinute ?: "CANLI"),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.error,
                    )
                } else {
                    Text(
                        text = timeFormatter.format(match.kickoff),
                        style = MaterialTheme.typography.labelSmall,
                    )
                }
            }

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    TeamLogo(match.homeTeam.shortName)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = match.homeTeam.name,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f),
                    )
                }
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    TeamLogo(match.awayTeam.shortName)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = match.awayTeam.name,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f),
                    )
                }
            }

            Column(horizontalAlignment = Alignment.End) {
                ScoreDisplay(match.homeScore, match.awayScore)
                if (match.status == MatchStatus.FINISHED) {
                    Text(text = "MS", style = MaterialTheme.typography.labelSmall)
                }
            }

            FavoriteButton(isFavorite = match.isFavorite, onToggle = onFavoriteToggle)
        }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/ui/components/SportSelector.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.scorelive.app.domain.model.Sport

@Composable
fun SportSelector(
    selectedSport: Sport,
    onSportSelected: (Sport) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyRow(
        modifier = modifier,
        contentPadding = PaddingValues(horizontal = 16.dp),
    ) {
        items(Sport.entries) { sport ->
            FilterChip(
                selected = sport == selectedSport,
                onClick = { onSportSelected(sport) },
                label = { Text(sport.emoji + " " + sport.label) },
                modifier = Modifier.padding(end = 8.dp),
            )
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
fun HomeScreen(viewModel: HomeViewModel = hiltViewModel()) {
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
                                onClick = { },
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

git add .
git commit -m "Stage 3: mock football data, match list UI, clean architecture layers"
git push
echo "TAMAMLANDI"
