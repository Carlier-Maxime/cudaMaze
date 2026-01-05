#pragma once

#include <concepts>
#include <cstddef>

size_t roundToNextPowerOfTwo(size_t a);

template<typename T>
T ceilDiv(T a, T b) {
    return (a + b - 1) / b;
}

template <typename T>
concept UnsignedIntegral = std::unsigned_integral<T>;

template<UnsignedIntegral U>
struct Position {
    U x;
    U y;

    Position(U _x, U _y) : x(_x), y(_y) {}
    Position() : x(0), y(0) {}
};