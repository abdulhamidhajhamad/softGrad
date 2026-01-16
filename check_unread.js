const { MongoClient, ObjectId } = require('mongodb');

async function checkUnreadCounts() {
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('weddingPlanner');
    
    // Get all vendors
    const vendors = await db.collection('users').find({ role: 'vendor' }).limit(3).toArray();
    
    console.log('\n📊 Checking unread counts for vendors:\n');
    
    for (const vendor of vendors) {
      const userId = vendor._id;
      
      // Get all chats for this vendor
      const chats = await db.collection('chats').find({ participants: userId }).toArray();
      const chatIds = chats.map(c => c._id);
      
      // Count unread messages (not sent by this user, isRead = false)
      const unreadCount = await db.collection('messages').countDocuments({
        chatId: { $in: chatIds },
        sender: { $ne: userId },
        isRead: false
      });
      
      console.log(`👤 ${vendor.userName || vendor.email}`);
      console.log(`   ID: ${userId}`);
      console.log(`   Chats: ${chats.length}`);
      console.log(`   Unread Messages: ${unreadCount}`);
      console.log('');
    }
    
    // Also check total messages status
    const totalUnread = await db.collection('messages').countDocuments({ isRead: false });
    const totalRead = await db.collection('messages').countDocuments({ isRead: true });
    console.log(`\n📈 Total Messages: Unread=${totalUnread}, Read=${totalRead}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

checkUnreadCounts();
