from utils.db import get_services_data
import numpy as np
import pandas as pd
from textblob import TextBlob
from bson import ObjectId
import itertools

def analyze_review_sentiment(text):
    """تحليل الريفيو لتحديد المزاج (إيجابي/سلبي)"""
    if not text or not isinstance(text, str):
        return 0
    return TextBlob(text).sentiment.polarity

def clean_service_data(service):
    """تنظيف البيانات من أي عناصر غير قابلة للتحويل لـ JSON"""
    clean_service = {}
    for key, value in service.items():
        if isinstance(value, (str, int, float, bool, list, dict)) or value is None:
            if isinstance(value, (int, float)):
                clean_service[key] = float(value)
            else:
                clean_service[key] = value
        elif isinstance(value, ObjectId):
            clean_service[key] = str(value)
    return clean_service

def to_jsonable(data):
    """تحويل أي بيانات تحتوي على ObjectId أو أنواع غير قابلة للتحويل إلى JSON"""
    if isinstance(data, list):
        return [to_jsonable(item) for item in data]
    elif isinstance(data, dict):
        return {k: to_jsonable(v) for k, v in data.items()}
    elif isinstance(data, ObjectId):
        return str(data)
    elif isinstance(data, (np.integer, np.floating)):
        return float(data)
    else:
        return data

def recommend_packages(services, budget, date):
    """توليد باكدجات زفاف ذكية - كل باكجة تحتوي على جميع الخدمات المطلوبة"""
    try:
        data = get_services_data()

        if not data:
            return [{"message": "لا توجد خدمات متاحة في النظام"}]

        print(f"🔍 البحث عن خدمات: {services}")
        print(f"💰 الميزانية: {budget}")
        print(f"📅 التاريخ: {date}")

        cleaned_data = [clean_service_data(service) for service in data]

        services_by_category = {}
        for service in cleaned_data:
            category = service.get('category')
            if category in services:  
                if category not in services_by_category:
                    services_by_category[category] = []
                
                booked_dates = service.get('bookedDates', [])
                price = float(service.get('price', 0))
                
                if (date not in booked_dates and 
                    price <= budget * 1.2): 
                    services_by_category[category].append(service)

        print(f"📊 الخدمات المتاحة بعد الفلترة:")
        for category, items in services_by_category.items():
            print(f"   - {category}: {len(items)} خدمة")

        missing_categories = [cat for cat in services if cat not in services_by_category or not services_by_category[cat]]
        if missing_categories:
            return [{"message": f"لا توجد خدمات متاحة للفئات: {', '.join(missing_categories)}"}]

        all_combinations = []
        
        category_services = [services_by_category[cat] for cat in services]
        
        for combination in itertools.product(*category_services):
            total_price = sum(float(item['price']) for item in combination)
            
            if total_price <= budget * 1.2:  # حتى 20% فوق الميزانية
                all_combinations.append({
                    'items': list(combination),
                    'total_price': total_price,
                    'score': sum(item.get('rating', 0) for item in combination) / len(combination)
                })

        print(f"🔢 عدد التركيبات الممكنة: {len(all_combinations)}")

        if not all_combinations:
            return [{"message": "لم نجد تركيبات تناسب ميزانيتك"}]
        all_combinations.sort(key=lambda x: x['total_price'])
        packages = []
        for i, combo in enumerate(all_combinations[:3]):
            packages.append({
                "name": f"الباقة {i+1}",
                "total_price": round(combo['total_price'], 2),
                "score": round(combo['score'], 2),
                "items": combo['items']
            })

        print(f"🎁 تم إنشاء {len(packages)} باقة")
        
        if len(packages) < 3:
            base_combo = all_combinations[0]
            for i in range(len(packages), 3):
                alternative_items = base_combo['items'].copy()
                
                category_to_change = services[i % len(services)]
                alternative_services = services_by_category[category_to_change]
                
                if len(alternative_services) > 1:
                    new_service = alternative_services[(i + 1) % len(alternative_services)]
                    for idx, item in enumerate(alternative_items):
                        if item['category'] == category_to_change:
                            alternative_items[idx] = new_service
                            break
                    
                    total_price = sum(float(item['price']) for item in alternative_items)
                    avg_score = sum(item.get('rating', 0) for item in alternative_items) / len(alternative_items)
                    
                    packages.append({
                        "name": f"الباقة {i+1}",
                        "total_price": round(total_price, 2),
                        "score": round(avg_score, 2),
                        "items": alternative_items
                    })

        return to_jsonable(packages)

    except Exception as e:
        print(f"❌ خطأ: {e}")
        return [{"error": "حدث خطأ في النظام", "details": str(e)}]