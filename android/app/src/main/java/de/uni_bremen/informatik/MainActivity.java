package de.uni_bremen.informatik;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;


import org.puredata.android.io.PdAudio;

import java.io.IOException;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (!PdAudio.isRunning()){
            PureDataController pureDataController = new PureDataController(getApplicationContext());
            pureDataController.initPdAudio();
            pureDataController.loadAndOpenPdMainPatch();
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        MethodChannelHandler channelHandler = new MethodChannelHandler(flutterEngine);
        channelHandler.configureMethodChannel();

    }

    @Override
    protected void onPause() {
        super.onPause();
        PureDataController.applyUserPrefsWhenEnteringBackground();
    }

    @Override
    protected void onResume() {
        super.onResume();
        PureDataController.applyUserPrefsWhenEnteringForeground();
    }

}
