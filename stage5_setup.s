set -e
cd ~/ScoreLive

cat > app/src/main/java/com/scorelive/app/domain/model/QuarterScore.kt << 'EOF'
package com.scorelive.app.domain.model

data class QuarterScore(
    val label: String,
    val homeScore: Int,
    val awayScore: Int,
)
EOF

cat > app/src/main/java/com/scorelive/app/domain/model/Match.kt << 'EOF'
package com.scorelive.app.domain.model

import java.time.LocalDateTime

data class Match(
    val id: String,
    val sport: Sport,
    val league: League,
    val homeTeam: Team,
    val awayTeam: Team,
    val homeScore: Int?,
    val awayScore: Int?,
    val status: MatchStatus,
    val kickoff: LocalDateTime,
    val liveMinute: String? = null,
    val quarterScores: List<QuarterScore>? = null,
    val isFavorite: Boolean = false,
)
EOF

cat > app/src/main/java/com/scorelive/app/data/repository/MockSportsRepositoryImpl.kt << 'EOF'
package com.scorelive.app.data.repository

import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.QuarterScore
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
    private val nba = League("nba", "NBA", "ABD", "\ud83c\uddfa\ud83c\uddf8")

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
    private val lakers = team("b1", "Lakers", "LAL")
    private val celtics = team("b2", "Celtics", "BOS")
    private val warriors = team("b3", "Warriors", "GSW")
    private val bulls = team("b4", "Bulls", "CHI")

    private fun buildFootballMatches(): List<Match> {
        val today = LocalDate.now()
        return listOf(
            Match(
                id = "m1",
                sport = Sport.FOOTBALL,
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
                sport = Sport.FOOTBALL,
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
                sport = Sport.FOOTBALL,
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
                sport = Sport.FOOTBALL,
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
                sport = Sport.FOOTBALL,
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

    private fun buildBasketballMatches(): List<Match> {
        val today = LocalDate.now()
        return listOf(
            Match(
                id = "b1",
                sport = Sport.BASKETBALL,
                league = nba,
                homeTeam = lakers,
                awayTeam = celtics,
                homeScore = 102,
                awayScore = 98,
                status = MatchStatus.LIVE,
                kickoff = today.atTime(20, 0),
                liveMinute = "4. Ceyrek - 05:32",
                quarterScores = listOf(
                    QuarterScore("1. Ceyrek", 24, 20),
                    QuarterScore("2. Ceyrek", 26, 24),
                    QuarterScore("3. Ceyrek", 28, 26),
                    QuarterScore("4. Ceyrek", 24, 28),
                ),
            ),
            Match(
                id = "b2",
                sport = Sport.BASKETBALL,
                league = nba,
                homeTeam = warriors,
                awayTeam = bulls,
                homeScore = null,
                awayScore = null,
                status = MatchStatus.NOT_STARTED,
                kickoff = today.atTime(21, 0),
            ),
        )
    }

    private fun buildAllMatches(): List<Match> = buildFootballMatches() + buildBasketballMatches()

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        if (date != LocalDate.now()) {
            return Result.success(emptyList())
        }
        val matches = when (sport) {
            Sport.FOOTBALL -> buildFootballMatches()
            Sport.BASKETBALL -> buildBasketballMatches()
            else -> emptyList()
        }
        return Result.success(matches)
    }

    override suspend fun getMatchDetails(matchId: String): Result<Match> {
        val match = buildAllMatches().find { it.id == matchId }
        return if (match != null) {
            Result.success(match)
        } else {
            Result.failure(NoSuchElementException("Mac bulunamadi."))
        }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/ui/components/StatRow.kt << 'EOF'
package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun StatRow(
    label: String,
    homeValue: String,
    awayValue: String,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(homeValue, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
        Text(label, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(awayValue, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
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
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.ui.components.EmptyView
import com.scorelive.app.ui.components.LoadingView
import com.scorelive.app.ui.components.ScoreDisplay
import com.scorelive.app.ui.components.StatRow
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
            0 -> {
                val quarters = match.quarterScores
                if (match.sport == Sport.BASKETBALL && !quarters.isNullOrEmpty()) {
                    Column(modifier = Modifier.fillMaxSize().padding(top = 8.dp)) {
                        StatRow(label = "Ceyrek", homeValue = match.homeTeam.shortName, awayValue = match.awayTeam.shortName)
                        quarters.forEach { q ->
                            StatRow(label = q.label, homeValue = q.homeScore.toString(), awayValue = q.awayScore.toString())
                        }
                    }
                } else {
                    EmptyView(message = "Bu mac icin ozet bilgisi henuz eklenmedi.", modifier = Modifier.fillMaxSize())
                }
            }
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
git commit -m "Stage 5: basketball support with mock NBA data and quarter scores"
git push
echo "TAMAMLANDI"
