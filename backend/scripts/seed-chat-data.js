/**
 * 🎯 Seed Script: Create Chat Conversations
 * 
 * This script will:
 * 1. Create chats between users and providers (asking about services)
 * 2. Create chats between users and admin (asking about promo codes, support)
 * 3. Add realistic conversation messages
 * 
 * Run: node scripts/seed-chat-data.js
 */

const { MongoClient, ObjectId } = require('mongodb');

// MongoDB Connection
const MONGO_URI = 'mongodb+srv://fordep:0592370454@weddingplanner.ledafad.mongodb.net/weddingPlanner?retryWrites=true&w=majority&appName=weddingplanner';

// ═══════════════════════════════════════════════════════════════════════════
// 📝 REALISTIC CONVERSATION TEMPLATES
// ═══════════════════════════════════════════════════════════════════════════

// User asking Provider about services
const USER_PROVIDER_CONVERSATIONS = [
  // Venue inquiries
  {
    category: 'Venues',
    messages: [
      { from: 'user', text: 'Hi! I saw your venue and it looks amazing. Is it available for July 15th, 2025?' },
      { from: 'provider', text: 'Hello! Thank you for your interest. Let me check our calendar for that date.' },
      { from: 'provider', text: 'Great news! July 15th is available. Would you like to schedule a visit to see the venue?' },
      { from: 'user', text: 'Yes please! Can I come this weekend?' },
      { from: 'provider', text: 'Of course! Saturday at 2 PM works for us. See you then! 😊' },
    ]
  },
  {
    category: 'Venues',
    messages: [
      { from: 'user', text: 'Hello, I wanted to ask about your venue capacity. How many guests can you accommodate?' },
      { from: 'provider', text: 'Hi there! Our venue can comfortably accommodate up to 300 guests.' },
      { from: 'user', text: 'Perfect! And do you offer catering services or should I arrange separately?' },
      { from: 'provider', text: 'We have in-house catering with various menu options. I can send you our packages if you\'d like.' },
      { from: 'user', text: 'Yes, please send them. Thank you!' },
    ]
  },
  // Photography inquiries
  {
    category: 'Photography',
    messages: [
      { from: 'user', text: 'Hi! I love your portfolio. Do you offer both photography and videography packages?' },
      { from: 'provider', text: 'Thank you so much! Yes, we offer combined packages that include both services.' },
      { from: 'user', text: 'What\'s included in your premium package?' },
      { from: 'provider', text: 'Our premium package includes 8 hours coverage, 2 photographers, 1 videographer, drone shots, and a highlight video!' },
      { from: 'user', text: 'That sounds perfect. Can we meet to discuss details?' },
      { from: 'provider', text: 'Absolutely! When are you free this week?' },
    ]
  },
  {
    category: 'Photography',
    messages: [
      { from: 'user', text: 'Hello! Do you travel for destination weddings?' },
      { from: 'provider', text: 'Hi! Yes, we do! We\'ve covered weddings in Jordan, Dubai, and Turkey.' },
      { from: 'user', text: 'Great! Our wedding will be in Amman. What are your travel fees?' },
      { from: 'provider', text: 'For Amman, we charge a flat travel fee of $500 which covers transportation and accommodation.' },
      { from: 'user', text: 'That\'s reasonable. I\'ll discuss with my partner and get back to you.' },
    ]
  },
  // Catering inquiries
  {
    category: 'Catering',
    messages: [
      { from: 'user', text: 'Hello! I\'m looking for catering for 200 guests. Do you offer vegetarian options?' },
      { from: 'provider', text: 'Hi! Yes, we have extensive vegetarian and vegan menu options.' },
      { from: 'user', text: 'Can you do a tasting session before we decide?' },
      { from: 'provider', text: 'Of course! We offer complimentary tasting sessions for bookings over 150 guests.' },
      { from: 'user', text: 'Wonderful! Can we schedule one for next week?' },
      { from: 'provider', text: 'Sure! How about Tuesday at 6 PM?' },
      { from: 'user', text: 'Perfect, see you then!' },
    ]
  },
  {
    category: 'Catering',
    messages: [
      { from: 'user', text: 'Hi, do you provide setup and serving staff?' },
      { from: 'provider', text: 'Hello! Yes, our packages include professional serving staff and full setup.' },
      { from: 'user', text: 'How early do you arrive for setup?' },
      { from: 'provider', text: 'We typically arrive 3-4 hours before the event to ensure everything is perfect.' },
      { from: 'user', text: 'Great, that\'s exactly what I was hoping for.' },
    ]
  },
  // Decoration inquiries
  {
    category: 'Decoration',
    messages: [
      { from: 'user', text: 'Hi! I\'m interested in a rustic theme for my wedding. Do you have experience with that style?' },
      { from: 'provider', text: 'Hello! Rustic themes are one of our specialties! We have beautiful wooden elements and fairy lights.' },
      { from: 'user', text: 'Can you share some photos of previous rustic weddings you\'ve done?' },
      { from: 'provider', text: 'Of course! I\'ll send you our portfolio link. You\'ll love our work at Garden Venue last month!' },
      { from: 'user', text: 'Looking forward to seeing it. Thank you!' },
    ]
  },
  {
    category: 'Decoration',
    messages: [
      { from: 'user', text: 'Do you provide flower arrangements as well?' },
      { from: 'provider', text: 'Yes! We work with top florists and can create stunning centerpieces and bouquets.' },
      { from: 'user', text: 'What flowers are in season for August weddings?' },
      { from: 'provider', text: 'August is perfect for roses, dahlias, and sunflowers. All beautiful options!' },
      { from: 'user', text: 'I love sunflowers! Can we do a yellow and white theme?' },
      { from: 'provider', text: 'Absolutely! That would be gorgeous. Let me sketch some ideas for you.' },
    ]
  },
  // DJ/Music inquiries
  {
    category: 'DJ',
    messages: [
      { from: 'user', text: 'Hello! Do you take song requests before the wedding?' },
      { from: 'provider', text: 'Hi! Yes, I always ask couples to share their must-play and do-not-play lists.' },
      { from: 'user', text: 'Perfect! We want a mix of Arabic and English songs.' },
      { from: 'provider', text: 'That\'s my specialty! I\'ll create a perfect blend that keeps everyone on the dance floor.' },
      { from: 'user', text: 'Sounds great! How do we proceed with booking?' },
    ]
  },
  // Event Planning inquiries
  {
    category: 'Event Planning',
    messages: [
      { from: 'user', text: 'Hi, we\'re overwhelmed with wedding planning. Can you help coordinate everything?' },
      { from: 'provider', text: 'Hello! That\'s exactly what we do. We can handle everything from venue selection to the last dance.' },
      { from: 'user', text: 'What does your full planning package include?' },
      { from: 'provider', text: 'It includes vendor coordination, timeline creation, budget management, and day-of coordination.' },
      { from: 'user', text: 'That would be such a relief! Can we have a consultation call?' },
      { from: 'provider', text: 'Absolutely! I have availability tomorrow at 4 PM or Thursday at 10 AM.' },
      { from: 'user', text: 'Tomorrow at 4 PM works great!' },
    ]
  },
  // Car Rental inquiries
  {
    category: 'Car Rental',
    messages: [
      { from: 'user', text: 'Hi! Do you have a white Rolls Royce available for wedding transportation?' },
      { from: 'provider', text: 'Hello! Yes, we have a beautiful white Rolls Royce Ghost available.' },
      { from: 'user', text: 'Is the driver included in the rental?' },
      { from: 'provider', text: 'Yes, a professional chauffeur in formal attire is included.' },
      { from: 'user', text: 'Perfect! What\'s the rate for 6 hours?' },
      { from: 'provider', text: 'For 6 hours it\'s $800, including the champagne toast setup!' },
    ]
  },
  // Sweets inquiries
  {
    category: 'Sweets',
    messages: [
      { from: 'user', text: 'Hello! Do you make custom wedding cakes?' },
      { from: 'provider', text: 'Hi! Yes, we specialize in custom wedding cakes in any design you can imagine!' },
      { from: 'user', text: 'Can you do a 5-tier cake with gold accents?' },
      { from: 'provider', text: 'Absolutely! That\'s one of our most popular requests. Do you have a color theme?' },
      { from: 'user', text: 'White and gold with some fresh flowers.' },
      { from: 'provider', text: 'Beautiful choice! I\'ll prepare some design sketches for you.' },
    ]
  },
  // General inquiries
  {
    category: 'General',
    messages: [
      { from: 'user', text: 'Hi, I saw your service and I\'m interested. Are you available in September?' },
      { from: 'provider', text: 'Hello! Thank you for reaching out. Yes, we have availability in September.' },
      { from: 'user', text: 'Great! What dates do you have open?' },
      { from: 'provider', text: 'We currently have September 5th, 12th, 19th, and 26th available.' },
      { from: 'user', text: 'September 12th would be perfect!' },
      { from: 'provider', text: 'Excellent choice! Shall I send you our booking details?' },
    ]
  },
  {
    category: 'General',
    messages: [
      { from: 'user', text: 'Hello! I wanted to ask about your pricing. Is there room for negotiation?' },
      { from: 'provider', text: 'Hi! Our prices are competitive, but we do offer package discounts for multiple services.' },
      { from: 'user', text: 'What kind of package deals do you have?' },
      { from: 'provider', text: 'If you book both our premium and basic services, we offer 15% off the total!' },
      { from: 'user', text: 'That\'s a good deal! Let me think about it and get back to you.' },
    ]
  },
  {
    category: 'General',
    messages: [
      { from: 'user', text: 'Hi, can you work with a tight timeline? Our wedding is in 6 weeks.' },
      { from: 'provider', text: 'Hello! 6 weeks is tight but doable. We\'ve handled last-minute weddings before!' },
      { from: 'user', text: 'That\'s a relief! What do you need from us to get started?' },
      { from: 'provider', text: 'Just your event details and a deposit. We can handle the rest!' },
      { from: 'user', text: 'You\'re amazing! Let\'s do this!' },
      { from: 'provider', text: 'Great! I\'ll send you the contract right away. Congratulations on your upcoming wedding! 🎉' },
    ]
  },
];

// User asking Admin questions
const USER_ADMIN_CONVERSATIONS = [
  {
    messages: [
      { from: 'user', text: 'Hi, are there any promo codes available right now?' },
      { from: 'admin', text: 'Hello! Yes, use code WEDDING2025 for 10% off your first booking!' },
      { from: 'user', text: 'That\'s great! Is there a minimum order for the discount?' },
      { from: 'admin', text: 'No minimum! The code works on any booking amount.' },
      { from: 'user', text: 'Perfect, thank you so much!' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'Hello, I\'m having trouble completing my payment. Can you help?' },
      { from: 'admin', text: 'Hi! I\'m sorry to hear that. What error message are you seeing?' },
      { from: 'user', text: 'It says "Payment method declined"' },
      { from: 'admin', text: 'This usually means your bank declined the transaction. Try using a different card or contact your bank.' },
      { from: 'user', text: 'I\'ll try another card. Thanks!' },
      { from: 'admin', text: 'Let me know if it works! I\'m here to help.' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'How do I cancel a booking?' },
      { from: 'admin', text: 'You can cancel from the "My Bookings" section in your profile. Refund policies depend on the service provider.' },
      { from: 'user', text: 'What if it\'s within 24 hours of the event?' },
      { from: 'admin', text: 'For cancellations within 24 hours, typically only 50% is refundable. Check the specific policy for your booking.' },
      { from: 'user', text: 'Got it, thank you for the information.' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'Hi! When will the summer discounts start?' },
      { from: 'admin', text: 'Hello! Our summer sale starts June 1st with up to 25% off selected services!' },
      { from: 'user', text: 'Will there be special packages for destination weddings?' },
      { from: 'admin', text: 'Yes! We\'re launching exclusive destination wedding packages. Stay tuned for announcements!' },
      { from: 'user', text: 'Exciting! Can\'t wait!' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'Is there a way to become a VIP member?' },
      { from: 'admin', text: 'Hi! VIP membership is automatically granted after your first 3 bookings.' },
      { from: 'user', text: 'What benefits do VIP members get?' },
      { from: 'admin', text: 'VIPs get early access to sales, exclusive promo codes, and priority customer support!' },
      { from: 'user', text: 'That sounds amazing. I\'ll definitely keep booking!' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'Hello, I want to report a problem with a vendor.' },
      { from: 'admin', text: 'I\'m sorry to hear that. Can you tell me what happened?' },
      { from: 'user', text: 'The vendor didn\'t show up on time and missed the first hour of our event.' },
      { from: 'admin', text: 'That\'s unacceptable. I\'ll investigate this immediately. Can you share your booking ID?' },
      { from: 'user', text: 'It\'s #BK-2025-0458' },
      { from: 'admin', text: 'Thank you. I\'ll contact the vendor and follow up with you within 24 hours.' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'Can I transfer my booking to someone else?' },
      { from: 'admin', text: 'Hi! Booking transfers depend on the service provider\'s policy. Which service did you book?' },
      { from: 'user', text: 'It\'s a photography package from Studio Leza' },
      { from: 'admin', text: 'Let me check... Yes, they allow transfers with a $50 processing fee. Want me to initiate it?' },
      { from: 'user', text: 'Yes please! The new person\'s email is friend@email.com' },
      { from: 'admin', text: 'Done! They\'ll receive a confirmation email shortly.' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'Hi, I forgot my account password. Can you help reset it?' },
      { from: 'admin', text: 'Of course! Use the "Forgot Password" option on the login page. You\'ll receive a reset link by email.' },
      { from: 'user', text: 'I didn\'t receive the email.' },
      { from: 'admin', text: 'Check your spam folder first. If not there, let me know your email and I\'ll resend it manually.' },
      { from: 'user', text: 'Found it in spam! Thank you!' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'Are there any payment plans available for expensive services?' },
      { from: 'admin', text: 'Yes! For bookings over $1000, you can pay in 3 installments with no extra fees.' },
      { from: 'user', text: 'That\'s helpful! How do I select that option?' },
      { from: 'admin', text: 'During checkout, choose "Pay in Installments" instead of "Pay Full Amount".' },
      { from: 'user', text: 'Perfect, thank you!' },
    ]
  },
  {
    messages: [
      { from: 'user', text: 'Hello! How can I leave a review for a service I used?' },
      { from: 'admin', text: 'Hi! Go to "My Bookings", find the completed booking, and click "Leave Review".' },
      { from: 'user', text: 'I don\'t see that option' },
      { from: 'admin', text: 'The review option appears after the event date has passed. When was your booking?' },
      { from: 'user', text: 'Oh it\'s tomorrow! I\'ll wait then.' },
      { from: 'admin', text: 'Perfect! After tomorrow you\'ll be able to share your experience. Hope it goes great! 🎊' },
    ]
  },
];

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

function getRandomElement(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// Generate date in 2025 for messages
function getRandomMessageDate(baseDate, index) {
  const date = new Date(baseDate);
  date.setMinutes(date.getMinutes() + (index * getRandomInt(5, 30))); // 5-30 minutes between messages
  return date;
}

// Generate conversation start date (May-December 2025)
function getRandomConversationDate() {
  const month = getRandomInt(4, 11); // May to December
  const day = getRandomInt(1, 28);
  const hour = getRandomInt(8, 22);
  return new Date(2025, month, day, hour, getRandomInt(0, 59), 0);
}

// ═══════════════════════════════════════════════════════════════════════════
// 🚀 MAIN SEEDING FUNCTION
// ═══════════════════════════════════════════════════════════════════════════

async function seedChats() {
  const client = new MongoClient(MONGO_URI);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('weddingPlanner');
    
    // Collections
    const usersCol = db.collection('users');
    const chatsCol = db.collection('chats');
    const messagesCol = db.collection('messages');
    const servicesCol = db.collection('services');
    
    // ═══════════════════════════════════════════════════════════════════════
    // STEP 1: Get test users and providers
    // ═══════════════════════════════════════════════════════════════════════
    
    console.log('\n📦 Fetching users and providers...');
    
    // Get our seed users
    const testUsers = await usersCol.find({ 
      email: { $regex: /^testuser\d+@wedding\.com$/ },
      role: 'user'
    }).toArray();
    
    console.log(`   Found ${testUsers.length} test users`);
    
    // Get vendors (providers)
    const vendors = await usersCol.find({ role: 'vendor' }).toArray();
    console.log(`   Found ${vendors.length} vendors`);
    
    // Get admin
    const admin = await usersCol.findOne({ role: 'admin' });
    if (!admin) {
      console.log('   ⚠️ No admin found, skipping admin chats');
    } else {
      console.log(`   Found admin: ${admin.userName || admin.email}`);
    }
    
    // Get services with their providers
    const services = await servicesCol.find({ 
      bookingType: { $ne: 'display' },
      isActive: true 
    }).toArray();
    console.log(`   Found ${services.length} active services`);
    
    if (testUsers.length === 0 || vendors.length === 0) {
      console.log('❌ Not enough users or vendors found!');
      return;
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // STEP 2: Create User-Provider Chats
    // ═══════════════════════════════════════════════════════════════════════
    
    console.log('\n💬 Creating User-Provider conversations...');
    
    let totalChats = 0;
    let totalMessages = 0;
    
    // Create 25-30 user-provider conversations
    const numUserProviderChats = getRandomInt(25, 30);
    
    for (let i = 0; i < numUserProviderChats; i++) {
      const user = getRandomElement(testUsers);
      const vendor = getRandomElement(vendors);
      
      // Check if chat already exists
      const existingChat = await chatsCol.findOne({
        participants: { $all: [user._id, vendor._id] }
      });
      
      if (existingChat) continue;
      
      // Pick a conversation template
      const conversation = getRandomElement(USER_PROVIDER_CONVERSATIONS);
      const startDate = getRandomConversationDate();
      
      // Create chat
      const chat = {
        participants: [user._id, vendor._id],
        lastMessage: conversation.messages[conversation.messages.length - 1].text,
        lastRead: [
          { userId: user._id, lastReadAt: new Date(startDate.getTime() + 86400000) },
          { userId: vendor._id, lastReadAt: new Date(startDate.getTime() + 86400000) }
        ],
        createdAt: startDate,
        updatedAt: new Date(startDate.getTime() + (conversation.messages.length * 20 * 60000))
      };
      
      const insertedChat = await chatsCol.insertOne(chat);
      totalChats++;
      
      // Create messages
      for (let j = 0; j < conversation.messages.length; j++) {
        const msg = conversation.messages[j];
        const senderId = msg.from === 'user' ? user._id : vendor._id;
        const messageDate = getRandomMessageDate(startDate, j);
        
        await messagesCol.insertOne({
          sender: senderId,
          chatId: insertedChat.insertedId,
          content: msg.text,
          isRead: true,
          createdAt: messageDate,
          updatedAt: messageDate
        });
        totalMessages++;
      }
      
      console.log(`   ✅ Chat ${i + 1}: ${user.userName} ↔ ${vendor.userName || vendor.email}`);
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // STEP 3: Create User-Admin Chats
    // ═══════════════════════════════════════════════════════════════════════
    
    if (admin) {
      console.log('\n💬 Creating User-Admin conversations...');
      
      // Create 10-15 user-admin conversations
      const numUserAdminChats = getRandomInt(10, 15);
      const usedUsers = new Set();
      
      for (let i = 0; i < numUserAdminChats && usedUsers.size < testUsers.length; i++) {
        // Pick a user we haven't used for admin chat yet
        let user;
        do {
          user = getRandomElement(testUsers);
        } while (usedUsers.has(user._id.toString()) && usedUsers.size < testUsers.length);
        
        if (usedUsers.has(user._id.toString())) break;
        usedUsers.add(user._id.toString());
        
        // Check if chat already exists
        const existingChat = await chatsCol.findOne({
          participants: { $all: [user._id, admin._id] }
        });
        
        if (existingChat) continue;
        
        // Pick a conversation template
        const conversation = getRandomElement(USER_ADMIN_CONVERSATIONS);
        const startDate = getRandomConversationDate();
        
        // Create chat
        const chat = {
          participants: [user._id, admin._id],
          lastMessage: conversation.messages[conversation.messages.length - 1].text,
          lastRead: [
            { userId: user._id, lastReadAt: new Date(startDate.getTime() + 86400000) },
            { userId: admin._id, lastReadAt: new Date(startDate.getTime() + 86400000) }
          ],
          createdAt: startDate,
          updatedAt: new Date(startDate.getTime() + (conversation.messages.length * 15 * 60000))
        };
        
        const insertedChat = await chatsCol.insertOne(chat);
        totalChats++;
        
        // Create messages
        for (let j = 0; j < conversation.messages.length; j++) {
          const msg = conversation.messages[j];
          const senderId = msg.from === 'user' ? user._id : admin._id;
          const messageDate = getRandomMessageDate(startDate, j);
          
          await messagesCol.insertOne({
            sender: senderId,
            chatId: insertedChat.insertedId,
            content: msg.text,
            isRead: true,
            createdAt: messageDate,
            updatedAt: messageDate
          });
          totalMessages++;
        }
        
        console.log(`   ✅ Chat ${i + 1}: ${user.userName} ↔ Admin`);
      }
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // SUMMARY
    // ═══════════════════════════════════════════════════════════════════════
    
    console.log('\n' + '═'.repeat(60));
    console.log('📊 CHAT SEEDING COMPLETE!');
    console.log('═'.repeat(60));
    console.log(`   💬 Conversations created: ${totalChats}`);
    console.log(`   📝 Messages created: ${totalMessages}`);
    console.log('═'.repeat(60));
    
    // Verify data
    console.log('\n🔍 Verification:');
    const verifyChats = await chatsCol.countDocuments({});
    const verifyMessages = await messagesCol.countDocuments({});
    
    console.log(`   Total Chats in DB: ${verifyChats}`);
    console.log(`   Total Messages in DB: ${verifyMessages}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
    console.log('\n✅ Connection closed');
  }
}

// Run the script
seedChats();
