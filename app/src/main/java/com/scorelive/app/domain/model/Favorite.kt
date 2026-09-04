package com.scorelive.app.domain.model

enum class FavoriteType { MATCH, TEAM, LEAGUE }

data class Favorite(
    val type: FavoriteType,
    val targetId: String,
    val label: String,
) {
    val key: String get() = "${type.name}:$targetId"
}
