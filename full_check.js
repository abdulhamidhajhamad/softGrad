const { MongoClient, ObjectId } = require('mongodb');

async function fullCheck() {
  const client = new MongoClient('mongodb://localhost:27017');
  
  try {
    await client.connect();
    const db = client.db('weddingPlanner');
    
    // Get all unique chatIds from messages
    const chatIdsInMessages = await db.collection('messages').distinct('chatId');
    console.log('📨 Unique chatIds in messages:', chatIdsInMessages.length);
    chatIdsInMessages.forEach(id => console.log('  -', id.toString()));
    
    // Get all chat _ids
    const chats = await db.collection('chats').find({}).toArray();
    console.log('\n💬 All chats:', chats.length);
    chats.forEach(c => console.log('  -', c._id.toString()));
    
    // Check which chatIds match which chats
    console.log('\n🔍 Matching chatIds to chats:');
    for (const chatId of chatIdsInMessages) {
      const chatIdStr = chatId.toString();
      const foundChat = chats.find(c => c._id.toString() === chatIdStr);
      console.log(`  ${chatIdStr}: ${foundChat ? '✅ Chat exists' : '❌ NO CHAT FOUND'}`);
      
      if (!foundChat) {
        // Count messages for this orphan chatId
        const count = await db.collection('messages').countDocuments({ chatId: chatId });
        console.log(`    -> Has ${count} messages with no matching chat!`);
      }
    }
    
    // Check if any chat has messages
    console.log('\n📊 Messages per chat:');
    for (const chat of chats) {
      const count = await db.collection('messages').countDocuments({ chatId: chat._id });
      console.log(`  Chat ${chat._id}: ${count} messages`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

fullCheck();
