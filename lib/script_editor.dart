import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_script/app_state.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class ScriptEditorPage extends StatefulWidget {
  const ScriptEditorPage({super.key});

  @override
  State<ScriptEditorPage> createState() => _ScriptEditorPageState();
}

class _ScriptEditorPageState extends State<ScriptEditorPage> {
  late TextEditingController _textController;
  final Map<String, Color> _colorMap = {
    '#000000': Colors.black,
    '#FFFFFF': Colors.white,
    '#FF0000': Colors.red,
    '#0000FF': Colors.blue,
    '#008000': Colors.green,
    '#800080': Colors.purple,
    '#FFA500': Colors.orange,
    '#FFC0CB': Colors.pink,
    '#008080': Colors.teal,
    '#4B0082': Colors.indigo,
  };

  final List<String> _colorCodes = [
    '#000000',
    '#FFFFFF',
    '#FF0000',
    '#0000FF',
    '#008000',
    '#800080',
    '#FFA500',
    '#FFC0CB',
    '#008080',
    '#4B0082',
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    // 首次进入页面时加载已保存的脚本内容
    _textController.text = Provider.of<AppState>(context, listen: false).scriptContent;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 新增方法：从文件系统加载脚本
  Future<void> _loadScriptFromFile() async {
    try {
      // 允许用户选择任何类型的文件，但通常脚本会是文本文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'json', 'script'], // 允许的文本文件扩展名
        allowMultiple: false, // 不允许选择多个文件
      );

      if (result != null && result.files.single.path != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          File file = File(filePath);
          String content = await file.readAsString();

          // 更新 AppState 和文本控制器
          final appState = Provider.of<AppState>(context, listen: false);
          appState.setScriptContent(content);
          _textController.text = content;

          if (mounted) {
            TDToast.showText('脚本文件已成功加载！', context: context);
          }
        }
      } else {
        // 用户取消了文件选择
        if (mounted) {
          TDToast.showText('文件选择已取消。', context: context);
        }
      }
    } catch (e) {
      // 处理文件加载错误
      print('加载文件失败: $e');
      if (mounted) {
        TDToast.showText('加载文件失败: $e', context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // 注意：这里的 _textController.text 赋值逻辑应该只在 initState 中执行一次，
    // 或者在 appState.scriptContent 真正更新时触发。
    // 在 build 方法中直接赋值会导致每次 build 都更新，可能影响性能或导致不必要的行为。
    // 更好的做法是在 appState.setScriptContent 后直接更新 _textController.text，
    // 或者依赖 Provider 的通知机制。
    // 为了简化，这里暂时保持你的原始逻辑，但建议优化。
    if (_textController.text != appState.scriptContent) {
      _textController.text = appState.scriptContent;
      // 移动光标到文本末尾，防止加载后光标在开头
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    return Scaffold(
      appBar: TDNavBar(
        title: '脚本编辑器',
        titleFontWeight: FontWeight.w600,
        screenAdaptation: true,
        useDefaultBack: false,
        rightBarItems: [
          TDNavBarItem(
            action: () {
              appState.setScriptContent(_textController.text);
              appState.saveScript();
              if (mounted) {
                TDToast.showText('脚本已保存', context: context);
              }
            },
            icon: Icons.save,
            iconSize: 24,
          ),
        ],
      ),
      body: Column(
        children: [
          // 文本样式控制区域
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '文本样式设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // 字体选择
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '字体',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TDDropdownMenu(
                            items: [
                              TDDropdownItem(
                                options: [
                                  TDDropdownItemOption(
                                    label: '默认字体', 
                                    value: 'Default',
                                    selected: appState.selectedFont == 'Default',
                                  ),
                                  TDDropdownItemOption(
                                    label: 'Serif', 
                                    value: 'serif',
                                    selected: appState.selectedFont == 'serif',
                                  ),
                                  TDDropdownItemOption(
                                    label: 'Monospace', 
                                    value: 'monospace',
                                    selected: appState.selectedFont == 'monospace',
                                  ),
                                ],
                                onChange: (value) {
                                  appState.setSelectedFont(value[0].toString());
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 文本颜色选择
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '颜色',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TDDropdownMenu(
                            items: [
                              TDDropdownItem(
                                options: _colorCodes.map((colorCode) {
                                  final color = _colorMap[colorCode]!;
                                  return TDDropdownItemOption(
                                    label: _getColorName(color),
                                    value: colorCode,
                                    selected: appState.textColor == colorCode,
                                  );
                                }).toList(),
                                onChange: (value) {
                                  // 直接使用value作为Color值
                                  if (value is List<String>) {
                                    // 如果是多选情况，取第一个值
                                    if (value.isNotEmpty) {
                                      appState.setTextColor(value[0]);
                                    }
                                  } else if (value is String) {
                                    // 如果是单选情况
                                    appState.setTextColor(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // TDButton(
                    //   text: '撤销',
                    //   icon: Icons.undo,
                    //   size: TDButtonSize.small,
                    //   type: TDButtonType.outline,
                    //   theme: TDButtonTheme.primary,
                    //   onTap: () {
                    //     // 撤销操作
                    //   },
                    // ),
                    // TDButton(
                    //   text: '重做',
                    //   icon: Icons.redo,
                    //   size: TDButtonSize.small,
                    //   type: TDButtonType.outline,
                    //   theme: TDButtonTheme.primary,
                    //   onTap: () {
                    //     // 重做操作
                    //   },
                    // ),
                    TDButton(
                      text: '加载文件',
                      icon: Icons.upload_file,
                      size: TDButtonSize.small,
                      theme: TDButtonTheme.primary,
                      onTap: () async {
                        // 调用新的文件加载方法
                        await _loadScriptFromFile();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 文本编辑区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlign: TextAlign.start,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '在此输入您的脚本内容...',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
                onChanged: (value) {
                  // 在文本更改时立即更新 AppState
                  appState.setScriptContent(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.black) return '黑色';
    if (color == Colors.white) return '白色';
    if (color == Colors.red) return '红色';
    if (color == Colors.blue) return '蓝色';
    if (color == Colors.green) return '绿色';
    if (color == Colors.purple) return '紫色';
    if (color == Colors.orange) return '橙色';
    if (color == Colors.pink) return '粉色';
    if (color == Colors.teal) return '蓝绿色';
    if (color == Colors.indigo) return '靛蓝色';
    return '其他';
  }

  String _getColorCode(Color color) {
    // 查找与给定颜色匹配的颜色代码
    for (var entry in _colorMap.entries) {
      if (entry.value.value == color.value) {
        return entry.key;
      }
    }
    // 如果没有找到匹配项，默认返回黑色
    return '#000000';
  }
}