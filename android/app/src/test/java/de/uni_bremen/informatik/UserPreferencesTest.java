package de.uni_bremen.informatik;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Assertions;

/**
 * Created by Fida on 22.01.21.
 */



class UserPreferencesTest {
    static UserPreferences userPreferences;

    @BeforeAll
    static void init(){
        userPreferences = new UserPreferences().initDefaults();

    }
    @Test
    void isPlayOnBoot() {
        Assertions.assertTrue(userPreferences.isPlayOnBoot());
    }


    @Test
    void isOneDimensionalMode() {
        Assertions.assertTrue(userPreferences.isOneDimensionalMode());
    }

    @Test
    void isTwoDimensionalMode() {
        Assertions.assertFalse(userPreferences.isTwoDimensionalMode());
    }

    @Test
    void getDefaultVolume() {
        Assertions.assertEquals(userPreferences.getDefaultVolume(),1f);
    }
}