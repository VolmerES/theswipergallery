import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'review_gallery_page.dart';

class SelectMonthScreen extends StatefulWidget {
  const SelectMonthScreen({super.key});

  @override
  State<SelectMonthScreen> createState() => _SelectMonthScreenState();
}

class _SelectMonthScreenState extends State<SelectMonthScreen> {
  final Map<String, List<AssetEntity>> _imagesByMonth = {};
  final Map<String, AssetEntity> _thumbnailPerMonth = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );

    final allImages = await albums.first.getAssetListPaged(page: 0, size: 1000);

    for (var image in allImages) {
      final date = image.createDateTime;
      final key = "${_monthName(date.month)} ${date.year}";

      _imagesByMonth.putIfAbsent(key, () => []).add(image);
      _thumbnailPerMonth.putIfAbsent(key, () => image);
    }

    setState(() {});
  }

  String _monthName(int month) {
    const names = [
      "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_imagesByMonth.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final keys = _imagesByMonth.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona un mes")),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final key = keys[index];
          final images = _imagesByMonth[key]!;
          final thumbImage = _thumbnailPerMonth[key]!;

          return FutureBuilder<Uint8List?>(
            future: thumbImage.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
            builder: (context, snapshot) {
              final thumb = snapshot.data;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewGalleryPage(initialImages: images),
                    ),
                  );
                },
                child: GridTile(
                  footer: GridTileBar(
                    backgroundColor: Colors.black54,
                    title: Text(key),
                    subtitle: Text("${images.length} fotos"),
                  ),
                  child: thumb != null
                      ? Image.memory(thumb, fit: BoxFit.cover)
                      : const Center(child: CircularProgressIndicator()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
