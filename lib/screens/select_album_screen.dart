import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'review_gallery_page.dart';

class ItemInfo {
  final int year;
  final int? month;
  final bool isYearDivider;

  ItemInfo({required this.year, this.month, required this.isYearDivider});
}

class SelectAlbumScreen extends StatefulWidget {
  const SelectAlbumScreen({super.key});

  @override
  State<SelectAlbumScreen> createState() => _SelectAlbumScreenState();
}

class _SelectAlbumScreenState extends State<SelectAlbumScreen> {
  Map<int, Map<int, List<AssetPathEntity>>> _albumsByYearAndMonth = {};
  List<int> _years = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
    });

    final result = await PhotoManager.requestPermissionExtend();
    if (!result.isAuth) {
      PhotoManager.openSetting();
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption:
          FilterOptionGroup()..addOrderOption(
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ),
    );

    final Map<int, Map<int, List<AssetPathEntity>>> albumsByYearAndMonth = {};

    for (var album in albums) {
      final assets = await album.getAssetListRange(start: 0, end: 1);
      if (assets.isEmpty) continue;

      final DateTime? createDate = assets.first.createDateTime;
      if (createDate == null) continue;

      final year = createDate.year;
      final month = createDate.month;

      if (!albumsByYearAndMonth.containsKey(year)) {
        albumsByYearAndMonth[year] = {};
      }

      if (!albumsByYearAndMonth[year]!.containsKey(month)) {
        albumsByYearAndMonth[year]![month] = [];
      }

      albumsByYearAndMonth[year]![month]!.add(album);
    }

    final years =
        albumsByYearAndMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _albumsByYearAndMonth = albumsByYearAndMonth;
      _years = years;
      _isLoading = false;
    });
  }

  Future<Uint8List?> _getThumbnail(AssetPathEntity album) async {
    final assets = await album.getAssetListRange(start: 0, end: 1);
    if (assets.isEmpty) return null;
    return assets.first.thumbnailDataWithSize(const ThumbnailSize(300, 300));
  }

  void _openAlbum(BuildContext context, AssetPathEntity album) async {
    final count = await album.assetCountAsync;
    final images = await album.getAssetListRange(start: 0, end: count);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewGalleryPage(initialImages: images),
      ),
    );
  }

  Future<int> _getAssetCount(AssetPathEntity album) async {
    return album.assetCountAsync;
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM', 'es').format(DateTime(0, month));
  }

  int _calculateTotalItems() {
    int total = 0;
    for (var year in _years) {
      total += 1;
      total += _albumsByYearAndMonth[year]!.length;
    }
    return total;
  }

  ItemInfo _getItemInfoForIndex(int index) {
    int currentIndex = 0;

    for (var year in _years) {
      if (currentIndex == index) {
        return ItemInfo(year: year, isYearDivider: true);
      }
      currentIndex++;

      final months =
          _albumsByYearAndMonth[year]!.keys.toList()
            ..sort((a, b) => b.compareTo(a));

      for (var month in months) {
        if (currentIndex == index) {
          return ItemInfo(year: year, month: month, isYearDivider: false);
        }
        currentIndex++;
      }
    }

    return ItemInfo(year: DateTime.now().year, isYearDivider: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona un álbum")),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _calculateTotalItems(),
        itemBuilder: (context, index) {
          final ItemInfo itemInfo = _getItemInfoForIndex(index);

          if (itemInfo.isYearDivider) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.grey[200],
              child: Center(
                child: Text(
                  itemInfo.year.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          } else {
            final month = itemInfo.month!;
            final year = itemInfo.year;
            final albums = _albumsByYearAndMonth[year]![month]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _getMonthName(month).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, albumIndex) {
                    final album = albums[albumIndex];
                    return FutureBuilder<Uint8List?>(
                      future: _getThumbnail(album),
                      builder: (context, snapshot) {
                        final thumb = snapshot.data;
                        return GestureDetector(
                          onTap: () => _openAlbum(context, album),
                          child: GridTile(
                            footer: GridTileBar(
                              backgroundColor: Colors.black54,
                              title: Text(album.name),
                              subtitle: FutureBuilder<int>(
                                future: _getAssetCount(album),
                                builder: (context, countSnapshot) {
                                  if (countSnapshot.connectionState ==
                                          ConnectionState.done &&
                                      countSnapshot.hasData) {
                                    return Text("${countSnapshot.data} fotos");
                                  } else {
                                    return const SizedBox(
                                      height: 2,
                                      child: LinearProgressIndicator(),
                                    );
                                  }
                                },
                              ),
                            ),
                            child:
                                thumb != null
                                    ? Image.memory(thumb, fit: BoxFit.cover)
                                    : const Center(
                                      child: Icon(Icons.photo_album, size: 48),
                                    ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
