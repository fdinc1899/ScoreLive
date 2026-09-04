set -e
cd ~/ScoreLive

# ---- Favori entity + DAO ----
cat > app/src/main/java/com/scorelive/app/data/database/FavoriteEntity.kt << 'EOF'
package com.scorelive.app.data.database

import androidx.room.Entity
import androidx.room.PrimaryKey

/** type: MATCH | TEAM | LEAGUE. Composite id keeps the three namespaces apart. */
@Entity(tableName = "favorites")
data class FavoriteEntity(
    @PrimaryKey val key: String,
    val type: String,
    val targetId: String,
    val label: String,
    val addedAtEpochMillis: Long,
)
EOF

cat > app/src/main/java/com/scorelive/app/data/database/FavoriteDao.kt << 'EOF'
package com.scorelive.app.data.database

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface FavoriteDao {

    @Query("SELECT * FROM favorites ORDER BY addedAtEpochMillis DESC")
    fun observeAll(): Flow<List<FavoriteEntity>>

    @Query("SELECT * FROM favorites WHERE type = :type")
    suspend fun getByType(type: String): List<FavoriteEntity>

    @Query("SELECT targetId FROM favorites WHERE type = :type")
    fun observeIdsByType(type: String): Flow<List<String>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(favorite: FavoriteEntity)

    @Query("DELETE FROM favorites WHERE key = :key")
    suspend fun deleteByKey(key: String)

    @Query("SELECT EXISTS(SELECT 1 FROM favorites WHERE key = :key)")
    suspend fun exists(key: String): Boolean
}
EOF

# ---- Database: favorites tablosunu ekle (v2) ----
cat > app/src/main/java/com/scorelive/app/data/database/ScoreLiveDatabase.kt << 'EOF'
package com.scorelive.app.data.database

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [CachedMatchEntity::class, FavoriteEntity::class],
    version = 2,
    exportSchema = false,
)
abstract class ScoreLiveDatabase : RoomDatabase() {
    abstract fun matchDao(): MatchDao
    abstract fun favoriteDao(): FavoriteDao
}
EOF

# ---- DI: FavoriteDao saglayicisi ----
cat > app/src/main/java/com/scorelive/app/di/DatabaseModule.kt << 'EOF'
package com.scorelive.app.di

import android.content.Context
import androidx.room.Room
import com.scorelive.app.data.database.FavoriteDao
import com.scorelive.app.data.database.MatchDao
import com.scorelive.app.data.database.ScoreLiveDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): ScoreLiveDatabase =
        Room.databaseBuilder(context, ScoreLiveDatabase::class.java, "scorelive.db")
            .fallbackToDestructiveMigration()
            .build()

    @Provides
    @Singleton
    fun provideMatchDao(database: ScoreLiveDatabase): MatchDao = database.matchDao()

    @Provides
    @Singleton
    fun provideFavoriteDao(database: ScoreLiveDatabase): FavoriteDao = database.favoriteDao()
}
EOF

# ---- Domain: favori modeli + repository sozlesmesi ----
cat > app/src/main/java/com/scorelive/app/domain/model/Favorite.kt << 'EOF'
package com.scorelive.app.domain.model

enum class FavoriteType { MATCH, TEAM, LEAGUE }

data class Favorite(
    val type: FavoriteType,
    val targetId: String,
    val label: String,
) {
    val key: String get() = "${type.name}:$targetId"
}
EOF

cat > app/src/main/java/com/scorelive/app/domain/repository/FavoritesRepository.kt << 'EOF'
package com.scorelive.app.domain.repository

import com.scorelive.app.domain.model.Favorite
import com.scorelive.app.domain.model.FavoriteType
import kotlinx.coroutines.flow.Flow

interface FavoritesRepository {
    fun observeFavorites(): Flow<List<Favorite>>
    fun observeFavoriteIds(type: FavoriteType): Flow<Set<String>>
    suspend fun toggle(favorite: Favorite)
}
EOF

cat > app/src/main/java/com/scorelive/app/data/repository/FavoritesRepositoryImpl.kt << 'EOF'
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
EOF

# ---- DI binding ----
cat > app/src/main/java/com/scorelive/app/di/RepositoryModule.kt << 'EOF'
package com.scorelive.app.di

import com.scorelive.app.data.repository.FavoritesRepositoryImpl
import com.scorelive.app.data.repository.RemoteSportsRepositoryImpl
import com.scorelive.app.domain.repository.FavoritesRepository
import com.scorelive.app.domain.repository.SportsRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

/**
 * Swap RemoteSportsRepositoryImpl for MockSportsRepositoryImpl here to run
 * the app entirely offline against static development data.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    abstract fun bindSportsRepository(impl: RemoteSportsRepositoryImpl): SportsRepository

    @Binds
    abstract fun bindFavoritesRepository(impl: FavoritesRepositoryImpl): FavoritesRepository
}
EOF

# ---- HomeViewModel: favori durumunu birlestir ----
cat > app/src/main/java/com/scorelive/app/presentation/home/HomeViewModel.kt << 'EOF'
package com.scorelive.app.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.scorelive.app.domain.model.Favorite
import com.scorelive.app.domain.model.FavoriteType
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.repository.FavoritesRepository
import com.scorelive.app.domain.repository.SportsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

data class HomeUiState(
    val selectedSport: Sport = Sport.FOOTBALL,
    val selectedDate: LocalDate = LocalDate.now(),
    val matches: List<Match> = emptyList(),
    val favoriteMatchIds: Set<String> = emptySet(),
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val sportsRepository: SportsRepository,
    private val favoritesRepository: FavoritesRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadMatches()
        viewModelScope.launch {
            favoritesRepository.observeFavoriteIds(FavoriteType.MATCH).collect { ids ->
                _uiState.value = _uiState.value.copy(favoriteMatchIds = ids)
            }
        }
    }

    fun onSportSelected(sport: Sport) {
        _uiState.value = _uiState.value.copy(selectedSport = sport)
        loadMatches()
    }

    fun onDateSelected(date: LocalDate) {
        _uiState.value = _uiState.value.copy(selectedDate = date)
        loadMatches()
    }

    fun onFavoriteToggle(match: Match) {
        viewModelScope.launch {
            favoritesRepository.toggle(
                Favorite(
                    type = FavoriteType.MATCH,
                    targetId = match.id,
                    label = match.homeTeam.name + " - " + match.awayTeam.name,
                )
            )
        }
    }

    fun retry() {
        loadMatches()
    }

    private fun loadMatches() {
        val sport = _uiState.value.selectedSport
        val date = _uiState.value.selectedDate
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            sportsRepository.getMatches(sport, date)
                .onSuccess { matches ->
                    _uiState.value = _uiState.value.copy(matches = matches, isLoading = false)
                }
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        errorMessage = error.message ?: "Veriler yuklenemedi.",
                    )
                }
        }
    }
}
EOF

# ---- HomeScreen: favori butonunu bagla ----
python3 - << 'PYEOF'
p = "app/src/main/java/com/scorelive/app/presentation/home/HomeScreen.kt"
s = open(p).read()
s = s.replace(
    """                            MatchCard(
                                match = match,
                                onClick = { onMatchClick(match.id) },
                                onFavoriteToggle = { },
                            )""",
    """                            MatchCard(
                                match = match.copy(isFavorite = match.id in uiState.favoriteMatchIds),
                                onClick = { onMatchClick(match.id) },
                                onFavoriteToggle = { viewModel.onFavoriteToggle(match) },
                            )"""
)
open(p, "w").write(s)
print("HomeScreen guncellendi")
PYEOF

# ---- Favoriler ekrani ----
cat > app/src/main/java/com/scorelive/app/presentation/favorites/FavoritesViewModel.kt << 'EOF'
package com.scorelive.app.presentation.favorites

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.scorelive.app.domain.model.Favorite
import com.scorelive.app.domain.repository.FavoritesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class FavoritesUiState(
    val favorites: List<Favorite> = emptyList(),
    val isLoading: Boolean = true,
)

@HiltViewModel
class FavoritesViewModel @Inject constructor(
    private val favoritesRepository: FavoritesRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(FavoritesUiState())
    val uiState: StateFlow<FavoritesUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            favoritesRepository.observeFavorites().collect { favorites ->
                _uiState.value = FavoritesUiState(favorites = favorites, isLoading = false)
            }
        }
    }

    fun onRemove(favorite: Favorite) {
        viewModelScope.launch { favoritesRepository.toggle(favorite) }
    }
}
EOF

cat > app/src/main/java/com/scorelive/app/presentation/favorites/FavoritesScreen.kt << 'EOF'
package com.scorelive.app.presentation.favorites

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.scorelive.app.domain.model.FavoriteType
import com.scorelive.app.ui.components.EmptyView
import com.scorelive.app.ui.components.FavoriteButton
import com.scorelive.app.ui.components.LoadingView

@Composable
fun FavoritesScreen(viewModel: FavoritesViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    when {
        uiState.isLoading -> LoadingView(modifier = Modifier.fillMaxSize())
        uiState.favorites.isEmpty() -> EmptyView(
            message = "Henuz favori eklemediniz.\nMac kartlarindaki yildiza dokunarak ekleyebilirsiniz.",
            modifier = Modifier.fillMaxSize(),
        )
        else -> LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(uiState.favorites, key = { it.key }) { favorite ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp),
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(start = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = favorite.label,
                            style = MaterialTheme.typography.bodyMedium,
                            modifier = Modifier.weight(1f),
                        )
                        Text(
                            text = typeLabel(favorite.type),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        FavoriteButton(isFavorite = true, onToggle = { viewModel.onRemove(favorite) })
                    }
                }
            }
        }
    }
}

private fun typeLabel(type: FavoriteType): String = when (type) {
    FavoriteType.MATCH -> "Mac"
    FavoriteType.TEAM -> "Takim"
    FavoriteType.LEAGUE -> "Lig"
}
EOF

git add .
git commit -m "Stage 8: favorites system with Room persistence"
git push
echo "TAMAMLANDI"
