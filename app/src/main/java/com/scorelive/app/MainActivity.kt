package com.scorelive.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.scorelive.app.core.config.AppConfig
import com.scorelive.app.ui.theme.ScoreLiveTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * Stage 1 placeholder host. Navigation Compose + real screens (home, live,
 * favorites, search, settings) are wired in Stage 2 per the phased plan.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ScoreLiveTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    Scaffold { innerPadding ->
                        StartupPlaceholder(modifier = Modifier.padding(innerPadding))
                    }
                }
            }
        }
    }
}

@Composable
fun StartupPlaceholder(modifier: Modifier = Modifier) {
    Text(
        text = "${AppConfig.APP_NAME} — Aşama 1 iskeleti hazır",
        modifier = modifier.padding(24.dp),
    )
}

@Preview(showBackground = true)
@Composable
private fun StartupPlaceholderPreview() {
    ScoreLiveTheme {
        StartupPlaceholder()
    }
}
