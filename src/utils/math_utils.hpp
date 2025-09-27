#pragma once

#include <concepts>
#include <cstdint>

uint32_t roundToNextPowerOfTwo(uint32_t a);

template<typename T>
T ceilDiv(T a, T b) {
    return (a + b - 1) / b;
}

template <typename T>
concept UnsignedIntegral = std::unsigned_integral<T>;