// lib/screens/payment.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/services/payment_service/payment_service.dart';
import 'cart.dart' show CartStore;

const Color kPrimaryColor = Color.fromARGB(215, 20, 20, 215);
const Color kTextColor = Colors.black;
const Color kBackgroundColor = Colors.white;

enum PaymentMethod { card }

class PaymentResult {
  final bool success;
  final PaymentMethod method;
  final String transactionId;

  PaymentResult({
    required this.success,
    required this.method,
    required this.transactionId,
  });

  String get methodLabel {
    switch (method) {
      case PaymentMethod.card:
        return "Card";
    }
  }
}

class PaymentPage extends StatefulWidget {
  final double amount;
  final String currency;
  final String title;
  final String subtitle;
  final String clientSecret;
  final double? originalAmount;
  final double? discount;
  final String? promoCode;

  const PaymentPage({
    super.key,
    required this.amount,
    this.currency = '₪',
    required this.title,
    required this.subtitle,
    required this.clientSecret,
    this.originalAmount,
    this.discount,
    this.promoCode,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod _method = PaymentMethod.card;

  final _nameCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cardCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _money(double v) => "${widget.currency}${v.toStringAsFixed(0)}";

  bool _validateCard() {
    final name = _nameCtrl.text.trim();
    final card = _cardCtrl.text.replaceAll(' ', '').trim();
    final exp = _expCtrl.text.trim();
    final cvv = _cvvCtrl.text.trim();

    if (name.length < 3) return false;
    if (card.length < 12) return false;
    if (!exp.contains('/')) return false;
    if (cvv.length < 3) return false;
    return true;
  }

  Future<void> _pay() async {
    if (_method == PaymentMethod.card && !_validateCard()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            "Please fill card details correctly",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(milliseconds: 1200));

      // Extract PaymentIntent ID from clientSecret
      final paymentIntentId = widget.clientSecret.split('_secret_')[0];

      // Call backend to confirm payment and create bookings
      final result = await PaymentService.confirmPayment(paymentIntentId);

      print('✅ Payment confirmed: ${result.success}'); // ✅ أضف هذا السطر

      setState(() => _loading = false);

      if (!mounted) return;

      if (result.success) {
        // ✅ Clear local CartStore after successful payment
        CartStore.instance.clear();
        
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Payment Successful ✓",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.originalAmount != null) ...[
                  _InfoLine(
                    label: "Original Amount:",
                    value: _money(widget.originalAmount!),
                  ),
                  const SizedBox(height: 6),
                ],
                if (widget.discount != null && widget.discount! > 0) ...[
                  _InfoLine(
                    label: "Discount:",
                    value: "- ${_money(widget.discount!)}",
                    valueColor: Colors.green.shade700,
                  ),
                  const SizedBox(height: 6),
                ],
                if (widget.promoCode != null) ...[
                  _InfoLine(
                    label: "Promo Code:",
                    value: widget.promoCode!,
                    valueColor: Colors.amber.shade800,
                  ),
                  const SizedBox(height: 6),
                ],
                _InfoLine(
                  label: "Amount Paid:",
                  value: _money(widget.amount),
                  bold: true,
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  label: "Method:",
                  value: _label(_method),
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  label: "Transaction:",
                  value: result.paymentIntent.id.substring(0, 20),
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  label: "Bookings Created:",
                  value: "${result.bookings.length}",
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Confirmation email sent!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "Done",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                ),
              )
            ],
          ),
        );

        // Return success
        Navigator.pop(
          context,
          PaymentResult(
            success: true,
            method: _method,
            transactionId: result.paymentIntent.id,
          ),
        );
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      print('❌ Payment error: $e'); // ✅ أضف هذا السطر

      setState(() => _loading = false);

      if (mounted) {
        // Show error dialog for better visibility
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Payment Failed',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kPrimaryColor),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  String _label(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return "Card";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () {
            Navigator.pop(
              context,
              PaymentResult(
                success: false,
                method: _method,
                transactionId: "",
              ),
            );
          },
        ),
        title: Text(
          "Payment",
          style: GoogleFonts.poppins(
            color: kTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        children: [
          _StepHeader(current: 2),
          const SizedBox(height: 12),
          _Card(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.originalAmount != null &&
                        widget.originalAmount! > widget.amount) ...[
                      Text(
                        _money(widget.originalAmount!),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      _money(widget.amount),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.promoCode != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Promo "${widget.promoCode}" applied',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  if (widget.discount != null)
                    Text(
                      '- ${_money(widget.discount!)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Method",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _MethodTile(
                  icon: Icons.credit_card_rounded,
                  title: "Card",
                  subtitle: "Visa / MasterCard",
                  selected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _cardForm(),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _pay,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_rounded),
              label: Text(
                _loading ? "Processing..." : "Pay Now",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kTextColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardForm() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Card Details",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _Input(
            controller: _nameCtrl,
            label: "Name on card",
            hint: "Full name",
            icon: Icons.person,
          ),
          const SizedBox(height: 10),
          _Input(
            controller: _cardCtrl,
            label: "Card number",
            hint: "1234 5678 9012 3456",
            icon: Icons.credit_card,
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Input(
                  controller: _expCtrl,
                  label: "Expiry",
                  hint: "MM/YY",
                  icon: Icons.calendar_month,
                  keyboard: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Input(
                  controller: _cvvCtrl,
                  label: "CVV",
                  hint: "***",
                  icon: Icons.password_rounded,
                  keyboard: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}

// ---------------- UI Widgets ----------------

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _InfoLine({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

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
          color: active ? kPrimaryColor : Colors.grey.shade200,
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
          dot(true, "1"),
          const SizedBox(width: 10),
          Text("Checkout",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
              height: 2, width: 26, color: Colors.black.withOpacity(0.12)),
          const SizedBox(width: 10),
          dot(current >= 2, "2"),
          const SizedBox(width: 10),
          Text("Payment",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
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

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? kPrimaryColor.withOpacity(0.10)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? kPrimaryColor.withOpacity(0.35)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Icon(
                icon,
                color: selected ? kPrimaryColor : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? kPrimaryColor : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;

  const _Input({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: Colors.grey.shade700),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
      ),
      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
    );
  }
}