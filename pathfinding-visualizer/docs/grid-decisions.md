# Grid Decisions

**Status:** Accepted (v1)
**Scope:** Fixed grid, tile, and chunk sizes for the pathfinding visualizer.

## Summary

| Setting      | Value           | Notes                                  |
| ------------ | --------------- | -------------------------------------- |
| Grid size    | 256 × 256 cells | 65,536 cells total                     |
| Tile size    | 16 px           | World is 4096 × 4096 px                |
| Chunk size   | 16 × 16 cells   | 16 × 16 = 256 chunks in the macro grid |
| Cell storage | 1 byte per cell | ~64 KB for the whole grid              |

All values are compile-time constants, defined once on each side of the GDExtension boundary:

```gdscript
# godot/scripts/config.gd
const GRID_W := 256
const GRID_H := 256
const TILE_SIZE := 16
const CHUNK_SIZE := 16
```

```cpp
// extension/src/config.h
constexpr int GRID_W = 256;
constexpr int GRID_H = 256;
constexpr int TILE_SIZE = 16;
constexpr int CHUNK_SIZE = 16;
```

If you change one, change the other. A startup assertion in the extension should compare its constants against the values passed from GDScript and fail loudly on a mismatch.

## Rationale

### Why 256 × 256 cells

- **Real workload.** A path across a mostly open 65k-cell map expands thousands of nodes. That is enough for the GDScript baseline to be visibly slow, which makes the C++ and hierarchical speedups measurable rather than theoretical.
- **Still small.** The whole grid is about 64 KB at one byte per cell, so it fits comfortably in cache. Performance differences in benchmarks come from the algorithms and data layout, not from memory pressure.
- **Room for crowds.** Hundreds to low thousands of agents fit on the map without constant overlap, so local avoidance steering has space to matter.

### Why 16 px tiles

- The world is 4096 × 4096 px, so the full map fits on a typical screen at roughly 0.26 zoom, and you can zoom in far enough to see individual agents.
- 16 px leaves room for tall obstacle sprites (16 × 32 or 16 × 48), which makes the Y-sort depth snapping visually obvious.
- 4096 px is far below the range where 32-bit float precision causes problems.

### Why 16 × 16 cell chunks

- A 16 × 16 macro grid (256 chunks) keeps the portal graph small enough for fast macro A*, while each chunk is small enough that micro A* inside it is cheap.
- Dynamic obstacle edits only dirty one chunk (plus portals on its borders), so rebuilds stay local and cheap.

### Why powers of two

Every dimension is a power of two, so index math becomes bit operations in the hot path:

```cpp
int idx       = (y << 8) | x;           // cell index (GRID_W = 256)
int chunk_x   = x >> 4;                 // CHUNK_SIZE = 16
int chunk_y   = y >> 4;
int chunk_idx = (chunk_y << 4) | chunk_x;
int local_x   = x & 15;                 // position inside the chunk
int local_y   = y & 15;
```

If any size stops being a power of two, these shortcuts silently break. Treat the constraint as a rule, and `static_assert` it in `config.h`.

## Alternatives considered

| Option                                  | Why not (for v1)                                                                                                                  |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 128 × 128 at 32 px (same 4096 px world) | Chunkier, more readable tiles, but a quarter of the cells weakens the performance story.                                          |
| 512 × 512 at 8 px                       | 262k cells makes the editing overlay and chunk rebuilds more work, and adds little to the demo. Tiles also get too small to read. |
| 64 × 64                                 | Too small. A\* in GDScript would finish instantly and the benchmarks would be uninteresting.                                      |
| Variable grid size at runtime           | Adds allocation and bounds-handling complexity to the hot path. Deferred to a stretch goal.                                       |

## Consequences

- Coordinates, indices, and chunk lookups can use bit shifts and masks.
- Grid storage can be a single flat array with no per-cell allocation.
- Benchmark results are only comparable across runs with the same constants, so record them in `docs/benchmarks.md` alongside every result.
- Supporting other sizes later means replacing the constants with runtime values and removing the bit-shift shortcuts. Plan for that as its own change, not a quick edit.

## Revisit if

- Profiling shows the macro graph is too large or too small for good query times (try 8 × 8 or 32 × 32 chunks first).
- The visual demo needs larger on-screen tiles (consider 128 × 128 at 32 px).
- A feature requires non-square or runtime-resizable maps.
