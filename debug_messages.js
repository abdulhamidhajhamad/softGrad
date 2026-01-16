const { MongoClient, ObjectId } = require('mongodb');

async function debugMessages() {
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    const db = client.db('weddingPlanner');
    
    // Get sample messages
    const messages = await db.collection('messages').find({}).limit(5).toArray();
    
    console.log('📨 Sample Messages:\n');
    for (const msg of messages) {
      console.log({
        _id: msg._id.toString(),
        chatId: msg.chatId?.toString(),
        chatIdType: typeof msg.chatId,
        sender: msg.sender?.toString(),
        isRead: msg.isRead,
        content: msg.content?.substring(0, 20)
      });
      
      // Check if chatId is ObjectId or string
      if (msg.chatId) {
        const chatExists = await db.collection('chats').findOne({ _id: msg.chatId });
        console.log(`   Chat exists: ${chatExists ? 'YES' : 'NO'}`);
        
        // Try as string
        if (!chatExists) {
          const chatAsString = await db.collection('chats').findOne({ _id: new ObjectId(msg.chatId.toString()) });
          console.log(`   Chat exists (as ObjectId): ${chatAsString ? 'YES' : 'NO'}`);
        }
      }
      console.log('');
    }
    
    // Check chats
    console.log('\n📬 Sample Chats:\n');
    const chats = await db.collection('chats').find({}).limit(3).toArray();
    for (const chat of chats) {
      console.log({
        _id: chat._id.toString(),
        participants: chat.participants?.map(p => p.toString()),
        lastMessage: chat.lastMessage?.substring(0, 20)
      });
      
      // Count messages for this chat
      const msgCount = await db.collection('messages').countDocuments({ chatId: chat._id });
      const msgCountStr = await db.collection('messages').countDocuments({ chatId: chat._id.toString() });
      console.log(`   Messages (ObjectId): ${msgCount}`);
      console.log(`   Messages (String): ${msgCountStr}`);
      console.log('');
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

debugMessages();
