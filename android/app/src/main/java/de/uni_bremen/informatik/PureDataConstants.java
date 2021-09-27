package de.uni_bremen.informatik;

public enum PureDataConstants {


    INPUT_X("targetX"),
    INPUT_Y("targetY"),
    INPUT_VOLUME("volume"),
    INPUT_MUTE("soundMute"),
    PINK_MUTE("pinkMute"),
    MAIN_PATCH("receiverLibPD.pd");
    String name;
    PureDataConstants(String name){
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public boolean equals(PureDataConstants constants){
        return constants != null && this.name.equals(constants.getName());
    }
    public boolean equals(String name){
        return this.name.equals(name);
    }
}
