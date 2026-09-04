package com.scorelive.app.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.scorelive.app.presentation.favorites.FavoritesScreen
import com.scorelive.app.presentation.home.HomeScreen
import com.scorelive.app.presentation.live.LiveScreen
import com.scorelive.app.presentation.matchdetail.MatchDetailScreen
import com.scorelive.app.presentation.search.SearchScreen
import com.scorelive.app.presentation.settings.SettingsScreen

@Composable
fun ScoreLiveNavHost(navController: NavHostController) {
    NavHost(navController = navController, startDestination = Destination.Home.route) {
        composable(Destination.Home.route) {
            HomeScreen(onMatchClick = { matchId ->
                navController.navigate(MatchDetailRoutes.route(matchId))
            })
        }
        composable(Destination.Live.route) { LiveScreen() }
        composable(Destination.Favorites.route) { FavoritesScreen() }
        composable(Destination.Search.route) { SearchScreen() }
        composable(Destination.Settings.route) { SettingsScreen() }
        composable(
            route = MatchDetailRoutes.ROUTE_PATTERN,
            arguments = listOf(navArgument(MatchDetailRoutes.ARG_MATCH_ID) { type = NavType.StringType }),
        ) {
            MatchDetailScreen(onBack = { navController.popBackStack() })
        }
    }
}
