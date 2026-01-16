const { MongoClient } = require('mongodb');

async function fixMessages() {
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('weddingPlanner');
    
    // Count before
    const beforeCount = await db.collection('messages').countDocuments({ isRead: true });
    console.log(`📊 Messages with isRead=true: ${beforeCount}`);
    
    // Reset all to unread
    const result = await db.collection('messages').updateMany(
      { isRead: true },
      { $set: { isRead: false } }
    );
    
    console.log(`✅ Reset ${result.modifiedCount} messages to isRead: false`);
    
    // Count after
    const afterUnread = await db.collection('messages').countDocuments({ isRead: false });
    console.log(`📊 Messages now unread: ${afterUnread}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

fixMessages();
