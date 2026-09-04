package com.scorelive.app.presentation.favorites

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.scorelive.app.ui.components.EmptyView

@Composable
fun FavoritesScreen() {
    EmptyView(message = "Henuz favori eklemediniz.", modifier = Modifier.fillMaxSize())
}
