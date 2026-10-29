package com.lirxowo.supercube.client.renderer.state;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.util.ARGB;
import org.joml.Matrix3f;
import org.joml.Matrix4f;

public class ProjectionBeamRenderState implements SubmitNodeCollector.CustomGeometryRenderer {
    public static final float SOURCE_RADIUS = 0.17F;
    private static final int SEGMENTS = 32;
    private static final int CORNERS_PER_SEGMENT = 4;
    private static final float MIN_LENGTH = 0.01F;
    private static final float[] CIRCLE = new float[(SEGMENTS + 1) * 2];
    public float endX;
    public float endY;
    public float endZ;
    public float endRadius;
    public float phase;
    public float opacity;

    static {
        for (int segment = 0; segment <= SEGMENTS; segment++) {
            double angle = segment * Math.TAU / SEGMENTS;
            CIRCLE[segment * 2] = (float) Math.cos(angle);
            CIRCLE[segment * 2 + 1] = (float) Math.sin(angle);
        }
    }

    @Override
    public void render(PoseStack.Pose pose, VertexConsumer buffer) {
        float length = (float) Math.sqrt(endX * endX + endY * endY + endZ * endZ);
        if (opacity <= 0.0F || length < MIN_LENGTH) {
            return;
        }
        float dx = endX / length;
        float dy = endY / length;
        float dz = endZ / length;
        float horizontalLength = (float) Math.sqrt(dx * dx + dz * dz);
        float ux = horizontalLength > 0.0F ? dz / horizontalLength : 1.0F;
        float uz = horizontalLength > 0.0F ? -dx / horizontalLength : 0.0F;
        float vx = dy * uz;
        float vy = dz * ux - dx * uz;
        float vz = -dy * ux;
        float slope = (endRadius - SOURCE_RADIUS) / length;
        float normalScale = 1.0F / (float) Math.sqrt(1.0F + slope * slope);
        int color = ARGB.white(opacity);
        Matrix4f matrix = pose.pose();
        Matrix3f normalMatrix = pose.normal();
        for (int segment = 0; segment < SEGMENTS; segment++) {
            for (int corner = 0; corner < CORNERS_PER_SEGMENT; corner++) {
                boolean atEnd = corner == 1 || corner == 2;
                int ringIndex = segment + (corner >= 2 ? 1 : 0);
                float cosine = CIRCLE[ringIndex * 2];
                float sine = CIRCLE[ringIndex * 2 + 1];
                float rx = ux * cosine + vx * sine;
                float ry = vy * sine;
                float rz = uz * cosine + vz * sine;
                float radius = atEnd ? endRadius : SOURCE_RADIUS;
                float x = rx * radius + (atEnd ? endX : 0.0F);
                float y = ry * radius + (atEnd ? endY : 0.0F);
                float z = rz * radius + (atEnd ? endZ : 0.0F);
                float nx = (rx - dx * slope) * normalScale;
                float ny = (ry - dy * slope) * normalScale;
                float nz = (rz - dz * slope) * normalScale;
                buffer.addVertex(matrix.m00() * x + matrix.m10() * y + matrix.m20() * z + matrix.m30(),
                                matrix.m01() * x + matrix.m11() * y + matrix.m21() * z + matrix.m31(),
                                matrix.m02() * x + matrix.m12() * y + matrix.m22() * z + matrix.m32())
                        .setColor(color)
                        .setUv(ringIndex / (float) SEGMENTS, atEnd ? 1.0F : 0.0F)
                        .setUv3(phase, 0.0F)
                        .setNormal(normalMatrix.m00() * nx + normalMatrix.m10() * ny + normalMatrix.m20() * nz,
                                normalMatrix.m01() * nx + normalMatrix.m11() * ny + normalMatrix.m21() * nz,
                                normalMatrix.m02() * nx + normalMatrix.m12() * ny + normalMatrix.m22() * nz);
            }
        }
    }
}
