# Fastboot LiquidGlass UI Redesign

## Goal
Bring the Fastboot panel into visual alignment with ADB's LiquidGlass theme:
consistent padding, card styling, and color palette while keeping the flash-specific red accent.

## Layout Architecture

```
padding(20)                          ← matches ADB panel
┌─────────────────────────────────────┐
│ [Header title + subtitle] [Mode    ]│  ← mode selector on header row
│                        [selector  ]│
│─────────────────────────────────────│
│ ┌─────────────────────────────────┐ │
│ │ [重启] [Bootloader] [Fastbootd]│ │  ← LiquidGlass card, 4 buttons
│ │      [Recovery]                │ │
│ └─────────────────────────────────┘ │
│ spacing(10)                         │
│ ┌─────────────────────────────────┐ │
│ │ Flash workspace card            │ │  ← Generic / Xiaomi / Oplus
│ │ (image input, partition,       │ │
│ │  command preview, flash btn)    │ │
│ └─────────────────────────────────┘ │
│ Spacer                              │
└─────────────────────────────────────┘
```

## Changes per File

### FastbootPanelView.swift
- `.padding(16)` → `.padding(20)` — match ADB
- Remove `fastbootAccent`, `fastbootPageBackground`, `fastbootBorder` constants
  - Use `Color.red` where accent needed (flash button, step indicators)
- **headerRow**: add `FastbootModeSelector` inside HStack to the right of title
  - Wrap in `HStack { title; Spacer; modeSelector }` 
  - Show `selectedFlashMode` state; mode changes affect `flashDetailCard`
- **rebootSection**: inline `FastbootRebootSectionView` directly (no GroupBox)
- **flashWorkspaceSection**: remove wrapper; just inline `flashDetailCard`
- Remove `genericFlashConfigColumn`, `placeholderFlashConfigColumn`, `genericPartitionPreviewColumn`, `placeholderPartitionPreviewColumn`
  - These live inside `GenericFastbootFlashCardView` and placeholder card
- Simplify `placeholderFlashDetailCard` to a single VStack with LiquidGlass card styling

### FastbootModeSelectorView.swift
- Keep compact HStack of 3 buttons
- Selected state: `accent.opacity(0.10)` bg + `accent.opacity(0.45)` stroke
- Match ADB segmented control visual weight

### FastbootRebootSectionView.swift
- **Remove** `GroupBox` wrapper
- Wrap in `VStack` with LiquidGlass card modifiers:
  - `.background(LiquidGlassTheme.cardBackground)`
  - `.background(LiquidGlassTheme.cardTint)`
  - overlay: `LiquidGlassTheme.glow` + `LiquidGlassTheme.stroke`
  - shadow
- Keep 4-button HStack layout
- Each button: LiquidGlass card style matching ADB feature tiles

### GenericFastbootFlashCardView.swift
- Remove outer `.padding(14)` + `.background` + overlay + shadow
  - The card inside (`mainCard`) already provides these
  - Single-layer LiquidGlass card
- Remove `accent` parameter; use `Color.red` directly
- Keep three-step tabs at top
- Keep image/path input, partition input, dropdown menu, command preview

### Placeholder Cards (Xiaomi / Oplus)
- Replace with uniform LiquidGlass card (same as generic but disabled)
- Show mode title + a note + device status

## Color / Theme
- Outer panel: `LiquidGlassTheme.panelBackground` (ultraThinMaterial) — no change
- Reboot card: `LiquidGlassTheme.cardBackground` + `cardTint` + glow + stroke
- Flash card: `LiquidGlassTheme.cardBackground` + `cardTint` + glow + stroke
- Flash accent: system `.red` for step indicator numbers, flash button, selected mode, mode selector
- Remove custom `fastbootAccent` / `fastbootPageBackground` / `fastbootBorder`

## Layout

| View | Padding | Background | Overlay |
|------|---------|------------|---------|
| FastbootPanelView | `.padding(20)` | `.ultraThinMaterial` | 20pt rounded + stroke |
| RebootSection | `.padding(14)` | `cardBackground + cardTint` | glow + stroke |
| GenericFlashCard (inner) | `.padding(14)` | `cardBackground` | secondaryStroke |

## Edge Cases
- No device connected: all flash buttons disabled, mode selector still interactive
- Xiaomi / Oplus modes: show placeholder card with same LiquidGlass styling
- Flash in progress: `isBusy` disables reboot buttons and flash button
