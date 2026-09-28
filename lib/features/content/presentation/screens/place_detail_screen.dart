import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/bite_card.dart';
import '../blocs/content_cubit.dart';
import '../widgets/social_comments_block.dart';

/// Restaurant / place detail sheet — ports `PlaceDetailScreen` from
/// `screens-detail.jsx`. Reached from the swipe deck when the active card
/// is a place (`card.isPlace`).
class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _liked = false;
  bool _saved = false;
  String _section = 'overview';
  String? _selectedSlot;

  static const List<({String name, String emoji, String tagline, String fee})>
  _delivery = [
    (
      name: 'DoorDash',
      emoji: '🔴',
      tagline: 'Delivery in 25-35 min',
      fee: r'$2.99 delivery',
    ),
    (
      name: 'Uber Eats',
      emoji: '🟢',
      tagline: 'Delivery in 30-40 min',
      fee: r'$1.99 delivery',
    ),
    (
      name: 'Grubhub',
      emoji: '🟠',
      tagline: 'Delivery in 35-45 min',
      fee: 'Free delivery',
    ),
  ];

  static const List<({String name, String emoji, List<String> slots})>
  _reservations = [
    (
      name: 'OpenTable',
      emoji: '🔴',
      slots: ['5:30 PM', '6:00 PM', '7:30 PM', '8:00 PM', '9:00 PM'],
    ),
    (name: 'Resy', emoji: '⚪', slots: ['6:00 PM', '7:00 PM', '8:30 PM']),
  ];

  static const List<SeedComment> _reviews = [
    SeedComment(
      user: '@foodienyc',
      avatarEmoji: '🍣',
      text: 'The omakase here is transcendent!',
      time: '2d',
      likes: 24,
    ),
    SeedComment(
      user: '@sushilover',
      avatarEmoji: '🥢',
      text: 'Best uni I\'ve had outside of Japan.',
      time: '1w',
      likes: 18,
    ),
    SeedComment(
      user: '@datenight_duo',
      avatarEmoji: '🌸',
      text: 'Beautiful ambiance, great for date night.',
      time: '2w',
      likes: 9,
    ),
  ];

  static const List<
    ({String user, String avatar, String text, int rating, String time})
  >
  _biteReviews = [
    (
      user: '@foodienyc',
      avatar: '🍣',
      rating: 3,
      time: '2d ago',
      text:
          "The omakase here is transcendent. Chef Sato's knife work is mesmerizing and every piece tells a story.",
    ),
    (
      user: '@sushilover',
      avatar: '🥢',
      rating: 3,
      time: '1w ago',
      text:
          "Best uni I've had outside of Japan. The sake pairing is worth every penny.",
    ),
    (
      user: '@datenight_duo',
      avatar: '🌸',
      rating: 2,
      time: '2w ago',
      text:
          'Beautiful ambiance but portions are small for the price. Still a great experience.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateCubit>().state;
    final content = context.watch<ContentCubit>().state;
    final deck = content.places;
    final place = deck.isEmpty
        ? null
        : deck[appState.activeCardIndex % deck.length];

    if (place == null) {
      return ColoredBox(
        color: const Color(0xB3000000),
        child: content.loading
            ? const LoadingState(label: 'Loading place…', backgroundColor: Colors.transparent)
            : content.error != null
                ? ErrorState(
                    message: content.error!,
                    backgroundColor: Colors.transparent,
                    onRetry: () => context.read<ContentCubit>().refetch(),
                  )
                : const EmptyState(
                    emoji: '📍',
                    title: 'No place to show',
                    message: 'Check back soon for new places.',
                  ),
      );
    }

    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: GestureDetector(
        onTap: () => context.read<FlowCubit>().goBack(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.88,
              widthFactor: 1,
              child: GestureDetector(
                onTap: () {},
                child: ZoomIn(
                  duration: const Duration(milliseconds: 380),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: ColoredBox(
                      color: AppColors.bgDark,
                      child: Column(
                        children: [
                          _dragHandle(),
                          Expanded(
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _hero(place),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          16,
                                          20,
                                          0,
                                        ),
                                        child: _header(place),
                                      ),
                                      _sectionTabs(),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          16,
                                          20,
                                          120,
                                        ),
                                        child: _sectionContent(place),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: SafeArea(
                                    top: false,
                                    child: _bottomCta(place),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: GestureDetector(
        onTap: () => context.read<FlowCubit>().goBack(),
        child: Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _hero(BiteCard place) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: EmojiThemes.cardBg(place.emoji),
              ),
            ),
            alignment: Alignment.center,
            child: (place.image == null || place.image!.isEmpty)
                ? Text(
                    place.emoji.isEmpty ? '🏠' : place.emoji,
                    style: const TextStyle(fontSize: 80),
                  )
                : null,
          ),
          if (place.image != null && place.image!.isNotEmpty)
            Image.network(
              place.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Positioned(
            top: 12,
            right: 16,
            child: GestureDetector(
              onTap: () => context.read<FlowCubit>().goBack(),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '24 photos',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          if (place.status != null)
            Positioned(
              top: 12,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x334CAF50),
                  border: Border.all(color: const Color(0x664CAF50)),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  place.status!,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(BiteCard place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          place.cuisine,
          style: const TextStyle(
            color: AppColors.placesPurple,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5A623)),
            const SizedBox(width: 4),
            Text(
              '${place.rating ?? '—'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${place.reviewCount ?? 0})',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(width: 12),
            Text(
              place.priceLevel ?? '',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.place_outlined, size: 12, color: AppColors.muted),
            const SizedBox(width: 3),
            Text(
              place.distance ?? '',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          place.address ?? '',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 11,
              color: AppColors.muted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                place.hours ?? '',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SocialCommentsBlock(
          hearts: place.hearts,
          saved: place.saved,
          accentColor: AppColors.placesPurple,
          baseCommentCount: 3,
          placeholder: 'Share your experience...',
          postedToast: '💬 Review posted!',
          quickChips: const [
            '🔥 Fire!',
            '😍 Love this!',
            'Best spot!',
            '💯 Amazing',
            'Coming back',
          ],
          seedComments: _reviews,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _circleToggle(
              icon: Icons.favorite_rounded,
              active: _liked,
              color: AppColors.coral,
              onTap: () => setState(() => _liked = !_liked),
            ),
            const SizedBox(width: 10),
            _circleToggle(
              icon: Icons.bookmark_rounded,
              active: _saved,
              color: AppColors.amber,
              onTap: () {
                setState(() => _saved = !_saved);
                if (_saved)
                  context.read<ContentCubit>().saveItem(place, 'place');
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _serviceButton(
              Icons.call_rounded,
              'Call',
              const Color(0xFF4CAF50),
              () => ToastService.instance.show('📞 Calling restaurant...'),
            ),
            _serviceButton(
              Icons.navigation_rounded,
              'Directions',
              AppColors.cyan,
              () => ToastService.instance.show(
                '🗺 Opening directions in Maps...',
              ),
            ),
            _serviceButton(
              Icons.public_rounded,
              'Website',
              AppColors.amber,
              () => ToastService.instance.show(
                '🌐 Opening restaurant website...',
              ),
            ),
            _serviceButton(
              Icons.ios_share_rounded,
              'Share',
              AppColors.coral,
              () => context.read<FlowCubit>().setScreen(AppScreen.shareSheet),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleToggle({
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withValues(alpha: 0.13) : AppColors.glass,
          border: Border.all(color: active ? color : AppColors.glassBorder),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _serviceButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTabs() {
    const sections = [
      ('overview', 'Overview'),
      ('menu', 'Menu'),
      ('photos', 'Photos'),
      ('reviews', 'Reviews'),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          for (final s in sections)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _section = s.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _section == s.$1
                            ? AppColors.placesPurple
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.$2,
                    style: TextStyle(
                      color: _section == s.$1
                          ? AppColors.placesPurple
                          : AppColors.muted,
                      fontWeight: _section == s.$1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionContent(BiteCard place) {
    return switch (_section) {
      'menu' => _menuSection(place),
      'photos' => _photosSection(place),
      'reviews' => _reviewsSection(place),
      _ => _overviewSection(place),
    };
  }

  Widget _overviewSection(BiteCard place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚗 Order Delivery',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final ds in _delivery)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => ToastService.instance.show(
                '🚗 Opening ${ds.name}... Order from ${place.title}',
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Text(ds.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ds.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ds.tagline,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ds.fee,
                          style: const TextStyle(
                            color: AppColors.placesPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 12,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          '🪑 Reserve a Table',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final rs in _reservations)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(rs.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      rs.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 10,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final slot in rs.slots)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _slotChip(rs.name, slot),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          '📸 Reviewed by',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () =>
              context.read<FlowCubit>().setScreen(AppScreen.creatorProfile),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.placesPurple, AppColors.coral],
                    ),
                  ),
                  child: const Text('🍣', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.creator,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'b🌶te Creator · 312 reviews',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _slotChip(String service, String slot) {
    final key = '$service-$slot';
    final selected = _selectedSlot == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSlot = key);
        ToastService.instance.show('🪑 Table reserved: $slot via $service!');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: selected
              ? AppColors.placesPurple
              : AppColors.placesPurple.withValues(alpha: 0.07),
          border: Border.all(
            color: AppColors.placesPurple.withValues(
              alpha: selected ? 1 : 0.27,
            ),
          ),
        ),
        child: Text(
          selected ? '✓ $slot' : slot,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.placesPurple,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _menuSection(BiteCard place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Menu Highlights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => ToastService.instance.show(
                '🌐 Opening full menu on restaurant website...',
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 12,
                    color: AppColors.placesPurple,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Full menu',
                    style: TextStyle(
                      color: AppColors.placesPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 10,
                    color: AppColors.placesPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < place.menuHighlights.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: i < place.menuHighlights.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    place.menuHighlights[i].name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  place.menuHighlights[i].price,
                  style: const TextStyle(
                    color: AppColors.placesPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.placesPurple.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.placesPurple.withValues(alpha: 0.13),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Menu data from Google Maps API',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    ToastService.instance.show('📋 Opening full menu...'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.placesPurple,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'View Full Menu ↗',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Order from Menu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final ds in _delivery.take(2))
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ToastService.instance.show(
                      '🚗 Opening ${ds.name}... Order from ${place.title}',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Column(
                        children: [
                          Text(ds.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            ds.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ds.fee,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _photosSection(BiteCard place) {
    final photos = place.photos.isEmpty
        ? const ['📷', '📷', '📷', '📷', '📷', '📷']
        : place.photos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Photos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'From Google · b🌶te users',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (final photo in photos)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.placesPurple.withValues(alpha: 0.13),
                      AppColors.bgCard,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: photo.startsWith('http')
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, _, _) =>
                            const Text('📷', style: TextStyle(fontSize: 28)),
                      )
                    : Text(photo, style: const TextStyle(fontSize: 32)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public_rounded, size: 14, color: AppColors.muted),
                  SizedBox(width: 6),
                  Text(
                    '24 photos on Google Maps',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    ToastService.instance.show('📸 Opening photo gallery...'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.placesPurple.withValues(alpha: 0.27),
                    ),
                  ),
                  child: const Text(
                    'View All Photos ↗',
                    style: TextStyle(
                      color: AppColors.placesPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'From b🌶te community',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: const [
            _CommunityPhotoCard(
              emoji: '🍣',
              caption: 'Best omakase in the city',
              user: '@foodienyc',
            ),
            _CommunityPhotoCard(
              emoji: '🍶',
              caption: 'The sake pairing was incredible',
              user: '@sushilover',
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewsSection(BiteCard place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Text(
                '${place.rating ?? '—'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: i <= (place.rating ?? 0).round()
                          ? const Color(0xFFF5A623)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${place.reviewCount ?? 0} reviews on Google',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '🌶 b🌶te Reviews',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final rev in _biteReviews)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.placesPurple, AppColors.coral],
                          ),
                        ),
                        child: Text(
                          rev.avatar,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.read<FlowCubit>().setScreen(
                            AppScreen.creatorProfile,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rev.user,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                rev.time,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var p = 0; p < 3; p++)
                            Opacity(
                              opacity: p < rev.rating ? 1 : 0.2,
                              child: const Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: Text(
                                  '🌶',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rev.text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () =>
                ToastService.instance.show('🌐 Opening Google Reviews...'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public_rounded, size: 14, color: AppColors.muted),
                  SizedBox(width: 6),
                  Text(
                    'See all Google Reviews ↗',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomCta(BiteCard place) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.bgDark.withValues(alpha: 0.96),
          ],
          stops: const [0, 0.3],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedSlot != null) {
                  final parts = _selectedSlot!.split('-');
                  ToastService.instance.show(
                    '🪑 Reservation confirmed: ${parts.last} via ${parts.first}!',
                  );
                } else {
                  ToastService.instance.show(
                    '📅 Select a time slot above to reserve',
                  );
                  setState(() => _section = 'overview');
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.placesPurple,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: const [
                    BoxShadow(color: Color(0x4D9B59B6), blurRadius: 16),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reserve a Table',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => ToastService.instance.show(
                '🚗 Opening DoorDash for delivery...',
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.placesPurple.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.placesPurple.withValues(alpha: 0.27),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🚗 Order Delivery',
                  style: TextStyle(
                    color: AppColors.placesPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPhotoCard extends StatelessWidget {
  const _CommunityPhotoCard({
    required this.emoji,
    required this.caption,
    required this.user,
  });

  final String emoji;
  final String caption;
  final String user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    AppColors.placesPurple.withValues(alpha: 0.2),
                    AppColors.bgCard,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            user,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
