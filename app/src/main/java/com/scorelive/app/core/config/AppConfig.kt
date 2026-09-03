package com.scorelive.app.core.config

/**
 * Central, single-source configuration for branding constants.
 *
 * The app's display name (as shown on the home screen launcher icon) lives in
 * res/values/strings.xml (R.string.app_name), since that is what Android
 * requires for the launcher label. This object mirrors the same value for use
 * anywhere in Kotlin code where a string resource isn't convenient (e.g. FCM
 * topic prefixes, log tags, About screen). To rebrand the app, update BOTH
 * this constant and R.string.app_name to the same value.
 */
object AppConfig {
    const val APP_NAME: String = "ScoreLive"
    const val APP_TAGLINE: String = "Canlı Skorlar, Anında"

    // Used as a prefix for FCM topic subscriptions, e.g. "scorelive_team_1905"
    const val FCM_TOPIC_PREFIX: String = "scorelive"
}
