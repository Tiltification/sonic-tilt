package de.uni_bremen.informatik;

import android.content.Context;

import org.puredata.android.io.AudioParameters;
import org.puredata.android.io.PdAudio;
import org.puredata.core.PdBase;
import org.puredata.core.utils.IoUtils;

import java.io.File;
import java.io.IOException;

/**
 * Created by Fida on 22.01.21.
 */
public class PureDataController {
    private static boolean isRunning;
    private static float loudness;
    private static boolean soundMute;
    private static boolean isPlaying; // 4 states we need at least 2 bits :D
    private static boolean wasPlaying;// to save the state before entering the background
    //for applying presets when reentering the foreground
    private static float actualRangeX=0f;
    private static float actualRangeY=0f;

    private Context context;


    public PureDataController(Context context) {
        this.context = context;
    }

    private static void setVolume(float volume) {
        String input = PureDataConstants.INPUT_VOLUME.getName();
        if (volume >= 0 && volume <= 10) {
            PdBase.sendFloat(input, volume);
        } else {
            PdBase.sendFloat(input, 1);
        }
    }

    private static void setMute(boolean mute) {
        float muteFlag = SimpleUtils.boolToFloatFlag(mute);
        String input = PureDataConstants.INPUT_MUTE.getName();
        PdBase.sendFloat(input, muteFlag);
    }

    public static void sendValueXToLibPd(float valueX) {
        actualRangeX = Math.abs(valueX);
        togglePinkNoiseDependingOnTiltingAngle();
        String input = PureDataConstants.INPUT_X.getName();
        PdBase.sendFloat(input, valueX);
    }

    public static void sendValueYToLibPd(float valueY) {
        actualRangeY = Math.abs(valueY);
        togglePinkNoiseDependingOnTiltingAngle();
        String input = PureDataConstants.INPUT_Y.getName();
        PdBase.sendFloat(input, valueY);
    }

    private static void togglePinkNoiseDependingOnTiltingAngle() {
        if (actualRangeX >= UserPreferences.getPinkNoiseSensitivityRange() || actualRangeY >= UserPreferences.getPinkNoiseSensitivityRange()) {
            setPinkMute(true);
        } else {
            setPinkMute(false);
        }
    }

    private static void setPinkMute(boolean mute) {
        float muteFlag = SimpleUtils.boolToFloatFlag(mute);
        String input = PureDataConstants.PINK_MUTE.getName();
        PdBase.sendFloat(input, muteFlag);
    }

    public static void startAudio() {
        soundMute = false;
        loudness = 1f;
        isRunning = true;
        setMute(soundMute);
        setVolume(loudness);
        setPinkMute(false);
        setIsPlaying(true);
    }

    public static void stopAudio() {
        soundMute = true;
        isRunning = false;
        loudness = 0f;
        setMute(soundMute);
        setVolume(loudness);
        setPinkMute(true);
        setIsPlaying(false);
    }

    //TODO: use this method.
    // call this in MethodChannelHandler.java by passing the preferences you get on start from flutter
    public static void initPdWithUserPreferences(UserPreferences userPreferences) {
        if (userPreferences == null) {
            userPreferences = new UserPreferences();
            userPreferences.initDefaults();
        }
        setMute(!userPreferences.isPlayOnBoot());
        setVolume(userPreferences.getDefaultVolume());
    }

    public static void applyUserPrefsAfterUIRendered(boolean startAudioOnBoot) {
        //dirty solution
        // we need to toggle the pink noise otherwise it will not be played
        setPinkMute(true);
        setPinkMute(false);
        if (startAudioOnBoot) {
            startAudio();
        } else {
            stopAudio();
        }
    }

    public static boolean isPlaying() {
        return PureDataController.isPlaying;
    }

    public static void setIsPlaying(boolean playing) {
        PureDataController.isPlaying = playing;
    }

    public static boolean wasPlaying() {
        return wasPlaying;
    }

    public static void setWasPlaying(boolean wasPlaying) {
        PureDataController.wasPlaying = wasPlaying;
    }

    public static void applyUserPrefsWhenEnteringBackground() {
        boolean playInBG = UserPreferences.allowPlayingInBackground();
        setWasPlaying(isPlaying());
        if (!playInBG) {
            stopAudio();
        }

    }

    public static void applyUserPrefsWhenEnteringForeground() {
        boolean toBePlayed = wasPlaying();
        if (toBePlayed) {
            startAudio();
        }

    }

    public void initPdAudio() {

        int sampleRate = Math.max(Configs.MIN_SAMPLE_RATE, AudioParameters.suggestSampleRate());
        try {
            PdAudio.initAudio(sampleRate, 0, 2, 8, true);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void loadAndOpenPdMainPatch() {
        try {
            File dir = context.getFilesDir();
            IoUtils.extractZipResource(context.getResources().openRawResource(R.raw.streamingassets), dir, true);
            File pdPatch = new File(dir, PureDataConstants.MAIN_PATCH.getName());
            PdBase.openPatch(pdPatch);
            PdAudio.startAudio(context);
        } catch (IOException ioException) {
            ioException.printStackTrace();
        }
    }

    public boolean isRunning() {
        return isRunning;
    }

    public float getLoudness() {
        return loudness;
    }

    public boolean isSoundMute() {
        return soundMute;
    }

    public Context getContext() {
        return context;
    }
}
