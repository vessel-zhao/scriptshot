# BeautyCam 插件集成说明

## 已实现功能

1. 美颜功能开关：`enableBeauty(true)`
2. 美颜等级调节：`setBeautyLevel(level)` (范围 0-1)
3. 相机切换：`switchCamera()`
4. 视频录制：`takeVideo()` 和 `stopVideo()`

## 待解决问题

### 1. 视频文件获取问题
当前 beauty_cam 插件的文档没有明确说明如何获取录制完成的视频文件路径。需要解决以下问题：
- 如何获取录制视频的文件路径
- 如何将视频保存到相册
- 如何预览录制的视频

### 2. 相机预览问题
当前仍在使用原来的 CameraPreview 组件，可能需要替换为 beauty_cam 提供的预览组件以正确显示美颜效果。

### 3. 美颜功能的完整性
目前仅实现了基础美颜功能，缺少：
- 独立的美白调节功能
- 瘦脸功能
- 大眼功能

## 建议解决方案

### 短期方案
1. 查看 beauty_cam 插件的源码或联系作者获取更详细的文档
2. 通过插件的 example 项目了解完整用法

### 长期方案
如果 beauty_cam 插件功能不足，考虑以下替代方案：
1. 寻找其他功能更完整的美颜插件
2. 集成专业美颜SDK（如相芯、FaceU等）
3. 自定义实现美颜算法

## API 使用说明

### 基础用法
```dart
// 初始化
BeautyCam? beautyCam = BeautyCam();

// 开启美颜
beautyCam?.enableBeauty(true);

// 设置美颜等级 (0-1)
beautyCam?.setBeautyLevel(0.7);

// 切换相机
beautyCam?.switchCamera();

// 开始录制
beautyCam?.takeVideo();

// 停止录制
beautyCam?.stopVideo();
```

## 注意事项

1. 需要仔细测试美颜效果是否正常显示
2. 注意性能问题，确保美颜处理不会导致帧率下降
3. 确保在不同设备上都能正常工作