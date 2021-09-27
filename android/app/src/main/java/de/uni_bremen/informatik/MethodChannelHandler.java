package de.uni_bremen.informatik;


import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Created by Fida on 22.01.21.
 */
public class MethodChannelHandler {
    private FlutterEngine flutterEngine;

    public MethodChannelHandler(FlutterEngine flutterEngine) {
        if (flutterEngine == null) {
            throw new RuntimeException("FlutterEngine not initialized properly");
        }
        this.flutterEngine = flutterEngine;
    }

    public void configureMethodChannel() {
        MethodChannel channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), Configs.CHANNEL);

        channel.setMethodCallHandler((call, result) -> {
            if (ChannelMethods.START_STOP_AUDIO.equals(call.method)) {
                toggleAudio(call);
            }
            if (ChannelMethods.INPUT_VALUE_X.equals(call.method)) {
                sendValueXToLibPd(call);
            }
            if (ChannelMethods.INPUT_VALUE_Y.equals(call.method)) {
                sendValueYToLibPd(call);
            }
            if (ChannelMethods.START_AUDIO_ON_BOOT.equals(call.method)) {
                applyUserPrefsAfterUIRendered(call);
            }
            if (ChannelMethods.PLAY_IN_BACKGROUND.equals(call.method)) {
                playInBackground(call);
            }
            if (ChannelMethods.PINK_NOISE_RANGE.equals(call.method)) {
                setPinkNoiseSensitivityRange(call);
            }
        });
    }

    private void setPinkNoiseSensitivityRange(MethodCall call) {
        String range = call.argument(ChannelMethods.PINK_NOISE_RANGE.getParam1());
        UserPreferences.setPinkNoiseSensitivityRange(Float.parseFloat(range));
    }

    private void toggleAudio(MethodCall call) {
        String argument = call.argument(ChannelMethods.START_STOP_AUDIO.getParam1());
        if (SimpleUtils.stringToBool(argument)) {
            PureDataController.startAudio();
        } else {
            PureDataController.stopAudio();
        }
    }

    private void sendValueXToLibPd(MethodCall call) {
        if (call != null) {
            double valueXd = call.argument(ChannelMethods.INPUT_VALUE_X.getParam1());
            float valueXf = (float) valueXd;
            PureDataController.sendValueXToLibPd(valueXf);
        }
    }

    private void sendValueYToLibPd(MethodCall call) {
        if (call != null) {
            double valueYd = call.argument(ChannelMethods.INPUT_VALUE_Y.getParam1());
            float valueYf = (float) valueYd;
            PureDataController.sendValueYToLibPd(valueYf);
        }
    }

    private void applyUserPrefsAfterUIRendered(MethodCall call) {
        String argument = call.argument(ChannelMethods.START_AUDIO_ON_BOOT.getParam1());
        boolean audioOnStartUp = SimpleUtils.stringToBool(argument);
        PureDataController.applyUserPrefsAfterUIRendered(audioOnStartUp);
    }

    private void playInBackground(MethodCall call){
        String argument = call.argument(ChannelMethods.PLAY_IN_BACKGROUND.getParam1());
        boolean playInBg = SimpleUtils.stringToBool(argument);
        UserPreferences.setAllowPlayingInBackground(playInBg);
    }


}
