package com.example.apploook

import android.app.Application

import com.yandex.mapkit.MapKitFactory

class MainApplication: Application() {
  override fun onCreate() {
    super.onCreate()
    //MapKitFactory.setLocale("YOUR_LOCALE") // Your preferred language. Not required, defaults to system language
    MapKitFactory.setApiKey("6186b8eb-d3dd-4b9b-8d91-5d08156ae106") // Your generated API key
  }
}
