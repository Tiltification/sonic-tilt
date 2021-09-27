package de.uni_bremen.informatik;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Created by Fida on 22.01.21.
 */
class PureDataConstantsTest {

    @Test
    void testEquals_String_As_Param() {
        PureDataConstants inputMute = PureDataConstants.INPUT_MUTE;
        Assertions.assertTrue(inputMute.equals("soundMute"));
        Assertions.assertFalse(inputMute.equals("volume"));

    }

    @Test
    void testEquals__Enum_As_Param() {
        PureDataConstants inputMute = PureDataConstants.INPUT_MUTE;
        PureDataConstants inputX = PureDataConstants.INPUT_X;
        PureDataConstants inputMute1 = PureDataConstants.INPUT_MUTE;
        Assertions.assertTrue(inputMute.equals(inputMute1));
        Assertions.assertFalse(inputMute.equals(inputX));
    }
}