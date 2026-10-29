package com.lirxowo.supercube.client.renderer;

import com.lirxowo.supercube.SuperCube;
import com.mojang.blaze3d.vertex.DefaultVertexFormat;
import com.mojang.renderpearl.api.GpuFormat;
import com.mojang.renderpearl.api.pipeline.BlendFunction;
import com.mojang.renderpearl.api.pipeline.ColorTargetState;
import com.mojang.renderpearl.api.pipeline.CompareOp;
import com.mojang.renderpearl.api.pipeline.DepthStencilState;
import com.mojang.renderpearl.api.pipeline.PrimitiveTopology;
import com.mojang.renderpearl.api.pipeline.RenderPipeline;
import com.mojang.renderpearl.api.vertex.VertexFormat;
import net.minecraft.client.renderer.RenderPipelines;
import net.minecraft.client.renderer.oit.OitPipelineSet;
import net.minecraft.client.renderer.rendertype.RenderSetup;
import net.minecraft.client.renderer.rendertype.RenderType;
import net.minecraft.resources.Identifier;

public final class HypercubeRenderTypes {
    public static final float FOUR_D_CAMERA_DISTANCE = 3.5F;
    public static final float HOVER_AMPLITUDE = 0.06F;
    public static final float GLOW_RADIUS = 4.0F;
    private static final RenderPipeline.Snippet SNIPPET = RenderPipeline.builder(createSnippet("hypercube", false))
            .withShaderDefine("FOUR_D_CAMERA_DISTANCE", FOUR_D_CAMERA_DISTANCE)
            .withShaderDefine("HOVER_AMPLITUDE", HOVER_AMPLITUDE)
            .withShaderDefine("GLOW_RADIUS", GLOW_RADIUS)
            .buildSnippet();
    private static final RenderPipeline.Snippet BEAM_SNIPPET = createSnippet("projection_beam", true);

    public static final RenderPipeline PIPELINE = RenderPipeline.builder(SNIPPET)
            .withLocation(Identifier.fromNamespaceAndPath(SuperCube.MODID, "pipeline/hypercube"))
            .withShaderDefine("HYPERCUBE_CORE_PASS")
            .withDepthStencilState(DepthStencilState.DEFAULT)
            .withColorTargetState(new ColorTargetState(BlendFunction.LIGHTNING))
            .build();
    public static final RenderPipeline GLOW_PIPELINE = RenderPipeline.builder(SNIPPET)
            .withLocation(Identifier.fromNamespaceAndPath(SuperCube.MODID, "pipeline/hypercube_glow"))
            .withShaderDefine("HYPERCUBE_GLOW_PASS")
            .withColorTargetState(new ColorTargetState(BlendFunction.LIGHTNING))
            .build();
    public static final OitPipelineSet OIT_PIPELINES = OitPipelineSet.builder(
            Identifier.fromNamespaceAndPath(SuperCube.MODID, "hypercube"),
            RenderPipeline.builder(SNIPPET).withShaderDefine("OIT_ADDITIVE")).build();
    public static final RenderType HYPERCUBE = RenderType.create("supercube_hypercube", RenderSetup.builder(PIPELINE)
            .setOitPipelines(OIT_PIPELINES)
            .sortOnUpload()
            .createRenderSetup());
    public static final RenderType HYPERCUBE_GLOW = RenderType.create("supercube_hypercube_glow", RenderSetup.builder(GLOW_PIPELINE)
            .sortOnUpload()
            .createRenderSetup());
    public static final RenderPipeline BEAM_PIPELINE = RenderPipeline.builder(BEAM_SNIPPET)
            .withLocation(Identifier.fromNamespaceAndPath(SuperCube.MODID, "pipeline/projection_beam"))
            .withColorTargetState(new ColorTargetState(BlendFunction.LIGHTNING))
            .build();
    public static final OitPipelineSet BEAM_OIT_PIPELINES = OitPipelineSet.builder(
            Identifier.fromNamespaceAndPath(SuperCube.MODID, "projection_beam"),
            RenderPipeline.builder(BEAM_SNIPPET).withShaderDefine("OIT_ADDITIVE")).build();
    public static final RenderType PROJECTION_BEAM = RenderType.create("supercube_projection_beam", RenderSetup.builder(BEAM_PIPELINE)
            .setOitPipelines(BEAM_OIT_PIPELINES)
            .sortOnUpload()
            .createRenderSetup());

    private static RenderPipeline.Snippet createSnippet(String shader, boolean includeNormals) {
        var format = VertexFormat.builder(0)
                .addAttribute(DefaultVertexFormat.POSITION_SEMANTIC_NAME, GpuFormat.RGB32_FLOAT)
                .addAttribute(DefaultVertexFormat.COLOR_SEMANTIC_NAME, GpuFormat.RGBA8_UNORM)
                .addAttribute(DefaultVertexFormat.UV0_SEMANTIC_NAME, GpuFormat.RG32_FLOAT)
                .addAttribute(DefaultVertexFormat.UV3_SEMANTIC_NAME, GpuFormat.RG32_FLOAT);
        if (includeNormals) {
            format.addAttribute(DefaultVertexFormat.NORMAL_SEMANTIC_NAME, GpuFormat.RGBA8_SNORM);
        }
        Identifier location = Identifier.fromNamespaceAndPath(SuperCube.MODID, "core/" + shader);
        return RenderPipeline.builder(RenderPipelines.MATRICES_FOG_SNIPPET)
                .withVertexShader(location)
                .withFragmentShader(location)
                .withVertexBinding(0, format.build())
                .withPrimitiveTopology(PrimitiveTopology.QUADS)
                .withDepthStencilState(new DepthStencilState(CompareOp.GREATER_THAN_OR_EQUAL, false))
                .withCull(false)
                .buildSnippet();
    }
}
