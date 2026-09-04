package com.scorelive.app.domain.model

data class League(
    val id: String,
    val name: String,
    val country: String,
    val countryFlagEmoji: String,
    val logoUrl: String? = null,
)
