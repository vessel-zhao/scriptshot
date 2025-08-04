# AppState 类文档

AppState 类是应用程序的核心状态管理类，负责管理应用的各种设置和状态。

## 属性

### 脚本相关
- `scriptContent` (String): 脚本内容
- `selectedFont` (String): 选中的字体
- `textColor` (Color): 文本颜色
- `textSize` (double): 文本大小

### 视频录制相关
- `videoResolution` (String): 视频分辨率（如 '1080P'）
- `videoAspectRatio` (String): 视频宽高比（如 '16:9'）
- `countdown` (int): 倒计时秒数

### 相机相关
- `scrollSpeed` (double): 脚本文本滚动速度

## 方法

### 脚本操作
- `setScriptContent(String content)`: 设置脚本内容
- `saveScript()`: 保存脚本到文件
- `loadScript()`: 从文件加载脚本

### 字体和文本设置
- `setSelectedFont(String font)`: 设置字体
- `setTextColor(Color color)`: 设置文本颜色
- `setTextSize(double size)`: 设置文本大小
- `increaseTextSize()`: 增加文本大小
- `decreaseTextSize()`: 减小文本大小

### 视频设置
- `setVideoResolution(String resolution)`: 设置视频分辨率
- `setVideoAspectRatio(String aspectRatio)`: 设置视频宽高比
- `setCountdown(int seconds)`: 设置倒计时秒数

### 相机控制
- `setScrollSpeed(double speed)`: 设置滚动速度
- `increaseScrollSpeed()`: 增加滚动速度
- `decreaseScrollSpeed()`: 减小滚动速度

## 使用示例

```dart
// 获取 AppState 实例
final appState = Provider.of<AppState>(context);

// 读取属性
String content = appState.scriptContent;
String font = appState.selectedFont;
Color color = appState.textColor;

// 调用方法
appState.setScriptContent("新脚本内容");
appState.setSelectedFont("Arial");
appState.setTextColor(Colors.blue);
```

## 通知机制

AppState 继承自 ChangeNotifier，当状态发生变化时会自动通知监听器。UI 组件可以通过 Provider.of<AppState>(context) 或 Consumer<AppState> 来监听状态变化。