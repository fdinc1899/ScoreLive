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
import com.scorelive.app.ui.components.ErrorView
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
            uiState.errorMessage != null -> ErrorView(
                message = uiState.errorMessage ?: "Veriler yuklenemedi.",
                onRetry = viewModel::retry,
            )
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
