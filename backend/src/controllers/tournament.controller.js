import { prisma } from "../index.js";

// ============================================
// TOURNAMENT CRUD OPERATIONS
// ============================================

/**
 * Create a new tournament
 * @route   POST /api/tournaments
 */
export const createTournament = async (req, res) => {
  try {
    const {
      futsalId,
      name,
      description,
      type,
      startDate,
      endDate,
      maxTeams,
      entryFee,
      prizePool,
      rules,
      prizes,
      isPublished,
    } = req.body;

    // Validate required fields
    if (!futsalId || !name || !type || !startDate || !maxTeams) {
      return res.status(400).json({
        status: "error",
        message: "Missing required fields",
      });
    }

    // Verify futsal ownership
    const futsal = await prisma.futsal.findFirst({
      where: {
        id: parseInt(futsalId),
        ownerId: req.user.id,
      },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found or you do not have permission",
      });
    }

    // Create tournament
    const tournament = await prisma.tournament.create({
      data: {
        futsalId: parseInt(futsalId),
        name,
        description,
        type: type.toUpperCase(),
        startDate: new Date(startDate),
        endDate: endDate ? new Date(endDate) : null,
        maxTeams: parseInt(maxTeams),
        entryFee: entryFee ? parseFloat(entryFee) : null,
        prizePool: prizePool ? parseFloat(prizePool) : null,
        rules,
        prizes: prizes || [],
        status: "DRAFT",
        isPublished: isPublished || false,
      },
    });

    res.status(201).json({
      status: "success",
      message: "Tournament created successfully",
      tournament,
    });
  } catch (error) {
    console.error("Create tournament error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Get all tournaments (public)
 * @route   GET /api/tournaments
 */
export const getAllTournaments = async (req, res) => {
  try {
    const { status, type, futsalId } = req.query;

    const whereClause = {
      isPublished: true,
      status: { not: "DRAFT" },
    };

    if (status) whereClause.status = status;
    if (type) whereClause.type = type;
    if (futsalId) whereClause.futsalId = parseInt(futsalId);

    const tournaments = await prisma.tournament.findMany({
      where: whereClause,
      include: {
        futsal: {
          select: {
            id: true,
            name: true,
            address: true,
            images: true,
          },
        },
        _count: {
          select: {
            teams: true,
            matches: true,
          },
        },
      },
      orderBy: {
        startDate: "asc",
      },
    });

    res.json({
      status: "success",
      results: tournaments.length,
      tournaments,
    });
  } catch (error) {
    console.error("Get all tournaments error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Get owner's tournaments (for dashboard)
 * @route   GET /api/tournaments/my-tournaments
 */
export const getMyTournaments = async (req, res) => {
  try {
    const tournaments = await prisma.tournament.findMany({
      where: {
        futsal: {
          ownerId: req.user.id,
        },
      },
      include: {
        futsal: {
          select: {
            id: true,
            name: true,
          },
        },
        _count: {
          select: {
            teams: true,
            matches: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    res.json({
      status: "success",
      results: tournaments.length,
      tournaments,
    });
  } catch (error) {
    console.error("Get my tournaments error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Get tournament by ID
 * @route   GET /api/tournaments/:id
 */
export const getTournamentById = async (req, res) => {
  try {
    const { id } = req.params;

    const tournament = await prisma.tournament.findUnique({
      where: { id: parseInt(id) },
      include: {
        futsal: {
          select: {
            id: true,
            name: true,
            address: true,
            ownerId: true,
          },
        },
        teams: {
          include: {
            players: {
              include: {
                user: {
                  select: {
                    id: true,
                    fullName: true,
                    email: true,
                  },
                },
              },
            },
          },
        },
        matches: {
          include: {
            homeTeam: true,
            awayTeam: true,
          },
          orderBy: {
            matchDate: "asc",
          },
        },
      },
    });

    if (!tournament) {
      return res.status(404).json({
        status: "error",
        message: "Tournament not found",
      });
    }

    res.json({
      status: "success",
      tournament,
    });
  } catch (error) {
    console.error("Get tournament by ID error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Update tournament
 * @route   PUT /api/tournaments/:id
 */
export const updateTournament = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    console.log("=== UPDATE TOURNAMENT DEBUG ===");
    console.log("Tournament ID:", id);
    console.log("Updates received:", JSON.stringify(updates, null, 2));

    console.log("PRIZES RECEIVED:", updates.prizes);
    console.log("PRIZES TYPE:", typeof updates.prizes);
    console.log("PRIZES IS ARRAY?", Array.isArray(updates.prizes));

    // Check ownership
    const tournament = await prisma.tournament.findUnique({
      where: { id: parseInt(id) },
      include: { futsal: true },
    });

    if (!tournament) {
      return res.status(404).json({
        status: "error",
        message: "Tournament not found",
      });
    }

    if (
      tournament.futsal.ownerId !== req.user.id &&
      req.user.role !== "ADMIN"
    ) {
      return res.status(403).json({
        status: "error",
        message: "You do not have permission to update this tournament",
      });
    }

    // Don't allow updating certain fields after tournament starts
    if (tournament.status !== "DRAFT") {
      delete updates.type;
      delete updates.maxTeams;
      delete updates.startDate;
    }

    // Prepare data for Prisma - handle special cases
    const { futsalId, prizes, ...otherUpdates } = updates;

    const updateData = {
      ...otherUpdates,
    };

    // Handle prizes: if null or undefined, set to empty array
    // If it's an array, use it as is
    if (prizes === null || prizes === undefined) {
      updateData.prizes = []; // Set to empty array instead of null
    } else if (Array.isArray(prizes)) {
      updateData.prizes = prizes;
    }

    // Handle futsal connection
    if (futsalId) {
      updateData.futsal = {
        connect: { id: parseInt(futsalId) },
      };
    }

    console.log("Final updateData:", JSON.stringify(updateData, null, 2));

    const updatedTournament = await prisma.tournament.update({
      where: { id: parseInt(id) },
      data: updateData,
    });

    console.log(
      "UPDATED TOURNAMENT FROM DB:",
      JSON.stringify(updatedTournament, null, 2),
    );
    console.log("SAVED PRIZES:", updatedTournament.prizes);

    res.json({
      status: "success",
      message: "Tournament updated successfully",
      tournament: updatedTournament,
    });
  } catch (error) {
    console.error("=== UPDATE TOURNAMENT ERROR ===");
    console.error(error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Delete tournament
 * @route   DELETE /api/tournaments/:id
 */
export const deleteTournament = async (req, res) => {
  try {
    const { id } = req.params;

    // Check ownership
    const tournament = await prisma.tournament.findUnique({
      where: { id: parseInt(id) },
      include: { futsal: true, teams: true, matches: true },
    });

    if (!tournament) {
      return res.status(404).json({
        status: "error",
        message: "Tournament not found",
      });
    }

    if (
      tournament.futsal.ownerId !== req.user.id &&
      req.user.role !== "ADMIN"
    ) {
      return res.status(403).json({
        status: "error",
        message: "You do not have permission to delete this tournament",
      });
    }

    // Don't allow deletion if tournament has started
    if (tournament.status !== "DRAFT") {
      return res.status(400).json({
        status: "error",
        message: "Cannot delete tournament after it has started",
      });
    }

    // Delete in transaction (matches, teams, then tournament)
    await prisma.$transaction(async (tx) => {
      // Delete matches
      await tx.match.deleteMany({
        where: { tournamentId: parseInt(id) },
      });

      // Delete teams and their members
      const teams = await tx.team.findMany({
        where: { tournamentId: parseInt(id) },
      });

      for (const team of teams) {
        await tx.teamMember.deleteMany({
          where: { teamId: team.id },
        });
      }

      await tx.team.deleteMany({
        where: { tournamentId: parseInt(id) },
      });

      // Delete tournament
      await tx.tournament.delete({
        where: { id: parseInt(id) },
      });
    });

    res.json({
      status: "success",
      message: "Tournament deleted successfully",
    });
  } catch (error) {
    console.error("Delete tournament error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Update tournament status
 * @route   PATCH /api/tournaments/:id/status
 */
export const updateTournamentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ["DRAFT", "ONGOING", "COMPLETED", "CANCELLED"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        status: "error",
        message: "Invalid status",
      });
    }

    // Check ownership
    const tournament = await prisma.tournament.findUnique({
      where: { id: parseInt(id) },
      include: { futsal: true },
    });

    if (!tournament) {
      return res.status(404).json({
        status: "error",
        message: "Tournament not found",
      });
    }

    if (
      tournament.futsal.ownerId !== req.user.id &&
      req.user.role !== "ADMIN"
    ) {
      return res.status(403).json({
        status: "error",
        message: "You do not have permission",
      });
    }

    // ✅ ADD THIS CHECK: Cannot change status of cancelled tournament
    if (tournament.status === "CANCELLED") {
      return res.status(400).json({
        status: "error",
        message: "Cannot change status of a cancelled tournament",
      });
    }

    // Validate status transitions
    if (tournament.status === "COMPLETED") {
      return res.status(400).json({
        status: "error",
        message: "Cannot change status of completed tournament",
      });
    }

    const updatedTournament = await prisma.tournament.update({
      where: { id: parseInt(id) },
      data: { status },
    });

    res.json({
      status: "success",
      message: `Tournament status updated to ${status}`,
      tournament: updatedTournament,
    });
  } catch (error) {
    console.error("Update tournament status error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

// ============================================
// TEAM MANAGEMENT
// ============================================

/**
 * Add team to tournament
 * @route   POST /api/tournaments/:tournamentId/teams
 */
export const addTeam = async (req, res) => {
  try {
    const { tournamentId } = req.params;
    const { name, captainName, captainPhone, players, jerseyColor } = req.body;

    // Check tournament exists and is in DRAFT status
    const tournament = await prisma.tournament.findUnique({
      where: { id: parseInt(tournamentId) },
      include: { futsal: true },
    });

    if (!tournament) {
      return res.status(404).json({
        status: "error",
        message: "Tournament not found",
      });
    }

    // Check if tournament is full
    const teamCount = await prisma.team.count({
      where: { tournamentId: parseInt(tournamentId) },
    });

    if (teamCount >= tournament.maxTeams) {
      return res.status(400).json({
        status: "error",
        message: "Tournament is full",
      });
    }

    // Check if team name already exists
    const existingTeam = await prisma.team.findFirst({
      where: {
        tournamentId: parseInt(tournamentId),
        name: name,
      },
    });

    if (existingTeam) {
      return res.status(400).json({
        status: "error",
        message: "Team name already exists",
      });
    }

    // Create team and team members in transaction
    const result = await prisma.$transaction(async (tx) => {
      // Create team
      const team = await tx.team.create({
        data: {
          tournamentId: parseInt(tournamentId),
          name,
          logo: null, // Will implement image upload later
        },
      });

      // Create captain as team member if user exists
      if (captainName) {
        // For now, create without user link
        await tx.teamMember.create({
          data: {
            teamId: team.id,
            userId: null,
            role: "CAPTAIN",
            playerName: captainName,
            playerPhone: captainPhone,
            jerseyColor,
          },
        });
      }

      // Add other players
      if (players && players.length > 0) {
        for (const player of players) {
          await tx.teamMember.create({
            data: {
              teamId: team.id,
              userId: null,
              role: "PLAYER",
              playerName: player,
            },
          });
        }
      }

      return team;
    });

    res.status(201).json({
      status: "success",
      message: "Team added successfully",
      team: result,
    });
  } catch (error) {
    console.error("Add team error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Get teams for a tournament
 * @route   GET /api/tournaments/:tournamentId/teams
 */
export const getTeams = async (req, res) => {
  try {
    const { tournamentId } = req.params;

    const teams = await prisma.team.findMany({
      where: { tournamentId: parseInt(tournamentId) },
      include: {
        players: {
          select: {
            id: true,
            role: true,
            playerName: true,
            playerPhone: true,
            jerseyColor: true,
          },
        },
      },
      orderBy: {
        name: "asc",
      },
    });

    res.json({
      status: "success",
      results: teams.length,
      teams,
    });
  } catch (error) {
    console.error("Get teams error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Update team
 * @route   PUT /api/teams/:teamId
 */
export const updateTeam = async (req, res) => {
  try {
    const { teamId } = req.params;
    const updates = req.body;

    // Check team exists and tournament is in DRAFT
    const team = await prisma.team.findUnique({
      where: { id: parseInt(teamId) },
      include: {
        tournament: {
          include: { futsal: true },
        },
      },
    });

    if (!team) {
      return res.status(404).json({
        status: "error",
        message: "Team not found",
      });
    }

    if (
      team.tournament.status !== "DRAFT" &&
      team.tournament.futsal.ownerId !== req.user.id
    ) {
      return res.status(400).json({
        status: "error",
        message: "Cannot update team after tournament has started",
      });
    }

    const updatedTeam = await prisma.team.update({
      where: { id: parseInt(teamId) },
      data: updates,
    });

    res.json({
      status: "success",
      message: "Team updated successfully",
      team: updatedTeam,
    });
  } catch (error) {
    console.error("Update team error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Delete team
 * @route   DELETE /api/teams/:teamId
 */
export const deleteTeam = async (req, res) => {
  try {
    const { teamId } = req.params;

    // Check team exists and tournament is in DRAFT
    const team = await prisma.team.findUnique({
      where: { id: parseInt(teamId) },
      include: {
        tournament: {
          include: { futsal: true },
        },
      },
    });

    if (!team) {
      return res.status(404).json({
        status: "error",
        message: "Team not found",
      });
    }

    if (
      team.tournament.status !== "DRAFT" &&
      team.tournament.futsal.ownerId !== req.user.id
    ) {
      return res.status(400).json({
        status: "error",
        message: "Cannot delete team after tournament has started",
      });
    }

    // Delete team members then team
    await prisma.$transaction([
      prisma.teamMember.deleteMany({
        where: { teamId: parseInt(teamId) },
      }),
      prisma.team.delete({
        where: { id: parseInt(teamId) },
      }),
    ]);

    res.json({
      status: "success",
      message: "Team deleted successfully",
    });
  } catch (error) {
    console.error("Delete team error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

// ============================================
// FIXTURE GENERATION
// ============================================

/**
 * Generate fixtures for tournament
 * @route   POST /api/tournaments/:tournamentId/generate-fixtures
 */
export const generateFixtures = async (req, res) => {
  try {
    const { tournamentId } = req.params;

    // Get tournament with teams
    const tournament = await prisma.tournament.findUnique({
      where: { id: parseInt(tournamentId) },
      include: {
        teams: true,
        futsal: true,
      },
    });

    if (!tournament) {
      return res.status(404).json({
        status: "error",
        message: "Tournament not found",
      });
    }

    // Verify ownership
    if (
      tournament.futsal.ownerId !== req.user.id &&
      req.user.role !== "ADMIN"
    ) {
      return res.status(403).json({
        status: "error",
        message: "You do not have permission",
      });
    }

    // Check if tournament already has fixtures
    const existingMatches = await prisma.match.count({
      where: { tournamentId: parseInt(tournamentId) },
    });

    if (existingMatches > 0) {
      return res.status(400).json({
        status: "error",
        message: "Fixtures already generated",
      });
    }

    // Check number of teams
    const teamCount = tournament.teams.length;
    if (teamCount < 2) {
      return res.status(400).json({
        status: "error",
        message: "Need at least 2 teams to generate fixtures",
      });
    }

    let matches = [];

    if (tournament.type === "KNOCKOUT") {
      // Generate knockout fixtures
      matches = generateKnockoutFixtures(
        tournament.teams,
        tournament.startDate,
        tournamentId,
      );
    } else {
      // Generate round robin fixtures
      matches = generateRoundRobinFixtures(
        tournament.teams,
        tournament.startDate,
        tournamentId,
      );
    }

    // Save matches to database
    const createdMatches = await prisma.match.createMany({
      data: matches,
    });

    // Update tournament status to ONGOING
    await prisma.tournament.update({
      where: { id: parseInt(tournamentId) },
      data: { status: "ONGOING" },
    });

    res.json({
      status: "success",
      message: "Fixtures generated successfully",
      matchesCount: matches.length,
    });
  } catch (error) {
    console.error("Generate fixtures error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

// Helper function for knockout fixtures
const generateKnockoutFixtures = (teams, startDate, tournamentId) => {
  const shuffled = [...teams].sort(() => 0.5 - Math.random());
  const matches = [];
  let matchDate = new Date(startDate);

  // Determine the correct round name based on number of teams
  let firstRoundName = "";
  const teamCount = teams.length;

  if (teamCount === 2) {
    firstRoundName = "FINAL";
  } else if (teamCount === 4) {
    firstRoundName = "SEMI_FINAL";
  } else if (teamCount === 8) {
    firstRoundName = "QUARTER_FINAL";
  } else if (teamCount === 16) {
    firstRoundName = "ROUND_OF_16";
  } else {
    firstRoundName = "QUARTER_FINAL"; // default
  }

  console.log(`🏆 Generating ${firstRoundName} matches for ${teamCount} teams`);

  for (let i = 0; i < shuffled.length; i += 2) {
    if (i + 1 < shuffled.length) {
      matches.push({
        tournamentId: parseInt(tournamentId),
        homeTeamId: shuffled[i].id,
        awayTeamId: shuffled[i + 1].id,
        matchDate: new Date(matchDate),
        round: firstRoundName, // Use dynamic round name
        status: "SCHEDULED",
      });
    }
    matchDate.setDate(matchDate.getDate() + 1);
  }

  return matches;
};

// Helper function for round robin fixtures
const generateRoundRobinFixtures = (teams, startDate, tournamentId) => {
  const matches = [];
  let matchDate = new Date(startDate);
  const numTeams = teams.length;

  for (let i = 0; i < numTeams; i++) {
    for (let j = i + 1; j < numTeams; j++) {
      matches.push({
        tournamentId: parseInt(tournamentId),
        homeTeamId: teams[i].id,
        awayTeamId: teams[j].id,
        matchDate: new Date(matchDate),
        round: "GROUP_STAGE",
        status: "SCHEDULED",
      });
      matchDate.setDate(matchDate.getDate() + 1);
    }
  }

  return matches;
};

// ============================================
// MATCH MANAGEMENT
// ============================================

/**
 * Get matches for tournament
 * @route   GET /api/tournaments/:tournamentId/matches
 */
export const getMatches = async (req, res) => {
  try {
    const { tournamentId } = req.params;

    const matches = await prisma.match.findMany({
      where: { tournamentId: parseInt(tournamentId) },
      include: {
        homeTeam: {
          select: { id: true, name: true },
        },
        awayTeam: {
          select: { id: true, name: true },
        },
      },
      orderBy: {
        matchDate: "asc",
      },
    });

    res.json({
      status: "success",
      results: matches.length,
      matches,
    });
  } catch (error) {
    console.error("Get matches error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

/**
 * Update match score and trigger next round generation
 */
export const updateMatchScore = async (req, res) => {
  try {
    const { matchId } = req.params;
    const { homeScore, awayScore, homePenalty, awayPenalty } = req.body;

    // Get match with tournament info
    const match = await prisma.match.findUnique({
      where: { id: parseInt(matchId) },
      include: {
        tournament: {
          include: { futsal: true },
        },
      },
    });

    if (!match) {
      return res.status(404).json({
        status: "error",
        message: "Match not found",
      });
    }

    // Verify ownership
    if (
      match.tournament.futsal.ownerId !== req.user.id &&
      req.user.role !== "ADMIN"
    ) {
      return res.status(403).json({
        status: "error",
        message: "You do not have permission",
      });
    }

    // Update match
    const updatedMatch = await prisma.match.update({
      where: { id: parseInt(matchId) },
      data: {
        homeScore,
        awayScore,
        homePenalty,
        awayPenalty,
        status: "COMPLETED",
      },
    });

    // For knockout tournaments, check if we need to generate next round
    if (match.tournament.type === "KNOCKOUT") {
      // Check if all matches in current round are completed
      const roundMatches = await prisma.match.findMany({
        where: {
          tournamentId: match.tournamentId,
          round: match.round,
        },
      });

      const completedMatches = roundMatches.filter(
        (m) => m.status === "COMPLETED",
      );

      if (completedMatches.length === roundMatches.length) {
        // All matches in this round are done, generate next round
        await generateNextRoundMatches(match.tournamentId, match.round);
      }
    }

    // For round robin, check if all matches are completed
    if (match.tournament.type === "ROUND_ROBIN") {
      // Get all matches for this tournament
      const allMatches = await prisma.match.findMany({
        where: {
          tournamentId: match.tournamentId,
        },
      });

      const completedMatches = allMatches.filter(
        (m) => m.status === "COMPLETED",
      );

      // If all matches are completed, mark tournament as COMPLETED
      if (completedMatches.length === allMatches.length && allMatches.length > 0) {
        await prisma.tournament.update({
          where: { id: match.tournamentId },
          data: { status: "COMPLETED" },
        });
        console.log("🏆 Round Robin tournament marked as COMPLETED");
      }
    }

    // For knockout, check if final match was just completed
    if (match.tournament.type === "KNOCKOUT" && match.round === "FINAL") {
      await prisma.tournament.update({
        where: { id: match.tournamentId },
        data: { status: "COMPLETED" },
      });
      console.log("🏆 Knockout tournament marked as COMPLETED");
    }

    res.json({
      status: "success",
      message: "Score updated successfully",
      match: updatedMatch,
    });
  } catch (error) {
    console.error("Update match score error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};
/**
 * Generate next round matches for knockout tournament
 * Called automatically when all matches in current round are completed
 */
const generateNextRoundMatches = async (tournamentId, currentRound) => {
  try {
    console.log(
      `🏆 Generating next round for tournament ${tournamentId} after ${currentRound}`,
    );

    // Get all completed matches in current round
    const completedMatches = await prisma.match.findMany({
      where: {
        tournamentId: parseInt(tournamentId),
        round: currentRound,
        status: "COMPLETED",
      },
      include: {
        homeTeam: true,
        awayTeam: true,
      },
    });

    if (completedMatches.length === 0) {
      console.log("No completed matches found");
      return;
    }

    // Get all matches in current round to check if all are completed
    const allMatchesInRound = await prisma.match.count({
      where: {
        tournamentId: parseInt(tournamentId),
        round: currentRound,
      },
    });

    // Only proceed if all matches in this round are completed
    if (completedMatches.length !== allMatchesInRound) {
      console.log("Not all matches in this round are completed yet");
      return;
    }

    // Determine winners from completed matches
    const winners = completedMatches
      .map((match) => {
        // Determine winner based on scores
        if (match.homeScore > match.awayScore) {
          return match.homeTeamId;
        } else if (match.awayScore > match.homeScore) {
          return match.awayTeamId;
        } else {
          // Handle draws - if penalties exist
          if (match.homePenalty !== null && match.awayPenalty !== null) {
            return match.homePenalty > match.awayPenalty
              ? match.homeTeamId
              : match.awayTeamId;
          }
          // If no penalties and draw, return null (should not happen in knockout)
          return null;
        }
      })
      .filter((winner) => winner !== null);

    console.log(`Winners: ${winners.length} teams advancing`);

    if (winners.length < 2) {
      console.log("Not enough winners to create next round");
      return;
    }

    // Determine next round name
    const nextRound = getNextRound(currentRound);
    if (!nextRound) {
      console.log("No next round available");
      return;
    }

    // Calculate next match date (day after last match)
    const lastMatchDate = new Date(
      Math.max(...completedMatches.map((m) => new Date(m.matchDate))),
    );
    const nextMatchDate = new Date(
      lastMatchDate.getTime() + 24 * 60 * 60 * 1000,
    );

    // Pair up winners for next round
    const nextRoundMatches = [];
    for (let i = 0; i < winners.length; i += 2) {
      if (i + 1 < winners.length) {
        nextRoundMatches.push({
          tournamentId: parseInt(tournamentId),
          homeTeamId: winners[i],
          awayTeamId: winners[i + 1],
          matchDate: new Date(
            nextMatchDate.getTime() + (i / 2) * 24 * 60 * 60 * 1000,
          ),
          round: nextRound,
          status: "SCHEDULED",
        });
      } else {
        // Odd number of teams - this team gets a bye to next round
        console.log(
          `Team ${winners[i]} gets a bye to ${getNextRound(nextRound)}`,
        );

        // Create a bye entry or handle specially
        // For now, we'll create a placeholder match or handle in next round
        // You might want to store this team as automatic qualifier
      }
    }

    if (nextRoundMatches.length > 0) {
      // Create next round matches
      await prisma.match.createMany({
        data: nextRoundMatches,
      });
      console.log(
        `Created ${nextRoundMatches.length} matches for ${nextRound}`,
      );
    }

    // Check if this was the final round
    if (nextRound === "FINAL" && nextRoundMatches.length === 1) {
      console.log("Final round created - tournament will complete after this");
    }
  } catch (error) {
    console.error("Error generating next round matches:", error);
  }
};

const getNextRound = (currentRound) => {
  const roundProgression = {
    ROUND_OF_16: "QUARTER_FINAL",
    QUARTER_FINAL: "SEMI_FINAL",
    SEMI_FINAL: "FINAL",
    FINAL: null,
  };

  return roundProgression[currentRound] || null;
};

/**
 * Update match status
 * @route   PATCH /api/matches/:matchId/status
 */
export const updateMatchStatus = async (req, res) => {
  try {
    const { matchId } = req.params;
    const { status } = req.body;

    const validStatuses = ["SCHEDULED", "ONGOING", "COMPLETED", "CANCELLED"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        status: "error",
        message: "Invalid status",
      });
    }

    const match = await prisma.match.update({
      where: { id: parseInt(matchId) },
      data: { status },
    });

    res.json({
      status: "success",
      message: "Match status updated",
      match,
    });
  } catch (error) {
    console.error("Update match status error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};

// ============================================
// TOURNAMENT STATISTICS
// ============================================

/**
 * Get tournament standings/leaderboard
 * @route   GET /api/tournaments/:tournamentId/standings
 */
export const getTournamentStandings = async (req, res) => {
  try {
    const { tournamentId } = req.params;

    const tournament = await prisma.tournament.findUnique({
      where: { id: parseInt(tournamentId) },
      include: {
        teams: {
          include: {
            homeMatches: {
              where: { status: "COMPLETED" },
            },
            awayMatches: {
              where: { status: "COMPLETED" },
            },
          },
        },
      },
    });

    if (!tournament) {
      return res.status(404).json({
        status: "error",
        message: "Tournament not found",
      });
    }

    // Calculate standings
    const standings = tournament.teams.map((team) => {
      const allMatches = [...team.homeMatches, ...team.awayMatches];
      const wins = allMatches.filter(
        (m) =>
          (m.homeTeamId === team.id && m.homeScore > m.awayScore) ||
          (m.awayTeamId === team.id && m.awayScore > m.homeScore),
      ).length;

      const draws = allMatches.filter(
        (m) => m.homeScore === m.awayScore,
      ).length;
      const losses = allMatches.length - wins - draws;
      const goalsFor = allMatches.reduce(
        (sum, m) =>
          sum + (m.homeTeamId === team.id ? m.homeScore : m.awayScore),
        0,
      );
      const goalsAgainst = allMatches.reduce(
        (sum, m) =>
          sum + (m.homeTeamId === team.id ? m.awayScore : m.homeScore),
        0,
      );

      return {
        teamId: team.id,
        teamName: team.name,
        played: allMatches.length,
        wins,
        draws,
        losses,
        goalsFor,
        goalsAgainst,
        goalDifference: goalsFor - goalsAgainst,
        points: wins * 3 + draws,
      };
    });

    // Sort by points, then goal difference, then goals for
    standings.sort((a, b) => {
      if (a.points !== b.points) return b.points - a.points;
      if (a.goalDifference !== b.goalDifference)
        return b.goalDifference - a.goalDifference;
      return b.goalsFor - a.goalsFor;
    });

    res.json({
      status: "success",
      standings,
    });
  } catch (error) {
    console.error("Get standings error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error",
    });
  }
};
