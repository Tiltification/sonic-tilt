package de.uni_bremen.informatik;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Created by Fida on 22.01.21.
 */
class MethodChannelHandlerTest {

    @Test
    void configureMethodChannel() {
        try {
            MethodChannelHandler handler = new MethodChannelHandler(null);
        }catch (RuntimeException e){
            // alright
        }

    }
}