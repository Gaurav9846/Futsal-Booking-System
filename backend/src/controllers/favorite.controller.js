import { prisma } from '../index.js';

// Get user's favorites
export const getFavorites = async (req, res) => {
  try {
    const favorites = await prisma.favorite.findMany({
      where: { userId: req.user.id },
      include: {
        futsal: {
          select: {
            id: true,
            name: true,
            address: true,
            images: true,
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      status: 'success',
      favorites: favorites
    });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Add to favorites
export const addFavorite = async (req, res) => {
  try {
    const { futsalId } = req.body;

    if (!futsalId) {
      return res.status(400).json({
        status: 'error',
        message: 'Futsal ID is required'
      });
    }

    // Check if already favorited
    const existing = await prisma.favorite.findFirst({
      where: {
        userId: req.user.id,
        futsalId: parseInt(futsalId)
      }
    });

    if (existing) {
      return res.status(400).json({
        status: 'error',
        message: 'Already in favorites'
      });
    }

    const favorite = await prisma.favorite.create({
      data: {
        userId: req.user.id,
        futsalId: parseInt(futsalId)
      }
    });

    res.json({
      status: 'success',
      message: 'Added to favorites',
      favorite: favorite
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Remove from favorites
export const removeFavorite = async (req, res) => {
  try {
    const { futsalId } = req.params;

    await prisma.favorite.deleteMany({
      where: {
        userId: req.user.id,
        futsalId: parseInt(futsalId)
      }
    });

    res.json({
      status: 'success',
      message: 'Removed from favorites'
    });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};