// lib/screens/favorites.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ----------- MODELS + STORE (can be reused from other screens) -----------

class FavoriteTemplate {
  final String asset; // image path
  final String name; // display name (e.g. "Blue Grace")
  final String category; // Classic / Minimal / ...

  FavoriteTemplate({
    required this.asset,
    required this.name,
    required this.category,
  });
}

class FavoriteVendor {
  final String name; // vendor name
  final String type; // category (Venue, Photographer, ...)
  final String? image; // optional image path

  FavoriteVendor({
    required this.name,
    required this.type,
    this.image,
  });
}

/// Simple in-memory favorites store.
/// TODO(API): later you can sync this with backend user favorites.
class FavoritesStore {
  static final List<FavoriteTemplate> _templates = [];
  static final List<FavoriteVendor> _vendors = [];

  // ---------- Templates ----------
  static List<FavoriteTemplate> get templates => List.unmodifiable(_templates);

  static bool isTemplateFavorite(String asset) =>
      _templates.any((t) => t.asset == asset);

  static void addTemplate(FavoriteTemplate t) {
    if (!isTemplateFavorite(t.asset)) {
      _templates.add(t);
    }
  }

  static void removeTemplateByAsset(String asset) {
    _templates.removeWhere((t) => t.asset == asset);
  }

  // ---------- Vendors ----------
  static List<FavoriteVendor> get vendors => List.unmodifiable(_vendors);

  static bool isVendorFavorite(String name) =>
      _vendors.any((v) => v.name == name);

  static void addVendor(FavoriteVendor v) {
    if (!isVendorFavorite(v.name)) {
      _vendors.add(v);
    }
  }

  static void removeVendorByName(String name) {
    _vendors.removeWhere((v) => v.name == name);
  }
}

/// ------------------------- FAVORITES PAGE UI ------------------------------

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

enum _FavTab { vendors, templates }

class _FavoritesPageState extends State<FavoritesPage> {
  _FavTab _tab = _FavTab.vendors;

  Color get _mint =>
      const Color.fromARGB(215, 20, 20, 215); // لون قريب من الصورة
  Color get _bgChip => const Color(0xFFF2F2F2);

  @override
  Widget build(BuildContext context) {
    final templates = FavoritesStore.templates;
    final vendors = FavoritesStore.vendors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        titleSpacing: 20,
        toolbarHeight: 72, // ↓ ينزل الـ "Favorites" للأسفل قليلاً
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _mint.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_border, color: _mint, size: 27),
            ),
            const SizedBox(width: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorites',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Your saved items',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // -------------------- Segmented control --------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
            child: Container(
              decoration: BoxDecoration(
                color: _bgChip,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Vendors',
                      selected: _tab == _FavTab.vendors,
                      mint: _mint,
                      onTap: () {
                        setState(() => _tab = _FavTab.vendors);
                      },
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Templates',
                      selected: _tab == _FavTab.templates,
                      mint: _mint,
                      onTap: () {
                        setState(() => _tab = _FavTab.templates);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // -------------------- Content --------------------
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tab == _FavTab.vendors
                  ? _VendorsFavoritesList(vendors: vendors)
                  : _TemplatesFavoritesGrid(templates: templates),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented button
class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color mint;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.mint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: mint, width: 2)
              : const Border.fromBorderSide(BorderSide.none),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? mint : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

/// --------------------- Vendors tab content -----------------------

class _VendorsFavoritesList extends StatelessWidget {
  final List<FavoriteVendor> vendors;

  const _VendorsFavoritesList({required this.vendors});

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return _EmptyState(message: 'No favorite vendors yet.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final v = vendors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: v.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      v.image!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.storefront),
                  ),
            title: Text(
              v.name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              v.type,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// --------------------- Templates tab content -----------------------

class _TemplatesFavoritesGrid extends StatelessWidget {
  final List<FavoriteTemplate> templates;

  const _TemplatesFavoritesGrid({required this.templates});

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return _EmptyState(message: 'No favorite templates yet.');
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: templates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final t = templates[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  t.asset,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
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
    );
  }
}

/// --------------------- Empty state -----------------------

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
