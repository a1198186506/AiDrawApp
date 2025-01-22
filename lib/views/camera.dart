import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:aibot1/components/PicViewDrawer.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraPage({super.key, required this.camera});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraController _controller;
  ScrollController _scrollController = ScrollController();
  late Future<void> _initializeControllerFuture;
  bool _isTakingPicture = false;
  String? _imagePath;
  List<String> _imageList = [];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 当应用恢复时,重新初始化相机
      initializeCamera();
    } else if (state == AppLifecycleState.inactive) {
      // 当应用不活跃时,释放相机资源
      dispose();
    }
  }

  Future<PermissionStatus> requestPermission() async {
    PermissionStatus status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status;
  }

  Future<void> initializeCamera() async {
    // 请求权限
    PermissionStatus status = await requestPermission();
    if (status.isGranted) {
      // 如果权限请求成功,则初始化相机控制器
      _controller = CameraController(
        widget.camera, // 相机描述
        ResolutionPreset.high, // 分辨率
      );
      try {
        _initializeControllerFuture = _controller.initialize();
      } catch (e) {
        print('Error initializing camera: $e');
        // 初始化失败时的错误处理
      }
    } else {
      // 如果权限请求失败,给出提示或进行错误处理
      print('Camera permission denied');
      // ...
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _controller = CameraController(
      widget.camera, // 相机描述
      ResolutionPreset.high, // 分辨率
    );

    _initializeControllerFuture = _controller.initialize(); // 初始化相机

    requestPermission();
  }

  // 切换摄像头
  Future<void> _switchCamera() async {
    // 获取当前摄像头的镜头方向
    final currentLensDirection = _controller.description.lensDirection;

    // 获取可用的摄像头列表
    final cameras = await availableCameras();

    // 找到与当前镜头方向相反的摄像头
    final newCamera = cameras.firstWhere(
      (camera) => camera.lensDirection != currentLensDirection,
      orElse: () => cameras.first,
    );

    // 重新创建 CameraController
    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
    );

    // 初始化新的 CameraController
    _initializeControllerFuture = _controller.initialize();

    // 刷新界面
    setState(() {});
  }

  // 从相册中选择图片
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _imagePath = pickedImage.path;
        printGreen('pickedImage.path: ${pickedImage.path}');
        _imageList.add(pickedImage.path);
      });

      // 列表滚动到最右边
      if (_scrollController.hasClients) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToRight();
          });
        });
      }
    }
  }

  // 拍照并保存图片
  Future<void> _takePicture() async {
    if (_controller.value.isTakingPicture) {
      return; // 如果已经在拍照，避免重复操作
    }
    setState(() {
      _isTakingPicture = true;
    });

    try {
      // 等待相机初始化完成
      await _initializeControllerFuture;
      XFile file = await _controller.takePicture();
      print('takePicture2');

      // 获取保存路径，例如应用的文档目录
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('imagePath: $imagePath');
      // 将拍摄的图片保存到指定路径
      await file.saveTo(imagePath);
      print('takePicture3');

      setState(() {
        _isTakingPicture = false;
        _imagePath = imagePath;
        _imageList.add(imagePath);
      });
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
      });
      print('Error taking picture: $e');
    }

    //列表滚动到最右边
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToRight();
      });
    });
  }

  void printGreen(String text) {
    print('\x1B[32m$text\x1B[0m');
  }

  // 滚动到最右边
  void _scrollToRight() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // 释放相机资源
    _scrollController.dispose(); // 释放滚动控制器资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                // 显示相机画面
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 500,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: CameraPreview(_controller),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 显示拍照按钮

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(
                          width: 70,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _switchCamera,
                            child: Image.asset('assets/images/refresh.png', width: 50, height: 50),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 242, 116, 37),
                            ),
                          ),
                        ),
                        Container(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isTakingPicture ? null : _takePicture,
                            child: Text('拍照', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 242, 116, 37),
                            ),
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _pickImageFromGallery,
                            child: Image.asset('assets/images/add-picture.png', width: 50, height: 50),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 242, 116, 37),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // 显示拍照后的图片
                if (_imagePath != null)
                  Container(
                    height: 140.0,
                    width: MediaQuery.of(context).size.width,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      controller: _scrollController,
                      itemCount: _imageList.length,
                      padding: EdgeInsets.only(left: 10),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: GestureDetector(
                            onTap: () {
                              print('Image tapped: ${_imageList[index]}');
                              setState(() {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => PicViewDrawer(imagePath: _imageList[index]),
                                  );
                                });
                              });
                            },
                            child: Image.file(
                              File(_imageList[index]),
                              fit: BoxFit.contain,
                              height: 140.0,
                            ),
                          ),
                        );
                      },
                    ),
                  )
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
