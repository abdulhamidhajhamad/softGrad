const { MongoClient, ObjectId } = require('mongodb');

async function verifyData() {
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('weddingPlanner');
    
    // Check messages
    const msg = await db.collection('messages').findOne({});
    console.log('\n📨 Sample Message:');
    console.log('  chatId:', msg?.chatId);
    console.log('  chatId type:', typeof msg?.chatId);
    console.log('  isObjectId:', msg?.chatId instanceof ObjectId);
    
    // Try to find chat with this chatId
    if (msg?.chatId) {
      const chatById = await db.collection('chats').findOne({ _id: msg.chatId });
      console.log('  Chat found by chatId:', chatById ? 'YES ✅' : 'NO ❌');
      
      // If not found, try converting
      if (!chatById) {
        const chatIdStr = msg.chatId.toString();
        const chatByStr = await db.collection('chats').findOne({ _id: new ObjectId(chatIdStr) });
        console.log('  Chat found by converted chatId:', chatByStr ? 'YES ✅' : 'NO ❌');
      }
    }
    
    // Count messages and their chatId status
    const allMsgs = await db.collection('messages').find({}).limit(5).toArray();
    console.log('\n📊 Message chatId types:');
    for (const m of allMsgs) {
      console.log(`  ${m._id}: chatId type=${typeof m.chatId}, isObjId=${m.chatId instanceof ObjectId}`);
    }
    
    // Check chats
    const chat = await db.collection('chats').findOne({});
    console.log('\n💬 Sample Chat:');
    console.log('  _id:', chat?._id);
    console.log('  _id type:', typeof chat?._id);
    
    // Count messages for this chat
    if (chat?._id) {
      const msgCountObj = await db.collection('messages').countDocuments({ chatId: chat._id });
      const msgCountStr = await db.collection('messages').countDocuments({ chatId: chat._id.toString() });
      console.log('  Messages by ObjectId:', msgCountObj);
      console.log('  Messages by String:', msgCountStr);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

verifyData();
