import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'review_gallery_page.dart';

class SelectAlbumScreen extends StatefulWidget {
  const SelectAlbumScreen({super.key});

  @override
  State<SelectAlbumScreen> createState() => _SelectAlbumScreenState();
}

class _SelectAlbumScreenState extends State<SelectAlbumScreen> {
  List<AssetPathEntity> _albums = [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
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

    setState(() {
      _albums = albums;
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

  @override
  Widget build(BuildContext context) {
    if (_albums.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona un álbum")),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _albums.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final album = _albums[index];

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
                          return const CircularProgressIndicator();
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
    );
  }
}
