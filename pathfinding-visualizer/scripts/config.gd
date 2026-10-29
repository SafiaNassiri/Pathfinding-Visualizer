class_name Config
extends RefCounted
## Single source of truth for grid constants on the GDScript side.
## Must match extension/src/config.h. See docs/grid-decisions.md.

const GRID_W := 64
const GRID_H := 64
const TILE_SIZE := 16
const CHUNK_SIZE := 16

# Power-of-two shifts, so index math can use bit operations.
const GRID_SHIFT := 6   # GRID_W == 1 << 6 (64)
const CHUNK_SHIFT := 4  # CHUNK_SIZE == 1 << 4 (16)

# Derived values
const CHUNKS_X := GRID_W >> CHUNK_SHIFT
const CHUNKS_Y := GRID_H >> CHUNK_SHIFT
const WORLD_W := GRID_W * TILE_SIZE
const WORLD_H := GRID_H * TILE_SIZE
