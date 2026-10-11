import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../social/presentation/social_navigation.dart';
import '../../domain/entities/bite_card.dart';
import '../../domain/entities/place_review.dart';
import '../../domain/entities/saved_item.dart';
import '../blocs/content_cubit.dart';
import '../blocs/place_reviews_cubit.dart';
import '../place_links.dart';
import '../widgets/place_photo_gallery.dart';
import '../widgets/sheet_backdrop_blur.dart';

/// Restaurant / place detail sheet — ports `PlaceDetailScreen` from
/// `screens-detail.jsx`. Reached from the swipe deck when the active card
/// is a place (`card.isPlace`).
///
/// Place data comes from `places`; b🌶te reviews from `place_reviews`.
/// Call / directions / reserve / delivery / menu open the real phone dialer,
/// maps app or partner website — nothing is booked or ordered in-app.
class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

typedef _Partner = ({String name, String emoji, Uri Function(BiteCard) url});

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final PlaceReviewsCubit _reviews = PlaceReviewsCubit();
  String _section = 'overview';
  bool _savingBookmark = false;

  static final List<_Partner> _delivery = [
    (name: 'DoorDash', emoji: '🔴', url: PlaceLinks.doorDash),
    (name: 'Uber Eats', emoji: '🟢', url: PlaceLinks.uberEats),
    (name: 'Grubhub', emoji: '🟠', url: PlaceLinks.grubhub),
  ];

  static final List<_Partner> _reservations = [
    (name: 'OpenTable', emoji: '🔴', url: PlaceLinks.openTable),
    (name: 'Resy', emoji: '⚪', url: PlaceLinks.resy),
  ];

  @override
  void dispose() {
    _reviews.close();
    super.dispose();
  }

  void _ensureReviewsLoaded(int placeId) {
    if (_reviews.state.placeId == placeId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reviews.load(placeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild when the active card index changes, not on every
    // AppState update.
    final activeCardIndex = context.select<AppStateCubit, int>(
      (c) => c.state.activeCardIndex,
    );
    final content = context.watch<ContentCubit>().state;
    final deck = content.places;
    final place = deck.isEmpty
        ? null
        : deck[activeCardIndex % deck.length];

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

    _ensureReviewsLoaded(place.id);
    final savedEntry = content.savedItems
        .where((s) => s.itemType == 'place' && s.itemId == place.id)
        .firstOrNull;

    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: GestureDetector(
        onTap: () => context.read<FlowCubit>().goBack(),
        child: SheetBackdropBlur(
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
                      child: BlocBuilder<PlaceReviewsCubit, PlaceReviewsState>(
                        bloc: _reviews,
                        builder: (context, reviews) => Column(
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
                                          child: _header(
                                            place,
                                            reviews,
                                            savedEntry,
                                          ),
                                        ),
                                        _sectionTabs(),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            16,
                                            20,
                                            120,
                                          ),
                                          child: _sectionContent(
                                            place,
                                            reviews,
                                          ),
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
      ),
    );
  }

  // ── Actions ──

  void _openGallery(BiteCard place, [int index = 0]) {
    final photos = place.photos.where((p) => p.startsWith('http')).toList();
    if (photos.isEmpty) {
      ToastService.instance.show('No photos for this place yet');
      return;
    }
    PlacePhotoGallery.show(
      context,
      photos: photos,
      title: place.title,
      initialIndex: index.clamp(0, photos.length - 1),
    );
  }

  Future<void> _toggleSaved(BiteCard place, SavedItem? savedEntry) async {
    if (_savingBookmark) return;
    final cubit = context.read<ContentCubit>();
    if (cubit.userId == null) {
      ToastService.instance.show('Sign in to save places');
      return;
    }
    setState(() => _savingBookmark = true);
    final result = savedEntry == null
        ? await cubit.saveItem(place, 'place')
        : await cubit.removeSavedItem(savedEntry.id);
    if (!mounted) return;
    setState(() => _savingBookmark = false);
    ToastService.instance.show(
      !result.isSuccess
          ? "⚠️ Couldn't update saved places. Try again."
          : savedEntry == null
              ? '🔖 Saved to your places'
              : 'Removed from saved',
    );
  }

  Future<void> _share(BiteCard place) async {
    final address = (place.address ?? '').trim();
    final text = [
      '📍 ${place.title}',
      if (place.cuisine.isNotEmpty) place.cuisine,
      if (address.isNotEmpty) address,
      PlaceLinks.mapsSearch(place).toString(),
    ].join('\n');
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: place.title),
      );
    } catch (_) {
      ToastService.instance.show("⚠️ Couldn't open the share sheet");
    }
  }

  void _showDeliveryOptions(BiteCard place) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SheetShell(
        title: '🚗 Order Delivery',
        subtitle: 'Opens ${place.title} on the delivery app’s website',
        children: [
          for (final ds in _delivery)
            _partnerTile(place, ds, onOpened: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  Future<void> _openReviewSheet(BiteCard place, PlaceReview? mine) async {
    if (_reviews.currentUserId == null) {
      ToastService.instance.show('Sign in to write a review');
      return;
    }
    final result = await showModalBottomSheet<({int rating, String body})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewComposer(placeTitle: place.title, existing: mine),
    );
    if (result == null || !mounted) return;
    final write = await _reviews.submit(
      rating: result.rating,
      body: result.body,
    );
    ToastService.instance.show(
      !write.isSuccess
          ? "⚠️ Couldn't post your review. Try again."
          : mine == null
              ? '🌶 Review posted!'
              : '🌶 Review updated',
    );
  }

  Future<void> _deleteReview(PlaceReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Delete your review?',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: const Text(
          'This removes your rating and review for this place.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await _reviews.delete(review.id);
    ToastService.instance.show(
      result.isSuccess ? 'Review deleted' : "⚠️ Couldn't delete your review",
    );
  }

  // ── Layout ──

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
    final hasImage = place.image != null && place.image!.isNotEmpty;
    final photoCount = place.photos.where((p) => p.startsWith('http')).length;
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
            child: !hasImage
                ? Text(
                    place.emoji.isEmpty ? '🏠' : place.emoji,
                    style: const TextStyle(fontSize: 80),
                  )
                : null,
          ),
          if (hasImage)
            GestureDetector(
              onTap: photoCount > 0 ? () => _openGallery(place) : null,
              child: AppNetworkImage(place.image!),
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
          if (photoCount > 0)
            Positioned(
              bottom: 12,
              right: 16,
              child: GestureDetector(
                onTap: () => _openGallery(place),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        photoCount == 1 ? '1 photo' : '$photoCount photos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if ((place.status ?? '').isNotEmpty)
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

  Widget _header(
    BiteCard place,
    PlaceReviewsState reviews,
    SavedItem? savedEntry,
  ) {
    final address = (place.address ?? '').trim();
    final hours = (place.hours ?? '').trim();
    final distance = (place.distance ?? '').trim();
    final canCall = PlaceLinks.dialable(place.phone) != null;
    final stats = reviews.stats;
    final mine = reviews.mine(_reviews.currentUserId);
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
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (place.rating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFF5A623),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    place.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((place.reviewCount ?? 0) > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${place.reviewCount})',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            if (stats.count > 0 && stats.average != null)
              GestureDetector(
                onTap: () => setState(() => _section = 'reviews'),
                child: Text(
                  '🌶 ${stats.average!.toStringAsFixed(1)} (${stats.count})',
                  style: const TextStyle(
                    color: AppColors.placesPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if ((place.priceLevel ?? '').isNotEmpty)
              Text(
                place.priceLevel!,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            if (distance.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 12,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    distance,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (address.isNotEmpty) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => PlaceLinks.open(
              PlaceLinks.directions(place),
              opening: '🗺 Opening Maps…',
            ),
            child: Text(
              address,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.muted,
              ),
            ),
          ),
        ],
        if (hours.isNotEmpty) ...[
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
                  hours,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            _circleToggle(
              icon: savedEntry == null
                  ? Icons.bookmark_border_rounded
                  : Icons.bookmark_rounded,
              active: savedEntry != null,
              color: AppColors.amber,
              onTap: () => _toggleSaved(place, savedEntry),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _section = 'reviews');
                  _openReviewSheet(place, mine);
                },
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.glass,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Text(
                    mine == null ? '🌶 Write a review' : '🌶 Edit your review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (canCall)
              _serviceButton(
                Icons.call_rounded,
                'Call',
                const Color(0xFF4CAF50),
                () => PlaceLinks.call(place),
              ),
            _serviceButton(
              Icons.navigation_rounded,
              'Directions',
              AppColors.cyan,
              () => PlaceLinks.open(
                PlaceLinks.directions(place),
                opening: '🗺 Opening Maps…',
              ),
            ),
            _serviceButton(
              Icons.public_rounded,
              'Website',
              AppColors.amber,
              () => PlaceLinks.open(
                PlaceLinks.website(place),
                opening: '🌐 Searching the web for ${place.title}…',
              ),
            ),
            _serviceButton(
              Icons.ios_share_rounded,
              'Share',
              AppColors.coral,
              () => _share(place),
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

  Widget _sectionContent(BiteCard place, PlaceReviewsState reviews) {
    return switch (_section) {
      'menu' => _menuSection(place),
      'photos' => _photosSection(place),
      'reviews' => _reviewsSection(place, reviews),
      _ => _overviewSection(place),
    };
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// A delivery / reservation partner row that opens the partner's site.
  Widget _partnerTile(
    BiteCard place,
    _Partner partner, {
    String? subtitle,
    VoidCallback? onOpened,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          onOpened?.call();
          PlaceLinks.open(
            partner.url(place),
            opening: 'Opening ${partner.name}…',
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Text(partner.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle ?? 'Find ${place.title} on ${partner.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewSection(BiteCard place) {
    final creator = place.creator.trim().toLowerCase();
    final creatorIsHandle = RegExp(r'^@[a-z0-9_.]+$').hasMatch(creator);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('🚗 Order Delivery'),
        const SizedBox(height: 12),
        for (final ds in _delivery) _partnerTile(place, ds),
        const SizedBox(height: 12),
        _sectionTitle('🪑 Reserve a Table'),
        const SizedBox(height: 4),
        const Text(
          'Check availability and book on the partner’s site.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final rs in _reservations)
          _partnerTile(
            place,
            rs,
            subtitle: 'See open tables for ${place.title}',
          ),
        if (creatorIsHandle) ...[
          const SizedBox(height: 12),
          _sectionTitle('📸 Reviewed by'),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => openCreator(context, creator),
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
                    child: Text(
                      place.emoji.isEmpty ? '🍽' : place.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
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
                          'b🌶te Creator',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
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
      ],
    );
  }

  Widget _menuSection(BiteCard place) {
    final menu = place.menuHighlights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Menu Highlights'),
            GestureDetector(
              onTap: () => PlaceLinks.open(
                PlaceLinks.menu(place),
                opening: '🌐 Searching for the full menu…',
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
        if (menu.isEmpty)
          const EmptyState(
            emoji: '📋',
            title: 'No menu highlights yet',
            message: 'Tap “Full menu” to look up the menu online.',
            compact: true,
          ),
        for (var i = 0; i < menu.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: i < menu.length - 1
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
                    menu[i].name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  menu[i].price,
                  style: const TextStyle(
                    color: AppColors.placesPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _sectionTitle('Order from Menu'),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final ds in _delivery.take(2))
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => PlaceLinks.open(
                      ds.url(place),
                      opening: 'Opening ${ds.name}…',
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
                          const Text(
                            'Opens website ↗',
                            style: TextStyle(
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
    final photos = place.photos.where((p) => p.startsWith('http')).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Photos'),
            if (photos.isNotEmpty)
              Text(
                photos.length == 1 ? '1 photo' : '${photos.length} photos',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (photos.isEmpty)
          const EmptyState(
            emoji: '📷',
            title: 'No photos yet',
            message: 'See more photos of this place on Google Maps.',
            compact: true,
          )
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (var i = 0; i < photos.length; i++)
                GestureDetector(
                  onTap: () => _openGallery(place, i),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.placesPurple.withValues(alpha: 0.13),
                          AppColors.bgCard,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AppNetworkImage(
                      photos[i],
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_) =>
                          const Text('📷', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Center(
          child: _outlinePill(
            label: 'More photos on Google Maps ↗',
            color: AppColors.placesPurple,
            onTap: () => PlaceLinks.open(
              PlaceLinks.mapsSearch(place),
              opening: '🗺 Opening Google Maps…',
            ),
          ),
        ),
      ],
    );
  }

  Widget _outlinePill({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withValues(alpha: 0.27)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stars(double value, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            Icons.star_rounded,
            size: size,
            color: i <= value.round()
                ? const Color(0xFFF5A623)
                : Colors.white.withValues(alpha: 0.15),
          ),
      ],
    );
  }

  Widget _reviewsSection(BiteCard place, PlaceReviewsState reviews) {
    final stats = reviews.stats;
    final userId = _reviews.currentUserId;
    final mine = reviews.mine(userId);
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
                stats.average?.toStringAsFixed(1) ?? '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 4),
              _stars(stats.average ?? 0),
              const SizedBox(height: 6),
              Text(
                stats.count == 0
                    ? 'No b🌶te reviews yet'
                    : stats.count == 1
                        ? '1 b🌶te review'
                        : '${stats.count} b🌶te reviews',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (place.rating != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Listing rating ★ ${place.rating!.toStringAsFixed(1)}'
                  '${(place.reviewCount ?? 0) > 0 ? ' · ${place.reviewCount} ratings' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _openReviewSheet(place, mine),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.placesPurple,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: reviews.submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          mine == null ? 'Write a review' : 'Edit your review',
                          style: const TextStyle(
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
        _sectionTitle('🌶 b🌶te Reviews'),
        const SizedBox(height: 12),
        if (reviews.loading && reviews.reviews.isEmpty)
          const LoadingState(
            label: 'Loading reviews…',
            height: 140,
            backgroundColor: Colors.transparent,
          )
        else if (reviews.error != null && reviews.reviews.isEmpty)
          ErrorState(
            message: reviews.error!,
            backgroundColor: Colors.transparent,
            onRetry: () => _reviews.load(place.id, force: true),
          )
        else if (reviews.reviews.isEmpty)
          const EmptyState(
            emoji: '🌶',
            title: 'Be the first to review',
            message: 'Share how your visit went with the b🌶te community.',
            compact: true,
          )
        else
          for (final rev in reviews.reviews)
            _reviewCard(place, rev, isMine: rev.userId == userId),
        const SizedBox(height: 8),
        Center(
          child: _outlinePill(
            label: 'See reviews on Google Maps ↗',
            color: AppColors.muted,
            icon: Icons.public_rounded,
            onTap: () => PlaceLinks.open(
              PlaceLinks.mapsSearch(place),
              opening: '🗺 Opening Google Maps…',
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(BiteCard place, PlaceReview rev, {required bool isMine}) {
    final handle = rev.authorHandle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMine
                ? AppColors.placesPurple.withValues(alpha: 0.4)
                : AppColors.glassBorder,
          ),
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
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.placesPurple, AppColors.coral],
                    ),
                  ),
                  child: rev.authorAvatarUrl != null
                      ? AppNetworkImage(
                          rev.authorAvatarUrl!,
                          width: 36,
                          height: 36,
                          errorBuilder: (_) => Text(
                            rev.authorEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                        )
                      : Text(
                          rev.authorEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: handle == null
                        ? null
                        : () => openCreator(context, handle),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMine ? '${rev.displayName} (you)' : rev.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          Formatters.timeAgo(rev.createdAt) == 'now'
                              ? 'just now'
                              : '${Formatters.timeAgo(rev.createdAt)} ago',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _stars(rev.rating.toDouble(), size: 14),
                if (isMine)
                  PopupMenuButton<String>(
                    tooltip: 'Review options',
                    padding: EdgeInsets.zero,
                    color: AppColors.bgCard,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    onSelected: (v) => v == 'edit'
                        ? _openReviewSheet(place, rev)
                        : _deleteReview(rev),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.coral),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (rev.body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                rev.body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
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
              onTap: () => PlaceLinks.open(
                PlaceLinks.openTable(place),
                opening: '🪑 Opening OpenTable…',
              ),
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
              onTap: () => _showDeliveryOptions(place),
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

/// Rounded dark bottom-sheet container with a title + subtitle.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Star picker + text field for writing / editing a b🌶te review.
/// Pops `(rating, body)` on submit, null on dismiss.
class _ReviewComposer extends StatefulWidget {
  const _ReviewComposer({required this.placeTitle, this.existing});

  final String placeTitle;
  final PlaceReview? existing;

  @override
  State<_ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<_ReviewComposer> {
  late int _rating = widget.existing?.rating ?? 0;
  late final TextEditingController _controller = TextEditingController(
    text: widget.existing?.body ?? '',
  );

  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Great', 'Amazing'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating < 1) {
      ToastService.instance.show('Tap the stars to rate this place');
      return;
    }
    Navigator.of(context).pop((rating: _rating, body: _controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _SheetShell(
        title: widget.existing == null ? 'Write a review' : 'Edit your review',
        subtitle: widget.placeTitle,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i star${i == 1 ? '' : 's'}',
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      Icons.star_rounded,
                      size: 34,
                      color: i <= _rating
                          ? const Color(0xFFF5A623)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: Text(
              _rating == 0 ? 'Tap to rate' : _labels[_rating],
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 3,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'What did you order? How was it?',
              hintStyle: const TextStyle(color: AppColors.muted),
              counterStyle: const TextStyle(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.glass,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.placesPurple),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _submit,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _rating == 0
                    ? AppColors.placesPurple.withValues(alpha: 0.4)
                    : AppColors.placesPurple,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                widget.existing == null ? 'Post review' : 'Save changes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
