package com.scorelive.app.data.repository

import com.scorelive.app.data.database.FavoriteDao
import com.scorelive.app.data.database.FavoriteEntity
import com.scorelive.app.domain.model.Favorite
import com.scorelive.app.domain.model.FavoriteType
import com.scorelive.app.domain.repository.FavoritesRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class FavoritesRepositoryImpl @Inject constructor(
    private val favoriteDao: FavoriteDao,
) : FavoritesRepository {

    override fun observeFavorites(): Flow<List<Favorite>> =
        favoriteDao.observeAll().map { entities ->
            entities.mapNotNull { entity ->
                val type = runCatching { FavoriteType.valueOf(entity.type) }.getOrNull() ?: return@mapNotNull null
                Favorite(type = type, targetId = entity.targetId, label = entity.label)
            }
        }

    override fun observeFavoriteIds(type: FavoriteType): Flow<Set<String>> =
        favoriteDao.observeIdsByType(type.name).map { it.toSet() }

    override suspend fun toggle(favorite: Favorite) {
        if (favoriteDao.exists(favorite.key)) {
            favoriteDao.deleteByKey(favorite.key)
        } else {
            favoriteDao.insert(
                FavoriteEntity(
                    key = favorite.key,
                    type = favorite.type.name,
                    targetId = favorite.targetId,
                    label = favorite.label,
                    addedAtEpochMillis = System.currentTimeMillis(),
                )
            )
        }
    }
}
