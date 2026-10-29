package com.lirxowo.supercube;

import com.lirxowo.supercube.config.BlackHoleConfig;
import com.lirxowo.supercube.config.HypercubeConfig;
import com.lirxowo.supercube.config.NeonwaveConfig;
import com.lirxowo.supercube.config.RubikCubeConfig;
import com.lirxowo.supercube.network.UpdateProjectionPayload;
import com.lirxowo.supercube.registry.SuperCubeContent;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.ModContainer;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.config.ModConfig;
import net.neoforged.neoforge.network.event.RegisterPayloadHandlersEvent;

@Mod(SuperCube.MODID)
public class SuperCube {
    public static final String MODID = "supercube";

    public SuperCube(IEventBus modBus, ModContainer container) {
        SuperCubeContent.register(modBus);
        modBus.addListener(SuperCube::registerPayloads);
        container.registerConfig(ModConfig.Type.CLIENT, HypercubeConfig.SPEC);
        container.registerConfig(ModConfig.Type.CLIENT, BlackHoleConfig.SPEC, "supercube-black-hole-client.toml");
        container.registerConfig(ModConfig.Type.CLIENT, RubikCubeConfig.SPEC, "supercube-rubik-cube-client.toml");
        container.registerConfig(ModConfig.Type.CLIENT, NeonwaveConfig.SPEC, "supercube-neonwave-client.toml");
    }

    private static void registerPayloads(RegisterPayloadHandlersEvent event) {
        event.registrar("1").playToServer(UpdateProjectionPayload.TYPE, UpdateProjectionPayload.STREAM_CODEC, UpdateProjectionPayload::handle);
    }
}
