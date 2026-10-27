#include "shapes.h"

Shape::~Shape() {}
double Shape::area() const { return props.empty() ? 0 : props.begin()->second; }

Shape gshape;
std::map<int, double> gmap;
std::shared_ptr<Shape> gptr;
std::function<double()> gfun;
std::_Rb_tree_node_base gnode;
