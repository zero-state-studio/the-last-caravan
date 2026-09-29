class_name ChapterTuning
extends Resource
## The numbers of a chapter that are not creatures or Ottavia's combat:
## the Truce (39, 125), the turning platforms, the shortcuts. Starting values
## from the level document, to be tuned by playing; one file per chapter
## (assets/combat/chapter_01_tuning.tres), editable in the F1 panel.

@export_group("Truce")
## Length of the Truce on the sundial (chapter 1: 7 minutes).
@export var truce_seconds: float = 420.0
## A Voltacampi calls the warning this long before the end.
@export var truce_warning_seconds: float = 60.0
## Warm stones given back at the caravan at the start of the Truce (129).
@export var truce_warm_stones: int = 3

@export_group("Turning platforms")
## One pull of a lever: a quarter turn clockwise in this time (4).
@export var platform_turn_seconds: float = 1.5
## Day beasts carried by a turn turn back toward the sun this slowly:
## the window on their shaded flank (36).
@export var day_beast_flank_seconds: float = 2.0
