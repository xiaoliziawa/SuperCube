
# SuperCube

Shader-driven tesseract and black hole projectors for Minecraft 26.3 / NeoForge 26.3.0.90, using Java 25.

## In Game

Find **Hypercube Projector** in the Functional Blocks creative tab, or use:

```mcfunction
/give @s supercube:hypercube
```

Place it to project a floating, rotating four-dimensional hypercube. Its 16 vertices and 32 edges rotate through the XW, YW, ZW and XZ planes before perspective projection into the world. The four edge directions have different colors, white cores, soft halos and traveling light pulses. The pedestal uses vanilla bitmap textures; no shader pack is required.

An animated, translucent beam connects the pedestal emitter to the projection. It widens towards the hologram, fades at its edges and tip, and follows the projection's size and position. Opaque world geometry occludes both the beam and the tesseract.

Find **Black Hole Projector** in the same creative tab, or use:

```mcfunction
/give @s supercube:black_hole
```

The black hole projects a three-dimensional accretion disk with gravitational lensing and the supplied galaxy background. Walk around, above or inside it to change the viewpoint. The scene is adapted from https://www.shadertoy.com/view/ltBGWh, retaining its five-octave noise, emission colors, star field, gravity and default 4 samples / 64 steps. The player's camera replaces the fixed Shadertoy camera; world time drives the animation and pauses with a singleplayer world. A sphere contains the background and lensing inside the projection, with depth testing against opaque world geometry and support for classic and improved transparency.

The two supplied PNG files are included unchanged as `textures/effect/black_hole_noise.png` and `textures/effect/black_hole_stars.png`. They are small previews (239x122 and 239x124); reproducing the original's full detail requires the original channel textures. See [shader credits](SHADER_CREDITS.md).

Find **Glass Cube Projector** in the same creative tab, or use:

```mcfunction
/give @s supercube:glass_cube
```

The glass cube projects a rotating, refracting glass block whose layered inner surfaces fade into each other. It is adapted from "Self" by Danil (https://www.shadertoy.com/view/NslGRN) and shows only the cube: the source's sky, floor plane and floor shadow are removed, so the projection draws nothing outside the cube silhouette and the glass reflects a plain gradient. The source scene is z-up; rays are rotated into that space and spun around the vertical axis, and the box intersection supplies the written depth. The scene also runs in the OIT alpha-only passes, which share the box intersection through `glass_cube_bounds.glsl`. See [shader credits](SHADER_CREDITS.md).

Walking inside the cube keeps the same layered, colored surfaces and glass shading seen from outside. Interior rays start at the player's position in the shared scene, with no separate lattice room or glowing core; the depth written is the far wall, so the world behind stays hidden while you are enclosed.

Centered, rotated-grid pixel samples replace the screen-seeded random offsets. Ray steps are deterministic, and each segment is clipped to the thin disk before integrating its density with up to eight midpoint samples. This reduces grain and missed disk intersections without applying a screen-space blur or changing the supplied textures. Inside the projection, the renderer caps pixel samples at two and density samples at four to bound the cost when the effect fills the screen. Rays entering or crossing the black hole core terminate with the accumulated disk emission; core and empty exterior segments skip disk sampling, and degenerate ray directions terminate safely.

Right-click either pedestal to edit its settings:

| Setting | Range | Default |
| --- | --- | --- |
| Size | Integer multipliers from 1 to 20 | 1, preserving the original size |
| X / Y / Z offset | -20 to 20 blocks on each world axis, in 0.25-block steps | 0 |

Changing size raises either projection to keep it above the pedestal before the Y offset is applied, and also scales the tesseract's edge thickness. X and Z offsets move it horizontally; positive Y raises it. The beam stays attached to the pedestal. Apply saves the settings; Cancel or Escape discards edits; Reset restores size 1 and zero offsets in the editor. Each placed projector saves its own settings with the world and synchronizes changes to tracking players. The server checks the open menu, interaction distance and allowed ranges before accepting an update.

The animation uses interpolated world time, stops while a singleplayer world is paused, and does not require a block entity ticker or animation packets. The item model shows the pedestal; the animated projection appears when placed.

## Configuration

Hypercube client settings are in `config/supercube-client.toml`:

| Setting | Default | Meaning |
| --- | --- | --- |
| `enabled` | `true` | Show the projection |
| `scale` | `0.45` | Baseline size before the projector's 1-20 multiplier |
| `rotationSpeed` | `0.35` | Base rotation speed in radians per second; `0` freezes the effect |
| `edgeWidth` | `0.012` | Radius of the bright edge core, in blocks |
| `opacity` | `0.85` | Projection opacity |
| `beamEnabled` | `true` | Show the projection beam |
| `beamOpacity` | `0.24` | Beam opacity, multiplied by the projection opacity |
| `viewDistance` | `64` | Rendering distance from the projection and beam bounds, in blocks |

The projection height and culling bounds adjust to size and offsets, including the beam and its emitter. English and Simplified Chinese translations are included.

Black hole client settings are in `config/supercube-black-hole-client.toml`:

| Setting | Default | Meaning |
| --- | --- | --- |
| `enabled` | `true` | Show black hole projections |
| `radius` | `2.0` | Projection boundary radius in blocks, before the size multiplier |
| `animationSpeed` | `1.0` | Accretion animation speed; `0` freezes the effect |
| `opacity` | `1.0` | Projection opacity; opaque black regions conceal the world behind them |
| `diskBrightness` | `6` | Disk emission multiplier, from 1 to 16; `1` matches the original intensity. Background and opacity are unaffected |
| `samples` | `4` | Maximum samples per pixel, from 1 to 4; capped at 2 inside the projection |
| `marchSteps` | `64` | Ray steps, from 32 to 128; step length adjusts to preserve the integration range |
| `beamEnabled` | `true` | Show the projection beam |
| `beamOpacity` | `0.24` | Beam opacity, multiplied by projection opacity |
| `viewDistance` | `64` | Rendering distance from the projection and beam bounds |

The black hole's proxy uses 24 vertices. Both camera rays and volumetric integration run on the GPU; OIT depth-bounds and transmittance passes skip the volumetric integration. All OIT phases use the ray-sphere intersection depth instead of the proxy cube's depth. Size and offsets reuse the shared projector block entity, settings menu and server-validated update packet.

Glass cube client settings are in `config/supercube-glass-cube-client.toml`:

| Setting | Default | Meaning |
| --- | --- | --- |
| `enabled` | `true` | Show glass cube projections |
| `radius` | `2.0` | Projection boundary radius in blocks, before the size multiplier |
| `animationSpeed` | `1.0` | Rotation speed; `0` freezes the effect |
| `opacity` | `1.0` | Projection opacity |
| `beamEnabled` | `true` | Show the projection beam |
| `beamOpacity` | `0.24` | Beam opacity, multiplied by projection opacity |
| `viewDistance` | `64` | Rendering distance from the projection and beam bounds |

## Rendering API Research

Implementation signatures were checked against the exact local source artifacts, rather than inferred from older tutorials:

- Minecraft: `build/moddev/artifacts/minecraft-patched-26.3.0.90-sources.jar`, generated from Minecraft 26.3 and NeoForge 26.3.0.90.
- NeoForge: `net.neoforged:neoforge:26.3.0.90:sources`, under `D:/GradleHome/caches/modules-2/files-2.1`.
- Compiler: `com/mojang/renderpearl/frontend/shaders/GlslCompiler.java` in the Minecraft sources, including its shaderc target and include handling.

| 26.3 API or behavior | Implementation |
| --- | --- |
| Pipeline and vertex types are in `com.mojang.renderpearl.api` | Use `RenderPipeline`, `VertexFormat` and `GpuFormat` from RenderPearl |
| Vertex formats describe named attributes with `GpuFormat` | A 32-byte vertex carries the center, tint, encoded edge corner, phase, scale and width |
| NeoForge registers required pipelines through `RegisterRenderPipelinesEvent` | Register the classic pipeline and all three OIT pipelines for resource reloads |
| Block entity rendering separates extraction from submission | Snapshot config and time in `extractRenderState`; submit only the snapshot with `submitCustomGeometry` |
| Reversed Z uses `GREATER_THAN_OR_EQUAL` | Depth-test against the world; in classic transparency, write depth only for the bright edge cores |
| Classic transparency draws clouds after translucent custom geometry | Draw depth-writing edge cores before a separate glow pass; keep glow and beam depth writes disabled |
| Improved transparency uses `OitPipelineSet` | Supply depth-bounds, transmittance and accumulation variants; use `OIT_ADDITIVE` and the vanilla OIT functions |
| Core shader resources use GLSL 330, explicit locations and `#include` | Follow the engine's shader format; the engine compiles to SPIR-V for its backends |
| World uniforms use `DynamicTransforms`, `Projection` and `Fog` bind groups | Reuse `RenderPipelines.MATRICES_FOG_SNIPPET`; apply environmental and render-distance fog to glow opacity |
| NeoForge exposes `getRenderBoundingBox` on the renderer | Bound the shader-displaced geometry, including its halo and hover motion |
| Section visibility alone cannot represent geometry extending beyond the pedestal's section | Use `shouldRenderOffScreen` with the global block entity path, which still applies frustum and distance checks in 26.3 |

The CPU emits 32 edge quads (128 vertices / 4 KiB) and, when enabled, a 32-segment beam (128 vertices / 4.5 KiB) per visible projector per frame. Classic transparency adds a second 4 KiB edge pass to separate depth-writing cores from the soft glow, preventing background clouds from covering foreground lines. Improved transparency uses the combined OIT shader without this extra pass. All 4D rotations, projection, camera-facing edge expansion, glow, beam rays and scanning pulses run on the GPU. Beam ring trigonometry is cached. There are no temporary objects in the vertex loops, custom GPU buffers, direct OpenGL calls, reflection or Mixins.

The 4D camera distance is greater than the vertex radius, keeping the perspective denominator positive for every rotation. The shader handles collapsed and camera-aligned edges. Animation phases wrap at a common period for all rotation planes to preserve precision over long sessions.

## Verification

Gradle `compileJava` and `processResources` passed with JDK 25 against the cached Minecraft and NeoForge dependencies. The Minecraft client started and completed resource loading without mod or shader compilation errors, generated both client configs, and shut down cleanly. All three shader programs compiled to SPIR-V for their classic and three OIT stages with both depth conventions: 52 shader compilations.

Offline checks also passed 2,500 settings/payload round trips, invalid-range and corrupted-save clamping checks, and 36 beam geometry cases covering vertical, horizontal, downward and nearly vertical directions, large radii, ring seams and normals. Disabled and degenerate beams emit no geometry. All 12 resource JSON files parsed successfully, with 31 matching English and Chinese translation keys.

GPU offscreen rendering on an RTX 4060 passed front, side, above, inside and portrait views, animation changes and full foreground depth occlusion. Actual scene shaders and the supplied textures were used. The grain reduction was compared at 1280x800 in front, overhead and close views. Images are in `build/codex-validation/black-hole/`, with the previous renderer captured in `baseline-sharpness/`.

The center slowdown was reproduced at 1920x1080 using OpenGL elapsed-time queries, two warm-up draws and the median of seven measured draws per view. At default settings, the core cost fell from about 32 ms to 0.13 ms, the in-disk view from 33 ms to 8 ms, and the outward view from 16 ms to 6 ms on the RTX 4060 Laptop GPU. These timings measure the projection draw, not total Minecraft frame time. `RenderBlackHole.java` runs these cases with `-Dsupercube.preview.center=true`; captures are in `baseline-center/` and `fixed-center/`. The core is checked for complete absorption at minimum and maximum quality settings.

In-world checks remain for settings, save/reload and multiplayer synchronization, size 1/20 and extreme offsets, beam appearance, clouds, glass with improved transparency on/off, pause/resume, resource reload and a dedicated server. Shader-pack combinations have not been tested.
