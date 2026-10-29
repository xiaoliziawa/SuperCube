package com.lirxowo.supercube.client.renderer.state;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.client.renderer.blockentity.state.BlockEntityRenderState;
import net.minecraft.util.ARGB;
import org.joml.Matrix4f;

public class HypercubeRenderState extends BlockEntityRenderState implements SubmitNodeCollector.CustomGeometryRenderer {
    private static final int DIMENSIONS = 4;
    private static final int VERTEX_COUNT = 1 << DIMENSIONS;
    private static final int CORNERS_PER_EDGE = 4;
    public final ProjectionBeamRenderState beam = new ProjectionBeamRenderState();
    public float phase;
    public float scale;
    public float edgeWidth;
    public float opacity;
    public boolean useImprovedTransparency;
    public double centerHeight;
    public float centerX;
    public float centerZ;

    @Override
    public void render(PoseStack.Pose pose, VertexConsumer buffer) {
        Matrix4f matrix = pose.pose();
        float x = matrix.m30();
        float y = matrix.m31();
        float z = matrix.m32();
        int color = ARGB.white(opacity);
        for (int vertex = 0; vertex < VERTEX_COUNT; vertex++) {
            for (int axis = 0; axis < DIMENSIONS; axis++) {
                if ((vertex & (1 << axis)) != 0) {
                    continue;
                }
                for (int corner = 0; corner < CORNERS_PER_EDGE; corner++) {
                    int encodedCorner = vertex << DIMENSIONS | axis << 2 | corner;
                    buffer.addVertex(x, y, z)
                            .setColor(color)
                            .setUv(encodedCorner, phase)
                            .setUv3(scale, edgeWidth);
                }
            }
        }
    }
}
