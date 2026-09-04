package com.scorelive.app.presentation.live

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.scorelive.app.ui.components.EmptyView

@Composable
fun LiveScreen() {
    EmptyView(message = "Su anda canli mac yok.", modifier = Modifier.fillMaxSize())
}
