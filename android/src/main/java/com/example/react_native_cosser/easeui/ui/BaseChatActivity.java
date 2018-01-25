package com.example.react_native_cosser.easeui.ui;

import android.content.Intent;
import android.content.res.Configuration;
import android.os.Bundle;

import com.example.react_native_cosser.R;
import com.example.react_native_cosser.easeui.util.Config;
import com.hyphenate.chat.ChatClient;

public class BaseChatActivity extends BaseActivity {
    protected ChatFragment chatFragment = null;
    protected String toChatUsername = null;

    @Override
    protected void onCreate(Bundle arg0) {
        super.onCreate(arg0);
        setContentView(R.layout.hd_activity_chat);
        Intent intent = getIntent();
        Bundle bundle = intent.getExtras();
        //IM服务号
        assert bundle != null;
        toChatUsername = bundle.getString(Config.EXTRA_SERVICE_IM_NUMBER);
        chatFragment = new ChatFragment();
        // 传入参数
        chatFragment.setArguments(intent.getExtras());
        getSupportFragmentManager().beginTransaction().add(R.id.container, chatFragment).commit();
        ChatClient.getInstance().chatManager().bindChat(toChatUsername);
    }

    @Override
    public void onBackPressed() {
        chatFragment.onBackPressed();
        super.onBackPressed();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        // 点击notification bar进入聊天页面，保证只有一个聊天页面
        String username = intent.getStringExtra(Config.EXTRA_SERVICE_IM_NUMBER);
        if (toChatUsername.equals(username))
            super.onNewIntent(intent);
        else {
            finish();
            startActivity(intent);
        }

    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
    }
}
