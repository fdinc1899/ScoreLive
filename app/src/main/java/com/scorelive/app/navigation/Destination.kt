package com.scorelive.app.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FiberManualRecord
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.ui.graphics.vector.ImageVector

sealed class Destination(val route: String, val label: String, val icon: ImageVector) {
    data object Home : Destination("home", "Ana Sayfa", Icons.Filled.Home)
    data object Live : Destination("live", "Canli", Icons.Filled.FiberManualRecord)
    data object Favorites : Destination("favorites", "Favoriler", Icons.Filled.Star)
    data object Search : Destination("search", "Ara", Icons.Filled.Search)
    data object Settings : Destination("settings", "Ayarlar", Icons.Filled.Settings)

    companion object {
        val bottomNavItems = listOf(Home, Live, Favorites, Search, Settings)
    }
}

object MatchDetailRoutes {
    const val ARG_MATCH_ID = "matchId"
    const val ROUTE_PATTERN = "match_detail/{$ARG_MATCH_ID}"
    fun route(matchId: String) = "match_detail/$matchId"
}
