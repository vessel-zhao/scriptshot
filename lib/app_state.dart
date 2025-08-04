import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AppState with ChangeNotifier {
  // 脚本内容
  String _scriptContent = '';
  // 字体
  String _selectedFont = 'Default';
  // 文本颜色
  Color _textColor = Colors.white; // 将默认颜色改为白色
  // 滚动速度
  double _scrollSpeed = 4.0;
  // 文字大小
  double _textSize = 16.0;
  // 视频分辨率
  String _videoResolution = '1080P';
  // 视频宽高比
  String _videoAspectRatio = '16:9';
  // 倒计时
  int _countdown = 3;

  // Getters
  String get scriptContent => _scriptContent;
  String get selectedFont => _selectedFont;
  Color get textColor => _textColor;
  double get scrollSpeed => _scrollSpeed;
  double get textSize => _textSize;
  String get videoResolution => _videoResolution;
  String get videoAspectRatio => _videoAspectRatio;
  int get countdown => _countdown;

  // Setters
  void setScriptContent(String content) {
    _scriptContent = content;
    notifyListeners();
  }

  void setSelectedFont(String font) {
    _selectedFont = font;
    notifyListeners();
  }

  void setTextColor(Color color) {
    _textColor = color;
    notifyListeners();
  }

  void setScrollSpeed(double speed) {
    _scrollSpeed = speed;
    notifyListeners();
  }

  void setTextSize(double size) {
    _textSize = size;
    notifyListeners();
  }

  void setVideoResolution(String resolution) {
    _videoResolution = resolution;
    notifyListeners();
  }

  void setVideoAspectRatio(String aspectRatio) {
    _videoAspectRatio = aspectRatio;
    notifyListeners();
  }

  void setCountdown(int seconds) {
    _countdown = seconds;
    notifyListeners();
  }

  // 增加滚动速度
  void increaseScrollSpeed() {
    _scrollSpeed += 0.1;
    notifyListeners();
  }

  // 减少滚动速度
  void decreaseScrollSpeed() {
    if (_scrollSpeed > 0.1) {
      _scrollSpeed -= 0.1;
      notifyListeners();
    }
  }

  // 增加文字大小
  void increaseTextSize() {
    _textSize += 1.0;
    notifyListeners();
  }

  // 减少文字大小
  void decreaseTextSize() {
    if (_textSize > 1.0) {
      _textSize -= 1.0;
      notifyListeners();
    }
  }

  // 保存脚本到文件
  Future<void> saveScript() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/script.txt');
      await file.writeAsString(_scriptContent);
    } catch (e) {
      // 错误处理
      print('Error saving script: $e');
    }
  }

  // 从文件加载脚本
  Future<void> loadScript() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/script.txt');
      if (await file.exists()) {
        _scriptContent = await file.readAsString();
        notifyListeners();
      }
    } catch (e) {
      // 错误处理
      print('Error loading script: $e');
    }
  }
}