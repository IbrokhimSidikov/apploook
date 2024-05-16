import android.app.Application;

import com.yandex.mapkit.MapKitFactory;

public class MainApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        // MapKitFactory.setLocale("YOUR_LOCALE"); // Your preferred language. Not required, defaults to system language
        MapKitFactory.setApiKey("824c3368-3c70-4276-9fd0-9f1497d12298"); // Your generated API key
    }
}