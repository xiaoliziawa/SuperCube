package com.lirxowo.supercube.registry;

import com.lirxowo.supercube.SuperCube;
import com.lirxowo.supercube.block.ProjectorBlock;
import com.lirxowo.supercube.block.entity.ProjectorBlockEntity;
import com.lirxowo.supercube.menu.ProjectionMenu;
import java.util.function.Supplier;
import net.minecraft.core.registries.Registries;
import net.minecraft.world.inventory.MenuType;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.CreativeModeTabs;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.entity.BlockEntityType;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.neoforge.common.extensions.IMenuTypeExtension;
import net.neoforged.neoforge.event.BuildCreativeModeTabContentsEvent;
import net.neoforged.neoforge.registries.DeferredBlock;
import net.neoforged.neoforge.registries.DeferredHolder;
import net.neoforged.neoforge.registries.DeferredItem;
import net.neoforged.neoforge.registries.DeferredRegister;

public final class SuperCubeContent {
    private static final int LIGHT_LEVEL = 10;
    private static final DeferredRegister.Blocks BLOCKS = DeferredRegister.createBlocks(SuperCube.MODID);
    private static final DeferredRegister.Items ITEMS = DeferredRegister.createItems(SuperCube.MODID);
    private static final DeferredRegister<BlockEntityType<?>> BLOCK_ENTITIES = DeferredRegister.create(Registries.BLOCK_ENTITY_TYPE, SuperCube.MODID);
    private static final DeferredRegister<MenuType<?>> MENUS = DeferredRegister.create(Registries.MENU, SuperCube.MODID);

    public static final DeferredBlock<ProjectorBlock> HYPERCUBE = registerProjector(
            "hypercube", () -> SuperCubeContent.HYPERCUBE_BLOCK_ENTITY.get());
    public static final DeferredItem<BlockItem> HYPERCUBE_ITEM = ITEMS.registerSimpleBlockItem(HYPERCUBE);
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<ProjectorBlockEntity>> HYPERCUBE_BLOCK_ENTITY = BLOCK_ENTITIES.register(
            "hypercube", () -> new BlockEntityType<>((pos, state) -> new ProjectorBlockEntity(
                    SuperCubeContent.HYPERCUBE_BLOCK_ENTITY.get(), pos, state), HYPERCUBE.get()));
    public static final DeferredBlock<ProjectorBlock> BLACK_HOLE = registerProjector(
            "black_hole", () -> SuperCubeContent.BLACK_HOLE_BLOCK_ENTITY.get());
    public static final DeferredItem<BlockItem> BLACK_HOLE_ITEM = ITEMS.registerSimpleBlockItem(BLACK_HOLE);
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<ProjectorBlockEntity>> BLACK_HOLE_BLOCK_ENTITY = BLOCK_ENTITIES.register(
            "black_hole", () -> new BlockEntityType<>((pos, state) -> new ProjectorBlockEntity(
                    SuperCubeContent.BLACK_HOLE_BLOCK_ENTITY.get(), pos, state), BLACK_HOLE.get()));
    public static final DeferredBlock<ProjectorBlock> RUBIK_CUBE = registerProjector(
            "rubik_cube", () -> SuperCubeContent.RUBIK_CUBE_BLOCK_ENTITY.get());
    public static final DeferredItem<BlockItem> RUBIK_CUBE_ITEM = ITEMS.registerSimpleBlockItem(RUBIK_CUBE);
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<ProjectorBlockEntity>> RUBIK_CUBE_BLOCK_ENTITY = BLOCK_ENTITIES.register(
            "rubik_cube", () -> new BlockEntityType<>((pos, state) -> new ProjectorBlockEntity(
                    SuperCubeContent.RUBIK_CUBE_BLOCK_ENTITY.get(), pos, state), RUBIK_CUBE.get()));
    public static final DeferredBlock<ProjectorBlock> NEONWAVE = registerProjector(
            "neonwave", () -> SuperCubeContent.NEONWAVE_BLOCK_ENTITY.get());
    public static final DeferredItem<BlockItem> NEONWAVE_ITEM = ITEMS.registerSimpleBlockItem(NEONWAVE);
    public static final DeferredHolder<BlockEntityType<?>, BlockEntityType<ProjectorBlockEntity>> NEONWAVE_BLOCK_ENTITY = BLOCK_ENTITIES.register(
            "neonwave", () -> new BlockEntityType<>((pos, state) -> new ProjectorBlockEntity(
                    SuperCubeContent.NEONWAVE_BLOCK_ENTITY.get(), pos, state), NEONWAVE.get()));
    public static final DeferredHolder<MenuType<?>, MenuType<ProjectionMenu>> PROJECTION_MENU = MENUS.register(
            "hypercube", () -> IMenuTypeExtension.create(ProjectionMenu::new));

    private static DeferredBlock<ProjectorBlock> registerProjector(String name, Supplier<BlockEntityType<ProjectorBlockEntity>> blockEntityType) {
        return BLOCKS.registerBlock(name, properties -> new ProjectorBlock(properties, blockEntityType),
                () -> BlockBehaviour.Properties.ofFullCopy(Blocks.IRON_BLOCK).noOcclusion().lightLevel(state -> LIGHT_LEVEL));
    }

    public static void register(IEventBus modBus) {
        BLOCKS.register(modBus);
        ITEMS.register(modBus);
        BLOCK_ENTITIES.register(modBus);
        MENUS.register(modBus);
        modBus.addListener(SuperCubeContent::addCreativeTabContents);
    }

    private static void addCreativeTabContents(BuildCreativeModeTabContentsEvent event) {
        if (event.getTabKey().equals(CreativeModeTabs.FUNCTIONAL_BLOCKS)) {
            event.accept(HYPERCUBE_ITEM.get());
            event.accept(BLACK_HOLE_ITEM.get());
            event.accept(RUBIK_CUBE_ITEM.get());
            event.accept(NEONWAVE_ITEM.get());
        }
    }
}
