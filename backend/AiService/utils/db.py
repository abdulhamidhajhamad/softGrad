from pymongo import MongoClient
import os
from dotenv import load_dotenv

load_dotenv()
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/weddingPlanner")
DB_NAME = os.getenv("DB_NAME", "weddingPlanner")

def get_services_data():
    try:
        client = MongoClient(MONGO_URI)
        db = client[DB_NAME]
        collection = db["services"]
        
        # ⚠️ استبعاد _id تماماً من النتائج
        data = list(collection.find({}, {'_id': 0}))
        
        print(f"✅ تم جلب {len(data)} خدمة من قاعدة البيانات")
        for item in data:
            print(f"   - {item.get('serviceName', 'لا يوجد اسم')} - السعر: {item.get('price', 'غير محدد')}")
        
        return data
    except Exception as e:
        print(f"❌ خطأ في جلب البيانات: {e}")
        return []


