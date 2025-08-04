import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:video_script/app_state.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:pixelfree/pixelfree.dart';
import 'package:pixelfree/pixelfree_platform_interface.dart';

class VideoRecorderPage extends StatefulWidget {
  const VideoRecorderPage({super.key});

  @override
  State<VideoRecorderPage> createState() => _VideoRecorderPageState();
}

class _VideoRecorderPageState extends State<VideoRecorderPage>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _showCountdown = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  Timer? _scrollTimer; // 新增：用于脚本滚动的计时器
  int _recordingTime = 0;
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _cameraInitialized = false;
  double _textScale = 1.0;
  Offset _textPosition = Offset.zero;
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  double _containerWidth = 300;
  double _containerHeight = 150;
  XFile? _recordedVideo; // 保存录制的视频文件
  final GlobalKey _textContainerKey = GlobalKey(); // 用于获取文本容器大小
  final ScrollController _textScrollController = ScrollController(); // 文本滚动控制器
  
  // 美颜相关属性
  late Pixelfree _pixelfree;
  double _eyeStrength = 0.0;      // 大眼
  double _faceThinning = 0.0;     // 瘦脸
  double _faceWhiten = 0.0;       // 美白
  double _faceBlur = 0.0;         // 磨皮
  bool _beautyPanelOpen = false;  // 美颜面板是否打开
  int? _beautyTextureId; // 美颜处理后的纹理ID

  @override
  void initState() {
    super.initState();
    _initializePixelfree();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _scrollTimer?.cancel(); // 释放滚动计时器
    _textScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializePixelfree() async {
    try {
      _pixelfree = Pixelfree();
      // 初始化Pixelfree SDK (需要license文件)
      // await _pixelfree.createWithLic('path/to/license.lic');
    } catch (e) {
      print('Pixelfree初始化失败: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0], // 使用后置摄像头
          ResolutionPreset.high,
        );
        await _controller?.initialize();
        
        // 监听相机帧数据
        _controller?.startImageStream((CameraImage image) async {
          await _processBeautyEffect(image);
        });
        
        setState(() {
          _cameraInitialized = true;
        });
      }
    } catch (e) {
      // 相机初始化失败处理
      print('相机初始化失败: $e');
    }
  }

  Future<void> _processBeautyEffect(CameraImage image) async {
    try {
      // 将CameraImage转换为Uint8List
      final Uint8List imageData = _cameraImageToUint8List(image);
      
      // 使用pixelfree处理图像
      final int textureId = await _pixelfree.processWithImage(
        imageData,
        image.width,
        image.height,
      );
      
      // 更新纹理ID
      setState(() {
        _beautyTextureId = textureId;
      });
    } catch (e) {
      print('美颜处理失败: $e');
    }
  }

  Uint8List _cameraImageToUint8List(CameraImage image) {
    // 这里需要根据图像格式进行转换
    // 简化处理，实际项目中需要根据具体的图像格式进行转换
    if (image.planes.length == 1) {
      // NV21 or other single plane format
      return image.planes[0].bytes;
    } else if (image.planes.length == 3) {
      // YUV420 format
      // 合并所有平面数据
      final BytesBuilder allBytes = BytesBuilder();
      for (final Plane plane in image.planes) {
        allBytes.add(plane.bytes);
      }
      return allBytes.toBytes();
    }
    return Uint8List(0);
  }

  void _startCountdown(int seconds) {
    setState(() {
      _showCountdown = true;
      _countdownValue = seconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownValue--;
      });

      if (_countdownValue <= 0) {
        _countdownTimer?.cancel();
        setState(() {
          _showCountdown = false;
          _isRecording = true;
          _recordingTime = 0;
        });
        // 开始录制视频
        _startRecording();
      }
    });
  }

  void _startRecording() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.startVideoRecording();
        // 开始计时器更新录制时间
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingTime++;
          });
        });
        // 开始自动滚动脚本
        _autoScrollScript();
      } catch (e) {
        print('开始录制失败: $e');
      }
    }
  }

  void _autoScrollScript() {
    // 确保在滚动前布局已经完成，以获取正确的scrollHeight
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_textScrollController.hasClients) {
        final double maxScrollExtent = _textScrollController.position.maxScrollExtent;
        if (maxScrollExtent > 0) { // 只有当内容超出容器时才需要滚动
          final double scrollSpeed = Provider.of<AppState>(context, listen: false).scrollSpeed;
          // 根据滚动速度计算总滚动时间，这里可以根据实际需求调整计算方式
          // 假设 1x 速度下，整个脚本滚动需要 30 秒，那么可以这样计算
          final double totalScrollDurationInSeconds = 30 / scrollSpeed;
          final double scrollPerSecond = maxScrollExtent / totalScrollDurationInSeconds;

          _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
            if (_textScrollController.hasClients && _isRecording) {
              // 每次滚动 50ms 对应的距离
              double scrollAmount = scrollPerSecond * 0.05; // 0.05 是 50ms / 1000ms
              double currentOffset = _textScrollController.offset;
              double targetOffset = currentOffset + scrollAmount;

              if (targetOffset < maxScrollExtent) {
                _textScrollController.jumpTo(targetOffset);
              } else {
                // 滚动到底部后停止计时器
                _scrollTimer?.cancel();
              }
            } else {
              _scrollTimer?.cancel(); // 如果停止录制或控制器不再可用，则停止滚动
            }
          });
        }
      }
    });
  }

  void _stopRecording() async {
    setState(() {
      _isRecording = false;
    });
    _recordingTimer?.cancel();
    _scrollTimer?.cancel(); // 停止脚本滚动计时器

    // 停止录制视频
    try {
      if (_controller != null && _controller!.value.isRecordingVideo) {
        final video = await _controller!.stopVideoRecording();

        // 获取临时目录
        final Directory appDirectory = await getTemporaryDirectory();
        final String videoDirectory = '${appDirectory.path}/Videos';
        await Directory(videoDirectory).create(recursive: true); // 确保目录存在

        // 构建带有 .mp4 扩展名的文件路径
        // 使用当前时间戳作为文件名，确保唯一性
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String videoPathWithExtension = path.join(videoDirectory, 'video_$timestamp.mp4');

        // 将录制的文件移动/复制到新路径
        final File originalFile = File(video.path);
        final File newFile = await originalFile.copy(videoPathWithExtension);

        setState(() {
          _recordedVideo = XFile(newFile.path); // 更新 _recordedVideo 为新路径
        });

        // 保存到相册
        try {
          // 使用带有扩展名的文件路径进行保存
          await GallerySaver.saveVideo(newFile.path);
          print('视频已保存到: ${newFile.path}');
        } catch (e) {
          print('保存到相册失败: $e');
        }

        // 显示保存成功提示和预览按钮
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('视频已保存'),
            action: SnackBarAction(
              label: '预览',
              onPressed: () {
                // 打开视频预览，使用新路径
                _previewVideo(_recordedVideo!);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('停止录制失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('视频保存失败')),
      );
    }
  }

  void _previewVideo(XFile video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewPage(videoFile: File(video.path)),
      ),
    );
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStart = details.globalPosition;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        final dragDelta = details.globalPosition - _dragStart;
        _textPosition += dragDelta;
        _dragStart = details.globalPosition;
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  void _showBeautyPanel() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '美颜设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 大眼调节
                          _buildBeautySlider(
                            label: '大眼',
                            value: _eyeStrength,
                            onChanged: (value) {
                              setState(() {
                                _eyeStrength = value;
                              });
                              _pixelfree.pixelFreeSetBeautyFilterParam(
                                  PFBeautyFiterType.eyeStrength, value);
                            },
                          ),
                          // 瘦脸调节
                          _buildBeautySlider(
                            label: '瘦脸',
                            value: _faceThinning,
                            onChanged: (value) {
                              setState(() {
                                _faceThinning = value;
                              });
                              _pixelfree.pixelFreeSetBeautyFilterParam(
                                  PFBeautyFiterType.faceThinning, value);
                            },
                          ),
                          // 美白调节
                          _buildBeautySlider(
                            label: '美白',
                            value: _faceWhiten,
                            onChanged: (value) {
                              setState(() {
                                _faceWhiten = value;
                              });
                              _pixelfree.pixelFreeSetBeautyFilterParam(
                                  PFBeautyFiterType.faceWhitenStrength, value);
                            },
                          ),
                          // 磨皮调节
                          _buildBeautySlider(
                            label: '磨皮',
                            value: _faceBlur,
                            onChanged: (value) {
                              setState(() {
                                _faceBlur = value;
                              });
                              _pixelfree.pixelFreeSetBeautyFilterParam(
                                  PFBeautyFiterType.faceBlurStrength, value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('关闭'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _resetBeautySettings() {
    setState(() {
      _eyeStrength = 0.0;
      _faceThinning = 0.0;
      _faceWhiten = 0.0;
      _faceBlur = 0.0;
    });
    
    // 重置美颜参数
    _pixelfree.pixelFreeSetBeautyFilterParam(PFBeautyFiterType.eyeStrength, 0.0);
    _pixelfree.pixelFreeSetBeautyFilterParam(PFBeautyFiterType.faceThinning, 0.0);
    _pixelfree.pixelFreeSetBeautyFilterParam(PFBeautyFiterType.faceWhitenStrength, 0.0);
    _pixelfree.pixelFreeSetBeautyFilterParam(PFBeautyFiterType.faceBlurStrength, 0.0);
  }

  Widget _buildBeautySlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).toInt()}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true, // 让 body 内容延伸到 AppBar 后面
      appBar: AppBar(
        title: const Text('录制视频', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent, // AppBar 透明
        elevation: 0, // 移除阴影
        actions: [
          // 美颜设置按钮
          IconButton(
            icon: const Icon(Icons.face, color: Colors.white),
            onPressed: _showBeautyPanel,
          ),
          // 重置美颜按钮
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetBeautySettings,
          ),
          // 视频分辨率选择
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            onSelected: (value) {
              appState.setVideoResolution(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '720P',
                child: Text('720P'),
              ),
              const PopupMenuItem(
                value: '1080P',
                child: Text('1080P'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 相机预览区域 - 全屏显示，并保持宽高比
          _cameraInitialized && _controller != null
              ? SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: FittedBox( // 关键修改：使用 FittedBox
              fit: BoxFit.cover, // 填充并裁剪以保持比例
              child: SizedBox(
                width: _controller!.value.previewSize!.height, // 使用预览尺寸的宽高比
                height: _controller!.value.previewSize!.width, // 使用预览尺寸的宽高比
                child: _beautyTextureId != null
                    ? Texture(textureId: _beautyTextureId!)
                    : CameraPreview(_controller!),
              ),
            ),
          )
              : Container(
            color: Colors.black,
            width: screenWidth,
            height: screenHeight,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    color: Colors.white38,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '相机初始化中...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. 倒计时显示 (浮动在视频之上)
          if (_showCountdown)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    '$_countdownValue',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // 3. 录制状态显示 (浮动在视频之上)
          if (_isRecording && !_showCountdown)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 10, // 避开AppBar
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_recordingTime ~/ 60).toString().padLeft(2, '0')}:${(_recordingTime % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. 可拖动和调整大小的脚本文本框 (浮动在视频之上)
          if (!_showCountdown && appState.scriptContent.isNotEmpty)
            Positioned(
              left: (screenWidth / 2 - _containerWidth / 2).clamp(0.0, screenWidth - _containerWidth) + _textPosition.dx,
              top: 50 + _textPosition.dy,
              child: GestureDetector(
                onPanStart: _handleDragStart,
                onPanUpdate: _handleDragUpdate,
                onPanEnd: _handleDragEnd,
                child: Container(
                  key: _textContainerKey,
                  width: _containerWidth,
                  height: _containerHeight,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDragging ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 文本内容 - 支持自动滚动
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          controller: _textScrollController,
                          scrollDirection: Axis.vertical,
                          child: Text(
                            appState.scriptContent,
                            style: TextStyle(
                              fontSize: appState.textSize * _textScale,
                              color: appState.textColor,
                              fontFamily: appState.selectedFont == 'Default'
                                  ? null
                                  : appState.selectedFont,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // 调整大小的手柄
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _containerWidth = (_containerWidth + details.delta.dx)
                                  .clamp(100.0, screenWidth - 50);
                              _containerHeight = (_containerHeight + details.delta.dy)
                                  .clamp(50.0, screenHeight * 0.4); // 限制最大高度，相对于屏幕高度
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            color: Colors.white54,
                            child: const Icon(
                              Icons.drag_handle,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. 控制工具区域 (浮动在视频之上，固定在底部)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea( // 确保不被底部导航栏等遮挡
              child: Container(
                color: Colors.black54, // 背景半透明，可以看到后面的视频
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 内容决定高度
                  children: [
                    // 配置项
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
                      children: [
                        // 左侧配置项
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 滚动速度控制
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('速度:', style: TextStyle(color: Colors.white)),
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.white),
                                    onPressed: () {
                                      appState.decreaseScrollSpeed();
                                    },
                                  ),
                                  Text('${appState.scrollSpeed.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white)),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    onPressed: () {
                                      appState.increaseScrollSpeed();
                                    },
                                  ),
                                ],
                              ),
                              // 视频比例选择
                              // Row(
                              //   mainAxisSize: MainAxisSize.min,
                              //   children: [
                              //     const Text('比例:', style: TextStyle(color: Colors.white)),
                              //     DropdownButton<String>(
                              //       value: appState.videoAspectRatio,
                              //       dropdownColor: Colors.black87, // 下拉菜单背景色
                              //       style: const TextStyle(color: Colors.white), // 选项文字颜色
                              //       icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // 下拉图标颜色
                              //       items: const [
                              //         DropdownMenuItem(value: '16:9', child: Text('16:9', style: TextStyle(color: Colors.white))),
                              //         DropdownMenuItem(value: '16:10', child: Text('16:10', style: TextStyle(color: Colors.white))),
                              //         DropdownMenuItem(value: '4:3', child: Text('4:3', style: TextStyle(color: Colors.white))),
                              //         DropdownMenuItem(value: '1:1', child: Text('1:1', style: TextStyle(color: Colors.white))),
                              //       ],
                              //       onChanged: (value) {
                              //         if (value != null) {
                              //           appState.setVideoAspectRatio(value);
                              //         }
                              //       },
                              //     ),
                              //   ],
                              // ),
                              // 文字大小控制
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('大小:', style: TextStyle(color: Colors.white)),
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _textScale = (_textScale - 0.1).clamp(0.5, 3.0);
                                      });
                                    },
                                  ),
                                  Text('${(appState.textSize * _textScale).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white)),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _textScale = (_textScale + 0.1).clamp(0.5, 3.0);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              // 倒计时选择
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('倒计时:', style: TextStyle(color: Colors.white)),
                                  DropdownButton<int>(
                                    value: appState.countdown,
                                    dropdownColor: Colors.black87, // 下拉菜单背景色
                                    style: const TextStyle(color: Colors.white), // 选项文字颜色
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // 下拉图标颜色
                                    items: const [
                                      DropdownMenuItem(value: 3, child: Text('3秒', style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: 5, child: Text('5秒', style: TextStyle(color: Colors.white))),
                                      DropdownMenuItem(value: 10, child: Text('10秒', style: TextStyle(color: Colors.white))),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        appState.setCountdown(value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 右侧控制 (镜头翻转，预览视频按钮)
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 镜头翻转
                              IconButton(
                                icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 30),
                                onPressed: () {
                                  if (_cameras.length > 1 && _controller != null) {
                                    final lensDirection = _controller!.description.lensDirection;
                                    CameraDescription newCamera;
                                    if (lensDirection == CameraLensDirection.back) {
                                      newCamera = _cameras.firstWhere(
                                            (camera) => camera.lensDirection == CameraLensDirection.front,
                                        orElse: () => _cameras[0],
                                      );
                                    } else {
                                      newCamera = _cameras.firstWhere(
                                            (camera) => camera.lensDirection == CameraLensDirection.back,
                                        orElse: () => _cameras[0],
                                      );
                                    }

                                    setState(() {
                                      _cameraInitialized = false;
                                    });

                                    _controller = CameraController(
                                      newCamera,
                                      ResolutionPreset.high,
                                    );

                                    _controller?.initialize().then((_) {
                                      if (mounted) {
                                        setState(() {
                                          _cameraInitialized = true;
                                        });
                                      }
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              // 显示最近录制的视频信息
                              if (_recordedVideo != null)
                                ElevatedButton(
                                  onPressed: () {
                                    _previewVideo(_recordedVideo!);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey, // 按钮背景色
                                    foregroundColor: Colors.white, // 文字颜色
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  child: const Text('预览视频'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10), // 录制按钮和上方内容的间距
                    // 录制按钮
                    GestureDetector(
                      onTap: () {
                        if (_isRecording) {
                          _stopRecording();
                        } else if (_cameraInitialized) {
                          _startCountdown(appState.countdown);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('相机初始化中，请稍后...')),
                          );
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        child: _isRecording
                            ? const Icon(
                          Icons.stop,
                          color: Colors.white,
                        )
                            : Container(
                          margin: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
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

// 视频预览页面
class VideoPreviewPage extends StatefulWidget {
  final File videoFile;

  const VideoPreviewPage({super.key, required this.videoFile});

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(widget.videoFile);
    _videoController.initialize().then((_) {
      setState(() {});
      _videoController.play();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频预览'),
        // actions: [
        //   // 删除按钮
        //   IconButton(
        //     icon: const Icon(Icons.delete),
        //     onPressed: () {
        //       _confirmDeleteVideo(context);
        //     },
        //   ),
        // ],
      ),
      body: Center(
        child: _videoController.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        )
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('视频加载中...'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_videoController.value.isPlaying) {
              _videoController.pause();
            } else {
              _videoController.play();
            }
          });
        },
        child: Icon(
          _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  void _confirmDeleteVideo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这个视频吗？\n\n注意：此操作只会删除应用内部的视频文件，如果视频已保存到系统相册，需要您手动从相册中删除。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVideo(context);
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteVideo(BuildContext context) {
    try {
      if (widget.videoFile.existsSync()) {
        // 删除应用内部的文件
        widget.videoFile.deleteSync();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('视频已从应用中删除')),
        );
        Navigator.of(context).pop(); // 返回上一页
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败')),
      );
    }
  }
}