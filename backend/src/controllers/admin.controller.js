import { prisma } from "../index.js";

/**
 * Get Admin Dashboard Stats
 */
export const getDashboardStats = async (req, res, next) => {
  try {
    const totalUsers = await prisma.user.count();

    const totalFutsals = await prisma.futsal.count({
      where: { status: 'ACTIVE' },
    });

    const pendingFutsals = await prisma.futsal.count({
      where: { status: 'PENDING' },
    });

    const totalBookings = await prisma.booking.count();

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayBookings = await prisma.booking.count({
      where: {
        bookingDate: {
          gte: today,
          lt: tomorrow,
        },
      },
    });

    const revenue = await prisma.booking.aggregate({
      _sum: { totalPrice: true },
      where: {
        status: { in: ["CONFIRMED", "COMPLETED"] },
      },
    });
    
    const recentBookings = await prisma.booking.findMany({
      orderBy: { bookingDate: "desc" },
      take: 5,
      include: {
        user: { select: { fullName: true } },
        slot: { include: { court: true } },
      },
    });

    res.json({
      status: "success",
      data: {
        totalUsers,
        totalFutsals,
        pendingFutsals,
        totalBookings,
        todayBookings,
        totalRevenue: revenue._sum.totalPrice || 0,
        recentActivities: recentBookings,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get All Users
 */
export const getUsers = async (req, res, next) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: {
        createdAt: "desc",
      },
    });

    res.json({
      status: "success",
      data: users,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Approve Owner Account
 */
export const approveOwner = async (req, res, next) => {
  try {
    const userId = parseInt(req.params.id);

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        isApproved: true,
      },
    });

    res.json({
      status: "success",
      message: "Owner approved successfully",
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Pending Futsals
 */
export const getPendingFutsals = async (req, res, next) => {
  try {
    const futsals = await prisma.futsal.findMany({
      where: { status: 'PENDING' },
      include: {
        owner: {
          select: { id: true, fullName: true, email: true, phoneNumber: true },
        },
        courts: {
          select: {
            id: true,
            courtNumber: true,
            courtType: true,
            basePrice: true,
            peakPrice: true,
            amenities: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    res.json({ status: "success", data: futsals });
  } catch (error) {
    next(error);
  }
};

/**
 * Approve Futsal
 */
export const approveFutsal = async (req, res, next) => {
  try {
    const futsalId = parseInt(req.params.id);

    const futsal = await prisma.futsal.update({
      where: { id: futsalId },
      data: {
        isApproved: true,
        status: 'ACTIVE',
      },
    });

    res.json({
      status: "success",
      message: "Futsal approved successfully",
      data: futsal,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Reject Futsal
 */
export const rejectFutsal = async (req, res, next) => {
  try {
    const futsalId = parseInt(req.params.id);

    await prisma.futsal.delete({
      where: { id: futsalId },
    });

    res.json({
      status: "success",
      message: "Futsal rejected and removed",
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get All Futsals (for admin)
 */
export const getAllFutsals = async (req, res, next) => {
  try {
    const futsals = await prisma.futsal.findMany({
      include: {
        owner: { select: { id: true, fullName: true, email: true } },
        courts: {
          select: {
            id: true,
            courtNumber: true,
            courtType: true,
            basePrice: true,
            isActive: true,
          },
        },
        _count: {
          select: { courts: true },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    // Add court count to each futsal
    const futsalsWithCount = futsals.map(futsal => ({
      ...futsal,
      courtCount: futsal._count?.courts || 0,
    }));

    res.json({ status: "success", data: futsalsWithCount });
  } catch (error) {
    next(error);
  }
};

/**
 * Toggle User Active Status
 */
export const toggleUserStatus = async (req, res, next) => {
  try {
    const userId = parseInt(req.params.id);
    const { isActive } = req.body;

    const user = await prisma.user.update({
      where: { id: userId },
      data: { isActive },
    });

    res.json({ status: "success", data: user });
  } catch (error) {
    next(error);
  }
};

/**
 * Generate Report
 */
export const generateReport = async (req, res, next) => {
  try {
    const { type, from, to } = req.query;
    const fromDate = new Date(from);
    const toDate = new Date(to);

    let data;
    if (type === "bookings") {
      data = await prisma.booking.findMany({
        where: { bookingDate: { gte: fromDate, lte: toDate } },
        include: {
          user: { select: { fullName: true, email: true } },
          slot: {
            include: {
              court: {
                include: { futsal: { select: { name: true } } }
              }
            }
          }
        },
      });
    } else if (type === "revenue") {
      data = await prisma.payment.findMany({
        where: {
          createdAt: { gte: fromDate, lte: toDate },
          status: "COMPLETED",
        },
        include: {
          booking: {
            include: {
              slot: {
                include: {
                  court: {
                    include: { futsal: { select: { name: true } } }
                  }
                }
              }
            }
          }
        },
      });
    }

    res.json({ status: "success", data });
  } catch (error) {
    next(error);
  }
};

/**
 * Get All Bookings
 */
export const getAllBookings = async (req, res, next) => {
  try {
    const { status, from, to, page = 1, limit = 20 } = req.query;

    const where = {};

    if (status && status !== 'ALL') {
      where.status = status;
    }

    if (from && to) {
      where.slot = {
        date: {
          gte: new Date(from),
          lte: new Date(to),
        },
      };
    }

    const total = await prisma.booking.count({ where });

    const bookings = await prisma.booking.findMany({
      where,
      include: {
        user: { select: { id: true, fullName: true, email: true } },
        slot: {
          include: {
            court: {
              include: {
                futsal: { select: { id: true, name: true } },
              },
            },
          },
        },
        payment: true,
      },
      orderBy: { bookingDate: 'desc' },
      skip: (parseInt(page) - 1) * parseInt(limit),
      take: parseInt(limit),
    });

    const formatted = bookings.map(b => ({
      id: b.id,
      playerName: b.user.fullName,
      playerEmail: b.user.email,
      futsalName: b.slot.court.futsal.name,
      courtNumber: b.slot.court.courtNumber,
      date: b.slot.date,
      startTime: b.slot.startTime,
      endTime: b.slot.endTime,
      totalPrice: b.totalPrice,
      paymentMethod: b.paymentMethod,
      paymentStatus: b.payment?.status ?? 'PENDING',
      bookingStatus: b.status,
      bookingDate: b.bookingDate,
    }));

    res.json({
      status: 'success',
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit)),
      bookings: formatted,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Admin Analytics
 */
export const getAdminAnalytics = async (req, res, next) => {
  try {
    // Last 7 days revenue
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
          slot: { date: { gte: date, lt: nextDate } },
          status: { in: ['CONFIRMED', 'COMPLETED'] },
        },
        _sum: { totalPrice: true },
      });

      weeklyRevenue.push(revenue._sum.totalPrice || 0);
    }

    // Bookings by status
    const bookingsByStatus = await prisma.booking.groupBy({
      by: ['status'],
      _count: { status: true },
    });

    // Top futsals by bookings
    const topFutsalsData = await prisma.booking.groupBy({
      by: ['slotId'],
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 5,
    });

    // Get futsal names for top bookings
    const topFutsals = await Promise.all(
      topFutsalsData.map(async (item) => {
        const slot = await prisma.timeSlot.findUnique({
          where: { id: item.slotId },
          include: {
            court: {
              include: { futsal: { select: { name: true } } }
            }
          }
        });
        return {
          futsalName: slot?.court?.futsal?.name || 'Unknown',
          bookings: item._count.id,
        };
      })
    );

    // Total stats
    const totalBookings = await prisma.booking.count();
    const totalRevenue = await prisma.booking.aggregate({
      _sum: { totalPrice: true },
      where: { status: { in: ['CONFIRMED', 'COMPLETED'] } },
    });
    const activeUsers = await prisma.user.count({
      where: { isActive: true },
    });

    res.json({
      status: 'success',
      weeklyRevenue,
      bookingsByStatus,
      topFutsals,
      totalBookings,
      totalRevenue: totalRevenue._sum.totalPrice || 0,
      activeUsers,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Admin Profile
 */
export const getAdminProfile = async (req, res, next) => {
  try {
    const adminId = req.user.id;

    const admin = await prisma.user.findUnique({
      where: { id: adminId },
      select: {
        id: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        role: true,
        createdAt: true,
        // Remove profileImage
      },
    });

    if (!admin) {
      return res.status(404).json({
        status: 'error',
        message: 'Admin not found',
      });
    }

    res.json({
      status: 'success',
      data: admin,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update Admin Profile
 */
export const updateAdminProfile = async (req, res, next) => {
  try {
    const adminId = req.user.id;
    const { fullName, phoneNumber } = req.body;

    // Update only provided fields
    const updateData = {};
    if (fullName !== undefined) updateData.fullName = fullName;
    if (phoneNumber !== undefined) updateData.phoneNumber = phoneNumber;

    const updatedAdmin = await prisma.user.update({
      where: { id: adminId },
      data: updateData,
      select: {
        id: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        role: true,
        createdAt: true,
      },
    });

    res.json({
      status: 'success',
      message: 'Profile updated successfully',
      data: updatedAdmin,
    });
  } catch (error) {
    console.error('❌ Update Profile Error:', error);
    next(error);
  }
};
