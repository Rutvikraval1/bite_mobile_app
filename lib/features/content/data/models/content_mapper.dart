import '../../domain/entities/bite_card.dart';
import '../../domain/entities/meal_plan.dart';
import '../../domain/entities/saved_item.dart';

/// Converts content table rows into frontend entities — mirrors the JS
/// `mapRecipe` / `mapDrink` / `mapPlace` mappers in `supabase.ts`.
abstract final class ContentMapper {
  static BiteCard recipeFromRow(Map<String, dynamic> r) => BiteCard(
        id: (r['id'] as num?)?.toInt() ?? 0,
        title: (r['title'] as String?) ?? '',
        creator: (r['creator'] as String?) ?? '',
        time: (r['time_min'] as String?) ?? '',
        diff: (r['difficulty'] as String?) ?? '',
        serves: (r['serves'] as num?)?.toInt() ?? 0,
        heat: (r['heat_level'] as num?)?.toInt() ?? 0,
        saved: (r['saved_count'] as String?) ?? '',
        hearts: (r['hearts_count'] as String?) ?? '',
        comments: (r['comments_count'] as num?)?.toInt() ?? 0,
        emoji: (r['emoji'] as String?) ?? '',
        image: r['image_url'] as String?,
        cuisine: (r['cuisine'] as String?) ?? '',
        gradient: (r['gradient'] as String?) ?? '',
        tags: ((r['tags'] as List?) ?? const []).cast<String>(),
      );

  static BiteCard drinkFromRow(Map<String, dynamic> d) => BiteCard(
        id: (d['id'] as num?)?.toInt() ?? 0,
        title: (d['title'] as String?) ?? '',
        creator: (d['creator'] as String?) ?? '',
        time: (d['time_min'] as String?) ?? '',
        diff: (d['difficulty'] as String?) ?? '',
        serves: (d['serves'] as num?)?.toInt() ?? 0,
        heat: (d['heat_level'] as num?)?.toInt() ?? 0,
        saved: (d['saved_count'] as String?) ?? '',
        hearts: (d['hearts_count'] as String?) ?? '',
        comments: (d['comments_count'] as num?)?.toInt() ?? 0,
        emoji: (d['emoji'] as String?) ?? '',
        image: d['image_url'] as String?,
        cuisine: (d['cuisine'] as String?) ?? 'Various',
        gradient: (d['gradient'] as String?) ?? '',
        tags: ((d['tags'] as List?) ?? const []).cast<String>(),
      );

  static BiteCard placeFromRow(Map<String, dynamic> p) => BiteCard(
        id: (p['id'] as num?)?.toInt() ?? 0,
        title: (p['title'] as String?) ?? '',
        creator: (p['creator'] as String?) ?? '',
        time: (p['price_level'] as String?) ?? '',
        diff: (p['cuisine'] as String?) ?? '',
        serves: 0,
        heat: 0,
        saved: (p['saved_count'] as String?) ?? '',
        hearts: (p['hearts_count'] as String?) ?? '',
        comments: (p['comments_count'] as num?)?.toInt() ?? 0,
        emoji: (p['emoji'] as String?) ?? '',
        image: p['image_url'] as String?,
        cuisine: (p['cuisine'] as String?) ?? '',
        gradient: (p['gradient'] as String?) ?? '',
        tags: ((p['tags'] as List?) ?? const []).cast<String>(),
        address: p['address'] as String?,
        phone: p['phone'] as String?,
        rating: ((p['rating'] as num?)?.toDouble()),
        reviewCount: (p['review_count'] as num?)?.toInt(),
        priceLevel: p['price_level'] as String?,
        hours: p['hours'] as String?,
        status: p['status'] as String?,
        distance: p['distance'] as String?,
        photos: ((p['photos'] as List?) ?? const []).cast<String>(),
        menuHighlights: _highlights(p['menu_highlights']),
      );

  static SavedItem savedFromRow(Map<String, dynamic> row) => SavedItem(
        id: (row['id'] as String?) ?? '',
        itemType: (row['item_type'] as String?) ?? 'food',
        itemId: (row['item_id'] as num?)?.toInt() ?? 0,
        title: (row['title'] as String?) ?? '',
        emoji: (row['emoji'] as String?) ?? '🍽',
        imageUrl: row['image_url'] as String?,
        cuisine: row['cuisine'] as String?,
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'].toString())
            : null,
      );

  static MealPlan mealFromRow(Map<String, dynamic> row) => MealPlan.fromRow({
        ...row,
        'color': _hexToInt(row['color'] as String?),
      });

  /// Parses a `#RRGGBB` hex color into an ARGB int (or null).
  static int? _hexToInt(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : 0xFF000000 | value;
  }

  static List<MenuHighlight> _highlights(dynamic raw) {
    final rows = raw as List?;
    if (rows == null) return const [];
    return rows.map((r) {
      final map = r as Map;
      return MenuHighlight(
        name: (map['name'] as String?) ?? '',
        price: (map['price'] as String?) ?? '',
      );
    }).toList();
  }
}
