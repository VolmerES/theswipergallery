import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ReviewGalleryPage extends StatefulWidget {
  final List<AssetEntity> initialImages;

  const ReviewGalleryPage({
    super.key,
    required this.initialImages,
  });

  @override
  State<ReviewGalleryPage> createState() => _ReviewGalleryPageState();
}

class _ReviewGalleryPageState extends State<ReviewGalleryPage> {
  late List<AssetEntity> _images;
  List<AssetEntity> _toDelete = [];
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _images = widget.initialImages;
  }

  void _handleKeep() => _nextImage();

  void _handleDelete() {
    _toDelete.add(_images[_currentIndex]);
    _nextImage();
  }

  void _nextImage() {
    if (_currentIndex < _images.length - 1) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisión completada')),
      );
      Navigator.pop(context); // o ir a pantalla de confirmación
    }
  }

  Future<Widget> _buildImage(AssetEntity entity) async {
    final thumb = await entity.thumbnailDataWithSize(const ThumbnailSize(800, 800));
    if (thumb == null) return const Center(child: Text("No disponible"));
    return Image.memory(thumb, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Revisión de galería")),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Widget>(
                  future: _buildImage(_images[index]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Center(child: snapshot.data!);
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _handleDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text("Eliminar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _handleKeep,
                  icon: const Icon(Icons.check),
                  label: const Text("Guardar"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
