package com.lirxowo.supercube.client.renderer;

import com.lirxowo.supercube.SuperCube;
import com.mojang.blaze3d.vertex.DefaultVertexFormat;
import com.mojang.renderpearl.api.GpuFormat;
import com.mojang.renderpearl.api.pipeline.BlendFunction;
import com.mojang.renderpearl.api.pipeline.ColorTargetState;
import com.mojang.renderpearl.api.pipeline.DepthStencilState;
import com.mojang.renderpearl.api.pipeline.PrimitiveTopology;
import com.mojang.renderpearl.api.pipeline.RenderPipeline;
import com.mojang.renderpearl.api.vertex.VertexFormat;
import net.minecraft.client.renderer.RenderPipelines;
import net.minecraft.client.renderer.oit.OitPipelineSet;
import net.minecraft.client.renderer.rendertype.RenderSetup;
import net.minecraft.client.renderer.rendertype.RenderType;
import net.minecraft.resources.Identifier;

public final class NeonwaveRenderTypes {
    public static final float SCENE_RADIUS = 8.0F;
    private static final RenderPipeline.Snippet SNIPPET = RenderPipeline.builder(RenderPipelines.MATRICES_FOG_SNIPPET)
            .withVertexShader(Identifier.fromNamespaceAndPath(SuperCube.MODID, "core/neonwave"))
            .withFragmentShader(Identifier.fromNamespaceAndPath(SuperCube.MODID, "core/neonwave"))
            .withShaderDefine("NEONWAVE_SCENE_RADIUS", SCENE_RADIUS)
            .withVertexBinding(0, VertexFormat.builder(0)
                    .addAttribute(DefaultVertexFormat.POSITION_SEMANTIC_NAME, GpuFormat.RGB32_FLOAT)
                    .addAttribute(DefaultVertexFormat.COLOR_SEMANTIC_NAME, GpuFormat.RGBA8_UNORM)
                    .addAttribute(DefaultVertexFormat.UV0_SEMANTIC_NAME, GpuFormat.RG32_FLOAT)
                    .addAttribute(DefaultVertexFormat.UV3_SEMANTIC_NAME, GpuFormat.RG32_FLOAT).build())
            .withPrimitiveTopology(PrimitiveTopology.QUADS)
            .withCull(false)
            .buildSnippet();
    public static final RenderPipeline PIPELINE = RenderPipeline.builder(SNIPPET)
            .withLocation(Identifier.fromNamespaceAndPath(SuperCube.MODID, "pipeline/neonwave"))
            .withDepthStencilState(DepthStencilState.DEFAULT)
            .withColorTargetState(new ColorTargetState(BlendFunction.TRANSLUCENT))
            .build();
    public static final OitPipelineSet OIT_PIPELINES = OitPipelineSet.builder(
            Identifier.fromNamespaceAndPath(SuperCube.MODID, "neonwave"), RenderPipeline.builder(SNIPPET)).build();
    public static final RenderType NEONWAVE = RenderType.create("supercube_neonwave", RenderSetup.builder(PIPELINE)
            .setOitPipelines(OIT_PIPELINES)
            .sortOnUpload()
            .createRenderSetup());
}
