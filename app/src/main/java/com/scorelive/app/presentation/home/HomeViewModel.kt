package com.scorelive.app.presentation.home

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
import java.time.LocalDate
import javax.inject.Inject

data class HomeUiState(
    val selectedSport: Sport = Sport.FOOTBALL,
    val selectedDate: LocalDate = LocalDate.now(),
    val matches: List<Match> = emptyList(),
    val favoriteMatchIds: Set<String> = emptySet(),
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val sportsRepository: SportsRepository,
    private val favoritesRepository: FavoritesRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadMatches()
        viewModelScope.launch {
            favoritesRepository.observeFavoriteIds(FavoriteType.MATCH).collect { ids ->
                _uiState.value = _uiState.value.copy(favoriteMatchIds = ids)
            }
        }
    }

    fun onSportSelected(sport: Sport) {
        _uiState.value = _uiState.value.copy(selectedSport = sport)
        loadMatches()
    }

    fun onDateSelected(date: LocalDate) {
        _uiState.value = _uiState.value.copy(selectedDate = date)
        loadMatches()
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

    fun retry() {
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
