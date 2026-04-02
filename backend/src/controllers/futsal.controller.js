import { prisma } from '../index.js';

/**
 * Get all approved futsals
 */
export const getAllFutsals = async (req, res) => {
  try {
    const { lat, lng, radius } = req.query;
    
    let whereClause = { isApproved: true };
    
    // Add location-based filtering if coordinates provided (optional)
    if (lat && lng && radius) {
      whereClause = {
        ...whereClause,
        latitude: { not: null },
        longitude: { not: null }
      };
    }

    const futsals = await prisma.futsal.findMany({
      where: whereClause,
      include: {
        reviews: {
          select: { rating: true }
        },
        owner: {
          select: { fullName: true }
        },
        _count: {
          select: {
            courts: true,  // Changed from 'slots' to 'courts'
            reviews: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Calculate average rating for each futsal
    const futsalsWithRating = futsals.map(futsal => {
      const avgRating = futsal.reviews.length > 0
        ? futsal.reviews.reduce((sum, review) => sum + review.rating, 0) / futsal.reviews.length
        : 0;
      
      // Remove reviews from response to keep it clean
      const { reviews, ...futsalWithoutReviews } = futsal;
      
      return {
        ...futsalWithoutReviews,
        averageRating: Math.round(avgRating * 10) / 10,
        courtCount: futsal._count?.courts || 0
      };
    });

    res.json({
      status: 'success',
      results: futsalsWithRating.length,
      futsals: futsalsWithRating
    });
  } catch (error) {
    console.error('Get all futsals error:', error);
    res.status(500).json({ 
      status: 'error',
      message: 'Server error: ' + error.message 
    });
  }
};

/**
 * Get futsal by ID
 */
export const getFutsalById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({ 
        status: 'error',
        message: 'Futsal ID is required' 
      });
    }

    const futsalId = parseInt(id);
    if (isNaN(futsalId)) {
      return res.status(400).json({ 
        status: 'error',
        message: 'Invalid futsal ID format' 
      });
    }
    
    const futsal = await prisma.futsal.findUnique({
      where: { id: futsalId },
      include: {
        reviews: {
          include: {
            user: {
              select: { id: true, fullName: true }
            }
          },
          orderBy: {
            createdAt: 'desc'
          }
        },
        owner: {
          select: { id: true, fullName: true, email: true, phoneNumber: true }
        },
        courts: {
          select: {
            id: true,
            courtNumber: true,
            courtType: true,
            basePrice: true,
            peakPrice: true,
            isActive: true
          }
        }
      }
    });

    if (!futsal) {
      return res.status(404).json({ 
        status: 'error',
        message: 'Futsal not found' 
      });
    }

    // Calculate average rating
    const avgRating = futsal.reviews.length > 0
      ? futsal.reviews.reduce((sum, review) => sum + review.rating, 0) / futsal.reviews.length
      : 0;

    const response = {
      ...futsal,
      averageRating: Math.round(avgRating * 10) / 10
    };

    res.json({
      status: 'success',
      futsal: response
    });
  } catch (error) {
    console.error('Get futsal by ID error:', error);
    res.status(500).json({ 
      status: 'error',
      message: 'Server error: ' + error.message 
    });
  }
};

/**
 * Get available slots for a futsal
 */
export const getFutsalSlots = async (req, res) => {
  try {
    const { id } = req.params;
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({ 
        status: 'error',
        message: 'Please provide a date' 
      });
    }

    // Parse date
    const queryDate = new Date(date);
    queryDate.setHours(0, 0, 0, 0);
    
    const nextDay = new Date(queryDate);
    nextDay.setDate(nextDay.getDate() + 1);

    // FIXED: Use court relation instead of direct futsalId
    const slots = await prisma.timeSlot.findMany({
      where: {
        court: {
          futsalId: parseInt(id)
        },
        date: {
          gte: queryDate,
          lt: nextDay
        }
      },
      include: {
        court: {
          select: {
            courtNumber: true,
            courtType: true
          }
        }
      },
      orderBy: [
        { court: { courtNumber: 'asc' } },
        { startTime: 'asc' }
      ]
    });

    // Format response to match frontend expectations
    const formattedSlots = slots.map(slot => ({
      id: slot.id,
      courtId: slot.courtId,
      courtNumber: slot.court.courtNumber,
      courtType: slot.court.courtType,
      date: slot.date,
      startTime: slot.startTime,
      endTime: slot.endTime,
      price: slot.price,
      status: slot.status,
      lockedUntil: slot.lockedUntil
    }));

    res.json({
      status: 'success',
      results: formattedSlots.length,
      slots: formattedSlots
    });
  } catch (error) {
    console.error('Get futsal slots error:', error);
    res.status(500).json({ 
      status: 'error',
      message: 'Server error: ' + error.message 
    });
  }
};

/**
 * Create a new futsal
 */
export const createFutsal = async (req, res) => {
  try {
    const { name, description, address, basePrice, images, latitude, longitude } = req.body;

    if (!name || !address || !basePrice) {
      return res.status(400).json({ 
        status: 'error',
        message: 'Please provide name, address, and base price' 
      });
    }

    if (!req.user || !req.user.id) {
      return res.status(401).json({ 
        status: 'error',
        message: 'Authentication required' 
      });
    }

    const futsal = await prisma.futsal.create({
      data: {
        name,
        description,
        address,
        basePrice: parseFloat(basePrice),
        images: images || [],
        latitude: latitude ? parseFloat(latitude) : null,
        longitude: longitude ? parseFloat(longitude) : null,
        ownerId: req.user.id,
        isApproved: false
      }
    });

    res.status(201).json({
      status: 'success',
      message: 'Futsal created successfully. Waiting for admin approval.',
      futsal
    });
  } catch (error) {
    console.error('Create futsal error:', error);
    res.status(500).json({ 
      status: 'error',
      message: 'Server error: ' + error.message 
    });
  }
};

/**
 * Update futsal details
 */
export const updateFutsal = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, address, basePrice, images, latitude, longitude } = req.body;

    const existingFutsal = await prisma.futsal.findFirst({
      where: {
        id: parseInt(id),
        ownerId: req.user.id
      }
    });

    if (!existingFutsal && req.user.role !== 'ADMIN') {
      return res.status(404).json({ 
        status: 'error',
        message: 'Futsal not found or you do not have permission' 
      });
    }

    const futsal = await prisma.futsal.update({
      where: { id: parseInt(id) },
      data: {
        name,
        description,
        address,
        basePrice: basePrice ? parseFloat(basePrice) : undefined,
        images,
        latitude: latitude ? parseFloat(latitude) : undefined,
        longitude: longitude ? parseFloat(longitude) : undefined
      }
    });

    res.json({
      status: 'success',
      message: 'Futsal updated successfully',
      futsal
    });
  } catch (error) {
    console.error('Update futsal error:', error);
    res.status(500).json({ 
      status: 'error',
      message: 'Server error: ' + error.message 
    });
  }
};

/**
 * Delete a futsal
 */
export const deleteFutsal = async (req, res) => {
  try {
    const { id } = req.params;

    const existingFutsal = await prisma.futsal.findFirst({
      where: {
        id: parseInt(id),
        ownerId: req.user.id
      }
    });

    if (!existingFutsal && req.user.role !== 'ADMIN') {
      return res.status(404).json({ 
        status: 'error',
        message: 'Futsal not found or you do not have permission' 
      });
    }

    await prisma.futsal.delete({
      where: { id: parseInt(id) }
    });

    res.json({
      status: 'success',
      message: 'Futsal deleted successfully'
    });
  } catch (error) {
    console.error('Delete futsal error:', error);
    res.status(500).json({ 
      status: 'error',
      message: 'Server error: ' + error.message 
    });
  }
};

/**
 * GET OWNER'S FUTSALS - For Dashboard
 */
export const getMyFutsals = async (req, res) => {
  console.log('\n📍 GET MY FUTSALS API HIT');
  
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ 
        status: 'error',
        message: 'User not authenticated' 
      });
    }

    const futsals = await prisma.futsal.findMany({
      where: { ownerId: req.user.id },
      include: {
        _count: {
          select: {
            courts: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Add court count to response
    const futsalsWithCount = futsals.map(futsal => ({
      ...futsal,
      courtCount: futsal._count?.courts || 0
    }));

    res.json({
      status: 'success',
      results: futsalsWithCount.length,
      futsals: futsalsWithCount
    });

  } catch (error) {
    console.error('\n❌ ERROR in getMyFutsals:', error);
    res.status(500).json({ 
      status: 'error',
      message: 'Server error: ' + error.message 
    });
  }
};