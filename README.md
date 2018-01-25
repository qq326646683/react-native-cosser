环信客服功能集成
## 1.INSTALL
1.npm install react-native-cosser --save
2.setting.gradle添加:

	include ':react-native-cosser'
    project(':react-native-cosser').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-cosser/android')
    
3.app/build.gradle添加:

	compile project(':react-native-cosser')
	
4.MainApplication.java添加：

    getPackages() {
        ...
	    new CosSerPackage()
	}

	onCreate(){
	    ...
    	//初始化客服功能
         ChatClient.getInstance().init(this, new ChatClient.Options().setAppkey("1429180122061804#kefuchannelapp52167").setTenantId("52167"));
        // Kefu EaseUI的初始化
        UIProvider.getInstance().init(this);

	}
	
5.替换key：

    serviceId：
        需要替换掉CosSerModule.java 中 27行serviceId：获取地址：kefu.easemob.com，“管理员模式 > 渠道管理 > 手机APP”页面的关联的“IM服务号”
        
    appkey：
        kefu.easemob.com，“管理员模式 > 渠道管理 > 手机APP”页面的关联的“AppKey”
        
    tenantId：
        kefu.easemob.com，“管理员模式 > 设置 > 企业信息”页面的“租户ID”
        
        
## 2.API
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
    
