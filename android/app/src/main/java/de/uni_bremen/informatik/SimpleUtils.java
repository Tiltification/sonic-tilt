package de.uni_bremen.informatik;

/**
 * Created by Fida on 11.02.21.
 */
public class SimpleUtils {

    public static float boolToFloatFlag(boolean isTrue){
        return isTrue ? 1f : 0f;
    }
    public static boolean stringToBool(String boolValue){
        return Boolean.parseBoolean(boolValue);
    }
}
