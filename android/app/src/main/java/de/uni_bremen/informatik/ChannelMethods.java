package de.uni_bremen.informatik;

/**
 * Created by Fida on 22.01.21.
 */
 enum ChannelMethods {

        START_STOP_AUDIO("toggleAudio","switchOff"),
        INPUT_VALUE_X("sendAngleXToLibPd","targetX"),
        START_AUDIO_ON_BOOT("applyUserPrefsAfterUIRendered","startAudioOnBoot"),
        INPUT_PINK_NOISE("togglePinkNoise","pinkMute"),
        INPUT_VALUE_Y("sendAngleYToLibPd","targetY"),
        PINK_NOISE_RANGE("setPinkNoiseSensitivityRange","range"),
        PLAY_IN_BACKGROUND("playInBackground","play");

        String methodName;
        String param1;


        ChannelMethods(String methodName, String param1) {
            this.methodName = methodName;
            this.param1 = param1;
        }

        public String getMethodName() {
            return methodName;
        }

        public String getParam1() {
            return param1;
        }

        public boolean equals(ChannelMethods method){
            return method != null && equals(method.getMethodName());
        }
        public boolean equals(String methodName){
            return this.methodName.equals(methodName);
        }
}
