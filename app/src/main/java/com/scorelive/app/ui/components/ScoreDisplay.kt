package com.scorelive.app.ui.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight

@Composable
fun ScoreDisplay(homeScore: Int?, awayScore: Int?, modifier: Modifier = Modifier) {
    val text = if (homeScore != null && awayScore != null) "$homeScore - $awayScore" else "vs"
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Bold,
        modifier = modifier,
    )
}
