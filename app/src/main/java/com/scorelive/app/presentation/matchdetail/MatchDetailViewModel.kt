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
