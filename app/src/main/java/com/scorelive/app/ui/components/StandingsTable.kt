package com.scorelive.app.ui.components

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.scorelive.app.domain.model.StandingRow

@Composable
fun StandingsTable(rows: List<StandingRow>, modifier: Modifier = Modifier) {
    LazyColumn(modifier = modifier.fillMaxSize()) {
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 8.dp),
            ) {
                Cell("#", width = 24, bold = true)
                Cell("Takim", weightCell = true, bold = true)
                Cell("O", width = 26, bold = true)
                Cell("G", width = 26, bold = true)
                Cell("B", width = 26, bold = true)
                Cell("M", width = 26, bold = true)
                Cell("AV", width = 32, bold = true)
                Cell("P", width = 30, bold = true)
            }
            HorizontalDivider()
        }
        items(rows, key = { it.teamId + it.rank }) { row ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 6.dp),
            ) {
                Cell(row.rank.toString(), width = 24)
                Cell(row.teamName, weightCell = true)
                Cell(row.played.toString(), width = 26)
                Cell(row.won.toString(), width = 26)
                Cell(row.drawn.toString(), width = 26)
                Cell(row.lost.toString(), width = 26)
                Cell(row.goalDifference.toString(), width = 32)
                Cell(row.points.toString(), width = 30, bold = true)
            }
        }
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.Cell(
    text: String,
    width: Int? = null,
    weightCell: Boolean = false,
    bold: Boolean = false,
) {
    val modifier = when {
        weightCell -> Modifier.weight(1f)
        width != null -> Modifier.width(width.dp)
        else -> Modifier
    }
    Text(
        text = text,
        modifier = modifier,
        style = MaterialTheme.typography.bodySmall,
        fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        textAlign = if (weightCell) TextAlign.Start else TextAlign.Center,
    )
}
