#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <glaze/glaze.hpp>
#include <vector>

struct A
{
   double x;
   int y;
};

template <>
struct glz::meta<A>
{
   static constexpr auto value = object("x", glz::quoted_num<&A::x>, "y", glz::quoted_num<&A::y>);
};

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* Data, size_t Size)
{
   if (Size < sizeof(A)) {
      return 0;
   }
   A a;

   std::memcpy(&a, Data, sizeof(A));

   auto str = glz::write_json(a).value_or(std::string{});
   if (str.empty()) {
      throw std::runtime_error(std::string{"failed serializing "} + std::to_string(a.x) + " and " +
                               std::to_string(a.y));
   }
   if (!std::isfinite(a.x)) {
      return 0;
   }
   auto restored = glz::read_json<A>(str);
   if (!restored) {
      throw std::runtime_error(std::string{"failed serializing "} + std::to_string(a.x) + " and " +
                               std::to_string(a.y) + " from " + str);
   }
   assert(restored);
   assert(restored.value().x == a.x);
   assert(restored.value().y == a.y);

   return 0;
}
