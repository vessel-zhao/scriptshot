# PixelFree 美颜SDK集成说明## 实现原理

### 实时美颜预览
1. 通过`startImageStream`监听相机帧数据
2. 使用`processWithImage`方法处理每一帧图像
3. 将处理后的纹理显示在预览界面中

### 录制带美颜效果的视频
1. 相机预览已经是美颜处理后的效果
2. 使用camera插件录制当前预览画面
3. 录制的视频自然包含美颜效果

## 已实现功能

1. 美颜参数控制面板（通过底部弹出方式）
2. 大眼效果调节
3. 瘦脸效果调节
4. 美白效果调节
5. 磨皮效果调节
6. 美颜参数重置功能
7. 实时美颜预览效果
8. 录制带美颜效果的视频

## 美颜功能列表

PixelFree SDK支持丰富的美颜功能：

- 大眼（eyeStrength）
- 瘦脸（faceThinning）
- 窄脸（faceNarrow）
- 下巴调节（faceChin）
- V脸（faceV）
- 小脸（faceSmall）
- 鼻子调节（faceNose）
- 额头调节（faceForehead）
- 嘴巴调节（faceMouth）
- 人中调节（facePhiltrum）
- 长鼻调节（faceLongNose）
- 眼距调节（faceEyeSpace）
- 微笑嘴角（faceSmile）
- 旋转眼睛（faceEyeRotate）
- 开眼角（faceCanthus）
- 磨皮（faceBlurStrength）
- 美白（faceWhitenStrength）
- 红润（faceRuddyStrength）
- 锐化（faceSharpenStrength）
- 新美白算法（faceNewWhitenStrength）
- 画质增强（faceQualityStrength）
- 亮眼（faceEyeBrighten）
- 滤镜名称（filterName）
- 滤镜强度（filterStrength）
- 绿幕（lvmu）
- 2D贴纸（sticker2DFilter）
- 一键美颜（typeOneKey）
- 水印（watermark）
- 扩展（extend）

## 当前实现的美颜功能

在当前实现中，我们集成了以下基础美颜功能：

1. 大眼效果：通过`PFBeautyFiterType.eyeStrength`控制
2. 瘦脸效果：通过`PFBeautyFiterType.faceThinning`控制
3. 美白效果：通过`PFBeautyFiterType.faceWhitenStrength`控制
4. 磨皮效果：通过`PFBeautyFiterType.faceBlurStrength`控制
5. 实时美颜预览：通过处理相机帧数据实现实时美颜效果
6. 录制美颜视频：录制的视频将包含美颜效果

## 使用方法

1. 点击AppBar上的脸部图标按钮打开美颜设置面板
2. 通过滑动条调节各项美颜参数
3. 点击"关闭"按钮保存设置并关闭面板
4. 点击刷新按钮重置所有美颜参数
5. 美颜效果将实时显示在相机预览中
6. 录制的视频将包含美颜效果

## 待完善功能

1. 添加更多美颜效果（如窄脸、V脸、下巴调节等）
2. 添加滤镜功能
3. 添加贴纸功能
4. 添加一键美颜功能
5. 集成License文件以完整启用SDK功能

## API使用说明

### 初始化
```dart
_pixelfree = Pixelfree();
// 需要license文件才能完整使用
// await _pixelfree.createWithLic('path/to/license.lic');
```

### 设置美颜参数
```dart
// 设置大眼效果 (范围 0.0~1.0)
await _pixelfree.pixelFreeSetBeautyFilterParam(PFBeautyFiterType.eyeStrength, value);

// 设置瘦脸效果 (范围 0.0~1.0)
await _pixelfree.pixelFreeSetBeautyFilterParam(PFBeautyFiterType.faceThinning, value);

// 设置美白效果 (范围 0.0~1.0)
await _pixelfree.pixelFreeSetBeautyFilterParam(PFBeautyFiterType.faceWhitenStrength, value);

// 设置磨皮效果 (范围 0.0~1.0)
await _pixelfree.pixelFreeSetBeautyFilterParam(PFBeautyFiterType.faceBlurStrength, value);
```

### 图像处理
```dart
// 处理图像并获取纹理ID
final textureId = await _pixelfree.processWithImage(
  imageData,  // Uint8List格式的图像数据
  width,      // 图像宽度
  height,     // 图像高度
);
```

### 其他功能API

```dart
// 设置一键美颜
await _pixelfree.pixelFreeSetBeautyTypeParam(PFBeautyFiterType.typeOneKey, 1);

// 色彩调节
final params = PFImageColorGrading(
  isUse: true,
  brightness: 0.1,
  contrast: 1.2,
  exposure: 0.5,
  highlights: 0.3,
  shadows: 0.2,
  saturation: 1.1,
  temperature: 5500.0,
  tint: 0.1,
  hue: 180.0,
);

final result = await _pixelfree.pixelFreeSetColorGrading(params);

// HLS滤镜
final hlsParams = PFHLSFilterParams(
  keyColor: [1.0, 0.0, 0.0],
  hue: 0.0,
  saturation: 1.0,
  brightness: 0.0,
  similarity: 0.0,
);

final handle = await _pixelfree.pixelFreeAddHLSFilter(hlsParams);
```

## 注意事项

1. 需要集成有效的License文件才能完整使用所有功能
2. 所有美颜参数范围均为0.0~1.0
3. 图像数据格式可能需要根据平台进行适配（Android/iOS）
4. 性能优化需要注意，避免美颜处理影响帧率
5. 大部分API调用都是异步的，需要使用await关键字
6. 美颜处理会增加CPU/GPU负载，注意性能监控