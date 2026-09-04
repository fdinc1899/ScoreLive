package com.scorelive.app.data.repository

import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.model.Team
import com.scorelive.app.domain.repository.SportsRepository
import java.time.LocalDate
import javax.inject.Inject

/**
 * Development-only repository returning static data so the UI is fully
 * navigable before Stage 6 wires up the real Sports API. UI copy never
 * implies this is live data.
 */
class MockSportsRepositoryImpl @Inject constructor() : SportsRepository {

    private val superLig = League("tr-superlig", "Trendyol Super Lig", "Turkiye", "\ud83c\uddf9\ud83c\uddf7")
    private val premierLeague = League("en-premier", "Premier League", "Ingiltere", "\ud83c\udff4")

    private fun team(id: String, name: String, shortName: String) = Team(id, name, shortName)

    private val basaksehir = team("t1", "Basaksehir", "BSK")
    private val galatasaray = team("t2", "Galatasaray", "GS")
    private val fenerbahce = team("t3", "Fenerbahce", "FB")
    private val trabzonspor = team("t4", "Trabzonspor", "TS")
    private val besiktas = team("t5", "Besiktas", "BJK")
    private val antalyaspor = team("t6", "Antalyaspor", "ANT")
    private val manCity = team("t7", "Manchester City", "MCI")
    private val liverpool = team("t8", "Liverpool", "LIV")
    private val arsenal = team("t9", "Arsenal", "ARS")
    private val chelsea = team("t10", "Chelsea", "CHE")

    private fun buildMockMatches(): List<Match> {
        val today = LocalDate.now()
        return listOf(
            Match(
                id = "m1",
                league = superLig,
                homeTeam = basaksehir,
                awayTeam = galatasaray,
                homeScore = 1,
                awayScore = 2,
                status = MatchStatus.LIVE,
                kickoff = today.atTime(19, 0),
                liveMinute = "67'",
            ),
            Match(
                id = "m2",
                league = superLig,
                homeTeam = fenerbahce,
                awayTeam = trabzonspor,
                homeScore = null,
                awayScore = null,
                status = MatchStatus.NOT_STARTED,
                kickoff = today.atTime(20, 0),
            ),
            Match(
                id = "m3",
                league = superLig,
                homeTeam = besiktas,
                awayTeam = antalyaspor,
                homeScore = 3,
                awayScore = 1,
                status = MatchStatus.FINISHED,
                kickoff = today.atTime(17, 0),
            ),
            Match(
                id = "m4",
                league = premierLeague,
                homeTeam = manCity,
                awayTeam = liverpool,
                homeScore = 0,
                awayScore = 0,
                status = MatchStatus.LIVE,
                kickoff = today.atTime(19, 30),
                liveMinute = "34'",
            ),
            Match(
                id = "m5",
                league = premierLeague,
                homeTeam = arsenal,
                awayTeam = chelsea,
                homeScore = null,
                awayScore = null,
                status = MatchStatus.NOT_STARTED,
                kickoff = today.atTime(22, 0),
            ),
        )
    }

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        if (sport != Sport.FOOTBALL || date != LocalDate.now()) {
            return Result.success(emptyList())
        }
        return Result.success(buildMockMatches())
    }

    override suspend fun getMatchDetails(matchId: String): Result<Match> {
        val match = buildMockMatches().find { it.id == matchId }
        return if (match != null) {
            Result.success(match)
        } else {
            Result.failure(NoSuchElementException("Mac bulunamadi."))
        }
    }
}
