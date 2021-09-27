package de.uni_bremen.informatik;

import android.content.Context;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.puredata.android.io.PdAudio;
import org.puredata.core.PdBase;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Created by Fida on 22.01.21.
 */
class PureDataControllerTest {
    PureDataController controller;
    @BeforeEach
    public  void init(){
        controller = new PureDataController( null);
    }
    @Test
    void startAudio() {
        Assertions.assertFalse(controller.isRunning());
    }

    @Test
    void stopAudio() {
        // we need some mocking
    }

    @Test
    void isRunning() {
        Assertions.assertFalse(controller.isRunning());
        // we need some mocking
        // PureDataController.startAudio();
        // Assertions.assertTrue(controller.isRunning());
    }

    @Test
    void getLoudness() {
        Assertions.assertEquals(0f, controller.getLoudness());
    }

    @Test
    void isSoundMute() {
        Assertions.assertFalse(controller.isSoundMute());
    }
}