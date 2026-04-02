import { prisma } from "../index.js";

/**
 * Get dashboard statistics for an owner's futsal
 * @route   GET /api/owner/dashboard/stats?futsalId=:id
 */
export const getDashboardStats = async (req, res) => {
  try {
    const { futsalId } = req.query;

    if (!futsalId) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID",
      });
    }

    // Verify the futsal belongs to this owner
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

    // Get total courts
    const totalCourts = await prisma.court.count({
      where: { futsalId: parseInt(futsalId) },
    });

    // Get today's bookings
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayBookings = await prisma.booking.count({
      where: {
        slot: {
          date: { gte: today, lt: tomorrow }, // ← slot date only
          court: {
            futsalId: parseInt(futsalId),
          },
        },
        status: { in: ["CONFIRMED", "PENDING", "COMPLETED"] },
      },
    });

    // Get today's revenue
    const todayRevenue = await prisma.booking.aggregate({
      where: {
        slot: {
          date: { gte: today, lt: tomorrow }, // ← slot date only
          court: {
            futsalId: parseInt(futsalId),
          },
        },
        status: { in: ["CONFIRMED", "COMPLETED"] },
      },
      _sum: {
        totalPrice: true,
      },
    });

    // Get pending approvals (for futsal itself)
    const pendingApprovals = futsal.isApproved ? 0 : 1;

    res.json({
      status: "success",
      totalCourts,
      todayBookings,
      todayRevenue: todayRevenue._sum?.totalPrice || 0,
      pendingApprovals,
    });
  } catch (error) {
    console.error("Get dashboard stats error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get today's bookings list for owner dashboard
 * @route   GET /api/owner/dashboard/today-bookings?futsalId=:id
 */
export const getTodayBookings = async (req, res) => {
  try {
    const { futsalId } = req.query;
    if (!futsalId)
      return res
        .status(400)
        .json({ status: "error", message: "Please provide futsal ID" });

    const futsal = await prisma.futsal.findFirst({
      where: { id: parseInt(futsalId), ownerId: req.user.id },
    });
    if (!futsal)
      return res
        .status(404)
        .json({ status: "error", message: "Futsal not found" });

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          date: { gte: today, lt: tomorrow }, // ✅ filter by slot date
          court: { futsalId: parseInt(futsalId) },
        },
        status: { notIn: ["CANCELLED"] }, // ✅ show all non-cancelled
      },
      include: {
        user: { select: { id: true, fullName: true, phoneNumber: true } },
        slot: { include: { court: { select: { courtNumber: true } } } },
        payment: true,
      },
      orderBy: { slot: { startTime: "asc" } },
    });

    const formattedBookings = bookings.map((booking) => ({
      id: booking.id,
      futsalId: parseInt(futsalId),
      userId: booking.user.id,
      customerName: booking.user.fullName,
      customerPhone: booking.user.phoneNumber,
      courtNumber: booking.slot.court.courtNumber,
      date: booking.slot.date, // ✅ slot date not booking date
      startTime: booking.slot.startTime,
      endTime: booking.slot.endTime,
      totalAmount: booking.totalPrice,
      paymentMethod: booking.paymentMethod, // ✅ so owner knows COD vs Khalti
      paymentStatus: booking.payment?.status ?? "PENDING",
      bookingStatus: booking.status,
      checkInTime: booking.checkInTime,
      checkOutTime: booking.checkOutTime,
    }));

    res.json({ status: "success", bookings: formattedBookings });
  } catch (error) {
    console.error("Get today bookings error:", error);
    res
      .status(500)
      .json({ status: "error", message: "Server error: " + error.message });
  }
};
/**
 * Get weekly revenue data for charts
 * @route   GET /api/owner/dashboard/weekly-revenue?futsalId=:id
 */
export const getWeeklyRevenue = async (req, res) => {
  try {
    const { futsalId } = req.query;

    if (!futsalId) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID",
      });
    }

    // Verify ownership
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

    // Get last 7 days
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const weeklyRevenue = [];

    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);

      const revenue = await prisma.booking.aggregate({
        where: {
          slot: {
            date: {
              // ← filter by slot date not booking date
              gte: date,
              lt: nextDate,
            },
            court: {
              futsalId: parseInt(futsalId),
            },
          },
          status: { in: ["CONFIRMED", "COMPLETED"] }, // ← include COMPLETED too
        },
        _sum: {
          totalPrice: true,
        },
      });
      weeklyRevenue.push(revenue._sum?.totalPrice || 0);
    }

    res.json({
      status: "success",
      revenue: weeklyRevenue,
    });
  } catch (error) {
    console.error("Get weekly revenue error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get peak hours analysis
 * @route   GET /api/owner/dashboard/peak-hours?futsalId=:id
 */
export const getPeakHours = async (req, res) => {
  try {
    const { futsalId } = req.query;

    if (!futsalId) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID",
      });
    }

    // Verify ownership
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

    // Get all confirmed bookings for this futsal
    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          court: {
            futsalId: parseInt(futsalId),
          },
        },
        status: { in: ['CONFIRMED', 'COMPLETED'] }
      },
      include: {
        slot: {
          select: {
            startTime: true,
          },
        },
      },
    });

    // Count bookings by hour
    const peakHours = {};

    bookings.forEach((booking) => {
      const hour = booking.slot.startTime.split(":")[0] + ":00";
      peakHours[hour] = (peakHours[hour] || 0) + 1;
    });

    res.json({
      status: "success",
      peakHours,
    });
  } catch (error) {
    console.error("Get peak hours error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get upcoming bookings for owner
 * @route   GET /api/owner/bookings/upcoming?futsalId=:id
 */
export const getOwnerUpcomingBookings = async (req, res) => {
  try {
    const { futsalId } = req.query;

    if (!futsalId) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID",
      });
    }

    // Verify ownership
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

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1); // ✅ add this

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          date: { gte: tomorrow }, // ✅ strictly future, not today
          court: { futsalId: parseInt(futsalId) },
        },
        status: { in: ["CONFIRMED", "PENDING"] },
      },
      include: {
        user: {
          select: {
            id: true,
            fullName: true,
            phoneNumber: true,
          },
        },
        slot: {
          include: {
            court: {
              select: {
                courtNumber: true,
              },
            },
          },
        },
        payment: true,
      },
      orderBy: [{ bookingDate: "asc" }, { slot: { startTime: "asc" } }],
    });

    const formattedBookings = bookings.map((booking) => ({
      id: booking.id,
      userId: booking.user.id,
      customerName: booking.user.fullName,
      customerPhone: booking.user.phoneNumber,
      courtNumber: booking.slot.court.courtNumber,
      date: booking.slot.date,
      startTime: booking.slot.startTime,
      endTime: booking.slot.endTime,
      totalAmount: booking.totalPrice,
      paymentMethod: booking.paymentMethod,
      paymentStatus: booking.payment?.status || "PENDING",
      bookingStatus: booking.status,
    }));

    res.json({
      status: "success",
      bookings: formattedBookings,
    });
  } catch (error) {
    console.error("Get upcoming bookings error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get month bookings for calendar view
 * @route   GET /api/owner/bookings/month?futsalId=:id&year=:year&month=:month
 */
export const getMonthBookings = async (req, res) => {
  try {
    const { futsalId, year, month } = req.query;

    if (!futsalId || !year || !month) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID, year, and month",
      });
    }

    // Verify ownership
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

    const startDate = new Date(parseInt(year), parseInt(month) - 1, 1);
    const endDate = new Date(parseInt(year), parseInt(month), 0);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          date: { gte: startDate, lte: endDate },
          court: { futsalId: parseInt(futsalId) },
        },
      },
      include: {
        user: {
          select: {
            fullName: true,
          },
        },
        slot: {
          include: {
            court: {
              select: {
                courtNumber: true,
              },
            },
          },
        },
      },
      orderBy: {
        bookingDate: "asc",
      },
    });

    const formattedBookings = bookings.map((booking) => ({
      id: booking.id,
      customerName: booking.user.fullName,
      courtNumber: booking.slot.court.courtNumber,
      date: booking.slot.date,
      startTime: booking.slot.startTime,
      endTime: booking.slot.endTime,
      totalAmount: booking.totalPrice,
      status: booking.status,
    }));

    res.json({
      status: "success",
      bookings: formattedBookings,
    });
  } catch (error) {
    console.error("Get month bookings error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};
