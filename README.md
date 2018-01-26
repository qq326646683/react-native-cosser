## 1.INSTALL
根目录下运行：

    npm install react-native-cosser --save

    react-native link react-native-cosser 

#### Android:
    
1.MainApplication.java添加：

    import com.example.react_native_cosser.easeui.UIProvider;
    import com.hyphenate.chat.ChatClient;

    onCreate(){
        ...
        //初始化客服功能
        ChatClient.getInstance().init(this, new ChatClient.Options().setAppkey("1429180122061804#kefuchannelapp52167").setTenantId("52167"));
        // Kefu EaseUI的初始化
        UIProvider.getInstance().init(this);

    }
    
2.替换key：

    serviceId：
        需要替换掉CosSerModule.java 中 27行serviceId：获取地址：kefu.easemob.com，“管理员模式 > 渠道管理 > 手机APP”页面的关联的“IM服务号”
        
    appkey：
        kefu.easemob.com，“管理员模式 > 渠道管理 > 手机APP”页面的关联的“AppKey”
        
    tenantId：
        kefu.easemob.com，“管理员模式 > 设置 > 企业信息”页面的“租户ID”
        
#### Ios:
1.在 iOS 工程 target 的 Build Phases->Link Binary with Libraries 中加入如下库：

    libz
    libc++
    libsqlite3.0
    libstdc++.6.0.9
2.该bundle文件放到ios主工程下

    http://7xt3sl.com2.z0.glb.qiniucdn.com/Root%202.bundle.zip

      
## 2.API（android）
##### 1.初始化
在componentDidMount()中添加：

    import CosSerModule from 'react-native-cosser'

    参数为设备的唯一标识
    CosSerModule.setUp(DeviceInfo.getUniqueID())
    
##### 2.注册登陆状态监听：
    DeviceEventEmitter.addListener('loginState', (state) => {
                this.setState({
                    isLogin:state
                })
            })
##### 3.注册未读消息数监听：
    DeviceEventEmitter.addListener('unreadCount', (count) => {
            this.setState({
                unreadCount:count
            })
        })
##### 4.注册错误监听：
    DeviceEventEmitter.addListener('onError', (error) => {
            alert(error)
        })
##### 5.事件-跳转到聊天页面：
    gotoChat = () => {
        if(this.state.isLogin){
            this.setState({unreadCount:0})
            //默认客服
            CosSerModule.gotoChat('')
            //指定客服
            // CosSerModule.gotoChat("326646683@qq.com")
        }else {
            alert('未登陆，登陆失败')
        }

    }
##### 6.事件-注销：
    CosSerModule.logout(result => {
            alert(result)
            if(result == true){
                this.setState({isLogin:false})
            }
        });
    
