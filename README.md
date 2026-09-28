# RangeColor

WoW 3.3.5a addon. Colors action bar icons when out of range — same `IsActionInRange` check the default hotkey uses.

Works on default action bars: ActionButton, MultiBar BottomLeft/BottomRight/Right/Left.

## Features

- Icon turns your color when spell/item is out of range
- Out-of-mana color (same as Bartender default)
- Color picker options frame
- Saved variables

## Usage

- `/rangecolor` or `/rcolor` — open options
- `/rangecolor range` — pick out-of-range color
- `/rangecolor mana` — pick out-of-mana color
- `/rangecolor reset` — reset defaults

## Install

Copy `RangeColor` folder into `Interface/AddOns/`.

## Notes

- No dependencies (no Ace3)
- Hooks `ActionButton_OnUpdate`, `ActionButton_UpdateUsable`, `ActionButton_Update`
- Also sweeps all default bar buttons every 0.1s
