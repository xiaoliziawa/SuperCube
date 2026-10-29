package com.lirxowo.supercube.client.renderer;

import com.lirxowo.supercube.block.ProjectorBlock;
import com.lirxowo.supercube.client.renderer.state.ProjectionBeamRenderState;
import com.lirxowo.supercube.projection.ProjectionSettings;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.core.BlockPos;
import net.minecraft.util.ARGB;
import net.minecraft.world.level.Level;
import net.minecraft.world.phys.AABB;
import org.jspecify.annotations.Nullable;
import org.joml.Matrix4f;

public final class ProjectionRenderHelper {
    private static final double TICKS_PER_SECOND = 20.0;
    private static final double HOVER_GAP = 0.1;
    private static final double EMITTER_HEIGHT = ProjectorBlock.BASE_HEIGHT + 0.005;
    private static final float BEAM_END_RADIUS_FACTOR = 0.75F;
    private static final float BEAM_END_HEIGHT_FACTOR = 0.2F;
    private static final int PROXY_VERTICES = 24;

    public static void renderProxy(PoseStack.Pose pose, VertexConsumer buffer, float scale, float time, float opacity, int quality) {
        Matrix4f matrix = pose.pose();
        int color = ARGB.white(opacity);
        for (int vertex = 0; vertex < PROXY_VERTICES; vertex++) {
            buffer.addVertex(matrix.m30(), matrix.m31(), matrix.m32())
                    .setColor(color)
                    .setUv(vertex, time)
                    .setUv3(scale, quality);
        }
    }

    public static double animationTime(@Nullable Level level, float partialTicks) {
        return level == null ? 0.0 : ((double) level.getGameTime() + partialTicks) / TICKS_PER_SECOND;
    }

    public static double centerHeight(double radius) {
        return ProjectorBlock.BASE_HEIGHT + radius + HOVER_GAP;
    }

    public static void prepareBeam(ProjectionBeamRenderState beam, ProjectionSettings settings, double centerHeight,
                                   float radius, float phase, float opacity) {
        beam.endX = settings.offsetX();
        beam.endY = (float) (centerHeight - EMITTER_HEIGHT) - radius * BEAM_END_HEIGHT_FACTOR;
        beam.endZ = settings.offsetZ();
        beam.endRadius = radius * BEAM_END_RADIUS_FACTOR;
        beam.phase = phase;
        beam.opacity = opacity;
    }

    public static void submitBeam(ProjectionBeamRenderState beam, PoseStack poseStack, SubmitNodeCollector collector) {
        if (beam.opacity <= 0.0F) {
            return;
        }
        poseStack.pushPose();
        poseStack.translate(0.5, EMITTER_HEIGHT, 0.5);
        collector.submitCustomGeometry(poseStack, HypercubeRenderTypes.PROJECTION_BEAM, beam);
        poseStack.popPose();
    }

    public static AABB bounds(BlockPos pos, ProjectionSettings settings, double centerHeight,
                              double horizontalRadius, double verticalRadius) {
        double centerX = pos.getX() + 0.5 + settings.offsetX();
        double centerY = pos.getY() + centerHeight;
        double centerZ = pos.getZ() + 0.5 + settings.offsetZ();
        return new AABB(Math.min(pos.getX(), centerX - horizontalRadius),
                Math.min(pos.getY(), centerY - verticalRadius), Math.min(pos.getZ(), centerZ - horizontalRadius),
                Math.max(pos.getX() + 1.0, centerX + horizontalRadius),
                Math.max(pos.getY() + EMITTER_HEIGHT + ProjectionBeamRenderState.SOURCE_RADIUS, centerY + verticalRadius),
                Math.max(pos.getZ() + 1.0, centerZ + horizontalRadius));
    }
}
