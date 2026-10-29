package com.lirxowo.supercube.block.entity;

import com.lirxowo.supercube.menu.ProjectionMenu;
import com.lirxowo.supercube.projection.ProjectionSettings;
import net.minecraft.core.BlockPos;
import net.minecraft.core.HolderLookup;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.chat.Component;
import net.minecraft.network.protocol.game.ClientboundBlockEntityDataPacket;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.MenuProvider;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.entity.BlockEntity;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.storage.ValueInput;
import net.minecraft.world.level.storage.ValueOutput;

public class ProjectorBlockEntity extends BlockEntity implements MenuProvider {
    private ProjectionSettings projectionSettings = ProjectionSettings.DEFAULT;

    public ProjectorBlockEntity(BlockEntityType<?> type, BlockPos pos, BlockState state) {
        super(type, pos, state);
    }

    public ProjectionSettings getProjectionSettings() {
        return projectionSettings;
    }

    public void setProjectionSettings(ProjectionSettings settings) {
        if (level == null || level.isClientSide() || !settings.isValid() || settings.equals(projectionSettings)) {
            return;
        }
        projectionSettings = settings;
        setChanged();
        BlockState state = getBlockState();
        level.sendBlockUpdated(worldPosition, state, state, Block.UPDATE_CLIENTS);
    }

    @Override
    protected void loadAdditional(ValueInput input) {
        super.loadAdditional(input);
        projectionSettings = new ProjectionSettings(input.getIntOr("Size", ProjectionSettings.MIN_SIZE),
                input.getIntOr("OffsetXSteps", 0), input.getIntOr("OffsetYSteps", 0), input.getIntOr("OffsetZSteps", 0)).clamped();
    }

    @Override
    protected void saveAdditional(ValueOutput output) {
        super.saveAdditional(output);
        output.putInt("Size", projectionSettings.size());
        output.putInt("OffsetXSteps", projectionSettings.offsetXSteps());
        output.putInt("OffsetYSteps", projectionSettings.offsetYSteps());
        output.putInt("OffsetZSteps", projectionSettings.offsetZSteps());
    }

    @Override
    public CompoundTag getUpdateTag(HolderLookup.Provider registries) {
        return saveCustomOnly(registries);
    }

    @Override
    public ClientboundBlockEntityDataPacket getUpdatePacket() {
        return ClientboundBlockEntityDataPacket.create(this);
    }

    @Override
    public Component getDisplayName() {
        return getBlockState().getBlock().getName();
    }

    @Override
    public ProjectionMenu createMenu(int containerId, Inventory inventory, Player player) {
        return new ProjectionMenu(containerId, this);
    }

    @Override
    public void writeClientSideData(ServerPlayer player, AbstractContainerMenu menu, RegistryFriendlyByteBuf buffer) {
        projectionSettings.write(buffer);
    }
}
