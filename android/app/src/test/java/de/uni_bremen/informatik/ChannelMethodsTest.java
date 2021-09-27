package de.uni_bremen.informatik;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

/**
 * Created by Fida on 22.01.21.
 */
class ChannelMethodsTest {

    @Test
    void testEquals_String_As_Param() {
        ChannelMethods method = ChannelMethods.INPUT_VALUE_X;
        Assertions.assertTrue(method.equals("sendAngleXToLibPd"));
        Assertions.assertFalse(method.equals("targetX"));
    }

    @Test
    void testEquals_Enum_As_Param() {
        ChannelMethods method = ChannelMethods.INPUT_VALUE_Y;
        ChannelMethods methodAxisY = ChannelMethods.INPUT_VALUE_Y;
        ChannelMethods methodAxisX = ChannelMethods.INPUT_VALUE_X;
        Assertions.assertTrue(methodAxisY.equals(method));
        Assertions.assertFalse(methodAxisX.equals(method));
    }
}