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
