#include "pathfinder_node.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void PathfinderNode::_bind_methods() {
    // Expose methods to GDScript
    ClassDB::bind_method(D_METHOD("get_extension_status"), &PathfinderNode::get_extension_status);
}

PathfinderNode::PathfinderNode() {
    // Constructor
}

PathfinderNode::~PathfinderNode() {
    // Destructor
}

void PathfinderNode::_process(double delta) {
    // Hot loop hook for future frame-budgeted path processing
}

String PathfinderNode::get_extension_status() const {
    return "GDExtension active: C++ backend linked.";
}