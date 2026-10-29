package com.lirxowo.supercube.network;

import com.lirxowo.supercube.SuperCube;
import com.lirxowo.supercube.menu.ProjectionMenu;
import com.lirxowo.supercube.projection.ProjectionSettings;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.Identifier;
import net.minecraft.world.entity.player.Player;
import net.neoforged.neoforge.network.handling.IPayloadContext;

public record UpdateProjectionPayload(int containerId, ProjectionSettings settings) implements CustomPacketPayload {
    public static final Type<UpdateProjectionPayload> TYPE = new Type<>(Identifier.fromNamespaceAndPath(SuperCube.MODID, "update_projection"));
    public static final StreamCodec<RegistryFriendlyByteBuf, UpdateProjectionPayload> STREAM_CODEC = CustomPacketPayload.codec(
            UpdateProjectionPayload::write, UpdateProjectionPayload::read);

    private void write(RegistryFriendlyByteBuf buffer) {
        buffer.writeVarInt(containerId);
        settings.write(buffer);
    }

    private static UpdateProjectionPayload read(RegistryFriendlyByteBuf buffer) {
        return new UpdateProjectionPayload(buffer.readVarInt(), ProjectionSettings.read(buffer));
    }

    public static void handle(UpdateProjectionPayload payload, IPayloadContext context) {
        Player player = context.player();
        if (player.containerMenu instanceof ProjectionMenu menu && menu.containerId == payload.containerId) {
            menu.applySettings(player, payload.settings);
        }
    }

    @Override
    public Type<UpdateProjectionPayload> type() {
        return TYPE;
    }
}
