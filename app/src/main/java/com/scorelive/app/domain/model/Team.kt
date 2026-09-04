package com.scorelive.app.domain.model

data class Team(
    val id: String,
    val name: String,
    val shortName: String,
    val logoUrl: String? = null,
)
