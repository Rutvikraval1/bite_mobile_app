import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';

/// Full-screen, swipeable viewer for a place's photos (pinch to zoom).
class PlacePhotoGallery extends StatefulWidget {
  const PlacePhotoGallery({
    super.key,
    required this.photos,
    required this.title,
    this.initialIndex = 0,
  });

  final List<String> photos;
  final String title;
  final int initialIndex;

  /// Pushes the gallery above everything (including the detail sheet).
  static Future<void> show(
    BuildContext context, {
    required List<String> photos,
    required String title,
    int initialIndex = 0,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => PlacePhotoGallery(
          photos: photos,
          title: title,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<PlacePhotoGallery> createState() => _PlacePhotoGalleryState();
}

class _PlacePhotoGalleryState extends State<PlacePhotoGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: AppNetworkImage(
                  widget.photos[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (_) => const Text(
                    '📷',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.title} · ${_index + 1}/${widget.photos.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
