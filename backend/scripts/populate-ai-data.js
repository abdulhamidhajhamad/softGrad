/**
 * 🤖 Script to populate AI data (tags, bestFor, ratings) for all services
 * 
 * This script will:
 * 1. Connect to MongoDB Atlas
 * 2. Fetch all services
 * 3. Generate appropriate aiAnalysis (tags, bestFor, score) based on category
 * 4. Assign random ratings distributed across 3 quality levels
 * 5. Update all services in the database
 * 
 * Run with: node scripts/populate-ai-data.js
 */

const { MongoClient } = require('mongodb');

// MongoDB Connection String
const MONGO_URI = 'mongodb+srv://fordep:0592370454@weddingplanner.ledafad.mongodb.net/weddingPlanner?retryWrites=true&w=majority&appName=weddingplanner';

// ============ AI Tags & BestFor Configuration by Category ============

const categoryConfig = {
  // Venues / قاعات
  'Venues': {
    tags: [
      ['Elegant', 'Spacious', 'Modern Design', 'Great Lighting', 'Professional Staff'],
      ['Luxury', 'Premium', 'High-End', 'Exclusive', 'VIP Service'],
      ['Cozy', 'Intimate', 'Affordable', 'Family-Friendly', 'Convenient Location'],
      ['Outdoor', 'Garden View', 'Natural Setting', 'Open Air', 'Scenic'],
      ['Indoor', 'Air Conditioned', 'Climate Controlled', 'Comfortable'],
      ['Large Capacity', 'Parking Available', 'Accessible', 'Central Location'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Wedding', 'Anniversary', 'Birthday'],
      ['Corporate Event', 'Conference', 'Meeting'],
      ['Birthday', 'Baby Shower', 'Graduation'],
      ['Henna Night', 'Religious Event'],
      ['Wedding', 'Corporate Event', 'Conference'],
    ]
  },

  // Photographers / مصورين
  'Photographers': {
    tags: [
      ['Creative', 'Professional', 'High Quality', 'Artistic Style', 'Attention to Detail'],
      ['Candid Photography', 'Natural Shots', 'Storytelling', 'Emotional Captures'],
      ['Studio Photography', 'Portrait Expert', 'Lighting Master', 'Retouching'],
      ['Drone Photography', 'Aerial Shots', 'Cinematic', 'Video Included'],
      ['Fast Delivery', 'Reliable', 'Punctual', 'Friendly', 'Patient'],
      ['Budget Friendly', 'Good Value', 'Affordable', 'Package Deals'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Wedding', 'Anniversary'],
      ['Birthday', 'Baby Shower', 'Graduation'],
      ['Corporate Event', 'Conference'],
      ['Henna Night', 'Religious Event'],
      ['Wedding', 'Birthday', 'Graduation'],
    ]
  },

  // Catering / طعام
  'Catering': {
    tags: [
      ['Delicious Food', 'Fresh Ingredients', 'Variety Menu', 'Quality Service'],
      ['Traditional Cuisine', 'Arabic Food', 'Authentic Taste', 'Home Style'],
      ['International Cuisine', 'Western Food', 'Fusion', 'Modern Presentation'],
      ['Buffet Style', 'Large Portions', 'Generous Servings', 'Good Value'],
      ['Fine Dining', 'Gourmet', 'Premium Quality', 'Elegant Presentation'],
      ['Fast Service', 'Professional Staff', 'Clean', 'Well Organized'],
      ['Vegetarian Options', 'Halal', 'Dietary Accommodations', 'Healthy Options'],
    ],
    bestFor: [
      ['Wedding', 'Engagement', 'Anniversary'],
      ['Corporate Event', 'Conference', 'Meeting'],
      ['Birthday', 'Baby Shower', 'Graduation'],
      ['Religious Event', 'Henna Night'],
      ['Wedding', 'Corporate Event'],
      ['Birthday', 'Graduation', 'Baby Shower'],
    ]
  },

  // Cake / كيك
  'Cake': {
    tags: [
      ['Beautiful Design', 'Custom Cakes', 'Artistic', 'Creative'],
      ['Delicious Taste', 'Fresh', 'Quality Ingredients', 'Moist'],
      ['Tiered Cakes', 'Wedding Specialty', 'Elegant', 'Classic'],
      ['Fondant Expert', 'Detailed Work', 'Intricate Designs', '3D Cakes'],
      ['Affordable', 'Good Value', 'Budget Friendly', 'Simple but Nice'],
      ['Fast Delivery', 'Reliable', 'On Time', 'Professional'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Birthday', 'Baby Shower'],
      ['Graduation', 'Anniversary'],
      ['Corporate Event'],
      ['Wedding', 'Birthday', 'Anniversary'],
      ['Henna Night', 'Religious Event'],
    ]
  },

  // Flower Shops / محلات ورود
  'Flower Shops': {
    tags: [
      ['Fresh Flowers', 'Beautiful Arrangements', 'Fragrant', 'Long Lasting'],
      ['Creative Designs', 'Unique Style', 'Custom Bouquets', 'Artistic'],
      ['Wedding Specialist', 'Bridal Bouquets', 'Centerpieces', 'Archways'],
      ['Affordable', 'Good Value', 'Budget Options', 'Simple Elegance'],
      ['Premium Flowers', 'Imported', 'Exotic', 'Rare Varieties'],
      ['Fast Delivery', 'Same Day', 'Reliable', 'Professional Setup'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Anniversary', 'Birthday'],
      ['Graduation', 'Corporate Event'],
      ['Religious Event', 'Henna Night'],
      ['Wedding', 'Anniversary'],
      ['Baby Shower', 'Birthday'],
    ]
  },

  // Decor & Lighting / ديكور وإضاءة
  'Decor & Lighting': {
    tags: [
      ['Stunning Decor', 'Elegant Setup', 'Professional', 'Attention to Detail'],
      ['Modern Design', 'Contemporary', 'Trendy', 'Instagram Worthy'],
      ['Traditional Style', 'Classic', 'Timeless', 'Cultural'],
      ['Creative Lighting', 'Mood Setting', 'Ambient', 'Dramatic Effects'],
      ['Full Package', 'Complete Setup', 'All Inclusive', 'Stress Free'],
      ['Affordable', 'Budget Friendly', 'Good Value', 'Basic Package'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Birthday', 'Baby Shower'],
      ['Corporate Event', 'Conference'],
      ['Henna Night', 'Anniversary'],
      ['Graduation', 'Religious Event'],
      ['Wedding', 'Birthday', 'Corporate Event'],
    ]
  },

  // Music & Entertainment / موسيقى وترفيه
  'Music & Entertainment': {
    tags: [
      ['Great Music', 'Party Starter', 'Crowd Pleaser', 'Energy'],
      ['Professional DJ', 'Quality Equipment', 'Great Sound', 'Light Show'],
      ['Live Band', 'Traditional Music', 'Arabic Music', 'Dabke'],
      ['Modern Music', 'International', 'Top Hits', 'Dance Music'],
      ['Family Friendly', 'All Ages', 'Clean Entertainment', 'Fun'],
      ['Affordable', 'Good Value', 'Budget Package', 'Basic Setup'],
    ],
    bestFor: [
      ['Wedding', 'Engagement', 'Henna Night'],
      ['Birthday', 'Graduation'],
      ['Corporate Event', 'Conference'],
      ['Anniversary', 'Baby Shower'],
      ['Wedding', 'Birthday'],
      ['Religious Event'],
    ]
  },

  // Event Planners & Coordinators / منظمي فعاليات
  'Event Planners & Coordinators': {
    tags: [
      ['Organized', 'Professional', 'Detail Oriented', 'Reliable'],
      ['Creative Ideas', 'Unique Concepts', 'Innovative', 'Fresh'],
      ['Stress Free', 'Full Service', 'All Inclusive', 'Peace of Mind'],
      ['Budget Management', 'Cost Effective', 'Value for Money', 'Transparent'],
      ['Experienced', 'Expert', 'Knowledgeable', 'Well Connected'],
      ['Communication', 'Responsive', 'Available', 'Friendly'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Corporate Event', 'Conference'],
      ['Birthday', 'Anniversary'],
      ['Baby Shower', 'Graduation'],
      ['Henna Night', 'Religious Event'],
      ['Wedding', 'Corporate Event', 'Birthday'],
    ]
  },

  // Card Printing / طباعة بطاقات
  'Card Printing': {
    tags: [
      ['Beautiful Designs', 'Elegant', 'High Quality Print', 'Premium Paper'],
      ['Custom Design', 'Personalized', 'Unique', 'Creative'],
      ['Fast Delivery', 'Quick Turnaround', 'On Time', 'Reliable'],
      ['Affordable', 'Budget Friendly', 'Good Value', 'Competitive Prices'],
      ['Traditional Style', 'Classic', 'Formal', 'Sophisticated'],
      ['Modern Design', 'Contemporary', 'Minimalist', 'Trendy'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Birthday', 'Graduation'],
      ['Corporate Event', 'Conference'],
      ['Baby Shower', 'Anniversary'],
      ['Religious Event', 'Henna Night'],
      ['Wedding', 'Birthday'],
    ]
  },

  // Jewelry & Accessories / مجوهرات وإكسسوارات
  'Jewelry & Accessories': {
    tags: [
      ['Beautiful Pieces', 'Elegant', 'High Quality', 'Stunning'],
      ['Bridal Jewelry', 'Wedding Sets', 'Traditional', 'Gold'],
      ['Modern Design', 'Contemporary', 'Trendy', 'Fashion Forward'],
      ['Affordable', 'Budget Friendly', 'Good Value', 'Costume Jewelry'],
      ['Custom Made', 'Personalized', 'Unique', 'One of a Kind'],
      ['Fast Service', 'Reliable', 'Professional', 'Helpful Staff'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Anniversary', 'Birthday'],
      ['Graduation', 'Henna Night'],
      ['Corporate Event'],
      ['Baby Shower'],
      ['Wedding', 'Engagement', 'Anniversary'],
    ]
  },

  // Car Rental & Transportation / تأجير سيارات ومواصلات
  'Car Rental & Transportation': {
    tags: [
      ['Luxury Cars', 'Premium Vehicles', 'Well Maintained', 'Clean'],
      ['Professional Drivers', 'Punctual', 'Reliable', 'Courteous'],
      ['Wedding Cars', 'Decorated', 'Special Occasion', 'Elegant'],
      ['Affordable', 'Budget Friendly', 'Good Value', 'Competitive'],
      ['Large Fleet', 'Variety', 'Options', 'Availability'],
      ['On Time', 'Dependable', 'Safe', 'Insured'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Corporate Event', 'Conference'],
      ['Birthday', 'Graduation'],
      ['Anniversary'],
      ['Religious Event'],
      ['Wedding', 'Corporate Event'],
    ]
  },

  // Gift & Souvenir / هدايا وتذكارات
  'Gift & Souvenir': {
    tags: [
      ['Unique Gifts', 'Special', 'Memorable', 'Quality'],
      ['Custom Made', 'Personalized', 'Engraved', 'Unique'],
      ['Beautiful Packaging', 'Elegant', 'Gift Ready', 'Presentable'],
      ['Affordable', 'Budget Friendly', 'Good Value', 'Variety'],
      ['Traditional', 'Cultural', 'Local', 'Authentic'],
      ['Fast Service', 'Reliable', 'Professional', 'Helpful'],
    ],
    bestFor: [
      ['Wedding', 'Engagement'],
      ['Birthday', 'Baby Shower'],
      ['Graduation', 'Anniversary'],
      ['Corporate Event'],
      ['Religious Event', 'Henna Night'],
      ['Wedding', 'Birthday', 'Graduation'],
    ]
  },

  // Default for any other category
  'Other': {
    tags: [
      ['Professional', 'Quality Service', 'Reliable', 'Experienced'],
      ['Affordable', 'Good Value', 'Budget Friendly', 'Fair Pricing'],
      ['Customer Focused', 'Friendly', 'Helpful', 'Responsive'],
      ['Fast Service', 'Efficient', 'On Time', 'Dependable'],
      ['Recommended', 'Popular', 'Well Reviewed', 'Trusted'],
    ],
    bestFor: [
      ['Wedding', 'Birthday', 'Corporate Event'],
      ['Engagement', 'Anniversary', 'Graduation'],
      ['Baby Shower', 'Henna Night', 'Religious Event'],
      ['Conference', 'Meeting'],
    ]
  }
};

// ============ Rating Distribution ============
// 33% Good (4.0-5.0), 34% Medium (2.5-3.5), 33% Poor (1.0-2.0)

function generateRating(index, totalCount) {
  const position = index / totalCount;
  
  if (position < 0.33) {
    // Good: 4.0 - 5.0
    return parseFloat((4.0 + Math.random() * 1.0).toFixed(1));
  } else if (position < 0.67) {
    // Medium: 2.5 - 3.5
    return parseFloat((2.5 + Math.random() * 1.0).toFixed(1));
  } else {
    // Poor: 1.0 - 2.0
    return parseFloat((1.0 + Math.random() * 1.0).toFixed(1));
  }
}

function generateAiScore(rating) {
  // AI Score correlates with rating (0.0 - 1.0)
  return parseFloat((rating / 5.0).toFixed(2));
}

function getRandomItems(array, count = 1) {
  const shuffled = [...array].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, Math.min(count, array.length));
}

function generateAiData(category, rating) {
  const config = categoryConfig[category] || categoryConfig['Other'];
  
  // Get random tag set and bestFor set
  const tagSet = getRandomItems(config.tags, 1)[0];
  const bestForSet = getRandomItems(config.bestFor, 1)[0];
  
  // Add some variation - pick 3-5 tags from the set
  const selectedTags = getRandomItems(tagSet, 3 + Math.floor(Math.random() * 3));
  
  // Pick 2-4 bestFor items
  const selectedBestFor = getRandomItems(bestForSet, 2 + Math.floor(Math.random() * 2));
  
  // Add quality-based tags
  if (rating >= 4.0) {
    selectedTags.push('Highly Recommended', 'Top Rated');
  } else if (rating >= 3.0) {
    selectedTags.push('Good Choice', 'Reliable');
  } else {
    selectedTags.push('Budget Option', 'Basic Service');
  }
  
  return {
    score: generateAiScore(rating),
    tags: [...new Set(selectedTags)], // Remove duplicates
    bestFor: [...new Set(selectedBestFor)],
    lastUpdated: new Date()
  };
}

// ============ Main Script ============

async function populateAiData() {
  const client = new MongoClient(MONGO_URI);
  
  try {
    console.log('🔌 Connecting to MongoDB Atlas...');
    await client.connect();
    console.log('✅ Connected successfully!\n');
    
    const db = client.db('weddingPlanner');
    const servicesCollection = db.collection('services');
    
    // Fetch all services
    console.log('📦 Fetching all services...');
    const services = await servicesCollection.find({}).toArray();
    console.log(`📊 Found ${services.length} services\n`);
    
    if (services.length === 0) {
      console.log('⚠️ No services found in database!');
      return;
    }
    
    // Shuffle services to randomize rating distribution
    const shuffledServices = services.sort(() => 0.5 - Math.random());
    
    // Process each service
    let updated = 0;
    let errors = 0;
    
    console.log('🔄 Updating services with AI data...\n');
    console.log('=' .repeat(60));
    
    for (let i = 0; i < shuffledServices.length; i++) {
      const service = shuffledServices[i];
      const category = service.category || 'Other';
      
      // Generate rating based on position (for distribution)
      const rating = generateRating(i, shuffledServices.length);
      const totalReviews = Math.floor(Math.random() * 50) + 5; // 5-55 reviews
      
      // Generate AI data
      const aiAnalysis = generateAiData(category, rating);
      
      try {
        await servicesCollection.updateOne(
          { _id: service._id },
          {
            $set: {
              averageRating: rating,
              totalReviews: totalReviews,
              aiAnalysis: aiAnalysis
            }
          }
        );
        
        updated++;
        
        // Log progress
        const ratingEmoji = rating >= 4 ? '⭐' : rating >= 3 ? '🌟' : '💫';
        console.log(`${ratingEmoji} [${i + 1}/${shuffledServices.length}] ${service.serviceName}`);
        console.log(`   Category: ${category}`);
        console.log(`   Rating: ${rating} | Reviews: ${totalReviews}`);
        console.log(`   Tags: ${aiAnalysis.tags.slice(0, 4).join(', ')}...`);
        console.log(`   BestFor: ${aiAnalysis.bestFor.join(', ')}`);
        console.log('-'.repeat(60));
        
      } catch (err) {
        errors++;
        console.error(`❌ Error updating ${service.serviceName}:`, err.message);
      }
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('📊 SUMMARY');
    console.log('='.repeat(60));
    console.log(`✅ Successfully updated: ${updated} services`);
    console.log(`❌ Errors: ${errors}`);
    
    // Show rating distribution
    const goodCount = shuffledServices.filter((_, i) => i / shuffledServices.length < 0.33).length;
    const mediumCount = shuffledServices.filter((_, i) => i / shuffledServices.length >= 0.33 && i / shuffledServices.length < 0.67).length;
    const poorCount = shuffledServices.filter((_, i) => i / shuffledServices.length >= 0.67).length;
    
    console.log('\n📈 Rating Distribution:');
    console.log(`   ⭐ Good (4.0-5.0): ~${goodCount} services`);
    console.log(`   🌟 Medium (2.5-3.5): ~${mediumCount} services`);
    console.log(`   💫 Poor (1.0-2.0): ~${poorCount} services`);
    
  } catch (error) {
    console.error('💥 Fatal error:', error);
  } finally {
    await client.close();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

// Run the script
populateAiData();
