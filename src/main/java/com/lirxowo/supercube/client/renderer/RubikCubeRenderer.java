package com.lirxowo.supercube.client.renderer;

import com.lirxowo.supercube.block.entity.ProjectorBlockEntity;
import com.lirxowo.supercube.client.renderer.state.RubikCubeRenderState;
import com.lirxowo.supercube.config.RubikCubeConfig;
import com.lirxowo.supercube.projection.ProjectionSettings;
import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.client.renderer.blockentity.BlockEntityRenderer;
import net.minecraft.client.renderer.feature.ModelFeatureRenderer;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;
import org.jspecify.annotations.Nullable;

public class RubikCubeRenderer implements BlockEntityRenderer<ProjectorBlockEntity, RubikCubeRenderState> {
    @Override
    public RubikCubeRenderState createRenderState() {
        return new RubikCubeRenderState();
    }

    @Override
    public void extractRenderState(ProjectorBlockEntity blockEntity, RubikCubeRenderState state, float partialTicks,
                                   Vec3 cameraPosition, ModelFeatureRenderer.@Nullable CrumblingOverlay breakProgress) {
        BlockEntityRenderer.super.extractRenderState(blockEntity, state, partialTicks, cameraPosition, breakProgress);
        ProjectionSettings settings = blockEntity.getProjectionSettings();
        state.scale = RubikCubeConfig.SCALE.get().floatValue() * settings.size();
        state.time = (float) (ProjectionRenderHelper.animationTime(blockEntity.getLevel(), partialTicks)
                * RubikCubeConfig.ANIMATION_SPEED.get());
        state.opacity = RubikCubeConfig.OPACITY.get().floatValue();
        state.centerX = 0.5F + settings.offsetX();
        state.centerHeight = ProjectionRenderHelper.centerHeight(RubikCubeRenderTypes.SCENE_RADIUS * state.scale)
                + settings.offsetY();
        state.centerZ = 0.5F + settings.offsetZ();
        ProjectionRenderHelper.prepareBeam(state.beam, settings, state.centerHeight,
                RubikCubeRenderTypes.SCENE_RADIUS * state.scale, state.time,
                RubikCubeConfig.BEAM_ENABLED.get() ? RubikCubeConfig.BEAM_OPACITY.get().floatValue() * state.opacity : 0.0F);
    }

    @Override
    public void submit(RubikCubeRenderState state, PoseStack poseStack, SubmitNodeCollector collector, CameraRenderState camera) {
        if (state.opacity <= 0.0F) {
            return;
        }
        poseStack.pushPose();
        poseStack.translate(state.centerX, state.centerHeight, state.centerZ);
        collector.submitCustomGeometry(poseStack, RubikCubeRenderTypes.RUBIK_CUBE, state);
        poseStack.popPose();
        ProjectionRenderHelper.submitBeam(state.beam, poseStack, collector);
    }

    @Override
    public boolean shouldRender(ProjectorBlockEntity blockEntity, Vec3 cameraPosition) {
        if (!RubikCubeConfig.ENABLED.get()) {
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
        return RubikCubeConfig.VIEW_DISTANCE.get();
    }

    @Override
    public AABB getRenderBoundingBox(ProjectorBlockEntity blockEntity) {
        ProjectionSettings settings = blockEntity.getProjectionSettings();
        double radius = RubikCubeRenderTypes.SCENE_RADIUS * RubikCubeConfig.SCALE.get() * settings.size();
        return ProjectionRenderHelper.bounds(blockEntity.getBlockPos(), settings,
                ProjectionRenderHelper.centerHeight(radius) + settings.offsetY(), radius, radius);
    }
}
