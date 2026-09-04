package com.scorelive.app.presentation.home

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SportsScore
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.scorelive.app.core.config.AppConfig
import com.scorelive.app.ui.components.DateSelector
import com.scorelive.app.ui.components.EmptyView
import com.scorelive.app.ui.components.Sport
import com.scorelive.app.ui.components.SportSelector
import java.time.LocalDate

@Composable
fun HomeScreen() {
    var selectedSport by remember { mutableStateOf(Sport.FOOTBALL) }
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }

    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.SportsScore, contentDescription = null)
            Text(
                text = AppConfig.APP_NAME,
                modifier = Modifier
                    .padding(start = 8.dp)
                    .weight(1f),
                style = MaterialTheme.typography.headlineSmall,
            )
            IconButton(onClick = { }) {
                Icon(Icons.Filled.Search, contentDescription = "Ara")
            }
            IconButton(onClick = { }) {
                Icon(Icons.Filled.Notifications, contentDescription = "Bildirimler")
            }
        }

        SportSelector(
            selectedSport = selectedSport,
            onSportSelected = { selectedSport = it },
        )

        Spacer(modifier = Modifier.height(8.dp))

        DateSelector(
            selectedDate = selectedDate,
            onDateSelected = { selectedDate = it },
            onCalendarClick = { },
        )

        Spacer(modifier = Modifier.height(8.dp))

        EmptyView(message = "Bu tarihte mac bulunamadi.")
    }
}
