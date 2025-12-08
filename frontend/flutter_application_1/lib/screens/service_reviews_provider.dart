// lib/screens/service_reviews_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart'; // ⭐ NEW: إضافة مكتبة kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kBackgroundColor = Colors.white;
const Color kTextColor = Colors.black;

/// موديل بسيط للتعليق/الريفيو على خدمة واحدة
class ServiceReview {
  final String id;
  final String customerName;
  final int rating; // من 1 إلى 5 فقط
  final String comment;
  final DateTime createdAt;
  // ⭐ إضافة حقل صورة العميل (افتراضي لإصلاح المشكلة)
  final String? customerAvatarUrl; 

  ServiceReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.customerAvatarUrl, // ⭐ إضافة الحقل إلى الدالة البانية
  });
}

/// شاشة عرض الريفيوز على خدمة معيّنة للبروفايدر
class ServiceReviewsProviderScreen extends StatelessWidget {
  final Map<String, dynamic> service;
  final List<ServiceReview> reviews;

  const ServiceReviewsProviderScreen({
    Key? key,
    required this.service,
    this.reviews = const [],
  }) : super(key: key);

  double get _avgRating {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / reviews.length;
  }

  // ⭐ NEW: دالة مساعدة ذكية لعرض الصورة (Avatar) لحل مشكلة الويب
  Widget _buildDisplayImage(String? imageSource) {
    if (imageSource == null || imageSource.isEmpty) {
      // الصورة الافتراضية
      return const Icon(Icons.person, color: Colors.white, size: 40);
    }
    
    // 1. صورة قادمة من السيرفر (URL)
    if (imageSource.startsWith('http')) {
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, color: Colors.white, size: 40),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    // 2. مسار ملف محلي (Android/iOS)
    if (!kIsWeb) {
      return Image.file(
        File(imageSource),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, color: Colors.white, size: 40),
      );
    }

    // 3. Fallback للويب (في حال كان الملف محلياً وغير URL)
    return const Icon(Icons.person, color: Colors.white, size: 40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0.3,
        centerTitle: true,
        title: Text(
          "Service Reviews",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kTextColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: reviews.isEmpty ? _EmptyReviewsState() : _ReviewsList(
        reviews: reviews,
        avgRating: _avgRating,
        buildImage: _buildDisplayImage, // ⭐ تمرير الدالة المساعدة
      ),
    );
  }
}

// ------------------------------------------------------------------
// تعديل كلاس _ReviewsList لاستقبال الدالة المساعدة
// ------------------------------------------------------------------
class _ReviewsList extends StatelessWidget {
  final List<ServiceReview> reviews;
  final double avgRating;
  final Widget Function(String?) buildImage; // ⭐ إضافة الدالة المساعدة

  const _ReviewsList({
    required this.reviews,
    required this.avgRating,
    required this.buildImage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الإحصائيات (متوسط التقييم والنجوم)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg. Rating',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: kTextColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _RatingStars(rating: avgRating.round()),
                    const SizedBox(height: 4),
                    Text(
                      '${reviews.length} total reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: kTextColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // قائمة الريفيوز
          ...reviews.map((r) => _ReviewCard(
            review: r,
            buildImage: buildImage, // ⭐ تمرير الدالة
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// تعديل كلاس _ReviewCard لاستقبال الدالة المساعدة واستخدامها
// ------------------------------------------------------------------
class _ReviewCard extends StatelessWidget {
  final ServiceReview review;
  final Widget Function(String?) buildImage; // ⭐ إضافة الدالة المساعدة

  const _ReviewCard({required this.review, required this.buildImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ⭐ هنا يتم استدعاء الدالة لحل مشكلة الصورة
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor, // لون خلفية افتراضي
                ),
                child: ClipOval(
                  child: Center(
                    child: buildImage(review.customerAvatarUrl), // ⭐ استخدام الدالة
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kTextColor,
                      ),
                    ),
                    _RatingStars(rating: review.rating),
                  ],
                ),
              ),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: kTextColor.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// *** بقية الكلاسات المساعدة (بدون تغيير) ***
// ------------------------------------------------------------------
class _RatingStars extends StatelessWidget {
  final int rating;

  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }
}

/// حالة عدم وجود أي تعليقات
class _EmptyReviewsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No reviews yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Once customers start leaving feedback on this service, you will see it here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}