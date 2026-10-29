package com.lirxowo.supercube.client.renderer.state;

import com.lirxowo.supercube.client.renderer.NeonwaveRenderTypes;
import com.lirxowo.supercube.client.renderer.ProjectionRenderHelper;
import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.client.renderer.blockentity.state.BlockEntityRenderState;

public class NeonwaveRenderState extends BlockEntityRenderState implements SubmitNodeCollector.CustomGeometryRenderer {
    public final ProjectionBeamRenderState beam = new ProjectionBeamRenderState();
    public float time;
    public float radius;
    public float opacity;
    public int terrainSteps;
    public float centerX;
    public double centerHeight;
    public float centerZ;

    @Override
    public void render(PoseStack.Pose pose, VertexConsumer buffer) {
        ProjectionRenderHelper.renderProxy(pose, buffer, radius / NeonwaveRenderTypes.SCENE_RADIUS, time, opacity, terrainSteps);
    }
}
