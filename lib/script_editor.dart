import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_script/app_state.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // 导入 file_picker

class ScriptEditorPage extends StatefulWidget {
  const ScriptEditorPage({super.key});

  @override
  State<ScriptEditorPage> createState() => _ScriptEditorPageState();
}

class _ScriptEditorPageState extends State<ScriptEditorPage> {
  late TextEditingController _textController;
  final List<Color> _availableColors = [
    Colors.black,
    Colors.white,  // 添加白色选项
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
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

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('脚本文件已成功加载！')),
          );
        }
      } else {
        // 用户取消了文件选择
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件选择已取消。')),
        );
      }
    } catch (e) {
      // 处理文件加载错误
      print('加载文件失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载文件失败: $e')),
      );
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
      appBar: AppBar(
        title: const Text('脚本编辑器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              appState.setScriptContent(_textController.text);
              appState.saveScript(); // 假设这个方法将内容保存到本地存储
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('脚本已保存')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 文本样式控制区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 字体选择
                DropdownButton<String>(
                  value: appState.selectedFont,
                  items: const [
                    DropdownMenuItem(value: 'Default', child: Text('默认字体')),
                    DropdownMenuItem(value: 'serif', child: Text('Serif')),
                    DropdownMenuItem(value: 'monospace', child: Text('Monospace')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      appState.setSelectedFont(value);
                    }
                  },
                ),
                // 文本颜色选择
                Row(
                  children: [
                    const Text('颜色: '),
                    DropdownButton<Color>(
                      value: appState.textColor,
                      items: _availableColors.map((color) {
                        return DropdownMenuItem(
                          value: color,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: color == Colors.white
                                  ? Border.all(color: Colors.grey, width: 1)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          appState.setTextColor(value);
                        }
                      },
                    ),
                  ],
                ),
                // 操作按钮
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: () {
                        // 撤销操作：TextField 内部应该有自带的撤销/重做功能，
                        // 如果要实现更复杂的历史记录，需要额外的逻辑
                        // _textController.undo(); // 假设有这样的方法
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo),
                      onPressed: () {
                        // 重做操作
                        // _textController.redo(); // 假设有这样的方法
                      },
                    ),
                    TextButton(
                      onPressed: () async {
                        // 调用新的文件加载方法
                        await _loadScriptFromFile();
                      },
                      child: const Text('加载'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 文本编辑区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlign: TextAlign.start,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '在此输入您的脚本内容...',
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
}