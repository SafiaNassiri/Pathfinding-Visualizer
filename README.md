# Pathfinding-Visualizer

A sandbox simulation that visually demonstrates advanced pathfinding architectures: hundreds of agents navigating a user-editable grid using a hybrid macro/micro A\* system, with batched CPU optimization and a C++ GDExtension for the hot path.

> **Status:** Early development. See the [Development Plan](#development-plan) for progress.

<!-- TODO: add demo GIF here once Phase 3 is done -->
<!-- ![demo](docs/media/demo.gif) -->

## Tech Stack

- **Engine:** Godot 4
- **Languages:** GDScript, C++ (GDExtension via [godot-cpp](https://github.com/godotengine/godot-cpp))
- **Target:** Desktop (Windows / Linux / macOS)

## Key Features

- **Hybrid macro/micro A\*:** a coarse cluster graph for long-range routing, fine grid A\* for local refinement
- **Hundreds of simultaneous agents** routing around user-placed obstacles in real time
- **Multi-agent CPU batch optimization:** time-sliced path requests, shared work, per-frame budgeting
- **Y-sort depth snapping** so overlapping entities and obstacles render correctly
- **Live algorithm visualization:** open/closed sets, cluster borders, portals, and path overlays
- **Benchmarks:** GDScript vs. C++ GDExtension, with real numbers

## Architecture (planned)

```
Agents ──► Path Request Queue ──► Macro Planner (cluster graph A*)
                │                         │
                │                         ▼
                └──────────────► Micro Planner (grid A* per cluster)
                                          │
                                          ▼
                                   Path Cache / Smoothing
```

| Layer     | Responsibility                                                |
| --------- | ------------------------------------------------------------- |
| Grid      | Walkability data, obstacle editing, cluster partitioning      |
| Macro     | Abstract graph of cluster entrances, long-range A\*           |
| Micro     | Fine A\* inside/between clusters, path refinement             |
| Scheduler | Queues requests, enforces per-frame time budget, batches work |
| Agents    | Movement along paths, repath on invalidation                  |
| Viz       | Debug overlays, stats panel, comparison tools                 |

## Project Structure (planned)

```
Pathfinding-Visualizer/
├── project.godot
├── scenes/
├── scripts/
│   ├── grid/
│   ├── pathfinding/
│   ├── agents/
│   └── ui/
├── gdextension/        # C++ source, SConstruct, .gdextension file
├── docs/               # notes, benchmarks, media
└── README.md
```

## Getting Started

```bash
git clone https://github.com/SafiaNassiri/Pathfinding-Visualizer.git
cd Pathfinding-Visualizer
# Open the project in Godot 4.x
```

C++ extension build instructions will be added in Phase 6.

---

## Development Plan

Check items off as they get done. Each phase should leave the project in a runnable state.

### Phase 0: Setup

- [x] Create Godot 4 project and commit base structure
- [x] Add `.gitignore` (Godot + C++ build artifacts) and `.gitattributes`
- [x] Pick license and add `LICENSE`
- [x] Set up folder layout (scenes, scripts, docs)
- [x] Add godot-cpp as a submodule and confirm an empty GDExtension loads
- [ ] Decide fixed grid size and tile size (document in `docs/`)

### Phase 1: Grid and Sandbox

- [ ] Grid data structure (walkable/blocked, cost per cell)
- [ ] Grid rendering (TileMap or custom draw)
- [ ] Camera pan and zoom
- [ ] Click-and-drag obstacle placement and erasing
- [ ] Start/goal placement
- [ ] Save/load maps (JSON or Resource)
- [ ] Random obstacle generator for stress tests

### Phase 2: Baseline A\* (single agent, GDScript)

- [ ] Binary heap priority queue
- [ ] A\* with 4- and 8-directional movement
- [ ] Heuristic options (Manhattan, Octile, Euclidean)
- [ ] Visualize open/closed sets and final path
- [ ] Step-through mode (play / pause / step)
- [ ] Stats readout (nodes expanded, path length, time in ms)
- [ ] Unit tests for correctness (known maps, unreachable goal, edge cases)

### Phase 3: Agents and Rendering

- [ ] Agent scene and movement along a path
- [ ] Spawner (click to spawn, spawn N at once)
- [ ] Simple local avoidance or separation
- [ ] Y-sort depth snapping for agents and obstacles
- [ ] Agent colors / IDs for readability
- [ ] Scale to 100+ agents with naive per-agent A\* (this is your "before" benchmark)

### Phase 4: Hybrid Macro/Micro A\*

- [ ] Partition grid into clusters (e.g. 10x10)
- [ ] Detect cluster entrances / portals
- [ ] Build abstract graph with intra-cluster edge costs
- [ ] Macro A\* over the abstract graph
- [ ] Micro refinement: fine A\* between portals
- [ ] Insert start/goal into the abstract graph on demand
- [ ] Incremental graph rebuild when obstacles change (only affected clusters)
- [ ] Debug overlay for clusters, portals, and macro path
- [ ] Compare path quality and speed against flat A\*

### Phase 5: Multi-Agent Batch Optimization

- [ ] Path request queue
- [ ] Per-frame time budget (time-sliced pathfinding)
- [ ] Request prioritization (e.g. closest-to-goal or oldest-first)
- [ ] Path cache for repeated start/goal pairs
- [ ] Group agents with shared goals (shared macro path or flow field)
- [ ] Spatial hashing for neighbor queries
- [ ] Repath throttling when obstacles change
- [ ] Profile with Godot's profiler and record findings

### Phase 6: C++ GDExtension

- [ ] Port grid data and binary heap to C++
- [ ] Port micro A\* hot loop
- [ ] Port macro graph search
- [ ] Expose clean API to GDScript
- [ ] Cross-platform build (SCons) and CI build check
- [ ] Benchmark GDScript vs. C++ and record results

### Phase 7: UI and Visualization Polish

- [ ] Toggle panel for overlays (open/closed, clusters, paths, heatmap)
- [ ] Live stats panel (FPS, agent count, queue length, avg path time)
- [ ] Algorithm selector (flat A\* vs. hybrid, GDScript vs. C++)
- [ ] Agent count slider
- [ ] Presets / demo scenes (maze, open field, bottleneck)

### Phase 8: Documentation and Release

- [ ] Benchmarks table (below) filled in with real numbers
- [ ] Demo GIFs / screenshots in `docs/media/`
- [ ] Write-up of the hybrid A\* design (`docs/architecture.md`)
- [ ] Exported builds for at least one platform
- [ ] Tag `v0.1.0` and publish a GitHub release
- [ ] Pin the repo on GitHub

### Stretch Goals

- [ ] Flow fields for very large groups
- [ ] Jump Point Search as another baseline
- [ ] Weighted terrain (mud, roads)
- [ ] Dynamic moving obstacles
- [ ] Multi-threaded batch processing via WorkerThreadPool

---

## Benchmarks

_To be filled in as phases complete._

| Agents | Flat A\* (GDScript) | Hybrid (GDScript) | Hybrid (C++) |
| ------ | ------------------- | ----------------- | ------------ |
| 50     | -                   | -                 | -            |
| 200    | -                   | -                 | -            |
| 500    | -                   | -                 | -            |
| 1000   | -                   | -                 | -            |

Metrics: average frame time (ms), avg path computation (ms), nodes expanded.

## Notes and References

- [Hierarchical Pathfinding A* (HPA*), Botea et al.](https://www.researchgate.net/publication/228785110_Near_optimal_hierarchical_path-finding_HPA)
- [Amit Patel's Red Blob Games: A\* and grid pathfinding](https://www.redblobgames.com/pathfinding/a-star/introduction.html)
- Godot docs: [GDExtension](https://docs.godotengine.org/en/4.4/tutorials/scripting/gdextension/what_is_gdextension.html), [`AStarGrid2D`](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html)

## License

MIT. See [LICENSE](LICENSE).
