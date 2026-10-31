package com.lirxowo.supercube.client.renderer;

import com.lirxowo.supercube.block.entity.ProjectorBlockEntity;
import com.lirxowo.supercube.client.renderer.state.GlassCubeRenderState;
import com.lirxowo.supercube.config.GlassCubeConfig;
import com.lirxowo.supercube.projection.ProjectionSettings;
import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.feature.ModelFeatureRenderer;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;
import org.jspecify.annotations.Nullable;

public class GlassCubeRenderer implements BlockEntityRenderer<ProjectorBlockEntity, GlassCubeRenderState> {
    @Override
    public GlassCubeRenderState createRenderState() {
        return new GlassCubeRenderState();
    }

    @Override
    public void extractRenderState(ProjectorBlockEntity blockEntity, GlassCubeRenderState state, float partialTicks,
                                   Vec3 cameraPosition, ModelFeatureRenderer.@Nullable CrumblingOverlay breakProgress) {
        BlockEntityRenderer.super.extractRenderState(blockEntity, state, partialTicks, cameraPosition, breakProgress);
        ProjectionSettings settings = blockEntity.getProjectionSettings();
        state.radius = GlassCubeConfig.RADIUS.get().floatValue() * settings.size();
        state.time = (float) (ProjectionRenderHelper.animationTime(blockEntity.getLevel(), partialTicks)
                * GlassCubeConfig.ANIMATION_SPEED.get());
        state.opacity = GlassCubeConfig.OPACITY.get().floatValue();
        state.centerX = 0.5F + settings.offsetX();
        state.centerHeight = ProjectionRenderHelper.centerHeight(state.radius) + settings.offsetY();
        state.centerZ = 0.5F + settings.offsetZ();
        ProjectionRenderHelper.prepareBeam(state.beam, settings, state.centerHeight, state.radius, state.time,
                GlassCubeConfig.BEAM_ENABLED.get() ? GlassCubeConfig.BEAM_OPACITY.get().floatValue() * state.opacity : 0.0F);
    }

    @Override
    public void submit(GlassCubeRenderState state, PoseStack poseStack, SubmitNodeCollector collector, CameraRenderState camera) {
        if (state.opacity <= 0.0F) {
            return;
        }
        poseStack.pushPose();
        poseStack.translate(state.centerX, state.centerHeight, state.centerZ);
        collector.submitCustomGeometry(poseStack, GlassCubeRenderTypes.GLASS_CUBE, state);
        poseStack.popPose();
        ProjectionRenderHelper.submitBeam(state.beam, poseStack, collector);
    }

    @Override
    public boolean shouldRender(ProjectorBlockEntity blockEntity, Vec3 cameraPosition) {
        if (!GlassCubeConfig.ENABLED.get()) {
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
        return GlassCubeConfig.VIEW_DISTANCE.get();
    }

    @Override
    public AABB getRenderBoundingBox(ProjectorBlockEntity blockEntity) {
        ProjectionSettings settings = blockEntity.getProjectionSettings();
        double radius = GlassCubeConfig.RADIUS.get() * settings.size();
        return ProjectionRenderHelper.bounds(blockEntity.getBlockPos(), settings,
                ProjectionRenderHelper.centerHeight(radius) + settings.offsetY(), radius, radius);
    }
}
