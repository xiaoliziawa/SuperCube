package com.lirxowo.supercube.client;

import com.lirxowo.supercube.SuperCube;
import com.lirxowo.supercube.client.renderer.BlackHoleRenderer;
import com.lirxowo.supercube.client.renderer.BlackHoleRenderTypes;
import com.lirxowo.supercube.client.renderer.HypercubeRenderer;
import com.lirxowo.supercube.client.renderer.HypercubeRenderTypes;
import com.lirxowo.supercube.client.renderer.NeonwaveRenderer;
import com.lirxowo.supercube.client.renderer.NeonwaveRenderTypes;
import com.lirxowo.supercube.client.renderer.RubikCubeRenderer;
import com.lirxowo.supercube.client.renderer.RubikCubeRenderTypes;
import com.lirxowo.supercube.client.screen.ProjectionScreen;
import com.lirxowo.supercube.registry.SuperCubeContent;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.fml.common.EventBusSubscriber;
import net.neoforged.neoforge.client.event.EntityRenderersEvent;
import net.neoforged.neoforge.client.event.RegisterMenuScreensEvent;
import net.neoforged.neoforge.client.event.RegisterRenderPipelinesEvent;

@EventBusSubscriber(modid = SuperCube.MODID, value = Dist.CLIENT)
public final class SuperCubeClient {
    @SubscribeEvent
    public static void registerScreens(RegisterMenuScreensEvent event) {
        event.register(SuperCubeContent.PROJECTION_MENU.get(), ProjectionScreen::new);
    }

    @SubscribeEvent
    public static void registerRenderers(EntityRenderersEvent.RegisterRenderers event) {
        event.registerBlockEntityRenderer(SuperCubeContent.HYPERCUBE_BLOCK_ENTITY.get(), context -> new HypercubeRenderer());
        event.registerBlockEntityRenderer(SuperCubeContent.BLACK_HOLE_BLOCK_ENTITY.get(), context -> new BlackHoleRenderer());
        event.registerBlockEntityRenderer(SuperCubeContent.RUBIK_CUBE_BLOCK_ENTITY.get(), context -> new RubikCubeRenderer());
        event.registerBlockEntityRenderer(SuperCubeContent.NEONWAVE_BLOCK_ENTITY.get(), context -> new NeonwaveRenderer());
    }

    @SubscribeEvent
    public static void registerPipelines(RegisterRenderPipelinesEvent event) {
        event.registerPipeline(HypercubeRenderTypes.PIPELINE);
        event.registerPipeline(HypercubeRenderTypes.GLOW_PIPELINE);
        event.registerOitPipelineSet(HypercubeRenderTypes.OIT_PIPELINES);
        event.registerPipeline(HypercubeRenderTypes.BEAM_PIPELINE);
        event.registerOitPipelineSet(HypercubeRenderTypes.BEAM_OIT_PIPELINES);
        event.registerPipeline(BlackHoleRenderTypes.PIPELINE);
        event.registerOitPipelineSet(BlackHoleRenderTypes.OIT_PIPELINES);
        event.registerPipeline(RubikCubeRenderTypes.PIPELINE);
        event.registerOitPipelineSet(RubikCubeRenderTypes.OIT_PIPELINES);
        event.registerPipeline(NeonwaveRenderTypes.PIPELINE);
        event.registerOitPipelineSet(NeonwaveRenderTypes.OIT_PIPELINES);
    }
}
