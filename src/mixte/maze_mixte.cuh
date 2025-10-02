#pragma once

#ifndef __CUDACC__
  #define HD
  #define HDI inline
#else
  #define HD __host__ __device__
  #define HDI __host__ __device__ inline
#endif

template<UnsignedIntegral U, typename T>
HDI T getGridElementValueOf_Impl(const size_t h, const size_t w, const size_t i, const size_t j,
                            const size_t wallVerticalSize, const size_t wallHorizontalSize, const U *pathValueIndices,
                            const T *pathValues, U maxPathValueIndex, T wallAngleValue, T wallVerticalValue,
                            T wallHorizontalValue, const bool *vWall, const bool *hWall, const size_t mazeWidth) {
    const bool hBorder = i<wallVerticalSize || i>=h-wallVerticalSize;
    const bool vBorder = j<wallHorizontalSize || j>=w-wallHorizontalSize;
    if (hBorder) return vBorder ? wallAngleValue : wallHorizontalValue;
    const bool input = i<2*wallVerticalSize && j<wallHorizontalSize;
    const bool output = i>=h-2*wallVerticalSize && j>=w-wallHorizontalSize;
    if (vBorder) {
        if (input) return pathValueIndices ? pathValues[pathValueIndices[0]] : pathValues[maxPathValueIndex];
        if (output) return pathValues[0];
        return wallVerticalValue;
    }
    const size_t y = (i-wallVerticalSize)/(wallVerticalSize+1);
    const bool isHWall = (i-wallVerticalSize)%(wallVerticalSize+1) == wallVerticalSize;
    const size_t x = (j-wallHorizontalSize)/(wallHorizontalSize+1);
    const bool isVWall = (j-wallHorizontalSize)%(wallHorizontalSize+1) == wallHorizontalSize;
    if (isHWall && isVWall) return wallAngleValue;
    const auto index = y * mazeWidth + x;
    const auto pathValue = pathValueIndices ? pathValues[pathValueIndices[index]] : *pathValues;
    if (isHWall) return hWall[index] ? wallHorizontalValue : pathValue;
    if (isVWall) return vWall[y*(mazeWidth-1)+x] ? wallVerticalValue : pathValue;
    return pathValue;
}