package com.lirxowo.supercube.menu;

import com.lirxowo.supercube.block.entity.ProjectorBlockEntity;
import com.lirxowo.supercube.projection.ProjectionSettings;
import com.lirxowo.supercube.registry.SuperCubeContent;
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.AbstractContainerMenu;
import net.minecraft.world.inventory.ContainerLevelAccess;
import net.minecraft.world.item.ItemStack;
import org.jspecify.annotations.Nullable;

public class ProjectionMenu extends AbstractContainerMenu {
    private final @Nullable ProjectorBlockEntity projector;
    private final ContainerLevelAccess access;
    private final ProjectionSettings initialSettings;

    public ProjectionMenu(int containerId, Inventory inventory, RegistryFriendlyByteBuf buffer) {
        this(containerId, null, ProjectionSettings.read(buffer));
    }

    public ProjectionMenu(int containerId, ProjectorBlockEntity projector) {
        this(containerId, projector, projector.getProjectionSettings());
    }

    private ProjectionMenu(int containerId, @Nullable ProjectorBlockEntity projector, ProjectionSettings settings) {
        super(SuperCubeContent.PROJECTION_MENU.get(), containerId);
        this.projector = projector;
        this.access = projector == null ? ContainerLevelAccess.NULL
                : ContainerLevelAccess.create(projector.getLevel(), projector.getBlockPos());
        this.initialSettings = settings;
    }

    public ProjectionSettings getInitialSettings() {
        return initialSettings;
    }

    public void applySettings(Player player, ProjectionSettings settings) {
        if (projector != null && !player.isSpectator() && stillValid(player) && settings.isValid()) {
            projector.setProjectionSettings(settings);
        }
    }

    @Override
    public boolean stillValid(Player player) {
        return projector == null || !projector.isRemoved()
                && projector.getLevel().getBlockEntity(projector.getBlockPos()) == projector
                && stillValid(access, player, projector.getBlockState().getBlock());
    }

    @Override
    public ItemStack quickMoveStack(Player player, int slotIndex) {
        return ItemStack.EMPTY;
    }
}
