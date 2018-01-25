package com.example.react_native_cosser.easeui.util;


import android.app.ActivityManager;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.text.TextUtils;

import com.example.react_native_cosser.R;
import com.hyphenate.chat.EMTextMessageBody;
import com.hyphenate.chat.Message;
import com.hyphenate.helpdesk.model.MessageHelper;
import com.hyphenate.helpdesk.util.Log;
import com.hyphenate.util.PathUtil;

import java.util.List;

public class CommonUtils {
    private static final String TAG = "CommonUtils";
    /**
     * 检测网络是否可用
     *
     */
    public static boolean isNetWorkConnected(Context context) {
        if (context != null) {
            ConnectivityManager mConnectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo mNetworkInfo = mConnectivityManager != null ? mConnectivityManager.getActiveNetworkInfo() : null;
            if (mNetworkInfo != null) {
                return mNetworkInfo.isAvailable() && mNetworkInfo.isConnected();
            }
        }

        return false;
    }

    /**
     * 检测Sdcard是否存在
     *
     * @return
     */
    public static boolean isExitsSdcard() {
        return android.os.Environment.getExternalStorageState().equals(android.os.Environment.MEDIA_MOUNTED);
    }

    static String getString(Context context, int resId){
        return context.getResources().getString(resId);
    }

    public static String getThumbnailImagePath(String thumbRemoteUrl) {
        String thumbImageName= thumbRemoteUrl.substring(thumbRemoteUrl.lastIndexOf("/") + 1, thumbRemoteUrl.length());
        String path = PathUtil.getInstance().getImagePath()+"/"+ "th"+thumbImageName;
        Log.d("msg", "thum image path:" + path);
        return path;
    }
    public static String getMessageDigest(Message message, Context context) {
        String digest;
        switch (message.getType()) {
            case LOCATION: // 位置消息
                if (message.direct() == Message.Direct.RECEIVE) {
                    //从sdk中提到了ui中，使用更简单不犯错的获取string方法
//	              digest = EasyUtils.getAppResourceString(context, "location_recv");
                    digest = getString(context, R.string.location_recv);
                    digest = String.format(digest, message.from());
                    return digest;
                } else {
//	              digest = EasyUtils.getAppResourceString(context, "location_prefix");
                    digest = getString(context, R.string.location_prefix);
                }
                break;
            case IMAGE: // 图片消息
                digest = getString(context, R.string.picture);
                break;
            case VOICE:// 语音消息
                digest = getString(context, R.string.voice_prefix);
                break;
            case VIDEO: // 视频消息
                digest = getString(context, R.string.video);
                break;
            case TXT: // 文本消息
                EMTextMessageBody txtBody = (EMTextMessageBody) message.body();
                switch (MessageHelper.getMessageExtType(message)) {
                    case RobotMenuMsg:
                        digest = getString(context, R.string.robot_menu);
                        break;
                    case BigExpressionMsg:
                        if (!TextUtils.isEmpty(txtBody.getMessage())) {
                            digest = txtBody.getMessage();
                        } else {
                            digest = getString(context, R.string.dynamic_expression);
                        }
                        break;
                    default:
                        digest = txtBody.getMessage();
                        break;
                }
                break;
            case FILE: //普通文件消息
                digest = getString(context, R.string.file);
                break;
            default:
                Log.e(TAG, "error, unknow type");
                return "";
        }

        return digest;
    }


    public static boolean isSingleActivity(Context ctx) {
        ActivityManager activityManager = (ActivityManager) ctx.getSystemService(Context.ACTIVITY_SERVICE);
        List<ActivityManager.RunningTaskInfo> tasks = activityManager != null ? activityManager.getRunningTasks(1) : null;
        return tasks.get(0).numRunning == 1;
    }
}