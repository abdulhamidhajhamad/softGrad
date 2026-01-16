import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'booking_common_widgets.dart'; 
import 'package:flutter_application_1/services/service_service.dart';

import '../../map_location_picker.dart' hide kPrimaryColor, kTextColor;

class AddHourlyService extends StatefulWidget {
  final String category;
  final String bookingType;

  const AddHourlyService({
    super.key,
    required this.category,
    required this.bookingType,
  });

  @override
  State<AddHourlyService> createState() => _AddHourlyServiceState();
}

class _AddHourlyServiceState extends State<AddHourlyService> {
  final _formKey = GlobalKey<FormState>();

  // common
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final latitudeCtrl = TextEditingController();
  final longitudeCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final discountCtrl = TextEditingController();

  String? _selectedCity;
  bool _visibleInSearch = true;

  // ✅ Multi-media gallery (up to 10 images/videos)
  final List<MediaItem> _mediaItems = [];
  static const int _maxMediaItems = 10;

  // ✅ Additional info items (key/value pairs)
  final List<Map<String, String>> _additionalInfo = [];

  // ✅ live pricing preview
  double? _finalPrice;
  double? _savedAmount;
  double? _selectedLat;
  double? _selectedLng;
  bool _hasLocationSet = false;

  // 🆕 هل الخدمة لها موقع ثابت أم تذهب للعميل
  bool _hasFixedLocation = true;

  // 🆕 Venue Type (Indoor/Outdoor) - Default: Indoor
  String _venueType = "indoor";

  // 🆕 Maximum Venue Capacity (عدد الأشخاص الأقصى)
  final maxCapacityCtrl = TextEditingController();

  // hourly-specific (min must allow 1 hour)
  final minHoursCtrl = TextEditingController(text: "1");
  final maxHoursCtrl = TextEditingController(text: "8");

  // days (full words)
  final List<String> _weekdays = const [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  final Set<String> _selectedDays = {"Friday", "Saturday", "Sunday"};

  TimeOfDay? _from;
  TimeOfDay? _to;

  // UX state
  RangeValues _hoursRange = const RangeValues(1, 8);

  // Daily capacity planner (suggested only)
  double _gapMinutes = 0;

  // ✅ NEW: choose suggested slots (count = seats per day)
  final Set<String> _selectedSuggestedSlots = {};

  @override
  void initState() {
    super.initState();

    final minH = int.tryParse(minHoursCtrl.text.trim()) ?? 1;
    final maxH = int.tryParse(maxHoursCtrl.text.trim()) ?? 8;

    final safeMin = minH.clamp(1, 24);
    final safeMax = maxH.clamp(1, 24);

    _hoursRange = RangeValues(
      safeMin.toDouble(),
      (safeMax < safeMin ? safeMin : safeMax).toDouble(),
    );

    _gapMinutes = 0;

    // ✅ live price calc
    priceCtrl.addListener(_recalcPrice);
    discountCtrl.addListener(_recalcPrice);
    _recalcPrice();
  }

  void _recalcPrice() {
    final price = double.tryParse(priceCtrl.text.trim());
    final disc = double.tryParse(discountCtrl.text.trim());

    if (price == null || price <= 0) {
      if (_finalPrice != null || _savedAmount != null) {
        setState(() {
          _finalPrice = null;
          _savedAmount = null;
        });
      }
      return;
    }

    final d = (disc ?? 0).clamp(0, 100);
    final finalP = price * (1 - d / 100.0);
    final saved = price - finalP;

    if (_finalPrice == finalP && _savedAmount == saved) return;

    setState(() {
      _finalPrice = finalP;
      _savedAmount = saved;
    });
  }

  Future<void> _pickImages() async {
    if (_mediaItems.length >= _maxMediaItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You can't upload more than $_maxMediaItems items",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;

    final remainingSlots = _maxMediaItems - _mediaItems.length;
    final filesToAdd = files.take(remainingSlots).toList();

    if (files.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Only $remainingSlots more items can be added. Some images were skipped.",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    for (final file in filesToAdd) {
      final bytes = await file.readAsBytes();
      setState(() {
        _mediaItems.add(MediaItem(
          bytes: bytes,
          isVideo: false,
          fileName: file.name,
        ));
      });
    }
  }

  Future<void> _pickVideo() async {
    if (_mediaItems.length >= _maxMediaItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You can't upload more than $_maxMediaItems items",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _mediaItems.add(MediaItem(
        bytes: bytes,
        isVideo: true,
        fileName: file.name,
      ));
    });
  }

  void _removeMediaItem(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
  }

  Future<void> _addAdditionalInfo() async {
    final result = await showAddInfoDialog(context);
    if (result != null) {
      setState(() => _additionalInfo.add(result));
    }
  }

  void _removeAdditionalInfo(int index) {
    setState(() => _additionalInfo.removeAt(index));
  }

  Future<void> _pickFrom() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _from ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: "Start time",
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _to ?? const TimeOfDay(hour: 22, minute: 0),
      helpText: "End time",
    );
    if (picked != null) setState(() => _to = picked);
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return "Not set";
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMinutes(int minutes) {
    final m = minutes % (24 * 60);
    final h = (m ~/ 60) % 24;
    final mm = m % 60;
    return TimeOfDay(hour: h, minute: mm);
  }

  String _day3(String d) => d.length <= 3 ? d : d.substring(0, 3);

  String _daysSummary() {
    if (_selectedDays.isEmpty) return "No days selected";
    if (_selectedDays.length == _weekdays.length) return "Every day";

    final ordered = _weekdays.where(_selectedDays.contains).toList();
    return ordered.map(_day3).join(", ");
  }

  void _syncHoursCtrls(RangeValues v) {
    minHoursCtrl.text = v.start.round().toString();
    maxHoursCtrl.text = v.end.round().toString();
  }

  int _eventsPerDay() {
    if (_from == null || _to == null) return 0;

    final fromMin = _toMinutes(_from!);
    final toMin = _toMinutes(_to!);

    final usable = toMin - fromMin;
    
    final minHours = double.tryParse(minHoursCtrl.text.trim()) ?? 1.0;
    final eventMin = (minHours * 60).round();
    final gapMin = _gapMinutes.round();

    if (usable <= 0 || eventMin <= 0) return 0;
    if (usable < eventMin) return 0;

    final n = ((usable + gapMin) / (eventMin + gapMin)).floor();
    return n.clamp(0, 50);
  }

  List<Map<String, String>> _buildSlotsPreview() {
    if (_from == null || _to == null) return [];

    final n = _eventsPerDay();
    if (n <= 0) return [];

    final toMin = _toMinutes(_to!);
    final start = _toMinutes(_from!);
    
    final minHours = double.tryParse(minHoursCtrl.text.trim()) ?? 1.0;
    final eventMin = (minHours * 60).round();
    final gapMin = _gapMinutes.round();

    var cur = start;
    final slots = <Map<String, String>>[];

    for (int i = 0; i < n; i++) {
      final s = cur;
      final e = cur + eventMin;
      if (e > toMin) break;

      slots.add({
        "start": _fmtTime(_fromMinutes(s)),
        "end": _fmtTime(_fromMinutes(e)),
      });

      cur = e + gapMin;
    }
    return slots;
  }

  String _slotKey(Map<String, String> s) => '${s["start"]}-${s["end"]}';

  bool _saving = false;

  Future<void> _trySave() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select at least one day", style: GoogleFonts.poppins())),
      );
      return;
    }

    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Set time range", style: GoogleFonts.poppins())),
      );
      return;
    }

    if (_toMinutes(_to!) <= _toMinutes(_from!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("End time must be after start time", style: GoogleFonts.poppins())),
      );
      return;
    }

    // 🆕 التحقق من المدينة فقط إذا كانت الخدمة لها موقع ثابت
    if (_hasFixedLocation && (_selectedCity == null || _selectedCity!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select a city", style: GoogleFonts.poppins())),
      );
      return;
    }

    final form = {
      "category": widget.category,
      "bookingType": "hourly",

      "name": nameCtrl.text.trim(),
      "description": descCtrl.text.trim(),

      // 🆕 إضافة hasFixedLocation
      "hasFixedLocation": _hasFixedLocation,

      // الموقع يُرسل فقط إذا كانت الخدمة لها موقع ثابت
      if (_hasFixedLocation) ...{
        "address": addressCtrl.text.trim(),
        "city": _selectedCity,
        "latitude": _selectedLat?.toString() ?? "",
        "longitude": _selectedLng?.toString() ?? "",
      },

      "price": priceCtrl.text.trim(),
      "discount": discountCtrl.text.trim(),

      "finalPrice": _finalPrice?.toStringAsFixed(2),
      "savedAmount": _savedAmount?.toStringAsFixed(2),

      // ✅ Multi-media: send list of media items
      "mediaItems": _mediaItems.map((item) => {
        "bytes": item.bytes,
        "isVideo": item.isVideo,
        "fileName": item.fileName,
      }).toList(),
      // ✅ Cover image is the first image (for backwards compatibility)
      "coverImage": _mediaItems.isNotEmpty && !_mediaItems.first.isVideo 
          ? _mediaItems.first.bytes 
          : null,
      "highlights": _additionalInfo,
      "visibleInSearch": _visibleInSearch,

      "pricingModel": "per_hour",
      "minHours": minHoursCtrl.text.trim(),
      "maxHours": maxHoursCtrl.text.trim(),
      "days": _selectedDays.toList(),
      "timeFrom": _fmtTime(_from),
      "timeTo": _fmtTime(_to),

      if (_gapMinutes > 0) "breakMinutes": _gapMinutes.round().toString(),
      
      "slotsPreview": _buildSlotsPreview(),
      "selectedSuggestedSlots": _selectedSuggestedSlots.toList(),
      "seatsPerDay": _selectedSuggestedSlots.length,

      // 🆕 إضافة venueType للقاعات فقط
      if (widget.category == "Venues") "venueType": _venueType,
      
      // 🆕 إضافة maxCapacity للقاعات فقط
      if (widget.category == "Venues" && maxCapacityCtrl.text.trim().isNotEmpty)
        "maxCapacity": maxCapacityCtrl.text.trim(),
    };

    setState(() => _saving = true);

    try {
      await ServiceService.addServiceFromBookingForm(form);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Service created successfully ✅", style: GoogleFonts.poppins())),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e", style: GoogleFonts.poppins())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    priceCtrl.removeListener(_recalcPrice);
    discountCtrl.removeListener(_recalcPrice);

    nameCtrl.dispose();
    descCtrl.dispose();
    addressCtrl.dispose();
    latitudeCtrl.dispose();
    longitudeCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    minHoursCtrl.dispose();
    maxHoursCtrl.dispose();
    maxCapacityCtrl.dispose();
    super.dispose();
  }

  Widget _miniTitle(String t) => Text(
        t,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
      );

  Widget _hint(String t) => Text(
        t,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
      );

  Widget _summaryRow({
    required IconData icon,
    required String title,
    required String value,
    bool smallValue = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kPrimaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: smallValue ? 11 : 12,
            fontWeight: smallValue ? FontWeight.w600 : FontWeight.w700,
            color: smallValue ? Colors.grey.shade800 : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _infoPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style:
                GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _prettyHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 100),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 44,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.access_time_rounded, color: kPrimaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hourly Booking!",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.category,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(String d) {
    final selected = _selectedDays.contains(d);

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      selectedColor: kPrimaryColor.withOpacity(0.14),
      backgroundColor: const Color(0xFFF9FAFB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      label: SizedBox(
        height: 20,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _day3(d),
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      onSelected: (_) {
        setState(() {
          if (selected) {
            _selectedDays.remove(d);
          } else {
            _selectedDays.add(d);
          }
        });
      },
    );
  }

  Widget _daysTwoRowsNeat() {
    final row1 = _weekdays.take(4).toList();
    final row2 = _weekdays.skip(4).take(3).toList();

    Widget buildRow(List<String> days, {bool addEmptyLast = false}) {
      return Row(
        children: [
          for (int i = 0; i < days.length; i++) ...[
            Expanded(child: SizedBox(height: 36, child: _dayChip(days[i]))),
            if (i != days.length - 1) const SizedBox(width: 8),
          ],
          if (addEmptyLast) ...[
            const SizedBox(width: 8),
            const Expanded(child: SizedBox(height: 36)),
          ],
        ],
      );
    }

    return Column(
      children: [
        buildRow(row1),
        const SizedBox(height: 8),
        buildRow(row2, addEmptyLast: true),
      ],
    );
  }

  Widget _dailyCapacityCard(int eventsCount, List<Map<String, String>> slots) {
    final validKeys = slots.map(_slotKey).toSet();
    _selectedSuggestedSlots.removeWhere((k) => !validKeys.contains(k));

    final minHours = double.tryParse(minHoursCtrl.text.trim()) ?? 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kPrimaryColor.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Daily capacity",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Set optional break time between bookings.",
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.grey.shade700),
          ),
          
          const SizedBox(height: 12),
          Text(
            "Break between events (optional)",
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _gapMinutes.clamp(0, 180),
                  min: 0,
                  max: 180,
                  divisions: 36,
                  label: _gapMinutes == 0 
                      ? "No break" 
                      : "${_gapMinutes.round()} min",
                  onChanged: (v) {
                    setState(() {
                      final rounded = (v / 5).round() * 5;
                      _gapMinutes = rounded.toDouble().clamp(0, 180);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _gapMinutes == 0 
                      ? "None" 
                      : "${_gapMinutes.round()} min",
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
              )
            ],
          ),
          
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoPill(
                icon: Icons.event_note_rounded,
                text: "$eventsCount events/day",
              ),
              _infoPill(
                icon: Icons.timer_rounded,
                text: "${minHours.toStringAsFixed(1)}h each",
              ),
              if (_gapMinutes > 0)
                _infoPill(
                  icon: Icons.more_time_rounded,
                  text: "${_gapMinutes.round()}m break",
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          Text(
            "Suggested schedule",
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          
          if (_from == null || _to == null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: kPrimaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Set your working hours first (Availability).",
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else if (slots.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Not enough time to fit an event with the current settings.",
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: slots.take(12).map((s) {
                final key = _slotKey(s);
                final selected = _selectedSuggestedSlots.contains(key);

                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedSuggestedSlots.remove(key);
                      } else {
                        _selectedSuggestedSlots.add(key);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? kPrimaryColor.withOpacity(0.10)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? kPrimaryColor.withOpacity(0.35)
                            : Colors.white.withOpacity(0.9),
                      ),
                    ),
                    child: Text(
                      '${s["start"]} - ${s["end"]}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: selected ? kPrimaryColor : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_seat_rounded,
                      color: kPrimaryColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Seats per day",
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    "${_selectedSuggestedSlots.length}",
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 Widget للـ Venue Type (Indoor/Outdoor) - Modern UI/UX
  Widget _buildVenueTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Venue Type",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Select whether your venue is indoors or outdoors",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Radio Buttons - Modern Design
          Row(
            children: [
              // Indoor Option
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _venueType = "indoor"),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _venueType == "indoor"
                          ? kPrimaryColor.withOpacity(0.12)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _venueType == "indoor"
                            ? kPrimaryColor
                            : Colors.grey.shade300,
                        width: _venueType == "indoor" ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _venueType == "indoor"
                                ? Colors.white
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.home_rounded,
                            color: _venueType == "indoor"
                                ? kPrimaryColor
                                : Colors.grey.shade600,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Indoor",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _venueType == "indoor"
                                ? kPrimaryColor
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Inside venue",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Outdoor Option
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _venueType = "outdoor"),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _venueType == "outdoor"
                          ? kPrimaryColor.withOpacity(0.12)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _venueType == "outdoor"
                            ? kPrimaryColor
                            : Colors.grey.shade300,
                        width: _venueType == "outdoor" ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _venueType == "outdoor"
                                ? Colors.white
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.park_rounded,
                            color: _venueType == "outdoor"
                                ? kPrimaryColor
                                : Colors.grey.shade600,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Outdoor",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _venueType == "outdoor"
                                ? kPrimaryColor
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Open space",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🆕 Widget للـ Maximum Capacity - Modern UI/UX
  Widget _buildMaxCapacityField() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Venue Capacity",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "What is the maximum number of guests your venue can accommodate?",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Input Field with Icon
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: kPrimaryColor,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: maxCapacityCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: "e.g. 200",
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      suffixText: "guests",
                      suffixStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null; // Optional
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return "Enter a valid number";
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Helpful tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: kPrimaryColor.withOpacity(0.8),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "This helps customers find venues that fit their guest count.",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsCount = _eventsPerDay();
    final slots = _buildSlotsPreview();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.2,
        title: Text("Add Service",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        leading: const BackButton(color: kTextColor),
      ),
      bottomNavigationBar: saveButton(_trySave),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _prettyHeader(),
              sectionLabel("Service Details"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: TextFormField(
                  controller: nameCtrl,
                  decoration: inputStyle("Service Name"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
              sectionLabel("Description"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: inputStyle("Describe your service"),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
              
              // 🆕 Venue Type Section (يظهر فقط للـ Venues)
              if (widget.category == "Venues") _buildVenueTypeSelector(),
              
              // 🆕 Maximum Capacity Section (يظهر فقط للـ Venues)
              if (widget.category == "Venues") _buildMaxCapacityField(),
              
              sectionLabel("Availability"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _miniTitle("Choose Days"),
                    const SizedBox(height: 10),
                    _daysTwoRowsNeat(),
                    const SizedBox(height: 16),
                    _miniTitle("Choose Working Hours"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickFrom,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      color: kPrimaryColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "From: ${_fmtTime(_from)}",
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTo,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      color: kPrimaryColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "To: ${_fmtTime(_to)}",
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: kPrimaryColor.withOpacity(0.12)),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(
                            icon: Icons.event_available_rounded,
                            title: "Days",
                            value: _daysSummary(),
                            smallValue: true,
                          ),
                          const SizedBox(height: 8),
                          _summaryRow(
                            icon: Icons.access_time_rounded,
                            title: "Working hours",
                            value: "${_fmtTime(_from)} → ${_fmtTime(_to)}",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              sectionLabel("Service Duration"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _miniTitle("How many hours can customers book?"),
                    const SizedBox(height: 6),
                    _hint("Minimum is 1 hour. Drag to set booking range."),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 18, color: kPrimaryColor),
                          const SizedBox(width: 8),
                          Text(
                            "Min: ${_hoursRange.start.round()}h",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            "Max: ${_hoursRange.end.round()}h",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    RangeSlider(
                      values: _hoursRange,
                      min: 1,
                      max: 24,
                      divisions: 23,
                      labels: RangeLabels(
                        "${_hoursRange.start.round()}h",
                        "${_hoursRange.end.round()}h",
                      ),
                      onChanged: (v) {
                        if (v.end - v.start < 1) return;
                        setState(() {
                          _hoursRange = RangeValues(
                            v.start.roundToDouble().clamp(1, 24),
                            v.end.roundToDouble().clamp(1, 24),
                          );
                          _syncHoursCtrls(_hoursRange);
                        });
                      },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _dailyCapacityCard(eventsCount, slots),
              ),
              
              // 🆕 سؤال: هل الخدمة لها موقع ثابت؟
              sectionLabel("Service Location Type"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasFixedLocation ? Icons.storefront_rounded : Icons.delivery_dining_rounded,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Does this service have a fixed location?",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasFixedLocation
                          ? "Clients will come to your location"
                          : "You will go to the client's location",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _hasFixedLocation = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _hasFixedLocation
                                    ? kPrimaryColor.withOpacity(0.1)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasFixedLocation
                                      ? kPrimaryColor
                                      : Colors.grey.shade300,
                                  width: _hasFixedLocation ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    color: _hasFixedLocation
                                        ? kPrimaryColor
                                        : Colors.grey.shade500,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Yes",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _hasFixedLocation
                                          ? kPrimaryColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    "Fixed Location",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _hasFixedLocation = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !_hasFixedLocation
                                    ? kPrimaryColor.withOpacity(0.1)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_hasFixedLocation
                                      ? kPrimaryColor
                                      : Colors.grey.shade300,
                                  width: !_hasFixedLocation ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.delivery_dining_rounded,
                                    color: !_hasFixedLocation
                                        ? kPrimaryColor
                                        : Colors.grey.shade500,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "No",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: !_hasFixedLocation
                                          ? kPrimaryColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    "I Go to Client",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 🆕 قسم الموقع يظهر فقط إذا كانت الخدمة لها موقع ثابت
              if (_hasFixedLocation) ...[
              sectionLabel("Location"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: kPrimaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Where is your service?",
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: inputStyle("Address"),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: inputStyle("City"),
                      items: kCities
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: GoogleFonts.poppins(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCity = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 14),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Map coordinates (optional)",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MapLocationPicker(
                                      initialLat: _selectedLat,
                                      initialLng: _selectedLng,
                                    ),
                                  ),
                                );

                                if (result != null && result is Map) {
                                  setState(() {
                                    _selectedLat = result['latitude'];
                                    _selectedLng = result['longitude'];
                                    _hasLocationSet = true;
                                  });
                                }
                              },
                              icon: Icon(
                                _hasLocationSet
                                    ? Icons.check_circle_rounded
                                    : Icons.map_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                _hasLocationSet
                                    ? "Location Set ✅"
                                    : "Add Map Location",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          if (_hasLocationSet && _selectedLat != null && _selectedLng != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_pin,
                                        color: kPrimaryColor, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Lat: ${_selectedLat!.toStringAsFixed(5)}, Lng: ${_selectedLng!.toStringAsFixed(5)}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18, color: kPrimaryColor),
                                      onPressed: () {
                                        setState(() {
                                          _selectedLat = null;
                                          _selectedLng = null;
                                          _hasLocationSet = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ], // 🆕 نهاية if (_hasFixedLocation)
              sectionLabel("Pricing"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payments_rounded,
                            color: kPrimaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "How much do you charge?",
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timelapse_rounded,
                              color: kPrimaryColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Price per hour (₪)",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.end,
                              decoration: inputStyle(""),
                              validator: (v) {
                                final n = num.tryParse(v?.trim() ?? "");
                                if (n == null || n <= 0) return "Required";
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              color: kPrimaryColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Discount (optional)",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              controller: discountCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.end,
                              decoration: inputStyle("%"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: kPrimaryColor.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calculate_rounded,
                              color: kPrimaryColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Final price",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            _finalPrice == null
                                ? "--"
                                : "${_finalPrice!.toStringAsFixed(2)} ₪",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          if (_savedAmount != null && _savedAmount! > 0) ...[
                            const SizedBox(width: 10),
                            Text(
                              "(-${_savedAmount!.toStringAsFixed(2)} ₪)",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              sectionLabel("Gallery"),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: MultiMediaGalleryBox(
                  mediaItems: _mediaItems,
                  onPickImages: _pickImages,
                  onPickVideo: _pickVideo,
                  onRemove: _removeMediaItem,
                  maxItems: _maxMediaItems,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: cardDecoration(),
                child: AdditionalInfoSection(
                  items: _additionalInfo,
                  onAdd: _addAdditionalInfo,
                  onRemove: _removeAdditionalInfo,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: cardDecoration(),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _visibleInSearch,
                  activeColor: kPrimaryColor,
                  onChanged: (v) => setState(() => _visibleInSearch = v),
                  title: Text("Visible in search",
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text("Turn off if temporarily unavailable.",
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}