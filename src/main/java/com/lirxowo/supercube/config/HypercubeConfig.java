package com.lirxowo.supercube.config;

import net.neoforged.neoforge.common.ModConfigSpec;

public final class HypercubeConfig {
    public static final ModConfigSpec SPEC;
    public static final ModConfigSpec.BooleanValue ENABLED;
    public static final ModConfigSpec.DoubleValue SCALE;
    public static final ModConfigSpec.DoubleValue ROTATION_SPEED;
    public static final ModConfigSpec.DoubleValue EDGE_WIDTH;
    public static final ModConfigSpec.DoubleValue OPACITY;
    public static final ModConfigSpec.BooleanValue BEAM_ENABLED;
    public static final ModConfigSpec.DoubleValue BEAM_OPACITY;
    public static final ModConfigSpec.IntValue VIEW_DISTANCE;

    static {
        ModConfigSpec.Builder builder = new ModConfigSpec.Builder();
        ENABLED = builder.translation("supercube.configuration.enabled").define("enabled", true);
        SCALE = builder.translation("supercube.configuration.scale").defineInRange("scale", 0.45, 0.1, 2.0);
        ROTATION_SPEED = builder.translation("supercube.configuration.rotationSpeed").defineInRange("rotationSpeed", 0.35, 0.0, 3.0);
        EDGE_WIDTH = builder.translation("supercube.configuration.edgeWidth").defineInRange("edgeWidth", 0.012, 0.002, 0.08);
        OPACITY = builder.translation("supercube.configuration.opacity").defineInRange("opacity", 0.85, 0.0, 1.0);
        BEAM_ENABLED = builder.translation("supercube.configuration.beamEnabled").define("beamEnabled", true);
        BEAM_OPACITY = builder.translation("supercube.configuration.beamOpacity").defineInRange("beamOpacity", 0.24, 0.0, 1.0);
        VIEW_DISTANCE = builder.translation("supercube.configuration.viewDistance").defineInRange("viewDistance", 64, 16, 128);
        SPEC = builder.build();
    }
}
