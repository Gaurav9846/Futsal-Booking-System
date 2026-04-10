import { prisma } from "../index.js";
import axios from "axios";
import { BookingStatus } from "@prisma/client"; // ✅ ADD THIS

// ============================================
// BOOKING CREATION
// ============================================

/**
 * Create a new booking
 */
export const createBooking = async (req, res) => {
  try {
    const { slotId, duration = 1, paymentMethod = "COD" } = req.body;

    if (!slotId) {
      return res
        .status(400)
        .json({ status: "error", message: "Slot ID is required" });
    }

    const result = await prisma.$transaction(async (tx) => {
      // 1. Find the starting slot
      const startSlot = await tx.timeSlot.findUnique({
        where: { id: parseInt(slotId) },
        include: { court: { include: { futsal: true } } },
      });

      if (!startSlot) throw new Error("Slot not found");
      if (
        startSlot.status !== "LOCKED" ||
        !startSlot.lockedUntil ||
        startSlot.lockedUntil < new Date()
      ) {
        throw new Error("Slot lock expired");
      }

      const futsalId = startSlot.court.futsalId;
      const isBlocked = await tx.block.findFirst({
        where: {
          playerId: req.user.id,
          futsalId: futsalId,
        },
      });

      if (isBlocked) {
        await tx.timeSlot.update({
          where: { id: parseInt(slotId) },
          data: { status: "AVAILABLE", lockedUntil: null },
        });
        throw new Error("You are blocked from booking at this futsal");
      }

      // 2. Find consecutive slots if duration > 1
      let allSlots = [startSlot];

      if (duration > 1) {
        const startHour = parseInt(startSlot.startTime.split(":")[0]);
        const consecutiveSlots = await tx.timeSlot.findMany({
          where: {
            courtId: startSlot.courtId,
            date: startSlot.date,
            startTime: {
              in: Array.from(
                { length: duration - 1 },
                (_, i) => `${String(startHour + i + 1).padStart(2, "0")}:00`,
              ),
            },
            status: "AVAILABLE",
          },
          orderBy: { startTime: "asc" },
        });

        if (consecutiveSlots.length < duration - 1) {
          throw new Error("Not enough consecutive slots available");
        }

        allSlots = [startSlot, ...consecutiveSlots];

        await tx.timeSlot.updateMany({
          where: { id: { in: consecutiveSlots.map((s) => s.id) } },
          data: {
            status: "LOCKED",
            lockedUntil: new Date(Date.now() + 5 * 60000),
          },
        });
      }

      // 3. Check no active booking exists
      const activeBooking = await tx.booking.findFirst({
        where: {
          slotId: { in: allSlots.map((s) => s.id) },
          status: { in: ["PENDING", "CONFIRMED"] }, // ✅ Changed
        },
      });
      if (activeBooking) throw new Error("One or more slots already booked");
      if (activeBooking) throw new Error("One or more slots already booked");

      // 4. Calculate total price
      const totalPrice = allSlots.reduce((sum, s) => sum + s.price, 0);

      // 5. Group ID ties multi-slot bookings together
      const groupId = `GRP_${req.user.id}_${Date.now()}`;

      // 6. Create one booking per slot
      const bookings = await Promise.all(
        allSlots.map((slot) =>
          tx.booking.create({
            data: {
              userId: req.user.id,
              slotId: slot.id,
              totalPrice: slot.price,
              duration: duration,
              paymentMethod: paymentMethod,
              groupId: groupId,
              status: "PENDING", // ✅ Changed from "PENDING" to "UNCONFIRMED"
            },
            include: {
              slot: { include: { court: { include: { futsal: true } } } },
            },
          }),
        ),
      );

      // 7. Mark all slots as BOOKED
      await tx.timeSlot.updateMany({
        where: { id: { in: allSlots.map((s) => s.id) } },
        data: { status: "BOOKED", lockedUntil: null },
      });

      return {
        bookings,
        groupId,
        totalPrice,
        primaryBooking: bookings[0],
      };
    });

    res.status(201).json({
      status: "success",
      booking: result.primaryBooking,
      bookingId: result.primaryBooking.id,
      groupId: result.groupId,
      totalPrice: result.totalPrice,
      slotCount: result.bookings.length,
    });
  } catch (error) {
    console.error("❌ CREATE BOOKING ERROR:", error);
    res.status(400).json({ status: "error", message: error.message });
  }
};

/**
 * Owner confirms COD payment AND completes booking
 */
export const confirmCodPayment = async (req, res) => {
  try {
    const { bookingId } = req.params;
    
    console.log("🔵 COD PAYMENT - Booking ID:", bookingId);

    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(bookingId) },
      include: {
        payment: true,
        slot: { include: { court: { include: { futsal: true } } } },
      },
    });

    console.log("🔵 Booking status:", booking.status);
    console.log("🔵 Booking payment:", booking.payment);

    if (!booking) {
      return res.status(404).json({ status: "error", message: "Booking not found" });
    }

    if (booking.slot.court.futsal.ownerId !== req.user.id) {
      return res.status(403).json({ status: "error", message: "Unauthorized" });
    }

    // Check if already completed
    if (booking.status === "COMPLETED") {
      console.log("❌ Booking already COMPLETED");
      return res.status(400).json({
        status: "error",
        message: "Booking already completed",
      });
    }

    // Update payment and booking
    await prisma.$transaction(async (tx) => {
      if (booking.payment) {
        await tx.payment.update({
          where: { bookingId: booking.id },
          data: { status: "COMPLETED" },
        });
      } else {
        await tx.payment.create({
          data: {
            bookingId: booking.id,
            amount: booking.totalPrice,
            method: "COD",
            status: "COMPLETED",
            transactionId: `COD_${booking.id}_${Date.now()}`,
          },
        });
      }

      await tx.booking.update({
        where: { id: parseInt(bookingId) },
        data: {
          status: "COMPLETED",
          checkOutTime: new Date(),
        },
      });
    });

    console.log("✅ COD payment successful for booking:", bookingId);

    res.json({
      status: "success",
      message: "Payment confirmed and booking completed",
    });
  } catch (error) {
    console.error("COD confirm error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

// ============================================
// GET BOOKINGS
// ============================================

/**
 * Get current user's bookings
 */
export const getUserBookings = async (req, res) => {
  try {
    const bookings = await prisma.booking.findMany({
      where: { userId: req.user.id },
      include: {
        slot: { include: { court: { include: { futsal: true } } } },
        payment: true,
      },
      orderBy: { bookingDate: "desc" },
    });

    res.json({
      status: "success",
      results: bookings.length,
      bookings,
    });
  } catch (error) {
    console.error("Get user bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

/**
 * Get booking by ID
 */
export const getBookingById = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const booking = await prisma.booking.findFirst({
      where: { id: parseInt(bookingId), userId: req.user.id },
      include: {
        slot: { include: { court: { include: { futsal: true } } } },
        payment: true,
      },
    });

    if (!booking)
      return res
        .status(404)
        .json({ status: "error", message: "Booking not found" });

    res.json({ status: "success", booking });
  } catch (error) {
    console.error("Get booking by ID error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

// ============================================
// CANCEL BOOKINGS
// ============================================

/**
 * User cancels booking
 */
export const userCancelBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(bookingId) },
      include: { payment: true },
    });

    if (!booking)
      return res
        .status(404)
        .json({ status: "error", message: "Booking not found" });
    if (booking.userId !== req.user.id)
      return res.status(403).json({ status: "error", message: "Unauthorized" });

    const groupBookings = booking.groupId
      ? await prisma.booking.findMany({ where: { groupId: booking.groupId } })
      : [booking];

    await prisma.$transaction(async (tx) => {
      await tx.booking.updateMany({
        where: { id: { in: groupBookings.map((b) => b.id) } },
        data: { status: "CANCELLED" },
      });
      await tx.timeSlot.updateMany({
        where: { id: { in: groupBookings.map((b) => b.slotId) } },
        data: { status: "AVAILABLE", lockedUntil: null },
      });
    });

    res.json({ status: "success", message: "Booking cancelled successfully" });
  } catch (error) {
    console.error("Cancel booking error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

// ============================================
// OWNER BOOKING ACTIONS
// ============================================

/**
 * Owner checks in a customer
 */
export const checkInBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(bookingId) },
      include: {
        slot: { include: { court: { include: { futsal: true } } } },
        payment: true,
      },
    });

    if (!booking)
      return res
        .status(404)
        .json({ status: "error", message: "Booking not found" });

    if (booking.slot.court.futsal.ownerId !== req.user.id)
      return res.status(403).json({ status: "error", message: "Unauthorized" });

    if (booking.status === "CANCELLED")
      return res.status(400).json({
        status: "error",
        message: "Cannot check in a cancelled booking",
      });

    // ✅ Prevent multiple check-ins
    if (booking.checkInTime) {
      return res.status(400).json({
        status: "error",
        message: "Already checked in",
      });
    }

    // Determine final status
    const isKhalti = booking.paymentMethod === "KHALTI";
    const isPaid = booking.payment?.status === "COMPLETED";
    
    // If Khalti and paid, mark as COMPLETED; otherwise CONFIRMED
    const newStatus = (isKhalti && isPaid) ? "COMPLETED" : "CONFIRMED";

    const updated = await prisma.booking.update({
      where: { id: parseInt(bookingId) },
      data: {
        status: newStatus,
        checkInTime: new Date(),
      },
    });

    res.json({
      status: "success",
      message: "Customer checked in",
      booking: updated,
    });
  } catch (error) {
    console.error("Check in error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

/**
 * Owner cancels booking
 */
export const ownerCancelBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(bookingId) },
      include: {
        slot: { include: { court: { include: { futsal: true } } } },
      },
    });

    if (!booking)
      return res
        .status(404)
        .json({ status: "error", message: "Booking not found" });

    if (booking.slot.court.futsal.ownerId !== req.user.id)
      return res.status(403).json({ status: "error", message: "Unauthorized" });

    const groupBookings = booking.groupId
      ? await prisma.booking.findMany({ where: { groupId: booking.groupId } })
      : [booking];

    await prisma.$transaction(async (tx) => {
      await tx.booking.updateMany({
        where: { id: { in: groupBookings.map((b) => b.id) } },
        data: { status: "CANCELLED" },
      });
      await tx.timeSlot.updateMany({
        where: { id: { in: groupBookings.map((b) => b.slotId) } },
        data: { status: "AVAILABLE", lockedUntil: null },
      });
    });

    res.json({ status: "success", message: "Booking cancelled successfully" });
  } catch (error) {
    console.error("Owner cancel error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

// ============================================
// KHALTI PAYMENT METHODS (Aligned with working payment.controller.js)
// ============================================

/**
 * Initiate Khalti Payment
 * @route POST /api/bookings/:bookingId/payment/initiate
 */
export const initiatePayment = async (req, res) => {
  const { bookingId, paymentMethod } = req.body;
  const userId = req.user.id;

  console.log("🔵 INITIATE PAYMENT CALLED:", {
    bookingId,
    paymentMethod,
    userId,
  });

  try {
    const booking = await prisma.booking.findFirst({
      where: { id: parseInt(bookingId), userId },
      include: {
        payment: true,
        slot: { include: { court: { include: { futsal: true } } } },
      },
    });

    console.log(
      "🔵 BOOKING FOUND:",
      booking
        ? {
            id: booking.id,
            status: booking.status,
            totalPrice: booking.totalPrice,
          }
        : "NOT FOUND",
    );

    if (!booking) return res.status(404).json({ message: "Booking not found" });
    if (booking.status !== "PENDING")
      return res
        .status(400)
        .json({ message: "Booking already confirmed or cancelled" });

    const existingPayment = await prisma.payment.findFirst({
      where: { bookingId: booking.id, status: "PENDING" },
    });
    if (existingPayment) return res.json({ payment: existingPayment });

    // Khalti Payment
    if (paymentMethod === "KHALTI") {
      const amountInPaisa = Math.round(booking.totalPrice * 100);
      console.log("🔵 KHALTI AMOUNT IN PAISA:", amountInPaisa);
      console.log(
        "🔵 KHALTI SECRET KEY:",
        process.env.KHALTI_SECRET_KEY ? "Present" : "MISSING!",
      );

      const payload = {
        return_url: `${process.env.BACKEND_URL}/api/bookings/payment/callback`, // ✅ Change this
        purchase_order_id: `BOOKING_${booking.id}`,
        purchase_order_name: `${booking.slot.court.futsal.name} - Booking (${booking.slot.startTime})`,
        amount: amountInPaisa,
        website_url: process.env.FRONTEND_URL,
        customer_info: {
          name: req.user.fullName || req.user.email,
          email: req.user.email,
          phone: req.user.phoneNumber || "9800000000",
        },
      };

      console.log("🔵 KHALTI PAYLOAD:", JSON.stringify(payload, null, 2));

      try {
        const resp = await axios.post(
          "https://dev.khalti.com/api/v2/epayment/initiate/",
          payload,
          {
            headers: {
              Authorization: `Key ${process.env.KHALTI_SECRET_KEY}`,
              "Content-Type": "application/json",
            },
          },
        );

        console.log("🔵 KHALTI RESPONSE:", resp.data);

        if (!resp.data?.pidx || !resp.data?.payment_url) {
          console.log("❌ Invalid Khalti response:", resp.data);
          return res
            .status(400)
            .json({ message: "Invalid Khalti response", details: resp.data });
        }

        const payment = await prisma.payment.create({
          data: {
            bookingId: booking.id,
            amount: booking.totalPrice,
            method: "KHALTI",
            status: "PENDING",
            transactionId: resp.data.pidx,
          },
        });

        return res.json({ paymentUrl: resp.data.payment_url, payment });
      } catch (khaltiError) {
        console.error("❌ KHALTI API ERROR:", {
          message: khaltiError.message,
          response: khaltiError.response?.data,
          status: khaltiError.response?.status,
          headers: khaltiError.response?.headers,
        });
        return res.status(500).json({
          message: "Khalti payment initiation failed",
          error: khaltiError.response?.data || khaltiError.message,
        });
      }
    }

    // Cash on Delivery (COD)
    if (paymentMethod === "COD") {
      const [payment] = await prisma.$transaction([
        prisma.payment.create({
          data: {
            bookingId: booking.id,
            amount: booking.totalPrice,
            method: "COD",
            status: "COMPLETED",
          },
        }),
        prisma.booking.update({
          where: { id: booking.id },
          data: { status: "CONFIRMED" },
        }),
      ]);

      return res.json({ message: "Booking placed successfully", payment });
    }

    return res.status(400).json({ message: "Unsupported payment method" });
  } catch (error) {
    console.error("❌ GENERAL ERROR:", error);
    return res
      .status(500)
      .json({ message: "Server error", error: error.message });
  }
};

/**
 * Verify Khalti Payment
 * @route POST /api/payments/verify
 */
export const verifyPayment = async (req, res) => {
  const { pidx } = req.body;

  try {
    console.log("🔵 VERIFY PAYMENT CALLED with pidx:", pidx);

    // 1. Find payment record
    const payment = await prisma.payment.findFirst({
      where: { transactionId: pidx },
      include: { booking: true },
    });

    if (!payment) {
      console.log("❌ Payment not found for pidx:", pidx);
      return res.status(404).json({ message: "Payment not found" });
    }

    console.log("🔵 Found payment:", {
      id: payment.id,
      status: payment.status,
      bookingId: payment.bookingId,
    });

    // 2. If already completed, return success
    if (payment.status === "COMPLETED") {
      console.log("✅ Payment already completed");
      return res.json({
        success: true,
        message: "Payment already verified",
        bookingId: payment.bookingId,
      });
    }

    // 3. Verify with Khalti
    const response = await axios.post(
      "https://a.khalti.com/api/v2/epayment/lookup/",
      { pidx },
      { headers: { Authorization: `Key ${process.env.KHALTI_SECRET_KEY}` } }
    );

    console.log("🔵 Khalti lookup response:", response.data);

    const status = response.data.status?.toString().toLowerCase();
    const isSuccess = status === "completed" || status === "success";

    if (isSuccess) {
      console.log("✅ Payment successful, updating database...");

      const [updatedPayment, updatedBooking] = await prisma.$transaction([
        prisma.payment.update({
          where: { id: payment.id },
          data: {
            status: "COMPLETED",
            transactionId: response.data.transaction_id || payment.transactionId,
          },
        }),
        prisma.booking.update({
          where: { id: payment.bookingId },
          data: {
            status: "CONFIRMED",
            paymentStatus: "PAID",
          },
        }),
      ]);

      console.log("✅ Database updated:", {
        paymentStatus: updatedPayment.status,
        bookingStatus: updatedBooking.status,
      });

      return res.json({
        success: true,
        message: "Payment verified successfully",
        bookingId: updatedBooking.id,
      });
    } else {
      // ✅ PAYMENT FAILED - Convert to COD
      console.log("❌ Payment failed, converting to COD...");

      const [updatedPayment, updatedBooking] = await prisma.$transaction([
        // Update payment as FAILED
        prisma.payment.update({
          where: { id: payment.id },
          data: { status: "FAILED" },
        }),
        // Convert booking to COD (so owner can mark as paid later)
        prisma.booking.update({
          where: { id: payment.bookingId },
          data: {
            paymentMethod: "COD",  // ✅ Switch to COD
            status: "PENDING",     // ✅ Keep as PENDING (waiting for venue payment)
          },
        }),
      ]);

      console.log("✅ Booking converted to COD:", updatedBooking.id);

      return res.json({
        success: false,
        message: "Payment failed. Booking converted to COD. Please pay at venue.",
        bookingId: updatedBooking.id,
        convertedToCOD: true,
      });
    }
  } catch (error) {
    console.error("❌ Khalti lookup error:", error.response?.data || error);
    return res.status(400).json({
      success: false,
      message: error.response?.data?.message || "Payment verification failed",
    });
  }
};

/**
 * Khalti Payment Callback (Redirect URL)
 * @route GET /api/payments/callback
 */
export const paymentCallback = async (req, res) => {
  const { pidx, booking_id } = req.query;
  const frontendUrl = process.env.FRONTEND_URL || "http://localhost:3000";

  try {
    if (!pidx) {
      return res.redirect(
        `${frontendUrl}/payment-status?status=error&message=No payment ID received`,
      );
    }

    const response = await axios.post(
      "https://a.khalti.com/api/v2/epayment/lookup/",
      { pidx },
      { headers: { Authorization: `Key ${process.env.KHALTI_SECRET_KEY}` } }
    );

    const payment = await prisma.payment.findFirst({
      where: { transactionId: pidx },
    });
    if (!payment) {
      return res.redirect(
        `${frontendUrl}/payment-status?status=error&message=Payment not found`,
      );
    }

    const status = response.data.status?.toString().toLowerCase();
    const isSuccess = status === "completed" || status === "success";

    if (isSuccess && payment.status !== "COMPLETED") {
      await prisma.$transaction([
        prisma.payment.update({
          where: { id: payment.id },
          data: { status: "COMPLETED" },
        }),
        prisma.booking.update({
          where: { id: payment.bookingId },
          data: { status: "CONFIRMED" },
        }),
      ]);
      return res.redirect(
        `${frontendUrl}/payment-status?status=success&booking_id=${booking_id}`,
      );
    } else {
      // ✅ Payment failed - convert to COD
      await prisma.$transaction([
        prisma.payment.update({
          where: { id: payment.id },
          data: { status: "FAILED" },
        }),
        prisma.booking.update({
          where: { id: payment.bookingId },
          data: {
            paymentMethod: "COD",
            status: "PENDING",
          },
        }),
      ]);
      return res.redirect(
        `${frontendUrl}/payment-status?status=failed&converted_to_cod=true&booking_id=${booking_id}`,
      );
    }
  } catch (error) {
    console.error("Callback error:", error);
    return res.redirect(
      `${frontendUrl}/payment-status?status=error&message=${encodeURIComponent(error.message)}`,
    );
  }
};
// ============================================
// OWNER DASHBOARD METHODS
// ============================================

export const getOwnerTodayBookings = async (req, res) => {
  try {
    const { futsalId } = req.query;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          court: { futsalId: parseInt(futsalId) },
          date: today,
        },
      },
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: { slot: { startTime: "asc" } },
    });

    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get today bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

export const getOwnerUpcomingBookings = async (req, res) => {
  try {
    const { futsalId } = req.query;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          court: { futsalId: parseInt(futsalId) },
          date: { gte: today },
        },
        status: { not: "CANCELLED" },
      },
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: [{ slot: { date: "asc" } }, { slot: { startTime: "asc" } }],
    });

    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get upcoming bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

export const getOwnerMonthBookings = async (req, res) => {
  try {
    const { year, month } = req.params;
    const { futsalId } = req.query;
    const futsalIdInt = parseInt(futsalId);
    const yearInt = parseInt(year);
    const monthInt = parseInt(month);

    console.log("🔵 Month bookings request:", {
      futsalId: futsalIdInt,
      year: yearInt,
      month: monthInt,
    });

    // Create start and end dates for the month
    const startDate = new Date(yearInt, monthInt - 1, 1);
    startDate.setHours(0, 0, 0, 0);

    const endDate = new Date(yearInt, monthInt, 0); // Last day of month
    endDate.setHours(23, 59, 59, 999);

    console.log("🔵 Date range:", { startDate, endDate });

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          court: { futsalId: futsalIdInt },
          date: {
            gte: startDate,
            lte: endDate,
          },
        },
      },
      include: {
        slot: {
          include: {
            court: true,
          },
        },
        user: {
          select: {
            fullName: true,
            phoneNumber: true,
            email: true,
          },
        },
        payment: true,
      },
      orderBy: { slot: { date: "asc" } },
    });

    console.log("🔵 Found bookings count:", bookings.length);

    // Return as object with bookings array
    res.json({ bookings: bookings });
  } catch (error) {
    console.error("❌ Get month bookings error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

export const getOwnerBookings = async (req, res) => {
  try {
    const { futsalId, status, courtId, date } = req.query;

    const where = {
      slot: {
        court: { futsalId: parseInt(futsalId) },
      },
    };

    if (status) where.status = status;
    if (courtId) where.slot.courtId = parseInt(courtId);
    if (date) {
      const filterDate = new Date(date);
      filterDate.setHours(0, 0, 0, 0);
      where.slot.date = filterDate;
    }

    const bookings = await prisma.booking.findMany({
      where,
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: { bookingDate: "desc" },
    });

    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get owner bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};
