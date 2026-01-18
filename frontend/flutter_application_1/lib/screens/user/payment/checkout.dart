// lib/screens/checkout.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment.dart';
import 'package:flutter_application_1/services/payment_service/cart_service.dart';
import 'package:flutter_application_1/services/payment_service/payment_service.dart';

// نفس الألوان الأصلية
const Color kPrimary = Color.fromARGB(215, 20, 20, 215);
const Color kBg = Color(0xFFF6F7FB);
const Color kText = Color(0xFF0B1220);
const Color kMuted = Color(0xFF6B7280);

class CheckoutPage extends StatefulWidget {
  final CartResponse cartData;
  final VoidCallback? onPaymentSuccess;

  const CheckoutPage({
    super.key,
    required this.cartData,
    this.onPaymentSuccess,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _promoCtrl = TextEditingController();

  String? _promoCodeApplied;
  double? _discount;
  bool _applyingPromo = false;
  bool _processingPayment = false;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  double get _subTotal => widget.cartData.totalAmount;
  double get _serviceFee => (_subTotal * 0.03);
  double get _finalAmount {
    double total = _subTotal + _serviceFee;
    if (_discount != null) {
      total -= _discount!;
    }
    return total.clamp(0, 999999);
  }

  String _money(double v) => '₪${v.toStringAsFixed(0)}';

  Future<void> _applyPromoFromBackend() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            'Please enter a promo code',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _applyingPromo = true);

    try {
      // Call backend to validate promo
      final checkoutResponse = await PaymentService.checkout(
        currency: 'ils', // ₪
        promoCode: code,
      );

      setState(() {
        _discount = checkoutResponse.discount;
        _promoCodeApplied = checkoutResponse.promoCodeApplied;
        _applyingPromo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              _discount != null && _discount! > 0
                  ? 'Promo applied! Save ${_money(_discount!)} ✓'
                  : 'Promo code not valid',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _applyingPromo = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              'Invalid promo code',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _goToPayment() async {
    setState(() => _processingPayment = true);

    try {
      // Step 1: Create Payment Intent
      final checkoutResponse = await PaymentService.checkout(
        currency: 'ils',
        promoCode: _promoCodeApplied,
      );

      setState(() => _processingPayment = false);

      if (!mounted) return;

      // Step 2: Navigate to Payment Page
      final paymentResult = await Navigator.push<PaymentResult>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            amount: checkoutResponse.finalAmount,
            currency: '₪',
            title: 'Cart Order',
            subtitle: '${widget.cartData.items.length} item(s)',
            clientSecret: checkoutResponse.clientSecret,
            originalAmount: checkoutResponse.originalAmount,
            discount: checkoutResponse.discount,
            promoCode: checkoutResponse.promoCodeApplied,
          ),
        ),
      );

      if (!mounted) return;

      // Step 3: Handle Payment Result
      if (paymentResult?.success == true) {
        // Payment confirmed! Cart will be cleared by backend
        widget.onPaymentSuccess?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              'Payment successful ✓  (${paymentResult!.methodLabel})',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );

        // Return to previous screen
        Navigator.pop(context);
      } else if (paymentResult != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              'Payment cancelled',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _processingPayment = false);

      if (mounted) {
        // Show error dialog instead of snackbar for better visibility
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Payment Error',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: kPrimary),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Order Summary
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Summary",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: kText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.cartData.items.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.black.withOpacity(0.06),
                    height: 14,
                  ),
                  itemBuilder: (_, i) {
                    final item = widget.cartData.items[i];
                    return Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: kPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.serviceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.companyName,
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
                          _money(item.price),
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
            ),
          ),

          const SizedBox(height: 12),

          // Promo Code (Optional)
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Promo Code",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          color: kText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'Optional',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
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
                            horizontal: 14,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                        ),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _applyingPromo ? null : _applyPromoFromBackend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _applyingPromo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Apply",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ],
                ),
                if (_promoCodeApplied != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Code "$_promoCodeApplied" applied!',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                if (_discount != null && _discount! > 0)
                  _LineItem(
                    title: "Discount",
                    value: "- ${_money(_discount!)}",
                    valueColor: Colors.green.shade700,
                  ),
                const SizedBox(height: 8),
                Divider(color: Colors.black.withOpacity(0.08)),
                const SizedBox(height: 6),
                _LineItem(
                  title: "Total",
                  value: _money(_finalAmount),
                  bold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _processingPayment ? null : _goToPayment,
              icon: _processingPayment
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
                _processingPayment ? "Processing..." : "Proceed to Payment",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kText,
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