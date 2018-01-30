package com.example.react_native_cosser;

import android.content.Intent;
import android.util.Log;

import com.example.react_native_cosser.easeui.util.IntentBuilder;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.hyphenate.chat.ChatClient;
import com.hyphenate.chat.ChatManager;
import com.hyphenate.chat.Conversation;
import com.hyphenate.chat.Message;
import com.hyphenate.helpdesk.callback.Callback;
import com.hyphenate.helpdesk.model.ContentFactory;

import java.util.List;

/**
 * Created by nell on 2018/1/23.
 */

public class CosSerModule extends ReactContextBaseJavaModule {
    public static final String CLASS_NAME = "CosSerModule";
    private ReactApplicationContext mContext;
    private String serviceId = "kefuchannelimid_934879";

    public CosSerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        mContext = reactContext;
        Log.i(CLASS_NAME, "构造");

    }

    @Override
    public String getName() {
        return CLASS_NAME;
    }

    /**
     * @param username 给用户注册，登陆用
     */
    @ReactMethod
    public void setUp(String username) {
        Log.i(CLASS_NAME, username);

        if (username == "" || username == null) {
            return;
        }

        register(username);
        listener();
    }

    /**
     * @param cosserEmail 客服邮箱
     */
    @ReactMethod()
    public void gotoChat(String cosserEmail) {
        Log.i(CLASS_NAME, cosserEmail);


        if (ChatClient.getInstance().isLoggedInBefore()) {
            if(cosserEmail == null || "".equals(cosserEmail)){
                Intent intent = new IntentBuilder(mContext)
                        .setServiceIMNumber(serviceId) //获取地址：kefu.easemob.com，“管理员模式 > 渠道管理 > 手机APP”页面的关联的“IM服务号”
                        .build();
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                mContext.startActivity(intent);
            }else {
                Intent intent = new IntentBuilder(mContext)
                        .setServiceIMNumber(serviceId) //获取地址：kefu.easemob.com，“管理员模式 > 渠道管理 > 手机APP”页面的关联的“IM服务号”
                        .setScheduleAgent(ContentFactory.createAgentIdentityInfo(cosserEmail))
                        .build();
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                mContext.startActivity(intent);
            }

        } else {
            //未登录，需要登录后，再进入会话界面
            mContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onError", "未登陆");
        }
    }

    @ReactMethod
    public void logout(final com.facebook.react.bridge.Callback callback) {
        ChatClient.getInstance().logout(true, new Callback() {
            @Override
            public void onSuccess() {
                callback.invoke(true);
            }

            @Override
            public void onError(int i, String s) {
                callback.invoke(false);
            }

            @Override
            public void onProgress(int i, String s) {

            }
        });
    }

    private void register(final String username) {
        ChatClient.getInstance().register(username, "password", new Callback() {
            @Override
            public void onSuccess() {
                login(username);
            }

            @Override
            public void onError(int i, String s) {
                if (s.equals("user already exist")) {
                    Log.i(CLASS_NAME, "用户已存在");
                    login(username);
                } else {
                    Log.i(CLASS_NAME, "error" + i + s);
                    mContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onError", i + s);
                }
            }

            @Override
            public void onProgress(int i, String s) {

            }
        });

    }

    private void login(String username) {
        Log.i(CLASS_NAME,"登陆的id:"+ username);
        ChatClient.getInstance().login(username, "password", new Callback() {
            @Override
            public void onSuccess() {
                Log.i(CLASS_NAME, "登陆成功");
                mContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("loginState", true);
            }

            @Override
            public void onError(int i, String s) {
                if(s.equals("User is already login")){
                    Log.i(CLASS_NAME, "登陆成功");
                    mContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("loginState", true);
                }else {
                    Log.i(CLASS_NAME, "登陆失败" +i+ s);
                    mContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("loginState", false);
                }

            }

            @Override
            public void onProgress(int i, String s) {
                Log.i(CLASS_NAME, "登陆中" + s);

            }
        });

    }

    private void listener() {
        ChatClient.getInstance().getChat().addMessageListener(new ChatManager.MessageListener() {
            @Override
            public void onMessage(List<Message> list) {
                //收到普通消息
                Conversation conversation = ChatClient.getInstance().chatManager().getConversation(serviceId);
                int count = conversation.unreadMessagesCount();
                Log.i(CLASS_NAME, count + "个");
                mContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("unreadCount", count);

            }

            @Override
            public void onCmdMessage(List<Message> list) {
                //收到命令消息，命令消息不存数据库，一般用来作为系统通知，例如留言评论更新，
                //会话被客服接入，被转接，被关闭提醒
            }

            @Override
            public void onMessageStatusUpdate() {
                //消息的状态修改，一般可以用来刷新列表，显示最新的状态
            }

            @Override
            public void onMessageSent() {
                //发送消息后，会调用，可以在此刷新列表，显示最新的消息
            }
        });

    }

}
