#pragma once

#include <cstdint>
#include <iomanip>
#include <iostream>

template <typename T>
void debugArray2D(T* arr, const size_t width, const size_t height, const size_t maxValue) {
    uint32_t w=1;
    for (uint32_t c=10, t=maxValue; t>c; w++, c*=10){}
    std::cout << std::endl;
    for (auto i=0; i<height; ++i) {
        std::cout << '|';
        for (auto j=0; j<width; ++j) {
            std::cout << std::setw(static_cast<int>(w)) << std::setfill(' ') << arr[i*width+j] << '|';
        }
        std::cout << std::endl;
    }
    std::cout << std::endl;
}
