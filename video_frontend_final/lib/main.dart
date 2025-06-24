import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VidGrabProApp());
}

class VidGrabProApp extends StatelessWidget {
  const VidGrabProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VidGrab Pro',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const VideoDownloaderScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF8C00),
              Color(0xFFFFD700),
              Color(0xFFFF6B35),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with scale animation
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/downloader_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback icon if asset is not found
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange[600]!, Colors.red[400]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.video_library_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // App name with slide animation
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'VidGrab Pro',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Download videos from anywhere',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String filePath;

  const VideoPlayerScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not found';
        });
        return;
      }

      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController.initialize();

      if (_videoPlayerController.value.hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize video player';
        });
        return;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFFF8C00),
          handleColor: const Color(0xFFFF8C00),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[300]!,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error playing video:\n$errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      debugPrint('Video player error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('VidGrab Pro Player'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _hasError
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to play video\n$_errorMessage',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        )
            : _isInitialized && _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}

class VideoDownloaderScreen extends StatefulWidget {
  const VideoDownloaderScreen({Key? key}) : super(key: key);

  @override
  State<VideoDownloaderScreen> createState() => _VideoDownloaderScreenState();
}

class _VideoDownloaderScreenState extends State<VideoDownloaderScreen>
    with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  List<DownloadItem> _downloads = [];
  late AnimationController _animationController;
  final Dio _dio = Dio();
  static const String baseUrl = 'https://downloader-production-b815.up.railway.app';
  bool _isValidUrl = false;
  String? _currentPlatform;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isDownloading = false;
  Map<String, String> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _urlController.addListener(_validateUrl);
    _requestPermissions();
    _loadDownloads();

    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validateUrl() {
    final url = _urlController.text.trim();
    final supportedPlatforms = {
      'youtube.com': 'YouTube',
      'youtu.be': 'YouTube',
      'tiktok.com': 'TikTok',
      'vm.tiktok.com': 'TikTok',
      'instagram.com': 'Instagram',
      'facebook.com': 'Facebook',
    };

    bool isValid = false;
    String? platform;

    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        for (final entry in supportedPlatforms.entries) {
          if (uri.host.contains(entry.key)) {
            isValid = true;
            platform = entry.value;
            break;
          }
        }
      } catch (e) {
        isValid = false;
      }
    }

    setState(() {
      _isValidUrl = isValid;
      _currentPlatform = platform;
    });

    if (isValid) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request storage permissions
      await Permission.storage.request();

      // For Android 11 and above
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      // Request media permissions for Android 13+
      await Permission.videos.request();
      await Permission.audio.request();
      await Permission.photos.request();
    }
  }

  Future<String> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Enhanced local storage approach - try multiple locations
      try {
        // First try: Public Downloads/VidGrabPro folder
        final downloadDir = Directory('/storage/emulated/0/Download/VidGrabPro');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        // Test write permission
        final testFile = File('${downloadDir.path}/.test');
        await testFile.writeAsString('test');
        await testFile.delete();

        return downloadDir.path;
      } catch (e) {
        try {
          // Second try: Movies/VidGrabPro folder
          final moviesDir = Directory('/storage/emulated/0/Movies/VidGrabPro');
          if (!await moviesDir.exists()) {
            await moviesDir.create(recursive: true);
          }
          return moviesDir.path;
        } catch (e) {
          // Final fallback: App's external directory
          Directory? dir = await getExternalStorageDirectory();
          final downloadDir = Directory('${dir!.path}/VidGrabPro/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir.path;
        }
      }
    } else {
      // iOS: Use Documents directory
      Directory dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/VidGrabPro/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir.path;
    }
  }

  Future<String> _getThumbnailDirectory() async {
    Directory dir = await getApplicationDocumentsDirectory();
    final thumbnailDir = Directory('${dir.path}/VidGrabPro/Thumbnails');
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }
    return thumbnailDir.path;
  }

  Future<void> _saveDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadsJson = _downloads.map((d) => jsonEncode({
      'id': d.id,
      'url': d.url,
      'platform': d.platform,
      'fileName': d.fileName,
      'filePath': d.filePath,
      'fileSize': d.fileSize,
      'thumbnailPath': d.thumbnailPath,
      'createdAt': d.createdAt.toIso8601String(),
    })).toList();
    await prefs.setStringList('vidgrab_downloads', downloadsJson);
  }

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadsJson = prefs.getStringList('vidgrab_downloads') ?? [];

    setState(() {
      _downloads = downloadsJson.map((json) {
        final data = jsonDecode(json);
        final filePath = data['filePath'];
        final fileExists = filePath != null && File(filePath).existsSync();

        return DownloadItem(
          id: data['id'],
          url: data['url'],
          platform: data['platform'],
          status: fileExists ? DownloadStatus.completed : DownloadStatus.failed,
          progress: 1.0,
          fileName: data['fileName'],
          filePath: filePath,
          fileSize: data['fileSize'],
          thumbnailPath: data['thumbnailPath'],
          createdAt: DateTime.parse(data['createdAt']),
        );
      }).toList();
    });
  }

  Future<String?> _generateThumbnail(String videoPath, String videoId) async {
    try {
      final thumbnailDir = await _getThumbnailDirectory();
      final thumbnailPath = '$thumbnailDir/thumb_$videoId.jpg';

      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 120,
        quality: 75,
        timeMs: 1000,
      );

      if (generatedPath != null && await File(generatedPath).exists()) {
        _thumbnailCache[videoId] = generatedPath;
        return generatedPath;
      }
    } catch (e) {
      debugPrint('Thumbnail generation error: $e');
    }
    return null;
  }

  Future<void> _downloadVideo() async {
    if (!_isValidUrl || _isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    final url = _urlController.text.trim();
    final downloadId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = 'vidgrab_${downloadId}.mp4';
    final downloadDir = await _getDownloadDirectory();
    final savePath = '$downloadDir/$fileName';

    final downloadItem = DownloadItem(
      id: downloadId,
      url: url,
      platform: _currentPlatform ?? 'Unknown',
      status: DownloadStatus.downloading,
      progress: 0.0,
      fileName: fileName,
    );

    setState(() => _downloads.insert(0, downloadItem));

    try {
      final response = await _dio.post(
        '$baseUrl/download',
        data: {'url': url},
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              final index = _downloads.indexWhere((item) => item.id == downloadId);
              if (index != -1) {
                _downloads[index] = downloadItem.copyWith(progress: received / total);
              }
            });
          }
        },
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.data as List<int>);

        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('Downloaded file is empty');
        }

        // Generate thumbnail
        final thumbnailPath = await _generateThumbnail(savePath, downloadId);

        final updatedItem = downloadItem.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          filePath: savePath,
          fileSize: _formatFileSize(fileSize),
          thumbnailPath: thumbnailPath,
        );

        setState(() {
          final index = _downloads.indexWhere((item) => item.id == downloadId);
          if (index != -1) {
            _downloads[index] = updatedItem;
          }
        });

        await _saveDownloads();
        _showSnackBar('Video saved to local storage!', Colors.green);

        // Clear URL after successful download
        _urlController.clear();
      } else {
        throw Exception('Download failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.statusMessage ?? e.message ?? 'Unknown error';
      setState(() {
        final index = _downloads.indexWhere((item) => item.id == downloadId);
        if (index != -1) {
          _downloads[index] = downloadItem.copyWith(
            status: DownloadStatus.failed,
            error: errorMessage,
          );
        }
      });
      await _saveDownloads();
      _showSnackBar('Download failed: $errorMessage', Colors.red);
    } catch (e) {
      setState(() {
        final index = _downloads.indexWhere((item) => item.id == downloadId);
        if (index != -1) {
          _downloads[index] = downloadItem.copyWith(
            status: DownloadStatus.failed,
            error: e.toString(),
          );
        }
      });
      await _saveDownloads();
      _showSnackBar('Download failed: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showSnackBar('File not found', Colors.red);
        return;
      }

      // Always use custom player for better control
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(filePath: filePath),
        ),
      );
    } catch (e) {
      _showSnackBar('Error opening file: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      if (await File(filePath).exists()) {
        await Share.shareXFiles([XFile(filePath)], text: 'Downloaded with VidGrab Pro!');
      } else {
        _showSnackBar('File not found', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error sharing file', Colors.red);
    }
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video from local storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _removeDownload(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _removeDownload(String id) async {
    setState(() {
      final download = _downloads.firstWhere((item) => item.id == id);
      if (download.filePath != null) {
        try {
          File(download.filePath!).delete();
        } catch (e) {
          debugPrint('Error deleting file: $e');
        }
      }
      if (download.thumbnailPath != null) {
        try {
          File(download.thumbnailPath!).delete();
        } catch (e) {
          debugPrint('Error deleting thumbnail: $e');
        }
      }
      _downloads.removeWhere((item) => item.id == id);
    });
    await _saveDownloads();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showSnackBar(String message, Color color) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _urlController.text = clipboardData!.text!;
      }
    } catch (e) {
      _showSnackBar('Failed to paste from clipboard', Colors.red);
    }
  }

  void _clearUrl() {
    _urlController.clear();
  }

  Widget _buildVideoThumbnail(DownloadItem download) {
    if (download.thumbnailPath != null && File(download.thumbnailPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(download.thumbnailPath!),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
        ),
      );
    }
    return _buildPlaceholderIcon();
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[300]!, Colors.yellow[200]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.videocam, size: 30, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
      body: Container(
      decoration: const BoxDecoration(
      gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
    ),
    ),
    child: SafeArea(
    child: Column(
    children: [
    Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
    children: [
    const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(
    Icons.video_library,
    color: Colors.white,
    size: 32,
    ),
    SizedBox(width: 12),
    Text(
    'VidGrab Pro',
    style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
    ],
    ),
    const SizedBox(height: 8),
    Text(
    'Download videos from YouTube, TikTok, Instagram & Facebook',
    style: TextStyle(
    fontSize: 16,
    color: Colors.white.withOpacity(0.9),
    ),
    textAlign: TextAlign.center,
    ),
    ],
    ),
    ),
    Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 20,
    offset: const Offset(0, 10),
    ),
    ],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
      Expanded(
        child: TextField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: 'Paste video URL here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: _urlController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearUrl,
            )
                : null,
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _downloadVideo(),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        onPressed: _pasteFromClipboard,
        icon: const Icon(Icons.paste),
        tooltip: 'Paste from clipboard',
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[200],
          padding: const EdgeInsets.all(12),
        ),
      ),
    ],
    ),
      const SizedBox(height: 16),
      if (_currentPlatform != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPlatformIcon(_currentPlatform!),
                size: 16,
                color: Colors.orange[800],
              ),
              const SizedBox(width: 4),
              Text(
                _currentPlatform!,
                style: TextStyle(
                  color: Colors.orange[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isValidUrl && !_isDownloading ? _downloadVideo : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isDownloading
              ? const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Text('Downloading...'),
            ],
          )
              : const Text(
            'Download Video',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
    ),
    ),
      const SizedBox(height: 20),
      Expanded(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.download_rounded,
                      color: Color(0xFFFF8C00),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Downloads',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_downloads.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _downloads.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No downloads yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paste a video URL above to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _downloads.length,
                  itemBuilder: (context, index) {
                    final download = _downloads[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: _buildVideoThumbnail(download),
                        title: Text(
                          download.fileName ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPlatformColor(download.platform),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    download.platform,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (download.fileSize != null)
                                  Text(
                                    download.fileSize!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (download.status == DownloadStatus.downloading)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: download.progress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF8C00),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(download.progress * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            else if (download.status == DownloadStatus.failed)
                              Text(
                                'Failed: ${download.error ?? 'Unknown error'}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Text(
                                'Downloaded ${_formatTimeAgo(download.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: download.status == DownloadStatus.completed
                            ? PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'play':
                                _openFile(download.filePath!);
                                break;
                              case 'share':
                                _shareFile(download.filePath!);
                                break;
                              case 'delete':
                                _showDeleteConfirmation(context, download.id);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'play',
                              child: Row(
                                children: [
                                  Icon(Icons.play_arrow, size: 20),
                                  SizedBox(width: 8),
                                  Text('Play'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share, size: 20),
                                  SizedBox(width: 8),
                                  Text('Share'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          child: const Icon(Icons.more_vert),
                        )
                            : download.status == DownloadStatus.downloading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF8C00),
                            ),
                          ),
                        )
                            : const Icon(Icons.error, color: Colors.red),
                        onTap: download.status == DownloadStatus.completed
                            ? () => _openFile(download.filePath!)
                            : null,
                      ),
                    );
                  },
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
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle_fill;
      case 'tiktok':
        return Icons.music_video;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.video_library;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Colors.red;
      case 'tiktok':
        return Colors.black;
      case 'instagram':
        return Colors.purple;
      case 'facebook':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

enum DownloadStatus {
  downloading,
  completed,
  failed,
}

class DownloadItem {
  final String id;
  final String url;
  final String platform;
  final DownloadStatus status;
  final double progress;
  final String? fileName;
  final String? filePath;
  final String? fileSize;
  final String? thumbnailPath;
  final String? error;
  final DateTime createdAt;

  DownloadItem({
    required this.id,
    required this.url,
    required this.platform,
    required this.status,
    required this.progress,
    this.fileName,
    this.filePath,
    this.fileSize,
    this.thumbnailPath,
    this.error,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DownloadItem copyWith({
    String? id,
    String? url,
    String? platform,
    DownloadStatus? status,
    double? progress,
    String? fileName,
    String? filePath,
    String? fileSize,
    String? thumbnailPath,
    String? error,
    DateTime? createdAt,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}