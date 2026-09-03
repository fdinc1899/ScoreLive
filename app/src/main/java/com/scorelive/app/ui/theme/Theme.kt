package com.scorelive.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColors = lightColorScheme(
    primary = PitchGreen40,
    onPrimary = Neutral99,
    primaryContainer = PitchGreen80,
    secondary = Amber40,
    secondaryContainer = Amber80,
    error = LiveRed,
    errorContainer = LiveRedContainer,
)

private val DarkColors = darkColorScheme(
    primary = PitchGreenDark80,
    onPrimary = Neutral10,
    primaryContainer = PitchGreen20,
    secondary = Amber80,
    error = LiveRed,
    errorContainer = LiveRedContainer,
)

/**
 * ThemeMode mirrors the user-facing setting from spec §24 (Sistem / Açık / Koyu).
 * Persisted via DataStore in a later stage; defaults to SYSTEM for now.
 */
enum class ThemeMode { SYSTEM, LIGHT, DARK }

@Composable
fun ScoreLiveTheme(
    themeMode: ThemeMode = ThemeMode.SYSTEM,
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val darkTheme = when (themeMode) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }

    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColors
        else -> LightColors
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content,
    )
}
