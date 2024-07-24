#include <array>
#include <cstddef>
#include <cstdint>
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
   // use a vector with null termination instead of a std::string to avoid
   // small string optimization to hide bounds problems
   std::vector<char> buffer{Data, Data + Size};
   buffer.push_back('\0');

   [[maybe_unused]] auto s = glz::read_json<A>(std::string_view{buffer.data(), Size});
   if (s) {
      // hooray! valid json found
   }
   return 0;
}
