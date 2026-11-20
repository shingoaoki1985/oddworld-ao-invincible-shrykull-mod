# Oddworld: Abe's Oddysee — Invincible + Infinite Shrykull (R.E.L.I.V.E.)

**English** | [日本語](README_JA.md)

A source patch for running the Steam version of *Oddworld: Abe's Oddysee* with R.E.L.I.V.E. and adding the following features:

- Permanent Abe invincibility
- Shrykull available immediately, including in a new game where it has never been acquired
- Unlimited Shrykull reuse without consuming the ability
- Shrykull ownership and resources preserved across screen changes and respawns
- Experimental correction for the Steam Japanese font-atlas mismatch
- No changes to the existing controller configuration

This is an unofficial fan modification. It is not an official product of Oddworld Inhabitants or AliveTeam.

## Gameplay demo

[▶ Watch the 74-second 720p gameplay demo](media/oddworld-invincible-infinite-shrykull-demo-720p.mp4)

The recording demonstrates Shrykull in an early-game area without completing the normal acquisition event, repeated use after returning to Abe, survival under enemy attacks, and the Steam Japanese game data running through the modified R.E.L.I.V.E. build.

## What is R.E.L.I.V.E.?

[R.E.L.I.V.E.](https://github.com/AliveTeam/alive_reversing) is a fan-made, open-source engine reimplementation developed by AliveTeam. It targets the first two Oddworld games:

- *Oddworld: Abe's Oddysee* (`AO` in the source tree)
- *Oddworld: Abe's Exoddus* (`AE` in the source tree)

R.E.L.I.V.E. does not replace or distribute the games' assets. It is a new executable engine that reads LVL archives, movies, audio, and other data from a legally obtained copy of the original game. Because the original game logic has been reimplemented in C++, modifications can be made in terms of the engine's actual game state instead of guessing protected executable offsets at runtime.

The main goals of R.E.L.I.V.E. include:

- Reimplementing the Oddysee and Exoddus engines
- Supporting modern Windows, Linux, and SDL environments
- Fixing bugs inherited from the original games
- Providing a foundation for level editing and mod development
- Studying and preserving the behavior of the original engines

R.E.L.I.V.E. is not primarily a cheat-distribution project. However, it exposes reimplemented source for the original invulnerability flag, level-selection and debug logic, Shrykull ownership, and Shrykull consumption. That makes a feature such as this mod possible without guessing fixed memory addresses.

This mod primarily changes the Oddysee side of R.E.L.I.V.E. under `Source/AliveLibAO`. It does not merely enable a pre-existing “Infinite Shrykull” option. It connects and modifies several separate systems:

- Abe's existing invulnerability flag
- Early loading of Shrykull transformation resources
- Continuous ownership and availability-timer maintenance
- Suppression of consumption when Shrykull ends
- Resource retention across screen changes and respawns
- Selection of font coordinates for the Steam Japanese release

### Official links and upstream base

- [R.E.L.I.V.E. official GitHub repository](https://github.com/AliveTeam/alive_reversing)
- [AliveTeam website](https://aliveteam.github.io/)
- [R.E.L.I.V.E. releases](https://github.com/AliveTeam/alive_reversing/releases)
- [Base commit used by this patch: `3be8967`](https://github.com/AliveTeam/alive_reversing/commit/3be8967b71b29e6e61009d291bd64dce39abf7ac)

This repository is not an official AliveTeam branch or release. Before reporting an issue upstream, verify whether it also occurs in an unmodified R.E.L.I.V.E. build.

## Feature specification

### 1. Permanent Abe invincibility

The patch enables the original-game invulnerability flag reimplemented by R.E.L.I.V.E., `gAbeInvulnerableCheat_5076E4`, from engine startup. This is a source-level change to the existing game-state check, not an external trainer that guesses and writes to a process address.

Abe is protected from common damage paths such as:

- Slig gunfire
- Normal attacks by Slogs, Scrabs, Paramites, and similar enemies
- Explosions and many hazardous objects
- Attacks routed through the usual damage and death handlers

The following may bypass the normal damage handler and are not guaranteed to be blocked:

- Falling out of the screen or into a bottomless pit
- Story-driven forced transitions
- Special scripted deaths or resets
- Direct map reloads performed by the engine

### 2. Shrykull without acquiring it first

Normally, Oddysee only allows Shrykull after the player satisfies an acquisition event such as the relevant bird-portal condition. With this patch, a new game and an existing save that never acquired Shrykull can transform immediately by chanting while Abe is idle.

Setting only an ownership flag is insufficient: a never-acquired playthrough has not loaded the transformation resources. The patch therefore implements all of the following as one feature:

- Loads Abe/Shrykull morph animations from `SHRYPORT.BND` when missing
- Loads the Shrykull attack spline from `SPLINE.BAN` when missing
- Enables current ownership through `field_16C_bHaveShrykull`
- Enables the restoration state through `field_154_bSavedHaveShrykull`
- Continuously refreshes `field_168_ring_pulse_timer` to 32,000 frames beyond the current frame

This happens when Abe is constructed and while gameplay is updating. Loading an old save without Shrykull therefore grants it immediately. The installer does not directly rewrite an existing save file; normal in-game saving may still update the save as usual.

### 3. Unlimited Shrykull reuse

In the original flow, when Shrykull kills a target and the transformation exits, the ring timer is consumed. This patch keeps `field_122_bResetRingTimer` clear inside `Shrykull::VUpdate_463AE0()`, preventing the exit path from clearing Abe's availability timer. Abe can chant and transform again immediately after returning to normal.

The ability and its required resources are also preserved across:

- Screen changes within a level
- Transitions to another level
- Abe's death and respawn
- Loading a save that never acquired Shrykull
- Completing a previous Shrykull use

In other words, this is not merely “unlimited after acquiring it once.” **The acquisition event is unnecessary: Shrykull is available from the start and remains reusable without a usage limit.**

### 4. Steam Japanese font support

The standard R.E.L.I.V.E. Oddysee renderer uses fixed English atlas tables containing 116 menu entries and 104 LCD entries. The Steam Japanese release uses different glyph placement and a larger character set, so applying the English coordinates to the Japanese font textures selects unrelated glyphs.

This patch loads coordinate tables generated locally by the user from the verified Japanese `AbeWin.exe`:

- Menu font: 238 entries
- LCD/status-board font: 238 entries
- Combined file size: 1,904 bytes

English labels added by R.E.L.I.V.E. itself are mapped to the uppercase Latin letters and digits present in the Japanese font textures. If the atlas file is missing or has an invalid size, the engine continues with the original English tables and writes a warning to the log instead of aborting.

Japanese support is experimental and specific to the verified Steam executable. The Japanese textures do not contain a complete general-purpose set of ASCII lowercase letters and punctuation. R.E.L.I.V.E.-specific English labels are therefore rendered in uppercase, and unsupported punctuation is treated as spacing. Complete Japanese rendering of every screen and every message is not guaranteed.

### 5. Controller behavior

The patch does not modify input handling, button mappings, or `abe.ini`. Controller support is inherited unchanged from R.E.L.I.V.E. and SDL3. A Nintendo Switch Pro Controller was detected in the test environment, but this project contains no device-specific mapping changes.

### 6. Launch behavior and original-file safety

- Forces the custom executable to run Abe's Oddysee (`AO`)
- Can locate the game root when used in the tested nested mod layout
- Does not overwrite the original `AbeWin.exe`, LVL archives, movies, or audio
- Allows the original game and the modified engine to remain separately launchable
- Does not apply a guessed fixed-address patch to the protected Steam executable

To return to the original game, exit the modified executable and launch the game through Steam or the original `AbeWin.exe`.

## Repository contents

This repository does **not** contain the game, extracted game-data files, the original executable, a pre-extracted font table, the complete R.E.L.I.V.E. source tree, or a compiled modified executable. It contains only a short user-recorded gameplay demonstration.

- `patches/invincible-infinite-shrykull-japanese.patch` — complete changes to apply to upstream R.E.L.I.V.E.
- `tools/Extract-JapaneseFontAtlas.ps1` — generates the Japanese coordinate table locally from the user's legally obtained Steam installation
- `NOTICE.md` — upstream attribution, supported version, and redistribution notes
- `README_JA.md` — full Japanese documentation
- `media/oddworld-invincible-infinite-shrykull-demo-720p.mp4` — compressed 74-second gameplay demonstration

## Supported build

- Steam App ID: `15700`
- Steam build ID: `252109`
- Upstream R.E.L.I.V.E. commit: `3be8967b71b29e6e61009d291bd64dce39abf7ac`
- `AbeWin.exe` SHA-256: `86D982094B9426F934B1B1925DA44766BBB524D430D203A5B94DC16F036C48E1`
- Tested on Windows x64 with SDL 3.4.18

The font-extraction offsets may differ in other releases. The extraction tool refuses to process an executable whose SHA-256 does not match the verified build.

## Build instructions

### 1. Obtain R.E.L.I.V.E.

```powershell
git clone --recursive https://github.com/AliveTeam/alive_reversing.git
cd alive_reversing
git checkout 3be8967b71b29e6e61009d291bd64dce39abf7ac
```

### 2. Apply the patch

```powershell
git apply C:\path\to\invincible-infinite-shrykull-japanese.patch
```

Use `git apply --check` first if you only want to verify that the patch can be applied.

### 3. Build x64 Release

Follow the upstream R.E.L.I.V.E. instructions to install CMake, Visual Studio, and SDL3.

```powershell
cmake -S . -B build-mod -A x64 -DSDL3_DIR=C:\path\to\SDL3\cmake
cmake --build build-mod --config Release --target relive
```

## Generate the Japanese font table

Exit the game, then run:

```powershell
.\tools\Extract-JapaneseFontAtlas.ps1 `
  -GameDirectory "D:\SteamLibrary\steamapps\common\Oddworld Abes Oddysee" `
  -OutputPath "C:\path\to\mod\japanese_font_atlas.bin"
```

The tool starts the verified original `AbeWin.exe` invisibly for a short time and reads only the two 238-entry coordinate tables from its unpacked memory. It does not modify the original executable, LVL archives, configuration, or save files.

Expected output:

- Size: `1,904 bytes`
- SHA-256: `235E5B729CFFC9C1C818BEF553926DEC1CEA025A9E0BE41A5D0A3E6F2DE03C89`

## Installation

Place the built `relive.exe`, the corresponding `SDL3.dll`, and the generated `japanese_font_atlas.bin` in the same mod directory. Start the executable with the Steam Oddysee directory as its working directory.

The original `AbeWin.exe` is not overwritten. Launch Steam or the original executable whenever you want to play the unmodified game.

## Verification checklist

1. Start a new game or load a save where Shrykull has never been acquired.
2. Chant while Abe is idle and confirm that he transforms into Shrykull.
3. After Shrykull ends, chant again and confirm that it can be reused.
4. Confirm that ordinary enemy attacks and explosions do not kill Abe.
5. Check menu, pause-screen, and LCD/status-board text.
6. Confirm that the existing controller setup still operates normally.

## Credits

- [AliveTeam / R.E.L.I.V.E.](https://github.com/AliveTeam/alive_reversing)
- [SDL](https://github.com/libsdl-org/SDL)
- *Oddworld: Abe's Oddysee* © its respective rights holders

The original documentation and extraction tool in this repository are released under the MIT License. The patch is applied to R.E.L.I.V.E. source and remains subject to the upstream project and third-party component terms described in `NOTICE.md`.


