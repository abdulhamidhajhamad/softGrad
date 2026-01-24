/**
 * 🎯 Seed Script: Create Users, Bookings, and Reviews
 * 
 * This script will:
 * 1. Create 30 verified users
 * 2. Create completed bookings for each service (excluding display-only)
 * 3. Create reviews matching each service's rating
 * 4. Update service statistics
 * 
 * Run: node scripts/seed-reviews-data.js
 */

const { MongoClient, ObjectId } = require('mongodb');
const bcrypt = require('bcrypt');

// MongoDB Connection
const MONGO_URI = 'mongodb+srv://fordep:0592370454@weddingplanner.ledafad.mongodb.net/weddingPlanner?retryWrites=true&w=majority&appName=weddingplanner';

// ═══════════════════════════════════════════════════════════════════════════
// 📝 REALISTIC USER NAMES & REVIEW COMMENTS
// ═══════════════════════════════════════════════════════════════════════════

const USER_NAMES = [
  'Sarah Ahmed', 'Mohammad Hassan', 'Layla Khalil', 'Omar Nasser', 'Fatima Ali',
  'Youssef Ibrahim', 'Nour Mansour', 'Ahmad Saleh', 'Rania Mahmoud', 'Khaled Younis',
  'Dina Awad', 'Fadi Haddad', 'Lina Khoury', 'Sami Bishara', 'Mona Darwish',
  'Tariq Abed', 'Hana Sabbagh', 'Ziad Nassar', 'Rana Qasim', 'Mazen Issa',
  'Nadia Barakat', 'Walid Hamdan', 'Samar Rizk', 'Bassam Farah', 'Reem Jabr',
  'Karim Taha', 'Amal Shukri', 'Imad Kanaan', 'Ghada Masri', 'Jihad Atallah'
];

// Reviews based on rating (5, 4, 3, 2, 1 stars)
const REVIEW_COMMENTS = {
  5: [
    "Absolutely amazing service! Exceeded all our expectations. The team was professional and attentive to every detail.",
    "Perfect experience from start to finish. Highly recommended for any wedding!",
    "Outstanding quality and exceptional customer service. Made our special day truly memorable.",
    "Best decision we made for our wedding. The attention to detail was incredible!",
    "Flawless execution! They went above and beyond to make everything perfect.",
    "Couldn't be happier with the results. Professional, timely, and beautiful work.",
    "Five stars isn't enough! They made our dream wedding come true.",
    "Exceptional service quality. Would definitely book again for future events.",
    "The team was incredibly professional and the results were stunning!",
    "Everything was perfect! From communication to execution, A+ service."
  ],
  4: [
    "Great service overall! A few minor things could be improved but very satisfied.",
    "Really good experience. Professional team and quality work.",
    "Very happy with the service. Would recommend to friends and family.",
    "Good value for money. The team was helpful and responsive.",
    "Solid service! Met our expectations and delivered on time.",
    "Professional and reliable. Just a few small suggestions for improvement.",
    "Very pleased with the outcome. Good communication throughout.",
    "Quality service at a fair price. Would use again.",
    "Great experience overall. The team was friendly and efficient.",
    "Happy with our choice. Good service with room for minor improvements."
  ],
  3: [
    "Decent service. Met basic expectations but nothing extraordinary.",
    "Average experience. Some things were good, others could be better.",
    "Okay service. Got what we paid for, nothing more nothing less.",
    "Mixed feelings. Some aspects were great, others needed work.",
    "Fair service. Communication could have been better.",
    "Acceptable quality. Would consider for smaller events.",
    "Service was fine. Met minimum requirements.",
    "Middle of the road experience. Not bad but not outstanding.",
    "Reasonable service for the price. Some room for improvement.",
    "Average performance. Delivered but with some delays."
  ],
  2: [
    "Below expectations. Several issues that affected our experience.",
    "Disappointed with the service. Expected better quality.",
    "Not satisfied. Communication was poor and execution was lacking.",
    "Would not recommend. Too many problems during our event.",
    "Service fell short of promises made during booking."
  ],
  1: [
    "Very disappointed. Did not deliver on promised services.",
    "Poor experience overall. Would not recommend.",
    "Significant issues with quality and professionalism."
  ]
};

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

function getRandomElement(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// Generate date in last 8 months of 2025 (May - December 2025)
function getRandomDate2025() {
  const startMonth = 4; // May (0-indexed)
  const endMonth = 11; // December
  const month = getRandomInt(startMonth, endMonth);
  const day = getRandomInt(1, 28); // Safe for all months
  return new Date(2025, month, day, getRandomInt(10, 18), 0, 0);
}

// Generate ratings based on service's average rating
function generateRatingsForService(avgRating, count) {
  const ratings = [];
  const roundedAvg = Math.round(avgRating);
  
  for (let i = 0; i < count; i++) {
    // Create variance around the average
    const variance = Math.random();
    let rating;
    
    if (avgRating >= 4.5) {
      // High rated: mostly 5s, some 4s
      rating = variance < 0.7 ? 5 : 4;
    } else if (avgRating >= 4.0) {
      // Good rated: mix of 5s and 4s
      rating = variance < 0.4 ? 5 : variance < 0.9 ? 4 : 3;
    } else if (avgRating >= 3.5) {
      // Above average: mix of 4s and 3s
      rating = variance < 0.3 ? 5 : variance < 0.7 ? 4 : 3;
    } else if (avgRating >= 3.0) {
      // Average: mostly 3s
      rating = variance < 0.2 ? 4 : variance < 0.8 ? 3 : 2;
    } else if (avgRating >= 2.0) {
      // Below average
      rating = variance < 0.3 ? 3 : variance < 0.7 ? 2 : 1;
    } else {
      // Poor
      rating = variance < 0.5 ? 2 : 1;
    }
    
    ratings.push(rating);
  }
  
  return ratings;
}

function getBookingDetailsForService(service, bookingDate) {
  const bookingType = service.bookingType || 'daily';
  const availableHours = service.availableHours || [10, 11, 12, 13, 14, 15, 16, 17];
  
  const details = {
    date: bookingDate,
  };
  
  switch (bookingType.toLowerCase()) {
    case 'hourly':
      const startHour = availableHours[getRandomInt(0, Math.max(0, availableHours.length - 3))];
      const duration = getRandomInt(service.minBookingHours || 2, service.maxBookingHours || 4);
      details.startHour = startHour;
      details.endHour = Math.min(startHour + duration, availableHours[availableHours.length - 1] + 1);
      break;
      
    case 'capacity':
      details.numberOfPeople = getRandomInt(50, service.maxCapacity || 200);
      details.startHour = 16;
      details.endHour = 22;
      break;
      
    case 'daily':
      details.startHour = availableHours[0] || 10;
      details.endHour = availableHours[availableHours.length - 1] + 1 || 18;
      break;
      
    case 'mixed':
      details.startHour = 16;
      details.endHour = 22;
      details.numberOfPeople = getRandomInt(50, service.maxCapacity || 150);
      break;
      
    default:
      details.startHour = 16;
      details.endHour = 20;
  }
  
  return details;
}

function calculatePrice(service, bookingDetails) {
  const bookingType = service.bookingType || 'daily';
  const priceOptions = service.priceOptions || {};
  
  switch (bookingType.toLowerCase()) {
    case 'hourly':
      const hours = (bookingDetails.endHour || 18) - (bookingDetails.startHour || 14);
      return (priceOptions.perHour || service.price || 100) * hours;
      
    case 'capacity':
      return (priceOptions.perPerson || service.price || 50) * (bookingDetails.numberOfPeople || 100);
      
    case 'daily':
      return priceOptions.perDay || service.price || 500;
      
    case 'mixed':
      const basePrice = priceOptions.basePrice || service.price || 1000;
      const perPersonExtra = (priceOptions.perPerson || 20) * (bookingDetails.numberOfPeople || 100);
      return basePrice + perPersonExtra;
      
    default:
      return service.price || 500;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🚀 MAIN SEEDING FUNCTION
// ═══════════════════════════════════════════════════════════════════════════

async function seedData() {
  const client = new MongoClient(MONGO_URI);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('weddingPlanner');
    
    // Collections
    const usersCol = db.collection('users');
    const servicesCol = db.collection('services');
    const bookingsCol = db.collection('bookings');
    const reviewsCol = db.collection('reviews');
    
    // ═══════════════════════════════════════════════════════════════════════
    // STEP 1: Get all bookable services (exclude display-only)
    // ═══════════════════════════════════════════════════════════════════════
    
    console.log('\n📦 Fetching services...');
    const services = await servicesCol.find({
      bookingType: { $ne: 'display' },
      isActive: true
    }).toArray();
    
    console.log(`   Found ${services.length} bookable services`);
    
    if (services.length === 0) {
      console.log('❌ No bookable services found!');
      return;
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // STEP 2: Create 30 verified users
    // ═══════════════════════════════════════════════════════════════════════
    
    console.log('\n👥 Creating users...');
    const hashedPassword = await bcrypt.hash('Test123!@#', 10);
    
    const usersToCreate = USER_NAMES.map((name, index) => ({
      userName: name,
      email: `testuser${index + 1}@wedding.com`,
      password: hashedPassword,
      phone: `059${String(1000000 + index).padStart(7, '0')}`,
      city: getRandomElement(['Nablus', 'Ramallah', 'Jerusalem', 'Bethlehem', 'Jenin', 'Hebron']),
      role: 'user',
      isVerified: true,
      favoriteServices: [],
      favoritePackages: [],
      favoriteOffers: [],
      createdAt: new Date(2025, getRandomInt(0, 3), getRandomInt(1, 28)),
      updatedAt: new Date()
    }));
    
    // Delete existing test users first
    await usersCol.deleteMany({ email: { $regex: /^testuser\d+@wedding\.com$/ } });
    
    const insertedUsers = await usersCol.insertMany(usersToCreate);
    const userIds = Object.values(insertedUsers.insertedIds);
    console.log(`   ✅ Created ${userIds.length} users`);
    
    // ═══════════════════════════════════════════════════════════════════════
    // STEP 3: Create bookings and reviews for each service
    // ═══════════════════════════════════════════════════════════════════════
    
    console.log('\n📅 Creating bookings and reviews...');
    
    let totalBookings = 0;
    let totalReviews = 0;
    
    // Track which users booked which services
    const userServiceMap = new Map();
    
    for (const service of services) {
      const serviceId = service._id;
      const currentRating = service.averageRating || getRandomInt(35, 50) / 10; // Default 3.5-5.0
      
      // Determine how many reviews for this service (3-8 reviews each)
      const reviewCount = getRandomInt(3, 8);
      const ratings = generateRatingsForService(currentRating, reviewCount);
      
      // Select random users for this service
      const availableUserIndices = [...Array(userIds.length).keys()];
      const selectedUserIndices = [];
      
      for (let i = 0; i < reviewCount && availableUserIndices.length > 0; i++) {
        const randomIndex = getRandomInt(0, availableUserIndices.length - 1);
        selectedUserIndices.push(availableUserIndices.splice(randomIndex, 1)[0]);
      }
      
      for (let i = 0; i < selectedUserIndices.length; i++) {
        const userIndex = selectedUserIndices[i];
        const userId = userIds[userIndex];
        const userName = USER_NAMES[userIndex];
        const rating = ratings[i];
        
        // Generate booking date (completed - in the past)
        const bookingDate = getRandomDate2025();
        const bookingDetails = getBookingDetailsForService(service, bookingDate);
        const price = calculatePrice(service, bookingDetails);
        
        // Create Booking
        const booking = {
          paymentIntentId: `pi_seed_${serviceId}_${userId}_${Date.now()}`,
          userId: userId,
          serviceId: serviceId,
          serviceName: service.serviceName,
          providerId: service.providerId,
          companyName: service.companyName || 'Wedding Provider',
          bookingType: service.bookingType || 'daily',
          bookingDetails: bookingDetails,
          price: price,
          status: 'completed',
          refunded: false,
          seen: true,
          isReviewed: true,
          reviewedAt: new Date(bookingDate.getTime() + 7 * 24 * 60 * 60 * 1000), // 7 days after booking
          createdAt: new Date(bookingDate.getTime() - 14 * 24 * 60 * 60 * 1000), // 14 days before event
          updatedAt: new Date(bookingDate.getTime() + 7 * 24 * 60 * 60 * 1000)
        };
        
        const insertedBooking = await bookingsCol.insertOne(booking);
        totalBookings++;
        
        // Create Review
        const reviewComment = getRandomElement(REVIEW_COMMENTS[rating] || REVIEW_COMMENTS[3]);
        const reviewDate = new Date(bookingDate.getTime() + getRandomInt(3, 14) * 24 * 60 * 60 * 1000);
        
        const review = {
          userId: userId,
          serviceId: serviceId,
          bookingId: insertedBooking.insertedId,
          rating: rating,
          comment: reviewComment,
          images: [],
          userName: userName,
          isVisible: true,
          createdAt: reviewDate,
          updatedAt: reviewDate
        };
        
        await reviewsCol.insertOne(review);
        totalReviews++;
      }
      
      // Update service rating statistics
      const serviceReviews = await reviewsCol.find({ 
        serviceId: serviceId, 
        isVisible: true 
      }).toArray();
      
      if (serviceReviews.length > 0) {
        const avgRating = serviceReviews.reduce((sum, r) => sum + r.rating, 0) / serviceReviews.length;
        
        await servicesCol.updateOne(
          { _id: serviceId },
          { 
            $set: { 
              averageRating: Math.round(avgRating * 10) / 10,
              totalReviews: serviceReviews.length
            } 
          }
        );
      }
      
      console.log(`   ✅ ${service.serviceName}: ${selectedUserIndices.length} bookings & reviews`);
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // SUMMARY
    // ═══════════════════════════════════════════════════════════════════════
    
    console.log('\n' + '═'.repeat(60));
    console.log('📊 SEEDING COMPLETE!');
    console.log('═'.repeat(60));
    console.log(`   👥 Users created: ${userIds.length}`);
    console.log(`   📅 Bookings created: ${totalBookings}`);
    console.log(`   ⭐ Reviews created: ${totalReviews}`);
    console.log(`   📦 Services updated: ${services.length}`);
    console.log('═'.repeat(60));
    
    // Verify data
    console.log('\n🔍 Verification:');
    const verifyUsers = await usersCol.countDocuments({ email: { $regex: /^testuser\d+@wedding\.com$/ } });
    const verifyBookings = await bookingsCol.countDocuments({ paymentIntentId: { $regex: /^pi_seed_/ } });
    const verifyReviews = await reviewsCol.countDocuments({ userName: { $in: USER_NAMES } });
    
    console.log(`   Users in DB: ${verifyUsers}`);
    console.log(`   Seed Bookings in DB: ${verifyBookings}`);
    console.log(`   Seed Reviews in DB: ${verifyReviews}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
    console.log('\n✅ Connection closed');
  }
}

// Run the script
seedData();
