// Types both C++ units use, so -fdebug-types-section puts each in a type unit
// that the units share.
#include <functional>
#include <map>
#include <memory>
#include <string>

struct Shape {
  virtual ~Shape();
  virtual double area() const;
  std::string name;
  std::map<int, double> props;
  std::function<double()> scale;
};

extern Shape gshape;
extern std::map<int, double> gmap;
extern std::shared_ptr<Shape> gptr;
extern std::function<double()> gfun;
extern std::_Rb_tree_node_base gnode;
