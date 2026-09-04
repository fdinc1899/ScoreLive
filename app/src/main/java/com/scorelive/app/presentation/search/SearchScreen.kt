package com.scorelive.app.presentation.search

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.scorelive.app.ui.components.EmptyView

@Composable
fun SearchScreen() {
    EmptyView(message = "Takim, oyuncu, lig veya mac arayin.", modifier = Modifier.fillMaxSize())
}
