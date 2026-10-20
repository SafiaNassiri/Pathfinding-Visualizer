#pragma once

#include <godot_cpp/classes/node2d.hpp>

namespace godot {

class PathfinderNode : public Node2D {
    GDCLASS(PathfinderNode, Node2D)

protected:
    static void _bind_methods();

public:
    PathfinderNode();
    ~PathfinderNode();

    void _process(double delta) override;
    String get_extension_status() const;
};

} // namespace godot