package com.scorelive.app.presentation.favorites

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.scorelive.app.domain.model.FavoriteType
import com.scorelive.app.ui.components.EmptyView
import com.scorelive.app.ui.components.FavoriteButton
import com.scorelive.app.ui.components.LoadingView

@Composable
fun FavoritesScreen(viewModel: FavoritesViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    when {
        uiState.isLoading -> LoadingView(modifier = Modifier.fillMaxSize())
        uiState.favorites.isEmpty() -> EmptyView(
            message = "Henuz favori eklemediniz.\nMac kartlarindaki yildiza dokunarak ekleyebilirsiniz.",
            modifier = Modifier.fillMaxSize(),
        )
        else -> LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(uiState.favorites, key = { it.key }) { favorite ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp),
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(start = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = favorite.label,
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.weight(1f),
                        )
                        Text(
                            text = typeLabel(favorite.type),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        FavoriteButton(isFavorite = true, onToggle = { viewModel.onRemove(favorite) })
                    }
                }
            }
        }
    }
}

private fun typeLabel(type: FavoriteType): String = when (type) {
    FavoriteType.MATCH -> "Mac"
    FavoriteType.TEAM -> "Takim"
    FavoriteType.LEAGUE -> "Lig"
}
