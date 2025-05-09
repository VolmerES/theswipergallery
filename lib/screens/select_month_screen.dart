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
  final Set<String> _seenAssetIds = {}; // Para evitar duplicados
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });

    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );

    if (albums.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final rawImages = await albums.first.getAssetListPaged(
      page: 0,
      size: 10000,
    );

    final uniqueImages = rawImages.where((e) => _seenAssetIds.add(e.id)).toList();

    final monthYearMap = <String, Map<String, dynamic>>{};

    for (var image in uniqueImages) {
      final date = image.createDateTime;
      final displayKey = "${_monthName(date.month)} ${date.year}";
      final sortKey = "${date.year}${date.month.toString().padLeft(2, '0')}";

      if (!monthYearMap.containsKey(sortKey)) {
        monthYearMap[sortKey] = {
          'displayKey': displayKey,
          'date': date,
          'images': <AssetEntity>[],
        };
      }
      monthYearMap[sortKey]!['images']!.add(image);
    }

    final sortedKeys = monthYearMap.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var sortKey in sortedKeys) {
      final data = monthYearMap[sortKey]!;
      final displayKey = data['displayKey'];
      final images = data['images'] as List<AssetEntity>;
      _imagesByMonth[displayKey] = images;
      _thumbnailPerMonth[displayKey] = images.first;
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _monthName(int month) {
    const names = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Cargando fotos...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_imagesByMonth.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Selecciona un mes")),
        body: const Center(
          child: Text(
            "No se encontraron fotos",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final keys = _imagesByMonth.keys.toList();
    final yearGroups = <String, List<String>>{};
    for (final key in keys) {
      final year = key.split(" ").last;
      yearGroups.putIfAbsent(year, () => []).add(key);
    }

    final years = yearGroups.keys.toList()..sort((a, b) => int.parse(b).compareTo(int.parse(a)));

    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona un mes")),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: years.length,
        itemBuilder: (context, yearIndex) {
          final year = years[yearIndex];
          final monthsInYear = yearGroups[year]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (yearIndex > 0)
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Divider(
                    thickness: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  year,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: monthsInYear.length,
                itemBuilder: (context, monthIndex) {
                  final key = monthsInYear[monthIndex];
                  final images = _imagesByMonth[key]!;
                  final thumbImage = _thumbnailPerMonth[key]!;

                  return FutureBuilder<Uint8List?>(
                    future: thumbImage.thumbnailDataWithSize(
                      const ThumbnailSize(300, 300),
                    ),
                    builder: (context, snapshot) {
                      final thumb = snapshot.data;
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewGalleryPage(initialImages: images),
                            ),
                          );

                          if (result != null) {
                            _loadImages();
                          }
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
            ],
          );
        },
      ),
    );
  }
}
