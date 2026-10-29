package com.lirxowo.supercube.client.renderer;

import com.lirxowo.supercube.block.entity.ProjectorBlockEntity;
import com.lirxowo.supercube.client.renderer.state.HypercubeRenderState;
import com.lirxowo.supercube.config.HypercubeConfig;
import com.lirxowo.supercube.projection.ProjectionSettings;
import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.feature.ModelFeatureRenderer;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;
import org.jspecify.annotations.Nullable;

public class HypercubeRenderer implements BlockEntityRenderer<ProjectorBlockEntity, HypercubeRenderState> {
    private static final int GLOW_RENDER_ORDER = 1;
    private static final double ANIMATION_PERIOD = Math.PI * 10.0;
    private static final double PROJECTED_RADIUS = 2.0 * HypercubeRenderTypes.FOUR_D_CAMERA_DISTANCE
            / Math.sqrt(HypercubeRenderTypes.FOUR_D_CAMERA_DISTANCE * HypercubeRenderTypes.FOUR_D_CAMERA_DISTANCE - 4.0);

    @Override
    public HypercubeRenderState createRenderState() {
        return new HypercubeRenderState();
    }

    @Override
    public void extractRenderState(ProjectorBlockEntity blockEntity, HypercubeRenderState state, float partialTicks,
                                   Vec3 cameraPosition, ModelFeatureRenderer.@Nullable CrumblingOverlay breakProgress) {
        BlockEntityRenderer.super.extractRenderState(blockEntity, state, partialTicks, cameraPosition, breakProgress);
        state.phase = (float) Math.IEEEremainder(ProjectionRenderHelper.animationTime(blockEntity.getLevel(), partialTicks)
                * HypercubeConfig.ROTATION_SPEED.get(), ANIMATION_PERIOD);
        ProjectionSettings settings = blockEntity.getProjectionSettings();
        state.scale = HypercubeConfig.SCALE.get().floatValue() * settings.size();
        state.edgeWidth = HypercubeConfig.EDGE_WIDTH.get().floatValue() * settings.size();
        state.opacity = HypercubeConfig.OPACITY.get().floatValue();
        state.useImprovedTransparency = Minecraft.getInstance().gameRenderer.useImprovedTransparency();
        state.centerX = 0.5F + settings.offsetX();
        state.centerHeight = centerHeight(state.scale) + settings.offsetY();
        state.centerZ = 0.5F + settings.offsetZ();
        float projectedRadius = (float) PROJECTED_RADIUS * state.scale;
        ProjectionRenderHelper.prepareBeam(state.beam, settings,
                state.centerHeight + Math.sin(state.phase * 2.0F) * HypercubeRenderTypes.HOVER_AMPLITUDE,
                projectedRadius, state.phase,
                HypercubeConfig.BEAM_ENABLED.get() ? HypercubeConfig.BEAM_OPACITY.get().floatValue() * state.opacity : 0.0F);
    }

    @Override
    public void submit(HypercubeRenderState state, PoseStack poseStack, SubmitNodeCollector collector, CameraRenderState camera) {
        if (state.opacity <= 0.0F) {
            return;
        }
        poseStack.pushPose();
        poseStack.translate(state.centerX, state.centerHeight, state.centerZ);
        collector.submitCustomGeometry(poseStack, HypercubeRenderTypes.HYPERCUBE, state);
        if (!state.useImprovedTransparency) {
            collector.order(GLOW_RENDER_ORDER).submitCustomGeometry(poseStack, HypercubeRenderTypes.HYPERCUBE_GLOW, state);
        }
        poseStack.popPose();
        ProjectionRenderHelper.submitBeam(state.beam, poseStack, collector);
    }

    @Override
    public boolean shouldRender(ProjectorBlockEntity blockEntity, Vec3 cameraPosition) {
        if (!HypercubeConfig.ENABLED.get()) {
            return false;
        }
        double viewDistance = getViewDistance();
        return getRenderBoundingBox(blockEntity).distanceToSqr(cameraPosition) < viewDistance * viewDistance;
    }

    @Override
    public boolean shouldRenderOffScreen() {
        return true;
    }

    @Override
    public int getViewDistance() {
        return HypercubeConfig.VIEW_DISTANCE.get();
    }

    @Override
    public AABB getRenderBoundingBox(ProjectorBlockEntity blockEntity) {
        ProjectionSettings settings = blockEntity.getProjectionSettings();
        double scale = HypercubeConfig.SCALE.get() * settings.size();
        double radius = PROJECTED_RADIUS * scale
                + 2.0 * HypercubeRenderTypes.GLOW_RADIUS * HypercubeConfig.EDGE_WIDTH.get() * settings.size();
        return ProjectionRenderHelper.bounds(blockEntity.getBlockPos(), settings, centerHeight(scale) + settings.offsetY(),
                radius, radius + HypercubeRenderTypes.HOVER_AMPLITUDE);
    }

    private static double centerHeight(double scale) {
        return ProjectionRenderHelper.centerHeight(PROJECTED_RADIUS * scale + HypercubeRenderTypes.HOVER_AMPLITUDE);
    }
}
