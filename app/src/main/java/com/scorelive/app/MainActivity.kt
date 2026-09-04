package com.scorelive.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.rememberNavController
import com.scorelive.app.navigation.ScoreLiveNavHost
import com.scorelive.app.presentation.settings.SettingsViewModel
import com.scorelive.app.ui.components.BottomNavigationBar
import com.scorelive.app.ui.theme.ScoreLiveTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ScoreLiveApp()
        }
    }
}

@Composable
private fun ScoreLiveApp(settingsViewModel: SettingsViewModel = hiltViewModel()) {
    val themeMode by settingsViewModel.themeMode.collectAsState()

    ScoreLiveTheme(themeMode = themeMode) {
        val navController = rememberNavController()
        Surface {
            Scaffold(
                bottomBar = { BottomNavigationBar(navController) },
            ) { innerPadding ->
                Box(modifier = Modifier.padding(innerPadding)) {
                    ScoreLiveNavHost(navController)
                }
            }
        }
    }
}
