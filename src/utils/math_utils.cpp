#include "math_utils.hpp"

uint32_t roundToNextPowerOfTwo(uint32_t a) {
    if (a == 0) return 0;
    a--;
    a |= a >> 1;
    a |= a >> 2;
    a |= a >> 4;
    a |= a >> 8;
    a |= a >> 16;
    return ++a;
}
