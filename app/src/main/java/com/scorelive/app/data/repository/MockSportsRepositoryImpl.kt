package com.scorelive.app.data.repository

import com.scorelive.app.domain.model.League
import com.scorelive.app.domain.model.Match
import com.scorelive.app.domain.model.MatchStatus
import com.scorelive.app.domain.model.QuarterScore
import com.scorelive.app.domain.model.Sport
import com.scorelive.app.domain.model.StandingRow
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
    private val nba = League("nba", "NBA", "ABD", "\ud83c\uddfa\ud83c\uddf8")

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
    private val lakers = team("b1", "Lakers", "LAL")
    private val celtics = team("b2", "Celtics", "BOS")
    private val warriors = team("b3", "Warriors", "GSW")
    private val bulls = team("b4", "Bulls", "CHI")

    private fun buildFootballMatches(): List<Match> {
        val today = LocalDate.now()
        return listOf(
            Match(
                id = "m1",
                sport = Sport.FOOTBALL,
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
                sport = Sport.FOOTBALL,
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
                sport = Sport.FOOTBALL,
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
                sport = Sport.FOOTBALL,
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
                sport = Sport.FOOTBALL,
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

    private fun buildBasketballMatches(): List<Match> {
        val today = LocalDate.now()
        return listOf(
            Match(
                id = "b1",
                sport = Sport.BASKETBALL,
                league = nba,
                homeTeam = lakers,
                awayTeam = celtics,
                homeScore = 102,
                awayScore = 98,
                status = MatchStatus.LIVE,
                kickoff = today.atTime(20, 0),
                liveMinute = "4. Ceyrek - 05:32",
                quarterScores = listOf(
                    QuarterScore("1. Ceyrek", 24, 20),
                    QuarterScore("2. Ceyrek", 26, 24),
                    QuarterScore("3. Ceyrek", 28, 26),
                    QuarterScore("4. Ceyrek", 24, 28),
                ),
            ),
            Match(
                id = "b2",
                sport = Sport.BASKETBALL,
                league = nba,
                homeTeam = warriors,
                awayTeam = bulls,
                homeScore = null,
                awayScore = null,
                status = MatchStatus.NOT_STARTED,
                kickoff = today.atTime(21, 0),
            ),
        )
    }

    private fun buildAllMatches(): List<Match> = buildFootballMatches() + buildBasketballMatches()

    override suspend fun getMatches(sport: Sport, date: LocalDate): Result<List<Match>> {
        if (date != LocalDate.now()) {
            return Result.success(emptyList())
        }
        val matches = when (sport) {
            Sport.FOOTBALL -> buildFootballMatches()
            Sport.BASKETBALL -> buildBasketballMatches()
            else -> emptyList()
        }
        return Result.success(matches)
    }

    override suspend fun getMatchDetails(matchId: String): Result<Match> {
        val match = buildAllMatches().find { it.id == matchId }
        return if (match != null) {
            Result.success(match)
        } else {
            Result.failure(NoSuchElementException("Mac bulunamadi."))
        }
    }

    override suspend fun getLiveMatches(sport: Sport): Result<List<Match>> {
        val live = buildAllMatches().filter {
            it.sport == sport && it.status == MatchStatus.LIVE
        }
        return Result.success(live)
    }

    override suspend fun search(query: String, sport: Sport): Result<List<Match>> {
        if (query.isBlank()) return Result.success(emptyList())
        val needle = query.trim().lowercase()
        return Result.success(
            buildAllMatches().filter { match ->
                match.sport == sport && (
                    match.homeTeam.name.lowercase().contains(needle) ||
                        match.awayTeam.name.lowercase().contains(needle) ||
                        match.league.name.lowercase().contains(needle)
                    )
            }
        )
    }

    override suspend fun getStandings(matchId: String, sport: Sport): Result<List<StandingRow>> =
        Result.success(emptyList())
}
