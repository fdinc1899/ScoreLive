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
