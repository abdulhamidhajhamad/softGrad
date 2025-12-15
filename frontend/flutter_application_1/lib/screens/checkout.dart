// lib/screens/checkout.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'payment.dart';

// نفس ألوانك
const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);

/// إذا عندك Booking class بملف تاني، احذف هذا الكلاس واعمل import لملفّك.
class Booking {
  final String clientName;
  final String eventType;
  final String date;
  final String time;
  final String location;
  String status;

  Booking({
    required this.clientName,
    required this.eventType,
    required this.date,
    required this.time,
    required this.location,
    this.status = 'Pending',
  });
}

class CheckoutPage extends StatefulWidget {
  /// ✅ Flow 1: booking checkout
  final Booking? booking;

  /// ✅ Flow 2: cart checkout (نستقبلها كـ List raw لتجنب circular import)
  final List? items;

  /// amount النهائي قبل الرسوم/الخصم (أو total تبع الكارت)
  final double amount;

  final String currency; // "₪"

  /// عشان نمسح الكارت بعد نجاح الدفع بدون ما نستورد CartStore هون
  final VoidCallback? onPaymentSuccess;

  const CheckoutPage({
    super.key,
    this.booking,
    this.items,
    required this.amount,
    this.currency = '₪',
    this.onPaymentSuccess,
  }) : assert(
          booking != null || items != null,
          'Provide either booking or items',
        );

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _promoCtrl = TextEditingController();

  double _discount = 0.0;
  bool _applyingPromo = false;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  double get _subTotal => widget.amount;
  double get _serviceFee => (_subTotal * 0.03);
  double get _total => (_subTotal + _serviceFee - _discount).clamp(0, 999999);

  String _money(double v) => "${widget.currency}${v.toStringAsFixed(0)}";

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _applyingPromo = true);
    await Future.delayed(const Duration(milliseconds: 500));

    double newDiscount = 0;
    if (code == "SAVE10") {
      newDiscount = (_subTotal * 0.10);
    } else if (code == "FREEFEE") {
      newDiscount = _serviceFee;
    } else {
      newDiscount = 0;
    }

    setState(() {
      _discount = newDiscount;
      _applyingPromo = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          newDiscount == 0 ? "Promo code not valid" : "Promo applied ✅",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _goToPayment() async {
    final title = widget.booking?.eventType ?? "Cart Order";
    final subtitle = widget.booking != null
        ? "${widget.booking!.date} • ${widget.booking!.time}"
        : "${(widget.items?.length ?? 0)} item(s)";

    final res = await Navigator.push<PaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          amount: _total,
          currency: widget.currency,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );

    if (!mounted) return;

    if (res?.success == true) {
      // ✅ clear cart / do extra actions from caller
      widget.onPaymentSuccess?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            "Payment successful ✅  (${res!.methodLabel})",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );

      Navigator.pop(context, res);
    } else if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            "Payment cancelled",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Checkout",
          style: GoogleFonts.poppins(
            color: kText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        children: [
          _StepHeader(current: 1),
          const SizedBox(height: 12),

          // ✅ Booking / Cart Summary
          _Card(
            child: b != null ? _bookingSummary(b) : _cartSummary(),
          ),

          const SizedBox(height: 12),

          // Promo
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Promo Code",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: kText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "e.g. SAVE10",
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.black.withOpacity(0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.black.withOpacity(0.08)),
                          ),
                        ),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _applyingPromo ? null : _applyPromo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _applyingPromo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              "Apply",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Price breakdown
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Details",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: kText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                _LineItem(title: "Subtotal", value: _money(_subTotal)),
                _LineItem(title: "Service fee", value: _money(_serviceFee)),
                _LineItem(
                  title: "Discount",
                  value: _discount <= 0 ? "—" : "- ${_money(_discount)}",
                  valueColor: Colors.green.shade700,
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.black.withOpacity(0.08)),
                const SizedBox(height: 6),
                _LineItem(title: "Total", value: _money(_total), bold: true),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _goToPayment,
              icon: const Icon(Icons.lock_rounded),
              label: Text(
                "Proceed to Payment",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kText,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingSummary(Booking b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Booking Summary",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.person, text: b.clientName),
        _InfoRow(icon: Icons.event, text: b.eventType),
        _InfoRow(icon: Icons.calendar_month, text: "${b.date} • ${b.time}"),
        _InfoRow(icon: Icons.location_on, text: b.location),
      ],
    );
  }

  Widget _cartSummary() {
    final list = widget.items ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Order Summary",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) =>
              Divider(color: Colors.black.withOpacity(0.06), height: 14),
          itemBuilder: (_, i) {
            final it = list[i]; // dynamic
            final title = (it?.title ?? "").toString();
            final provider = (it?.providerName ?? "").toString();
            final city = (it?.city ?? "").toString();
            final price = (it?.price is num) ? (it.price as num).toDouble() : 0.0;

            return Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shopping_bag_rounded,
                      color: kPrimary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        "$provider • $city",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _money(price),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------- UI Widgets ----------------

class _StepHeader extends StatelessWidget {
  final int current;
  const _StepHeader({required this.current});

  @override
  Widget build(BuildContext context) {
    Widget dot(bool active, String t) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active ? kPrimary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        alignment: Alignment.center,
        child: Text(
          t,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : Colors.grey.shade700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          dot(current >= 1, "1"),
          const SizedBox(width: 10),
          Text("Checkout", style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(height: 2, width: 26, color: Colors.black.withOpacity(0.12)),
          const SizedBox(width: 10),
          dot(current >= 2, "2"),
          const SizedBox(width: 10),
          Text("Payment", style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: kText),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final String title;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _LineItem({
    required this.title,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              color: valueColor ?? kText,
            ),
          ),
        ],
      ),
    );
  }
}
