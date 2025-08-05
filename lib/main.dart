import 'package:flutter/material.dart';
import 'package:video_script/app_state.dart';
import 'package:video_script/script_editor.dart';
import 'package:video_script/video_recorder.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '视频提词器',
      locale: const Locale('zh', 'CN'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [ScriptEditorPage(), VideoRecorderPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: TDBottomTabBar(
            TDBottomTabBarBasicType.iconText,
            currentIndex: _currentIndex,
            useVerticalDivider: false,
            navigationTabs: [
              TDBottomTabBarTabConfig(
                tabText: '脚本编辑',
                selectedIcon: const Icon(Icons.edit),
                unselectedIcon: const Icon(Icons.edit_outlined),
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              TDBottomTabBarTabConfig(
                tabText: '录制视频',
                selectedIcon: const Icon(Icons.videocam),
                unselectedIcon: const Icon(Icons.videocam_outlined),
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
