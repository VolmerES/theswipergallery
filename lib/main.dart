import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallery Cleaner',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

/// Pantalla que pide permiso de lectura y agrupa fotos por mes.
class SelectMonthScreen extends StatefulWidget {
  const SelectMonthScreen({super.key});
  @override
  State<SelectMonthScreen> createState() => _SelectMonthScreenState();
}

class _SelectMonthScreenState extends State<SelectMonthScreen> {
  bool _loading = true;
  String _error = '';
  final Map<String, List<AssetEntity>> _byMonth = {};

  @override
  void initState() {
    super.initState();
    _ensurePermissionAndLoad();
  }

  Future<void> _ensurePermissionAndLoad() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    var ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      await PhotoManager.openSetting();
      ps = await PhotoManager.requestPermissionExtend();
    }

    if (ps.isAuth || ps.hasAccess) {
      await _loadPhotosByMonth();
    } else {
      setState(() {
        _loading = false;
        _error = 'Permiso denegado. No se pueden cargar las fotos.';
      });
    }
  }

  Future<void> _loadPhotosByMonth() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup()
          ..addOrderOption(const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          )),
      );

      const pageSize = 200;
      final all = <AssetEntity>[];
      for (final p in paths) {
        final total = await p.assetCountAsync;
        for (int i = 0; i * pageSize < total; i++) {
          all.addAll(await p.getAssetListPaged(page: i, size: pageSize));
        }
      }

      final grouped = <String, List<AssetEntity>>{};
      for (var a in all) {
        final dt = a.createDateTime ?? a.modifiedDateTime;
        if (dt == null) continue;
        final key =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []).add(a);
      }

      if (!mounted) return;
      setState(() {
        _byMonth
          ..clear()
          ..addAll(grouped);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar fotos: $e';
        _loading = false;
      });
    }
  }

  Future<Uint8List?> _thumb(List<AssetEntity> assets) =>
      assets.isEmpty ? Future.value(null) : assets.first.thumbnailDataWithSize(const ThumbnailSize(300, 300));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fotos por mes')),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    final months = _byMonth.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      appBar: AppBar(title: const Text('Fotos por mes')),
      body: ListView.builder(
        itemCount: months.length,
        itemBuilder: (_, i) {
          final key = months[i].key;
          final list = months[i].value;
          return FutureBuilder<Uint8List?>(
            future: _thumb(list),
            builder: (_, snap) {
              final data = snap.data;
              return ListTile(
                leading: data != null
                    ? Image.memory(data, width: 60, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.photo, size: 60),
                title: Text(_format(key)),
                subtitle: Text('${list.length} fotos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewGalleryPage(images: list),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _format(String key) {
    final parts = key.split('-');
    final year = int.parse(parts[0]), month = int.parse(parts[1]);
    const names = [
      'Enero','Febrero','Marzo','Abril','Mayo','Junio',
      'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'
    ];
    return '${names[month - 1]} $year';
  }
}

/// Lógica de swipes para guardar o eliminar (corregido).
class ReviewGalleryPage extends StatefulWidget {
  final List<AssetEntity> images;
  const ReviewGalleryPage({super.key, required this.images});
  @override
  State<ReviewGalleryPage> createState() => _ReviewGalleryPageState();
}

class _ReviewGalleryPageState extends State<ReviewGalleryPage> {
  late List<AssetEntity> _imgs;
  final List<AssetEntity> _toDelete = [];
  int _idx = 0;
  bool _loading = true;
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    _imgs = List.of(widget.images);
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    setState(() => _loading = true);
    if (_idx < _imgs.length) {
      final d = await _imgs[_idx].thumbnailDataWithSize(const ThumbnailSize(600, 600));
      if (!mounted) return;
      setState(() {
        _thumb = d;
        _loading = false;
      });
    }
  }

  void _swipe(bool delete) {
    if (delete) _toDelete.add(_imgs[_idx]);

    setState(() {
      _imgs.removeAt(_idx);
      if (_idx >= _imgs.length) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DeletePreviewPage(images: _toDelete)),
        );
      } else {
        _loadThumb();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_idx + 1}/${_imgs.length}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Dismissible(
              key: ValueKey(_imgs[_idx].id),
              direction: DismissDirection.horizontal,
              onDismissed: (d) => _swipe(d == DismissDirection.endToStart),
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                child: const Icon(Icons.check, size: 40, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Icon(Icons.delete, size: 40, color: Colors.white),
              ),
              child: Center(
                child: _thumb != null
                    ? Image.memory(_thumb!, fit: BoxFit.contain)
                    : const Icon(Icons.photo, size: 200),
              ),
            ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(onPressed: () => _swipe(true), child: const Text('Eliminar')),
          ElevatedButton(onPressed: () => _swipe(false), child: const Text('Guardar')),
        ],
      ),
    );
  }
}

/// Página de confirmación y borrado.
class DeletePreviewPage extends StatefulWidget {
  final List<AssetEntity> images;
  const DeletePreviewPage({super.key, required this.images});
  @override
  State<DeletePreviewPage> createState() => _DeletePreviewPageState();
}

class _DeletePreviewPageState extends State<DeletePreviewPage> {
  bool _busy = false;

  Future<void> _confirmDelete() async {
    setState(() => _busy = true);
    try {
      final failed = await PhotoManager.editor.deleteWithIds(
        widget.images.map((e) => e.id).toList(),
      );
      await PhotoManager.clearFileCache();
      if (!mounted) return;
      final msg = failed.isEmpty
          ? 'Imágenes enviadas a la papelera'
          : 'No se pudieron eliminar ${failed.length} imágenes';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _busy = false);
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar borrado')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4),
                    itemCount: widget.images.length,
                    itemBuilder: (_, i) {
                      return FutureBuilder<Uint8List?>(
                        future: widget.images[i]
                            .thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                        builder: (_, snap) {
                          final b = snap.data;
                          return b != null
                              ? Image.memory(b, fit: BoxFit.cover)
                              : Container(color: Colors.grey[300]);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: _confirmDelete,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text(_busy ? 'Procesando...' : 'Borrar ${widget.images.length}'),
                  ),
                ),
              ],
            ),
    );
  }
}
