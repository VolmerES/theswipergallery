import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_indicator.dart';
import 'review_gallery_page.dart';

class SelectMonthScreen extends StatefulWidget {
  const SelectMonthScreen({super.key});

  @override
  State<SelectMonthScreen> createState() => _SelectMonthScreenState();
}

class _SelectMonthScreenState extends State<SelectMonthScreen> with SingleTickerProviderStateMixin {
  final Map<String, List<AssetEntity>> _imagesByMonth = {};
  final Map<String, AssetEntity> _thumbnailPerMonth = {};
  final Set<String> _seenAssetIds = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.repeat(reverse: true);
    _loadImages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth && !permission.hasAccess) {
        await PhotoManager.openSetting();
        final newPermission = await PhotoManager.requestPermissionExtend();
        if (!newPermission.isAuth && !newPermission.hasAccess) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Se requiere permiso para acceder a las fotos';
          });
          return;
        }
      }

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

      if (uniqueImages.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

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
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al cargar las imágenes: $e';
      });
    }
  }

  String _monthName(int month) {
    const names = [
      "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fotos por meses"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: !_isLoading && !_hasError && _imagesByMonth.isNotEmpty
          ? FloatingActionButton(
              onPressed: _loadImages,
              backgroundColor: AppTheme.neonBlue,
              foregroundColor: Colors.black,
              elevation: 8,
              child: const Icon(Icons.refresh_rounded),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: LoadingIndicator(message: "Cargando colección de fotos..."),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.neonPink,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadImages,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Reintentar"),
            ),
          ],
        ),
      );
    }

    if (_imagesByMonth.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              "No se encontraron fotos",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      );
    }

    final keys = _imagesByMonth.keys.toList();
    final yearGroups = <String, List<String>>{};
    for (final key in keys) {
      final year = key.split(" ").last;
      yearGroups.putIfAbsent(year, () => []).add(key);
    }

    final years = yearGroups.keys.toList()
      ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16, top: 8),
      itemCount: years.length,
      itemBuilder: (context, yearIndex) {
        final year = years[yearIndex];
        final monthsInYear = yearGroups[year]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.neonBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.neonBlue, width: 1.5),
                    ),
                    child: Text(
                      year,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppTheme.neonBlue.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: monthsInYear.length,
              itemBuilder: (context, monthIndex) {
                final key = monthsInYear[monthIndex];
                final images = _imagesByMonth[key]!;
                final thumbImage = _thumbnailPerMonth[key]!;

                return FutureBuilder<Uint8List?>(
                  future: thumbImage.thumbnailDataWithSize(
                    const ThumbnailSize(400, 400),
                  ),
                  builder: (context, snapshot) {
                    final thumb = snapshot.data;
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;

                    return GestureDetector(
                      onTap: () async {
                        if (isLoading) return;
                        
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
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isLoading
                                      ? Colors.transparent
                                      : AppTheme.neonBlue.withOpacity(0.15 + _animationController.value * 0.05),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Imagen
                              thumb != null
                                  ? Image.memory(
                                      thumb,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      filterQuality: FilterQuality.high,
                                    )
                                  : Container(
                                      color: AppTheme.surfaceDark,
                                      child: isLoading
                                          ? const Center(child: CircularProgressIndicator())
                                          : const Icon(Icons.image_not_supported, size: 40, color: Colors.white30),
                                    ),
                              
                              // Gradiente inferior
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Información
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        key,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${images.length} fotos",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}