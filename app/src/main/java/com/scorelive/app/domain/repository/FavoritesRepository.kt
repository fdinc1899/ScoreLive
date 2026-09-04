package com.scorelive.app.domain.repository

import com.scorelive.app.domain.model.Favorite
import com.scorelive.app.domain.model.FavoriteType
import kotlinx.coroutines.flow.Flow

interface FavoritesRepository {
    fun observeFavorites(): Flow<List<Favorite>>
    fun observeFavoriteIds(type: FavoriteType): Flow<Set<String>>
    suspend fun toggle(favorite: Favorite)
}
