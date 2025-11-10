import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'template_editor.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({Key? key}) : super(key: key);

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  // الفلاتر المتاحة
  static const List<String> _filters = [
    'All',
    'Classic',
    'Minimal',
    'Botanical',
    'Romantic',
  ];

  String _selectedFilter = 'All';

  // كل التمبليتات مع التصنيف
  static final List<_TemplateItem> _allItems = [
    // Classic
    _TemplateItem(
      category: 'Classic',
      name: 'Classic',
      asset: 'assets/images/classic.png',
    ),
    _TemplateItem(
      category: 'Classic',
      name: 'Classic',
      asset: 'assets/images/classic1.png',
    ),
    _TemplateItem(
      category: 'Classic',
      name: 'Classic',
      asset: 'assets/images/classic2.png',
    ),

    // Minimal
    _TemplateItem(
      category: 'Minimal',
      name: 'Minimal',
      asset: 'assets/images/minimal.png',
    ),
    _TemplateItem(
      category: 'Minimal',
      name: 'Minimal',
      asset: 'assets/images/minimal1.png',
    ),

    // Botanical
    _TemplateItem(
      category: 'Botanical',
      name: 'Botanical',
      asset: 'assets/images/botanical.png',
    ),
    _TemplateItem(
      category: 'Botanical',
      name: 'Botanical',
      asset: 'assets/images/botanical1.png',
    ),

    // Romantic
    _TemplateItem(
      category: 'Romantic',
      name: 'Romantic',
      asset: 'assets/images/romantic.png',
    ),
    _TemplateItem(
      category: 'Romantic',
      name: 'Romantic',
      asset: 'assets/images/romantic1.png',
    ),
    _TemplateItem(
      category: 'Romantic',
      name: 'Romantic',
      asset: 'assets/images/romantic2.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // فلترة حسب النوع المختار
    final List<_TemplateItem> visibleItems = _selectedFilter == 'All'
        ? _allItems
        : _allItems.where((t) => t.category == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB14E56), // أحمر بدل الأزرق
        title: Text(
          'Invitation Templates',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الفلاتر
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final bool selected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        f,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFFB14E56),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                      ),
                      backgroundColor: const Color(0xFFF2F2F2),
                      onSelected: (_) {
                        setState(() => _selectedFilter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Grid
            Expanded(
              child: GridView.builder(
                itemCount: visibleItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (ctx, i) {
                  final t = visibleItems[i];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TemplateEditorPage(
                              templateName: t.name,
                              imagePath: t.asset,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              t.asset,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
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
                                t.category,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateItem {
  final String category; // Classic / Minimal / Romantic / Botanical
  final String name; // اسم التمبلت (للـ Editor)
  final String asset;

  const _TemplateItem({
    required this.category,
    required this.name,
    required this.asset,
  });
}
