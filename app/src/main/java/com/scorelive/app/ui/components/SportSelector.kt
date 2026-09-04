package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.scorelive.app.domain.model.Sport

@Composable
fun SportSelector(
    selectedSport: Sport,
    onSportSelected: (Sport) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyRow(
        modifier = modifier,
        contentPadding = PaddingValues(horizontal = 16.dp),
    ) {
        items(Sport.entries) { sport ->
            FilterChip(
                selected = sport == selectedSport,
                onClick = { onSportSelected(sport) },
                label = { Text(sport.emoji + " " + sport.label) },
                modifier = Modifier.padding(end = 8.dp),
            )
        }
    }
}
