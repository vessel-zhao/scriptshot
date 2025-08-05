import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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
import 'package:tdesign_flutter/tdesign_flutter.dart';

// 速度预览组件
class SpeedPreviewWidget extends StatefulWidget {
  final double initialSpeed;

  const SpeedPreviewWidget({Key? key, required this.initialSpeed})
    : super(key: key);

  @override
  State<SpeedPreviewWidget> createState() => _SpeedPreviewWidgetState();
}

class _SpeedPreviewWidgetState extends State<SpeedPreviewWidget>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this);
    _startScrolling();
  }

  @override
  void didUpdateWidget(covariant SpeedPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSpeed != widget.initialSpeed) {
      _resetAndRestartScrolling();
    }
  }

  void _startScrolling() {
    // 取消之前的重置定时器（如果有的话）
    _resetTimer?.cancel();

    // 在短暂延迟后开始滚动，让用户看到初始状态
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(
            milliseconds: (5000 ~/ widget.initialSpeed).toInt(),
          ),
          curve: Curves.linear,
        );

        // 滚动完成后重置位置
        _resetTimer = Timer(
          Duration(milliseconds: (5000 ~/ widget.initialSpeed).toInt()),
          () {
            if (mounted) {
              _resetAndRestartScrolling();
            }
          },
        );
      }
    });
  }

  void _resetAndRestartScrolling() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
      _startScrolling();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这是滚动速度预览文本，用于展示不同速度下的滚动效果。调整滑块可以改变滚动速度，预览会自动重新开始滚动。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Text(
            '预览文本会根据设定的速度持续滚动，滚动完成后会自动回到初始位置重新开始。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Text(
            '通过这个预览功能，您可以直观地感受到不同速度设置对实际使用效果的影响。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const Text(
            '这是滚动速度预览文本，用于展示不同速度下的滚动效果。调整滑块可以改变滚动速度，预览会自动重新开始滚动。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Text(
            '预览文本会根据设定的速度持续滚动，滚动完成后会自动回到初始位置重新开始。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Text(
            '通过这个预览功能，您可以直观地感受到不同速度设置对实际使用效果的影响。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const Text(
            '这是滚动速度预览文本，用于展示不同速度下的滚动效果。调整滑块可以改变滚动速度，预览会自动重新开始滚动。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Text(
            '预览文本会根据设定的速度持续滚动，滚动完成后会自动回到初始位置重新开始。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),
          const Text(
            '通过这个预览功能，您可以直观地感受到不同速度设置对实际使用效果的影响。',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

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
  double _eyeStrength = 0.0; // 大眼
  double _faceThinning = 0.0; // 瘦脸
  double _faceWhiten = 0.0; // 美白
  double _faceBlur = 0.0; // 磨皮
  bool _beautyPanelOpen = false; // 美颜面板是否打开
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
        final double maxScrollExtent =
            _textScrollController.position.maxScrollExtent;
        if (maxScrollExtent > 0) {
          // 只有当内容超出容器时才需要滚动
          final double scrollSpeed = Provider.of<AppState>(
            context,
            listen: false,
          ).scrollSpeed;
          // 根据滚动速度计算总滚动时间，这里可以根据实际需求调整计算方式
          // 假设 1x 速度下，整个脚本滚动需要 30 秒，那么可以这样计算
          final double totalScrollDurationInSeconds = 30 / scrollSpeed;
          final double scrollPerSecond =
              maxScrollExtent / totalScrollDurationInSeconds;

          _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (
            timer,
          ) {
            if (_textScrollController.hasClients && _isRecording) {
              // 每次滚动 50ms 对应的距离
              double scrollAmount =
                  scrollPerSecond * 0.05; // 0.05 是 50ms / 1000ms
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
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String videoPathWithExtension = path.join(
          videoDirectory,
          'video_$timestamp.mp4',
        );

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('视频保存失败')));
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
    Navigator.of(context).push(
      TDSlidePopupRoute(
        modalBarrierColor: Colors.black.withOpacity(0.5),
        slideTransitionFrom: SlideTransitionFrom.bottom,
        builder: (context) {
          return TDPopupBottomDisplayPanel(
            title: '美颜设置',
            closeClick: () {
              Navigator.maybePop(context);
            },
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  height: 400,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                                    PFBeautyFiterType.eyeStrength,
                                    value,
                                  );
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
                                    PFBeautyFiterType.faceThinning,
                                    value,
                                  );
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
                                    PFBeautyFiterType.faceWhitenStrength,
                                    value,
                                  );
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
                                    PFBeautyFiterType.faceBlurStrength,
                                    value,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
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
    _pixelfree.pixelFreeSetBeautyFilterParam(
      PFBeautyFiterType.eyeStrength,
      0.0,
    );
    _pixelfree.pixelFreeSetBeautyFilterParam(
      PFBeautyFiterType.faceThinning,
      0.0,
    );
    _pixelfree.pixelFreeSetBeautyFilterParam(
      PFBeautyFiterType.faceWhitenStrength,
      0.0,
    );
    _pixelfree.pixelFreeSetBeautyFilterParam(
      PFBeautyFiterType.faceBlurStrength,
      0.0,
    );

    TDToast.showText('美颜设置已重置', context: context);
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
          child: TDSlider(
            sliderThemeData: TDSliderThemeData(
              context: context,
              min: 0.0,
              max: 1.0,
            ),
            value: value,
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

  void _flipCamera() {
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

      _controller = CameraController(newCamera, ResolutionPreset.high);

      _controller?.initialize().then((_) {
        if (mounted) {
          setState(() {
            _cameraInitialized = true;
          });
        }
      });
    }
  }

  void _showSettings() {
    final appState = Provider.of<AppState>(context, listen: false);

    TDActionSheet(
      context,
      visible: true,
      items: [
        TDActionSheetItem(label: '滚动速度设置'),
        TDActionSheetItem(label: '文字大小设置'),
        TDActionSheetItem(label: '倒计时设置'),
        TDActionSheetItem(label: '重置美颜设置'),
      ],
      onSelected: (item, index) {
        // 先关闭ActionSheet，再打开对应的设置面板
        Navigator.of(context).pop();
        // 使用addPostFrameCallback确保在下一帧执行，避免Navigator冲突
        WidgetsBinding.instance.addPostFrameCallback((_) {
          switch (index) {
            case 0:
              _showScrollSpeedSetting();
              break;
            case 1:
              _showTextSizeSetting();
              break;
            case 2:
              _showCountdownSetting();
              break;
            case 3:
              _resetBeautySettings();
              break;
          }
        });
      },
    );
  }

  void _showScrollSpeedSetting() {
    final appState = Provider.of<AppState>(context, listen: false);

    Navigator.of(context).push(
      TDSlidePopupRoute(
        modalBarrierColor: TDTheme.of(context).fontGyColor2,
        slideTransitionFrom: SlideTransitionFrom.bottom,
        builder: (context) {
          return TDPopupBottomDisplayPanel(
            title: '滚动速度设置',
            closeClick: () {
              Navigator.maybePop(context);
            },
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      TDSlider(
                        sliderThemeData: TDSliderThemeData(
                          context: context,
                          min: 0.1,
                          max: 3.0,
                        ),
                        value: appState.scrollSpeed,
                        onChanged: (value) {
                          appState.setScrollSpeed(value);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 20),
                      Text('当前速度: ${appState.scrollSpeed.toStringAsFixed(1)}x'),
                      const SizedBox(height: 20),
                      Container(
                        height: 80,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SpeedPreviewWidget(
                          initialSpeed: appState.scrollSpeed,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showTextSizeSetting() {
    Navigator.of(context).push(
      TDSlidePopupRoute(
        modalBarrierColor: TDTheme.of(context).fontGyColor2,
        slideTransitionFrom: SlideTransitionFrom.bottom,
        builder: (context) {
          return TDPopupBottomDisplayPanel(
            title: '文字大小设置',
            closeClick: () {
              Navigator.maybePop(context);
            },
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  TDButton(
                    text: '小 (14px)',
                    theme: TDButtonTheme.primary,
                    type: TDButtonType.outline,
                    size: TDButtonSize.large,
                    onTap: () {
                      final baseSize = Provider.of<AppState>(
                        context,
                        listen: false,
                      ).textSize;
                      setState(() {
                        _textScale = 14.0 / baseSize;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  TDButton(
                    text: '中 (18px)',
                    theme: TDButtonTheme.primary,
                    type: TDButtonType.outline,
                    size: TDButtonSize.large,
                    onTap: () {
                      final baseSize = Provider.of<AppState>(
                        context,
                        listen: false,
                      ).textSize;
                      setState(() {
                        _textScale = 18.0 / baseSize;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  TDButton(
                    text: '大 (24px)',
                    theme: TDButtonTheme.primary,
                    type: TDButtonType.outline,
                    size: TDButtonSize.large,
                    onTap: () {
                      final baseSize = Provider.of<AppState>(
                        context,
                        listen: false,
                      ).textSize;
                      setState(() {
                        _textScale = 24.0 / baseSize;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  TDButton(
                    text: '超大 (32px)',
                    theme: TDButtonTheme.primary,
                    type: TDButtonType.outline,
                    size: TDButtonSize.large,
                    onTap: () {
                      final baseSize = Provider.of<AppState>(
                        context,
                        listen: false,
                      ).textSize;
                      setState(() {
                        _textScale = 32.0 / baseSize;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCountdownSetting() {
    final appState = Provider.of<AppState>(context, listen: false);

    Navigator.of(context).push(
      TDSlidePopupRoute(
        modalBarrierColor: TDTheme.of(context).fontGyColor2,
        slideTransitionFrom: SlideTransitionFrom.bottom,
        builder: (context) {
          return TDPopupBottomDisplayPanel(
            title: '倒计时设置',
            closeClick: () {
              Navigator.maybePop(context);
            },
            child: Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  TDButton(
                    text: '3秒',
                    theme: TDButtonTheme.primary,
                    type: TDButtonType.outline,
                    size: TDButtonSize.large,
                    onTap: () {
                      appState.setCountdown(3);
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  TDButton(
                    text: '5秒',
                    theme: TDButtonTheme.primary,
                    type: TDButtonType.outline,
                    size: TDButtonSize.large,
                    onTap: () {
                      appState.setCountdown(5);
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  TDButton(
                    text: '10秒',
                    theme: TDButtonTheme.primary,
                    type: TDButtonType.outline,
                    size: TDButtonSize.large,
                    onTap: () {
                      appState.setCountdown(10);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: TDNavBar(
        title: '录制视频',
        titleFontWeight: FontWeight.w600,
        screenAdaptation: true,
        useDefaultBack: false,
        rightBarItems: [
          TDNavBarItem(
            icon: Icons.face,
            iconSize: 24,
            padding: const EdgeInsets.only(right: 16),
            action: _showBeautyPanel,
          ),
          TDNavBarItem(
            icon: Icons.flip_camera_android,
            iconSize: 24,
            padding: const EdgeInsets.only(right: 16),
            action: _flipCamera,
          ),
          TDNavBarItem(
            icon: Icons.settings,
            iconSize: 24,
            padding: const EdgeInsets.only(right: 16),
            action: _showSettings,
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
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize!.height,
                      height: _controller!.value.previewSize!.width,
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
                          style: TextStyle(fontSize: 18, color: Colors.white70),
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
                    color: Colors.black.withOpacity(0.8), // 使用带透明度的颜色
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    '$_countdownValue',
                    style: const TextStyle(
                      fontSize: 72,
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
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8), // 使用带透明度的颜色
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${(_recordingTime ~/ 60).toString().padLeft(2, '0')}:${(_recordingTime % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. 可拖动和调整大小的脚本文本框 (浮动在视频之上)
          if (!_showCountdown && appState.scriptContent.isNotEmpty)
            Stack(
              children: [
                // 在文本框上方添加滚动速度显示
                Positioned(
                  left:
                      (screenWidth / 2 - _containerWidth / 2).clamp(
                        0.0,
                        screenWidth - _containerWidth,
                      ) +
                      _textPosition.dx,
                  top: 120 + _textPosition.dy,
                  child: GestureDetector(
                    onTap: _showScrollSpeedSetting,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.speed,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${appState.scrollSpeed.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left:
                      (screenWidth / 2 - _containerWidth / 2).clamp(
                        0.0,
                        screenWidth - _containerWidth,
                      ) +
                      _textPosition.dx,
                  top: 150 + _textPosition.dy,
                  child: GestureDetector(
                    onPanStart: _handleDragStart,
                    onPanUpdate: _handleDragUpdate,
                    onPanEnd: _handleDragEnd,
                    child: Container(
                      key: _textContainerKey,
                      width: _containerWidth,
                      height: _containerHeight,
                      // 调整BoxDecoration，确保不会影响手势识别
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // 使用带透明度的颜色
                        borderRadius: BorderRadius.circular(16),
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
                                appState.scriptContent.isEmpty
                                    ? '在此处输入提词内容\n点击编辑按钮可编辑内容'
                                    : appState.scriptContent,
                                style: TextStyle(
                                  fontSize: appState.textSize * _textScale,
                                  color: appState.scriptContent.isEmpty
                                      ? Colors.white70
                                      : appState.textColorValue,
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
                              // 确保调整大小的手势不会向上传播
                              behavior: HitTestBehavior.translucent,
                              onPanUpdate: (details) {
                                setState(() {
                                  _containerWidth =
                                      (_containerWidth + details.delta.dx)
                                          .clamp(100.0, screenWidth - 50);
                                  _containerHeight =
                                      (_containerHeight + details.delta.dy)
                                          .clamp(50.0, screenHeight * 0.4);
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  // 使用带透明度的颜色
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.drag_handle,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // 字体大小调整按钮
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _textScale = (_textScale - 0.1).clamp(
                                        0.5,
                                        3.0,
                                      );
                                    });
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _textScale = (_textScale + 0.1).clamp(
                                        0.5,
                                        3.0,
                                      );
                                    });
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // 5. 控制工具区域 (浮动在视频之上，固定在底部)
          // 简化版控制面板，只保留录制按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 录制按钮 (仅在非倒计时期间显示)
                    if (!_showCountdown)
                      GestureDetector(
                        onTap: () {
                          if (_isRecording) {
                            _stopRecording();
                          } else if (_cameraInitialized) {
                            _startCountdown(appState.countdown);
                          } else {
                            if (mounted) {
                              TDToast.showText('相机初始化中，请稍后...', context: context);
                            }
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
      appBar: TDNavBar(
        title: '视频预览',
        titleFontWeight: FontWeight.w600,
        screenAdaptation: true,
        useDefaultBack: true,
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
      floatingActionButton: TDButton(
        text: _videoController.value.isPlaying ? '暂停' : '播放',
        icon: _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
        type: TDButtonType.fill,
        theme: TDButtonTheme.primary,
        size: TDButtonSize.large,
        onTap: () {
          setState(() {
            if (_videoController.value.isPlaying) {
              _videoController.pause();
            } else {
              _videoController.play();
            }
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _confirmDeleteVideo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text(
            '确定要删除这个视频吗？\n\n注意：此操作只会删除应用内部的视频文件，如果视频已保存到系统相册，需要您手动从相册中删除。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TDButton(
              text: '删除',
              type: TDButtonType.outline,
              theme: TDButtonTheme.danger,
              size: TDButtonSize.small,
              onTap: () {
                Navigator.of(context).pop();
                _deleteVideo(context);
              },
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('视频已从应用中删除')));
        Navigator.of(context).pop(); // 返回上一页
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除失败')));
    }
  }
}
