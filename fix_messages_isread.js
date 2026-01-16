// fix_messages_isread.js
// هذا السكريبت يصلح الرسائل القديمة اللي isRead: true بالغلط
// يجب أن تكون isRead: false للرسائل اللي المستقبل ما فتحها

const { MongoClient, ObjectId } = require('mongodb');

const MONGO_URI = 'mongodb://localhost:27017/eventPlanner'; // غير الـ URI حسب إعداداتك

async function fixMessagesIsRead() {
  const client = new MongoClient(MONGO_URI);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db();
    const messagesCollection = db.collection('messages');
    const chatsCollection = db.collection('chats');
    
    // 1. جلب جميع الشاتات
    const chats = await chatsCollection.find({}).toArray();
    console.log(`📊 Found ${chats.length} chats`);
    
    let totalFixed = 0;
    
    for (const chat of chats) {
      const chatId = chat._id;
      const participants = chat.participants;
      
      // 2. لكل شات، نشوف آخر قراءة لكل مشارك
      const lastReadMap = {};
      if (chat.lastRead && Array.isArray(chat.lastRead)) {
        for (const lr of chat.lastRead) {
          lastReadMap[lr.userId.toString()] = lr.lastReadAt;
        }
      }
      
      // 3. جلب جميع رسائل هذا الشات
      const messages = await messagesCollection.find({ chatId: chatId }).toArray();
      
      for (const message of messages) {
        const senderId = message.sender.toString();
        
        // 4. إيجاد المستقبل (الشخص الآخر غير المرسل)
        const recipientId = participants.find(p => p.toString() !== senderId);
        
        if (!recipientId) continue;
        
        const recipientIdStr = recipientId.toString();
        const recipientLastRead = lastReadMap[recipientIdStr];
        const messageCreatedAt = message.createdAt;
        
        // 5. إذا المستقبل ما قرأ الرسالة (lastReadAt < messageCreatedAt أو null)
        // فالرسالة يجب أن تكون isRead: false
        let shouldBeRead = false;
        
        if (recipientLastRead && messageCreatedAt) {
          shouldBeRead = new Date(recipientLastRead) >= new Date(messageCreatedAt);
        }
        
        // 6. إذا الرسالة فيها isRead: true بس المفروض false، نصلحها
        if (message.isRead === true && !shouldBeRead) {
          await messagesCollection.updateOne(
            { _id: message._id },
            { $set: { isRead: false } }
          );
          totalFixed++;
          console.log(`🔧 Fixed message ${message._id} in chat ${chatId}`);
        }
      }
    }
    
    console.log(`\n✅ Done! Fixed ${totalFixed} messages`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// طريقة أبسط: جعل كل الرسائل اللي isRead: true تصير false
// (بعدين المستخدمين لما يفتحوا الشات بتصير true)
async function resetAllMessagesToUnread() {
  const client = new MongoClient(MONGO_URI);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db();
    const messagesCollection = db.collection('messages');
    
    // تحديث كل الرسائل لتكون isRead: false
    const result = await messagesCollection.updateMany(
      { isRead: true },
      { $set: { isRead: false } }
    );
    
    console.log(`✅ Reset ${result.modifiedCount} messages to isRead: false`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

// اختر واحدة من الدالتين:
// fixMessagesIsRead();  // طريقة دقيقة
resetAllMessagesToUnread();  // طريقة سريعة (الأفضل للاختبار)
