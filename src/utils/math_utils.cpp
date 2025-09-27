#include "math_utils.hpp"

size_t roundToNextPowerOfTwo(size_t a) {
    if (a == 0) return 0;
    a--;
    a |= a >> 1;
    a |= a >> 2;
    a |= a >> 4;
    a |= a >> 8;
    a |= a >> 16;
    return ++a;
}
