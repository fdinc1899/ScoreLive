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
