const { MongoClient, ObjectId } = require('mongodb');

async function fixChatIds() {
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('weddingPlanner');
    
    // Get all messages with string chatId
    const messages = await db.collection('messages').find({}).toArray();
    
    let fixedCount = 0;
    
    for (const msg of messages) {
      // Check if chatId is string (not ObjectId)
      if (msg.chatId && typeof msg.chatId === 'string') {
        try {
          const chatIdObj = new ObjectId(msg.chatId);
          
          await db.collection('messages').updateOne(
            { _id: msg._id },
            { $set: { chatId: chatIdObj } }
          );
          
          fixedCount++;
        } catch (e) {
          console.log(`⚠️ Could not convert chatId for message ${msg._id}: ${e.message}`);
        }
      }
    }
    
    console.log(`✅ Fixed ${fixedCount} messages (converted chatId from String to ObjectId)`);
    
    // Verify
    const sampleAfter = await db.collection('messages').findOne({});
    console.log('\n📊 Sample message after fix:');
    console.log({
      _id: sampleAfter._id,
      chatId: sampleAfter.chatId,
      chatIdType: typeof sampleAfter.chatId,
      isObjectId: sampleAfter.chatId instanceof ObjectId
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

fixChatIds();
