import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

//图片预览弹窗组件
class PicViewDrawer extends StatefulWidget {
  final String imagePath;

  const PicViewDrawer({super.key, required this.imagePath});

  @override
  State<PicViewDrawer> createState() => _PicViewDrawerState(imagePath);
}

class _PicViewDrawerState extends State<PicViewDrawer> {
  _PicViewDrawerState(this.RawImagePath);

  final TDInputcontroller = [TextEditingController(), TextEditingController(), TextEditingController()];

  String RawImagePath = '';
  String NowImagePath = '';

  //自定义提示词(prompt)开关
  bool promptSwitch = false;

  //风格选项
  List<Map<String, dynamic>> styleOptions = [
    {
      'name': 'Q版画风',
      'icon': 'assets/images/candy.png',
      'background': Color.fromARGB(206, 62, 62, 62),
      'example': 'https://pic1.imgdb.cn/item/67828b69d0e0a243d4f37683.jpg',
    },
    {
      'name': '美漫风格',
      'icon': 'assets/images/chessman.png',
      'background': Color.fromARGB(206, 62, 62, 62),
      'example': 'https://pic1.imgdb.cn/item/67828df0d0e0a243d4f376f2.jpg',
    },
    {
      'name': '赛博朋克',
      'icon': 'assets/images/robot.png',
      'background': Color.fromARGB(206, 62, 62, 62),
      'example': 'https://pic1.imgdb.cn/item/67835b68d0e0a243d4f39394.jpg',
    },
  ];

  //模型选项
  List<Map<String, dynamic>> modelOptions = [
    {
      'name': 'flux',
      'background': Color.fromARGB(206, 62, 62, 62),
      'icon': 'assets/images/flux.svg',
    },
    {
      'name': 'Mid journey',
      'background': Color.fromARGB(206, 62, 62, 62),
      'icon': 'assets/images/mj.svg',
    },
  ];

  //生成的图片
  List<String> generatedImages = [
    // "https://img1.baidu.com/it/u=2693733305,4035903587&fm=253&fmt=auto&app=138&f=JPEG?w=800&h=1200",
    // "http://img1.baidu.com/it/u=1199547783,1110108782&fm=253&app=138&f=JPEG?w=800&h=1200",
  ];

  //点击展示
  late OverlayEntry overlayEntry;
  late OverlayState overlay;
  late String drawtype;
  late String modeltype;

  //自定义提示词(prompt)
  String prompt_str = '';

  //风格选项点击事件
  void styleOptionClick(int index) {
    setState(() {
      for (var i = 0; i < styleOptions.length; i++) {
        if (i == index) {
          styleOptions[i]['background'] = Color.fromARGB(255, 242, 116, 37);
        } else {
          styleOptions[i]['background'] = Color.fromARGB(206, 62, 62, 62);
        }
      }

      if (index == 0) {
        drawtype = 'BubbleMattStyle';
      } else if (index == 1) {
        drawtype = 'CartoonStyle';
      } else if (index == 2) {
        drawtype = 'CyberpunkStyle';
      }
    });
  }

  //模型选择
  void modelOptionClick(int index) {
    setState(() {
      for (var i = 0; i < modelOptions.length; i++) {
        if (i == index) {
          modelOptions[i]['background'] = Color.fromARGB(255, 242, 116, 37);
        } else {
          modelOptions[i]['background'] = Color.fromARGB(206, 62, 62, 62);
        }
      }

      if (index == 0) {
        modeltype = 'flux';
      } else {
        modeltype = 'midjourney';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity, // 让宽度填充整个屏幕
        height: double.infinity, // 让高度填充整个屏幕
        color: Colors.black, // 半透明背景
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      // 在 setState 的回调中执行关闭弹窗操作
                      showDialog(
                        context: context,
                        builder: (context) => _buildBackDialog(),
                      );
                    },
                    icon: Icon(Icons.arrow_back),
                    color: Colors.white,
                    iconSize: 30,
                  ),
                  Text(
                    '返回',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 130),
                  ElevatedButton(
                    onPressed: () {
                      _saveImageToGallery();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 242, 116, 37),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        Text('保存图片', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              //图片预览
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildUpScaleDialog(NowImagePath),
                    barrierColor: Colors.black.withOpacity(0.9),
                  );
                },
                child: _buildPreviewImage(NowImagePath),
              ),
              SizedBox(height: 20),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      //标题
                      Row(
                        children: [
                          SizedBox(width: 10),
                          Text('原图', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(width: 50),
                          if (generatedImages.length > 0)
                            Text('绘制图片', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 5),
                      //图片预览图
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 10),
                          //原图
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 50,
                              height: 50,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    NowImagePath = RawImagePath;
                                  });
                                },
                                child: Image.file(File(RawImagePath), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          //生成的图片
                          SizedBox(width: 10),
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width - 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true, // 让 ListView 的高度不依赖于其他视图
                              itemCount: generatedImages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(left: index == 0 ? 10 : 0, right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      print('generatedImages[index]: ${generatedImages[index]}');
                                      setState(() {
                                        NowImagePath = generatedImages[index];
                                      });
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        generatedImages[index],
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      //绘制风格
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text('绘制风格',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left),
                        ),
                      ),
                      SizedBox(height: 13),

                      Container(
                        //绘画风格选择
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: styleOptions.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                print('styleOptionClick: $index');
                                styleOptionClick(index);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: styleOptions[index]['background'],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(styleOptions[index]['icon'], width: 40, height: 40),
                                          Text(styleOptions[index]['name'], style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    //查看示例
                                    GestureDetector(
                                      onTap: () {
                                        showExampleDialog(index);
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 80,
                                          height: 25,
                                          color: const Color.fromARGB(255, 176, 176, 176),
                                          child: Center(
                                            child: Text('查看示例', style: TextStyle(color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      //自定义提示词(prompt)
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text('自定义提示词(开启后上面的绘制风格选项无效)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left),
                        ),
                      ),
                      SizedBox(height: 13),
                      Row(
                        children: [
                          SizedBox(width: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 80,
                              color: const Color.fromARGB(255, 167, 167, 167),
                              child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('提示词是否打开：',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.left),
                                        SizedBox(width: 10),
                                        TDSwitch(
                                          onChanged: (value) {
                                            setState(() {
                                              promptSwitch = value;
                                              if (promptSwitch) {
                                                showGeneralDialog(
                                                  context: context,
                                                  pageBuilder: (BuildContext buildContext, Animation<double> animation,
                                                      Animation<double> secondaryAnimation) {
                                                    return Padding(
                                                      padding: EdgeInsets.only(bottom: 140),
                                                      child: TDInputDialog(
                                                        textEditingController: TDInputcontroller[0],
                                                        title: '请输入自定义提示词',
                                                        hintText: '例如:3d,卡通,可爱,Q版',
                                                        content: prompt_str,
                                                        leftBtn: TDDialogButtonOptions(
                                                          title: '取消',
                                                          action: () {
                                                            Navigator.of(context).pop();
                                                            if (TDInputcontroller[0].text.isEmpty) {
                                                              setState(() {
                                                                promptSwitch = false;
                                                              });
                                                            } else {
                                                              setState(() {
                                                                prompt_str = TDInputcontroller[0].text;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                        rightBtn: TDDialogButtonOptions(
                                                          title: '确定',
                                                          action: () {
                                                            Navigator.of(context).pop();
                                                            if (TDInputcontroller[0].text.isEmpty) {
                                                              setState(() {
                                                                promptSwitch = false;
                                                              });
                                                            } else {
                                                              setState(() {
                                                                prompt_str = TDInputcontroller[0].text;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                              print('promptSwitch: $promptSwitch');
                                            });
                                            return value;
                                          },
                                          isOn: promptSwitch,
                                          size: TDSwitchSize.large,
                                          trackOnColor: Colors.orange,
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    if (prompt_str.isNotEmpty)
                                      Container(
                                          width: MediaQuery.of(context).size.width - 80,
                                          child: Text(prompt_str, style: TextStyle(color: Colors.white))),
                                    SizedBox(height: 10),
                                  ])),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      //模型选择
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text('模型选择', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: modelOptions.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                print('modelOptionClick: $index');
                                modelOptionClick(index);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Container(
                                  width: 80,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: modelOptions[index]['background'],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(modelOptions[index]['icon'], width: 30, height: 30),
                                      Text(modelOptions[index]['name'],
                                          style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              //绘制按钮
              Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildWaitingDialog("绘制中..."),
                      barrierDismissible: false,
                    );
                    drawImage();
                  },
                  child: Text('绘制', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 242, 116, 37),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //图片预览组件
  Widget _buildPreviewImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // 网络图片
      return FadeInImage(
        placeholder: AssetImage('assets/images/photo_waitting.gif'), // 占位图片
        image: NetworkImage(imagePath),
        height: 300,
        fit: BoxFit.fitHeight,
      );
    } else if (imagePath.startsWith('assets/')) {
      // 资源图片
      return Image.asset(imagePath, height: 300, fit: BoxFit.fitHeight);
    } else {
      // 本地文件图片
      return Image.file(File(imagePath), height: 300, fit: BoxFit.fitHeight);
    }
  }

  //点击返回时提示弹窗
  Widget _buildBackDialog() {
    return AlertDialog(
      title: Text('提示'),
      content: Text('确定要返回吗？没保存的话会丢失掉生成图片的哦'),
      actions: [
        TextButton(
            onPressed: () => {Navigator.of(context).pop()}, child: Text('取消', style: TextStyle(color: Colors.grey))),
        TextButton(
            onPressed: () => {Navigator.of(context).pop(), Navigator.of(context).pop()},
            child: Text('确定', style: TextStyle(color: Colors.orange))),
      ],
    );
  }

  //等待弹窗组件 转圈
  Widget _buildWaitingDialog(String text) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 100,
          height: 100,
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 10),
              Text(text, style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // 保存图片到本地相册
  Future<void> _saveImageToGallery() async {
    showDialog(
      context: context,
      builder: (context) => _buildWaitingDialog("保存中..."),
      barrierDismissible: false,
    );
    if (NowImagePath.startsWith('http://') || NowImagePath.startsWith('https://')) {
      // 远程图片
      final response = await http.get(Uri.parse(NowImagePath));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/temp_image.jpg').writeAsBytes(bytes);
      final result = await GallerySaver.saveImage(file.path, albumName: 'ai画廊');
      if (result != null && result) {
        Navigator.of(context).pop();
        TDToast.showSuccess('已保存到相册', direction: IconTextDirection.vertical, context: context);
      } else {
        Navigator.of(context).pop();
        TDToast.showFail('保存图片失败', direction: IconTextDirection.vertical, context: context);
      }
    } else {
      // 本地图片
      final result = await GallerySaver.saveImage(NowImagePath, albumName: 'ai画廊');
      if (result != null && result) {
        TDToast.showSuccess('已保存到相册', direction: IconTextDirection.vertical, context: context);
      } else {
        TDToast.showFail('保存图片失败', direction: IconTextDirection.vertical, context: context);
      }
    }
  }

  //读取本地图片文件转换成base64的形式
  Future<String> readImageFromFile(String filePath) async {
    var file = File(filePath);

    if (await file.exists()) {
      // 读取文件内容并将其转换为字节数据
      List<int> bytes = await file.readAsBytes();
      // 将字节数据转换为 Base64 编码的字符串
      return base64Encode(bytes);
    } else {
      throw Exception('File does not exist');
    }
  }

  //上传图片到服务器
  Future<Map<String, dynamic>> uploadImage(String base64Image) async {
    var url = Uri.parse('your own server url（你自己的后端服务器）');
    var body = {
      'imagebase64': base64Image,
      'uploadtype': drawtype,
      'modeltype': modeltype,
      'prompt': promptSwitch ? prompt_str : '',
    };

    // 创建一个 Client 实例
    var client = http.Client();

    try {
      // 设置请求的超时时间,例如 200 秒
      var response = await client
          .post(
            url,
            body: body,
          )
          .timeout(Duration(seconds: 500));

      if (response.statusCode == 200) {
        print('Image uploaded successfully');

        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        print('Failed to upload image: ${response.statusCode}');
        print('response.body: ${response.body}');
        return {'url': '', 'state': 'error101'};
      }
    } catch (e) {
      print('Error: $e');
      return {'url': '', 'state': 'error102'};
    } finally {
      // 关闭 Client 实例
      client.close();
    }
  }

  //绘制图片
  Future<void> drawImage() async {
    var base64Image = await readImageFromFile(RawImagePath);
    try {
      var response = await uploadImage(base64Image);
      print('response: ${response}');
      if (response['state'] == 'success') {
        generatedImages.addAll(response['url'].whereType<String>());
        setState(() {
          NowImagePath = response['url'][0];
        });
        Navigator.of(context).pop();
        TDToast.showSuccess('绘制成功', direction: IconTextDirection.vertical, context: context);
      } else {
        Navigator.of(context).pop();
        TDToast.showFail('绘制失败', direction: IconTextDirection.vertical, context: context);
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (e is TimeoutException) {
        TDToast.showFail('请求超时,请检查网络连接', direction: IconTextDirection.vertical, context: context);
      } else {
        print('e: $e');
        TDToast.showFail('绘制失败2', direction: IconTextDirection.vertical, context: context);
      }
    }
  }

  //图片放大弹窗
  Widget _buildUpScaleDialog(String imgurl) {
    return Center(
      child: Container(
        height: 400,
        color: Colors.black,
        child: _buildPreviewImage(imgurl),
      ),
    );
  }

  //查看示例点击事件
  void showExampleDialog(int index) {
    String img_str = styleOptions[index]['example'];

    showDialog(
      context: context,
      builder: (context) => _buildUpScaleDialog(img_str),
      barrierColor: Colors.black.withOpacity(0.9),
    );
  }

  @override
  void initState() {
    super.initState();
    NowImagePath = RawImagePath;
    styleOptionClick(0);
    modelOptionClick(0);
  }

  @override
  void dispose() {
    overlayEntry.remove();
    super.dispose();
  }
}
