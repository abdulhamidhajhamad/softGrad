import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // ل RenderRepaintBoundary
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// تأكدي من إضافة حزمة pdf في pubspec.yaml
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class TemplateEditorPage extends StatefulWidget {
  final String templateName; // Classic / Minimal / ...
  final String imagePath;

  const TemplateEditorPage({
    Key? key,
    required this.templateName,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  final _key = GlobalKey();

  final _nameA = TextEditingController(text: 'Aya');
  final _nameB = TextEditingController(text: 'Qais');
  final _day = TextEditingController(text: 'Saturday');
  final _date = TextEditingController(text: 'Feb 26, 2026');
  final _loc = TextEditingController(text: 'Ceremony');
  final _customCaption = TextEditingController();

  TimeOfDay _from = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 21, minute: 0);

  final List<String> _captions = const [
    'A new chapter of love begins',
    'A day to remember',
    'Forever starts here',
    ' — Custom — ',
  ];

  // لازم تكون القيمة الابتدائية واحدة من القائمة
  String _selectedCaption = 'A new chapter of love begins';

  bool get _useCustomCaption => _selectedCaption == ' — Custom — ';

  String get _captionText =>
      _useCustomCaption ? _customCaption.text : _selectedCaption;

  @override
  void dispose() {
    _nameA.dispose();
    _nameB.dispose();
    _day.dispose();
    _date.dispose();
    _loc.dispose();
    _customCaption.dispose();
    super.dispose();
  }

  Future<Uint8List> _exportPngBytes() async {
    final boundary =
        _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<String> _saveTemp(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/invite_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  // Share (كما كان)
  Future<void> _share() async {
    final bytes = await _exportPngBytes();
    final path = await _saveTemp(bytes);
    await Share.shareXFiles([XFile(path)], text: 'Wedding invitation');
  }

  // حفظ PNG في ملف دائم
  Future<void> _saveAsPngToDevice() async {
    final bytes = await _exportPngBytes();
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/invite_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved PNG to:\n$path')),
    );
  }

  // إنشاء وحفظ PDF من نفس الصورة
  Future<void> _saveAsPdfToDevice() async {
    final pngBytes = await _exportPngBytes();

    final pdf = pw.Document();
    final image = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/invite_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save(), flush: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved PDF to:\n$path')),
    );
  }

  void _openSaveOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Save as PNG'),
              onTap: () async {
                Navigator.pop(context);
                await _saveAsPngToDevice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Save as PDF'),
              onTap: () async {
                Navigator.pop(context);
                await _saveAsPdfToDevice();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Future<void> _pickTime(bool from) async {
    final base = from ? _from : _to;
    final t = await showTimePicker(context: context, initialTime: base);
    if (t != null) {
      setState(() {
        if (from) {
          _from = t;
        } else {
          _to = t;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintStyle =
        GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB14E56), // نفس لون صفحة Templates
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Customize • ${widget.templateName}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _share,
            tooltip: 'Share',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: RepaintBoundary(
              key: _key,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          widget.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.templateName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_captionText.isNotEmpty)
                              Text(
                                _captionText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2E2E2E),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              '${_nameA.text} & ${_nameB.text}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E2E2E),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_day.text}, ${_date.text}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF4A4A68),
                              ),
                            ),
                            Text(
                              '${_fmt(_from)} – ${_fmt(_to)}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF4A4A68),
                              ),
                            ),
                            Text(
                              _loc.text,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF4A4A68),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Label('Bride'),
          TextField(
            controller: _nameA,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'First partner name',
              hintStyle: hintStyle,
            ),
          ),
          const SizedBox(height: 16),
          _Label('Groom'),
          TextField(
            controller: _nameB,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Second partner name',
              hintStyle: hintStyle,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Day'),
                    TextField(
                      controller: _day,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g., Saturday',
                        hintStyle: hintStyle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Date'),
                    TextField(
                      controller: _date,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g., Oct 26, 2024',
                        hintStyle: hintStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _Label('Time'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text('From ${_fmt(_from)}'),
                  onPressed: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text('To ${_fmt(_to)}'),
                  onPressed: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _Label('Location'),
          TextField(
            controller: _loc,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Venue / City',
              hintStyle: hintStyle,
            ),
          ),
          const SizedBox(height: 16),
          const _Label('Caption'),
          DropdownButtonFormField<String>(
            value: _selectedCaption,
            items: _captions
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCaption = v!),
          ),
          if (_useCustomCaption) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customCaption,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Write your own short caption',
              ),
            ),
          ],
          const SizedBox(height: 26),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB14E56), // نفس اللون الأحمر
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            icon: const Icon(Icons.save),
            label: Text(
              'Save as PNG / PDF',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            onPressed: _openSaveOptions,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
