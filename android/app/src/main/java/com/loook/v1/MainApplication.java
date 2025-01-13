package com.loook.v1;

import android.app.Application;

import com.yandex.mapkit.MapKitFactory;

public class MainApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        MapKitFactory.setApiKey("7829b061-64f7-4387-89f8-dab711940e2f"); // Your generated API key
        MapKitFactory.initialize(this);
    }
}
