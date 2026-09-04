package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.time.LocalDate

private data class DateOption(val date: LocalDate, val label: String)

@Composable
fun DateSelector(
    selectedDate: LocalDate,
    onDateSelected: (LocalDate) -> Unit,
    onCalendarClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val today = LocalDate.now()
    val options = listOf(
        DateOption(today.minusDays(1), "Dun"),
        DateOption(today, "Bugun"),
        DateOption(today.plusDays(1), "Yarin"),
        DateOption(today.plusDays(2), "2 Gun Sonra"),
    )

    Row(modifier = modifier) {
        LazyRow(
            modifier = Modifier.weight(1f),
            contentPadding = PaddingValues(horizontal = 16.dp),
        ) {
            items(options) { option ->
                FilterChip(
                    selected = option.date == selectedDate,
                    onClick = { onDateSelected(option.date) },
                    label = { Text(option.label) },
                    modifier = Modifier.padding(end = 8.dp),
                )
            }
        }
        IconButton(onClick = onCalendarClick) {
            Icon(Icons.Filled.CalendarMonth, contentDescription = "Takvim")
        }
    }
}
