### Ai相机(flutter)

#### 技术栈 flutter + nodejs

### 应用部分截图
![](https://cdn-app-screenshot.pgyer.com/d/3/0/7/4/d30746bc0a168b15e1eb6f20bc11929c?x-oss-process=image/resize,m_lfit,h_528,w_528/format,jpg)

![](https://cdn-app-screenshot.pgyer.com/5/5/0/2/d/5502d753e44f658ceeaf8895e9686939?x-oss-process=image/resize,m_lfit,h_528,w_528/format,jpg)

#### 效果：
![](https://pic1.imgdb.cn/item/67828b69d0e0a243d4f37683.jpg)

### 填入服务器地址（PicViewDrawer.dart 661行）
    var url = Uri.parse('your own server url（你自己的后端服务器）');
        var body = {
          'imagebase64': base64Image,
          'uploadtype': drawtype,
          'modeltype': modeltype,
          'prompt': promptSwitch ? prompt_str : '',
        };
		
##后端在分支serve里

### 修改后端key以及代理地址(index.js 7行)
    const aikey = ""; //你的openai key
    const mjkey = ""; //你的midjourney key
    const host = ""; //你的代理地址(国内)


