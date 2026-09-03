package com.scorelive.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Application entry point. @HiltAndroidApp triggers Hilt's code generation,
 * building the top-level DI component that all modules (data/, domain/,
 * presentation/) will hang off of in later stages.
 */
@HiltAndroidApp
class ScoreLiveApplication : Application()
