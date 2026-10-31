package com.lirxowo.supercube.config;

import net.neoforged.neoforge.common.ModConfigSpec;

public final class GlassCubeConfig {
    public static final ModConfigSpec SPEC;
    public static final ModConfigSpec.BooleanValue ENABLED;
    public static final ModConfigSpec.DoubleValue RADIUS;
    public static final ModConfigSpec.DoubleValue ANIMATION_SPEED;
    public static final ModConfigSpec.DoubleValue OPACITY;
    public static final ModConfigSpec.BooleanValue BEAM_ENABLED;
    public static final ModConfigSpec.DoubleValue BEAM_OPACITY;
    public static final ModConfigSpec.IntValue VIEW_DISTANCE;

    static {
        ModConfigSpec.Builder builder = new ModConfigSpec.Builder();
        ENABLED = builder.translation("supercube.configuration.glassCube.enabled").define("enabled", true);
        RADIUS = builder.translation("supercube.configuration.glassCube.radius").defineInRange("radius", 2.0, 0.25, 4.0);
        ANIMATION_SPEED = builder.translation("supercube.configuration.glassCube.animationSpeed").defineInRange("animationSpeed", 1.0, 0.0, 4.0);
        OPACITY = builder.translation("supercube.configuration.glassCube.opacity").defineInRange("opacity", 1.0, 0.0, 1.0);
        BEAM_ENABLED = builder.translation("supercube.configuration.beamEnabled").define("beamEnabled", true);
        BEAM_OPACITY = builder.translation("supercube.configuration.beamOpacity").defineInRange("beamOpacity", 0.24, 0.0, 1.0);
        VIEW_DISTANCE = builder.translation("supercube.configuration.viewDistance").defineInRange("viewDistance", 64, 16, 128);
        SPEC = builder.build();
    }
}
