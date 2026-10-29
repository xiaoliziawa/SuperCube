package com.lirxowo.supercube.client.renderer;

import com.lirxowo.supercube.SuperCube;
import com.mojang.blaze3d.systems.RenderSystem;
import com.mojang.blaze3d.vertex.DefaultVertexFormat;
import com.mojang.renderpearl.api.GpuFormat;
import com.mojang.renderpearl.api.pipeline.BlendFunction;
import com.mojang.renderpearl.api.pipeline.ColorTargetState;
import com.mojang.renderpearl.api.pipeline.DepthStencilState;
import com.mojang.renderpearl.api.pipeline.PrimitiveTopology;
import com.mojang.renderpearl.api.pipeline.RenderPipeline;
import com.mojang.renderpearl.api.textures.FilterMode;
import com.mojang.renderpearl.api.vertex.VertexFormat;
import net.minecraft.client.renderer.BindGroupLayouts;
import net.minecraft.client.renderer.RenderPipelines;
import net.minecraft.client.renderer.oit.OitPipelineSet;
import net.minecraft.client.renderer.rendertype.RenderSetup;
import net.minecraft.client.renderer.rendertype.RenderType;
import net.minecraft.resources.Identifier;

public final class BlackHoleRenderTypes {
    public static final float SCENE_RADIUS = 8.0F;
    public static final int QUALITY_STEP_SHIFT = 3;
    public static final int DISK_BRIGHTNESS_SHIFT = 11;
    private static final RenderPipeline.Snippet SNIPPET = RenderPipeline.builder(RenderPipelines.MATRICES_FOG_SNIPPET)
            .withVertexShader(Identifier.fromNamespaceAndPath(SuperCube.MODID, "core/black_hole"))
            .withFragmentShader(Identifier.fromNamespaceAndPath(SuperCube.MODID, "core/black_hole"))
            .withBindGroupLayout(BindGroupLayouts.SAMPLER0_SAMPLER1)
            .withShaderDefine("BLACK_HOLE_SCENE_RADIUS", SCENE_RADIUS)
            .withShaderDefine("BLACK_HOLE_QUALITY_STEP_SHIFT", QUALITY_STEP_SHIFT)
            .withShaderDefine("BLACK_HOLE_DISK_BRIGHTNESS_SHIFT", DISK_BRIGHTNESS_SHIFT)
            .withVertexBinding(0, VertexFormat.builder(0)
                    .addAttribute(DefaultVertexFormat.POSITION_SEMANTIC_NAME, GpuFormat.RGB32_FLOAT)
                    .addAttribute(DefaultVertexFormat.COLOR_SEMANTIC_NAME, GpuFormat.RGBA8_UNORM)
                    .addAttribute(DefaultVertexFormat.UV0_SEMANTIC_NAME, GpuFormat.RG32_FLOAT)
                    .addAttribute(DefaultVertexFormat.UV3_SEMANTIC_NAME, GpuFormat.RG32_FLOAT).build())
            .withPrimitiveTopology(PrimitiveTopology.QUADS)
            .withCull(false)
            .buildSnippet();
    public static final RenderPipeline PIPELINE = RenderPipeline.builder(SNIPPET)
            .withLocation(Identifier.fromNamespaceAndPath(SuperCube.MODID, "pipeline/black_hole"))
            .withDepthStencilState(DepthStencilState.DEFAULT)
            .withColorTargetState(new ColorTargetState(BlendFunction.TRANSLUCENT))
            .build();
    public static final OitPipelineSet OIT_PIPELINES = OitPipelineSet.builder(
            Identifier.fromNamespaceAndPath(SuperCube.MODID, "black_hole"), RenderPipeline.builder(SNIPPET)).build();
    public static final RenderType BLACK_HOLE = RenderType.create("supercube_black_hole", RenderSetup.builder(PIPELINE)
            .setOitPipelines(OIT_PIPELINES)
            .withTexture("Sampler0", texture("black_hole_noise.png"), () -> RenderSystem.getSamplerCache().getRepeat(FilterMode.LINEAR))
            .withTexture("Sampler1", texture("black_hole_stars.png"), () -> RenderSystem.getSamplerCache().getRepeat(FilterMode.LINEAR))
            .sortOnUpload()
            .createRenderSetup());

    private static Identifier texture(String filename) {
        return Identifier.fromNamespaceAndPath(SuperCube.MODID, "textures/effect/" + filename);
    }
}
