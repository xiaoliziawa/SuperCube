package com.lirxowo.supercube.projection;

import net.minecraft.network.RegistryFriendlyByteBuf;

public record ProjectionSettings(int size, int offsetXSteps, int offsetYSteps, int offsetZSteps) {
    public static final int MIN_SIZE = 1;
    public static final int MAX_SIZE = 20;
    public static final int OFFSET_STEPS_PER_BLOCK = 4;
    public static final int MAX_OFFSET_BLOCKS = 20;
    public static final int MAX_OFFSET_STEPS = MAX_OFFSET_BLOCKS * OFFSET_STEPS_PER_BLOCK;
    public static final ProjectionSettings DEFAULT = new ProjectionSettings(MIN_SIZE, 0, 0, 0);

    public boolean isValid() {
        return size >= MIN_SIZE && size <= MAX_SIZE
                && Math.abs((long) offsetXSteps) <= MAX_OFFSET_STEPS
                && Math.abs((long) offsetYSteps) <= MAX_OFFSET_STEPS
                && Math.abs((long) offsetZSteps) <= MAX_OFFSET_STEPS;
    }

    public ProjectionSettings clamped() {
        return isValid() ? this : new ProjectionSettings(Math.clamp(size, MIN_SIZE, MAX_SIZE),
                Math.clamp(offsetXSteps, -MAX_OFFSET_STEPS, MAX_OFFSET_STEPS),
                Math.clamp(offsetYSteps, -MAX_OFFSET_STEPS, MAX_OFFSET_STEPS),
                Math.clamp(offsetZSteps, -MAX_OFFSET_STEPS, MAX_OFFSET_STEPS));
    }

    public float offsetX() {
        return offsetXSteps / (float) OFFSET_STEPS_PER_BLOCK;
    }

    public float offsetY() {
        return offsetYSteps / (float) OFFSET_STEPS_PER_BLOCK;
    }

    public float offsetZ() {
        return offsetZSteps / (float) OFFSET_STEPS_PER_BLOCK;
    }

    public void write(RegistryFriendlyByteBuf buffer) {
        buffer.writeByte(size);
        buffer.writeByte(offsetXSteps);
        buffer.writeByte(offsetYSteps);
        buffer.writeByte(offsetZSteps);
    }

    public static ProjectionSettings read(RegistryFriendlyByteBuf buffer) {
        return new ProjectionSettings(buffer.readUnsignedByte(), buffer.readByte(), buffer.readByte(), buffer.readByte());
    }
}
