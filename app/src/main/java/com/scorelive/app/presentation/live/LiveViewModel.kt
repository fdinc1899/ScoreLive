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
