package com.lirxowo.supercube.client.screen;

import com.lirxowo.supercube.menu.ProjectionMenu;
import com.lirxowo.supercube.network.UpdateProjectionPayload;
import com.lirxowo.supercube.projection.ProjectionSettings;
import java.util.OptionalInt;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.components.AbstractSliderButton;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.components.Tooltip;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.client.input.KeyEvent;
import net.minecraft.network.chat.CommonComponents;
import net.minecraft.network.chat.Component;
import net.minecraft.world.entity.player.Inventory;
import net.neoforged.neoforge.client.network.ClientPacketDistributor;

public class ProjectionScreen extends AbstractContainerScreen<ProjectionMenu> {
    private static final Component[] AXES = {
            Component.translatable("screen.supercube.axis.x"),
            Component.translatable("screen.supercube.axis.y"),
            Component.translatable("screen.supercube.axis.z")
    };
    private static final Component OFFSET_LABEL = Component.translatable("screen.supercube.offset");
    private static final Component OFFSET_RANGE = Component.translatable("screen.supercube.offset.range",
            -ProjectionSettings.MAX_OFFSET_BLOCKS, ProjectionSettings.MAX_OFFSET_BLOCKS,
            1.0 / ProjectionSettings.OFFSET_STEPS_PER_BLOCK);
    private final String[] offsetValues;
    private final OffsetControl[] offsetControls = new OffsetControl[AXES.length];
    private int selectedSize;
    private SizeSlider sizeSlider;
    private Button applyButton;
    private boolean validOffsets;

    public ProjectionScreen(ProjectionMenu menu, Inventory inventory, Component title) {
        super(menu, inventory, title, 280, 222);
        ProjectionSettings settings = menu.getInitialSettings();
        selectedSize = settings.size();
        offsetValues = new String[]{formatOffset(settings.offsetXSteps()), formatOffset(settings.offsetYSteps()),
                formatOffset(settings.offsetZSteps())};
    }

    @Override
    protected void init() {
        super.init();
        sizeSlider = addRenderableWidget(new SizeSlider(leftPos + 16, topPos + 34, imageWidth - 32));
        for (int axis = 0; axis < AXES.length; axis++) {
            offsetControls[axis] = addOffsetControl(axis, topPos + 82 + axis * 26);
        }
        addRenderableWidget(Button.builder(Component.translatable("screen.supercube.reset"), button -> resetSettings())
                .bounds(leftPos + 16, topPos + 186, 78, 20).build());
        addRenderableWidget(Button.builder(CommonComponents.GUI_CANCEL, button -> onClose())
                .bounds(leftPos + 101, topPos + 186, 78, 20).build());
        applyButton = addRenderableWidget(Button.builder(Component.translatable("screen.supercube.apply"), button -> applySettings())
                .bounds(leftPos + 186, topPos + 186, 78, 20).build());
        updateControls();
    }

    private OffsetControl addOffsetControl(int axis, int y) {
        EditBox input = new EditBox(font, leftPos + 68, y, 172, 20,
                Component.translatable("screen.supercube.offset.axis", AXES[axis]));
        input.setMaxLength(8);
        input.setValue(offsetValues[axis]);
        input.setTooltip(Tooltip.create(OFFSET_RANGE));
        input.setResponder(value -> {
            offsetValues[axis] = value;
            updateControls();
        });
        addRenderableWidget(input);
        Button decrease = addRenderableWidget(Button.builder(Component.translatable("screen.supercube.decrease.symbol"),
                        button -> stepOffset(axis, -1))
                .bounds(leftPos + 44, y, 20, 20)
                .tooltip(Tooltip.create(Component.translatable("screen.supercube.decrease", AXES[axis]))).build());
        Button increase = addRenderableWidget(Button.builder(Component.translatable("screen.supercube.increase.symbol"),
                        button -> stepOffset(axis, 1))
                .bounds(leftPos + 244, y, 20, 20)
                .tooltip(Tooltip.create(Component.translatable("screen.supercube.increase", AXES[axis]))).build());
        return new OffsetControl(input, decrease, increase);
    }

    private void stepOffset(int axis, int direction) {
        int steps = parseOffset(offsetValues[axis]).orElse(0);
        offsetControls[axis].input.setValue(formatOffset(Math.clamp(steps + direction,
                -ProjectionSettings.MAX_OFFSET_STEPS, ProjectionSettings.MAX_OFFSET_STEPS)));
    }

    private void updateControls() {
        validOffsets = true;
        for (int axis = 0; axis < offsetControls.length; axis++) {
            OffsetControl control = offsetControls[axis];
            OptionalInt steps = parseOffset(offsetValues[axis]);
            validOffsets &= steps.isPresent();
            control.input.setTextColor(steps.isPresent() ? 0xFFE0E0E0 : 0xFFFF7070);
            control.decrease.active = steps.isEmpty() || steps.getAsInt() > -ProjectionSettings.MAX_OFFSET_STEPS;
            control.increase.active = steps.isEmpty() || steps.getAsInt() < ProjectionSettings.MAX_OFFSET_STEPS;
        }
        applyButton.active = validOffsets && minecraft.player != null && !minecraft.player.isSpectator();
    }

    private void resetSettings() {
        sizeSlider.setSize(ProjectionSettings.MIN_SIZE);
        for (OffsetControl control : offsetControls) {
            control.input.setValue(formatOffset(0));
        }
    }

    private void applySettings() {
        if (!applyButton.active) {
            return;
        }
        ProjectionSettings settings = new ProjectionSettings(selectedSize,
                parseOffset(offsetValues[0]).orElseThrow(), parseOffset(offsetValues[1]).orElseThrow(),
                parseOffset(offsetValues[2]).orElseThrow());
        ClientPacketDistributor.sendToServer(new UpdateProjectionPayload(menu.containerId, settings));
        onClose();
    }

    private static OptionalInt parseOffset(String text) {
        try {
            double steps = Double.parseDouble(text) * ProjectionSettings.OFFSET_STEPS_PER_BLOCK;
            return Double.isFinite(steps) && Math.abs(steps) <= ProjectionSettings.MAX_OFFSET_STEPS && steps == Math.rint(steps)
                    ? OptionalInt.of((int) steps) : OptionalInt.empty();
        } catch (NumberFormatException exception) {
            return OptionalInt.empty();
        }
    }

    private static String formatOffset(int steps) {
        return steps % ProjectionSettings.OFFSET_STEPS_PER_BLOCK == 0
                ? Integer.toString(steps / ProjectionSettings.OFFSET_STEPS_PER_BLOCK)
                : Float.toString(steps / (float) ProjectionSettings.OFFSET_STEPS_PER_BLOCK);
    }

    @Override
    public void extractRenderState(GuiGraphicsExtractor graphics, int mouseX, int mouseY, float partialTick) {
        graphics.fill(leftPos, topPos, leftPos + imageWidth, topPos + imageHeight, 0xF0202425);
        graphics.outline(leftPos, topPos, imageWidth, imageHeight, 0xFF687578);
        graphics.fill(leftPos + 16, topPos + 26, leftPos + imageWidth - 16, topPos + 27, 0xFF3CA8B7);
        super.extractRenderState(graphics, mouseX, mouseY, partialTick);
    }

    @Override
    protected void extractLabels(GuiGraphicsExtractor graphics, int mouseX, int mouseY) {
        graphics.centeredText(font, title, imageWidth / 2, 12, 0xFFF2F5F5);
        graphics.text(font, OFFSET_LABEL, 16, 66, 0xFFB6C6C9);
        for (int axis = 0; axis < AXES.length; axis++) {
            graphics.text(font, AXES[axis], 16, 88 + axis * 26, 0xFFE0E0E0);
        }
        if (!validOffsets) {
            graphics.centeredText(font, OFFSET_RANGE, imageWidth / 2, 164, 0xFFFF9090);
        }
    }

    private record OffsetControl(EditBox input, Button decrease, Button increase) {}

    private class SizeSlider extends AbstractSliderButton {
        private static final int SIZE_RANGE = ProjectionSettings.MAX_SIZE - ProjectionSettings.MIN_SIZE;

        private SizeSlider(int x, int y, int width) {
            super(x, y, width, DEFAULT_HEIGHT, CommonComponents.EMPTY,
                    (selectedSize - ProjectionSettings.MIN_SIZE) / (double) SIZE_RANGE);
            updateMessage();
        }

        private void setSize(int size) {
            setValue((size - ProjectionSettings.MIN_SIZE) / (double) SIZE_RANGE);
        }

        @Override
        protected void updateMessage() {
            setMessage(Component.translatable("screen.supercube.size", selectedSize));
        }

        @Override
        protected void applyValue() {
            selectedSize = ProjectionSettings.MIN_SIZE + (int) Math.round(value * SIZE_RANGE);
            value = (selectedSize - ProjectionSettings.MIN_SIZE) / (double) SIZE_RANGE;
        }

        @Override
        public boolean keyPressed(KeyEvent event) {
            if (canChangeValue && (event.isLeft() || event.isRight())) {
                setSize(selectedSize + (event.isLeft() ? -1 : 1));
                return true;
            }
            return super.keyPressed(event);
        }
    }
}
