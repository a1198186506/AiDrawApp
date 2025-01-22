import 'package:flutter/material.dart';
import './views/camera.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras(); // 获取可用的相机
  final firstCamera = cameras.first; // 选择第一个相机（通常是后置摄像头）
  runApp(MainApp(camera: firstCamera)); // 传入选定的相机
}

class MainApp extends StatelessWidget {
  final CameraDescription camera;
  const MainApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    // 让状态栏隐藏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return MaterialApp(
      title: '相机应用',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CameraPage(camera: camera), // 进入相机页面
    );
  }
}
