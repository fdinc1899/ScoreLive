package com.scorelive.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import java.time.format.DateTimeFormatter

private val timeFormatter = DateTimeFormatter.ofPattern("HH:mm")

@Composable
fun MatchCard(
    match: Match,
    onClick: () -> Unit,
    onFavoriteToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val isLive = match.status == MatchStatus.LIVE || match.status == MatchStatus.HALF_TIME

    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        border = if (isLive) BorderStroke(1.5.dp, MaterialTheme.colorScheme.error) else null,
        colors = CardDefaults.cardColors(
            containerColor = if (isLive) {
                MaterialTheme.colorScheme.errorContainer
            } else {
                MaterialTheme.colorScheme.surfaceVariant
            },
        ),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.width(48.dp)) {
                if (isLive) {
                    Text(
                        text = "\ud83d\udd34 " + (match.liveMinute ?: "CANLI"),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.error,
                    )
                } else {
                    Text(
                        text = timeFormatter.format(match.kickoff),
                        style = MaterialTheme.typography.labelSmall,
                    )
                }
            }

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    TeamLogo(match.homeTeam.shortName)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = match.homeTeam.name,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f),
                    )
                }
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    TeamLogo(match.awayTeam.shortName)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = match.awayTeam.name,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f),
                    )
                }
            }

            Column(horizontalAlignment = Alignment.End) {
                ScoreDisplay(match.homeScore, match.awayScore)
                if (match.status == MatchStatus.FINISHED) {
                    Text(text = "MS", style = MaterialTheme.typography.labelSmall)
                }
            }

            FavoriteButton(isFavorite = match.isFavorite, onToggle = onFavoriteToggle)
        }
    }
}
