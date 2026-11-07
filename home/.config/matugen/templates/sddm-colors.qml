pragma Singleton
import QtQuick

QtObject {
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color primaryForeground: "{{colors.on_primary.default.hex}}"
    readonly property color primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color primaryContainerForeground: "{{colors.on_primary_container.default.hex}}"
    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color surfaceContainer: "{{colors.surface_container.default.hex}}"
    readonly property color surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    readonly property color surfaceForeground: "{{colors.on_surface.default.hex}}"
    readonly property color surfaceVariantForeground: "{{colors.on_surface_variant.default.hex}}"
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color outlineVariant: "{{colors.outline_variant.default.hex}}"
    readonly property color error: "{{colors.error.default.hex}}"
}
