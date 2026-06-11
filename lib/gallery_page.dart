import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<AssetEntity> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() => _loading = false);
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final photos = await albums.first.getAssetListRange(start: 0, end: 200);
    setState(() {
      _photos = photos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [

            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (!_loading)
                    Text(
                      '${_photos.length} photos',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _photos.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  color: Colors.white24, size: 64),
                              SizedBox(height: 16),
                              Text(
                                'No photos yet',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 3,
                            mainAxisSpacing: 3,
                          ),
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            return _PhotoTile(
                              asset: _photos[index],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _PhotoViewPage(
                                    assets: _photos,
                                    initialIndex: index,
                                  ),
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

// ── Grid thumbnail tile ──
class _PhotoTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _PhotoTile({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FutureBuilder<Uint8List?>(
        future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(color: const Color(0xFF1A1A1A));
          }
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}

// ── Full screen photo viewer ──
class _PhotoViewPage extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;

  const _PhotoViewPage({required this.assets, required this.initialIndex});

  @override
  State<_PhotoViewPage> createState() => _PhotoViewPageState();
}

class _PhotoViewPageState extends State<_PhotoViewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ── Swipeable full screen photos ──
          PageView.builder(
            controller: _pageController,
            itemCount: widget.assets.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return FutureBuilder<Uint8List?>(
                future: widget.assets[index].originBytes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Center(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ── Top bar ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.assets.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}