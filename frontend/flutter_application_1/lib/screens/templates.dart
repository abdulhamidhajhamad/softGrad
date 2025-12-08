import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'template_editor.dart';
import 'favorites.dart'; // for FavoritesStore & FavoriteTemplate

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({Key? key}) : super(key: key);

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  // available filters
  static const List<String> _filters = [
    'All',
    'Classic',
    'Minimal',
    'Botanical',
    'Romantic',
  ];

  String _selectedFilter = 'All';

  // all templates
  static final List<_TemplateItem> _allItems = [
    // Classic
    _TemplateItem(
      category: 'Classic',
      name: 'Blue Grace',
      asset: 'assets/images/classic.png',
    ),
    _TemplateItem(
      category: 'Classic',
      name: 'Golden Vow',
      asset: 'assets/images/classic1.png',
    ),
    _TemplateItem(
      category: 'Classic',
      name: 'Ivory Frame',
      asset: 'assets/images/classic2.png',
    ),

    // Minimal
    _TemplateItem(
      category: 'Minimal',
      name: 'Soft Petal',
      asset: 'assets/images/minimal.png',
    ),
    _TemplateItem(
      category: 'Minimal',
      name: 'Wood Harmony',
      asset: 'assets/images/minimal1.png',
    ),

    // Botanical
    _TemplateItem(
      category: 'Botanical',
      name: 'Green Whisper',
      asset: 'assets/images/botanical.png',
    ),
    _TemplateItem(
      category: 'Botanical',
      name: 'Dusty Bloom',
      asset: 'assets/images/botanical1.png',
    ),

    // Romantic
    _TemplateItem(
      category: 'Romantic',
      name: 'Crimson Love',
      asset: 'assets/images/romantic.png',
    ),
    _TemplateItem(
      category: 'Romantic',
      name: 'Blush Dream',
      asset: 'assets/images/romantic1.png',
    ),
    _TemplateItem(
      category: 'Romantic',
      name: 'Rosy Charm',
      asset: 'assets/images/romantic2.png',
    ),
  ];

  Color get _brandColor => const Color(0xFFB14E56); // نفس لون صفحة Templates

  @override
  Widget build(BuildContext context) {
    // filter by selected category
    final List<_TemplateItem> visibleItems = _selectedFilter == 'All'
        ? _allItems
        : _allItems.where((t) => t.category == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brandColor,
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
            // filters
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
                      selectedColor: _brandColor,
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
            const SizedBox(height: 22),

            // grid
            Expanded(
              child: GridView.builder(
                itemCount: visibleItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      2 / 3, // taller cards so images stay vertical
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (ctx, i) {
                  final t = visibleItems[i];

                  // use global FavoritesStore instead of local Set
                  final bool isFav = FavoritesStore.isTemplateFavorite(t.asset);

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // image
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.asset(
                              t.asset,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),

                        // bottom content
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // top row: favorite + tag
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 20,
                                      color: isFav
                                          ? _brandColor
                                          : Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (isFav) {
                                          FavoritesStore.removeTemplateByAsset(
                                              t.asset);
                                        } else {
                                          FavoritesStore.addTemplate(
                                            FavoriteTemplate(
                                              asset: t.asset,
                                              name: t.name,
                                              category: t.category,
                                            ),
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          186, 0, 0, 0), // نفس ما عندك
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(color: _brandColor),
                                    ),
                                    child: Text(
                                      t.category,
                                      style: GoogleFonts.poppins(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),

                              // template name
                              Text(
                                t.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Customize button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Customize',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
  final String name; // template name for editor
  final String asset;

  const _TemplateItem({
    required this.category,
    required this.name,
    required this.asset,
  });
}
