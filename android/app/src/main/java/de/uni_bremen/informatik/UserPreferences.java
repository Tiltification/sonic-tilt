package de.uni_bremen.informatik;

public class UserPreferences {

    private boolean playOnBoot;
    private float defaultVolume;
    private boolean oneDimensionalMode;
    private boolean twoDimensionalMode;
    private static boolean playInBackground;// should and will come from flutter/hive and is set in channelHandler

    public UserPreferences(){

    }
    public UserPreferences initDefaults(){
        UserPreferences preferences = new UserPreferences();
        preferences.setDefaultVolume(1f);
        preferences.setPlayOnBoot(true);
        preferences.setOneDimensionalMode(true);
        preferences.setTwoDimensionalMode(false);
        return preferences;
    }
    public boolean isPlayOnBoot() {
        return playOnBoot;
    }

    public void setPlayOnBoot(boolean playOnBoot) {
        this.playOnBoot = playOnBoot;
    }

    public float getDefaultVolume() {
        return defaultVolume;
    }

    public void setDefaultVolume(float defaultVolume) {
        this.defaultVolume = defaultVolume;
    }

    public boolean isOneDimensionalMode() {
        return oneDimensionalMode;
    }

    public void setOneDimensionalMode(boolean oneDimensionalMode) {
        this.oneDimensionalMode = oneDimensionalMode;
    }

    public boolean isTwoDimensionalMode() {
        return twoDimensionalMode;
    }

    public void setTwoDimensionalMode(boolean twoDimensionalMode) {
        this.twoDimensionalMode = twoDimensionalMode;
    }

    public static boolean allowPlayingInBackground() {
        return playInBackground;
    }

    public static void setAllowPlayingInBackground(boolean playInBackground) {
        UserPreferences.playInBackground = playInBackground;
    }

    public static float pinkNoiseSensitivityRange = 0.045f;

    public static float getPinkNoiseSensitivityRange() {
        return pinkNoiseSensitivityRange;
    }

    public static void setPinkNoiseSensitivityRange(float pinkNoiseSensitivityRange) {
        UserPreferences.pinkNoiseSensitivityRange = pinkNoiseSensitivityRange;
    }
}
