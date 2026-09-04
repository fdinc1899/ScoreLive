package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun LeagueHeader(
    countryFlagEmoji: String,
    countryName: String,
    leagueName: String,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(text = countryFlagEmoji + " " + countryName, style = MaterialTheme.typography.labelSmall)
        }
        Text(text = leagueName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
    }
}
