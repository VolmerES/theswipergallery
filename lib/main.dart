import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swiper Gallery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ReviewGalleryPage(),
    );
  }
}

class ReviewGalleryPage extends StatefulWidget {
  const ReviewGalleryPage({super.key});

  @override
  State<ReviewGalleryPage> createState() => _ReviewGalleryPageState();
}

class _ReviewGalleryPageState extends State<ReviewGalleryPage> {
  List<AssetEntity> _images = [];
  List<AssetEntity> _toDelete = [];
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadImages();
  }

  Future<void> _requestPermissionAndLoadImages() async {
    final status = await Permission.photos.request();

    if (!status.isGranted) {
      PhotoManager.openSetting();
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );

    final recent = albums.first;
    final images = await recent.getAssetListPaged(page: 0, size: 100);

    setState(() {
      _images = images;
    });
  }

  void _handleKeep() {
    _nextImage();
  }

  void _handleDelete() {
    _toDelete.add(_images[_currentIndex]);
    _nextImage();
  }

  void _nextImage() {
    if (_currentIndex < _images.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmDeletePage(images: _toDelete),
        ),
      );
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

class ConfirmDeletePage extends StatelessWidget {
  final List<AssetEntity> images;

  const ConfirmDeletePage({super.key, required this.images});

  Future<void> _deleteImages(BuildContext context) async {
    final ids = images.map((e) => e.id).toList();
    final failed = await PhotoManager.editor.deleteWithIds(ids);

    if (failed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Imágenes eliminadas correctamente.")),
      );
      Navigator.pop(context); // Volver al inicio
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("No se pudieron eliminar ${failed.length} imágenes.")),
      );
    }
  }

  Future<Uint8List?> _thumb(AssetEntity entity) {
    return entity.thumbnailDataWithSize(const ThumbnailSize(200, 200));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirmar eliminación")),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return FutureBuilder<Uint8List?>(
                  future: _thumb(images[index]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    } else {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 1));
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteImages(context),
                    icon: const Icon(Icons.delete),
                    label: Text("Eliminar (${images.length})"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
