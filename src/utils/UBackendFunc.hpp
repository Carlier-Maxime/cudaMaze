#pragma once

#include <stdexcept>

#include "../backend/Backend.h"
#include "math_utils.hpp"

struct UBackendFunc {
    template <UnsignedIntegral U, Backend_T Backend>
    void call() {}
};

template <typename T>
concept UBackendFunc_T = std::derived_from<T, UBackendFunc> && !std::same_as<UBackendFunc, T>;

template <UnsignedIntegral U, Backend_T Backend, UBackendFunc_T UBackendFunc>
bool tryCallUBackendFunc(const size_t max, UBackendFunc& func) {
    if (static_cast<size_t>(std::numeric_limits<U>::max()) >= max) {
        func.template call<U, Backend>();
        return true;
    }
    return false;
}

template <UBackendFunc_T UBackendFunc, Backend_T Backend, UnsignedIntegral... Us>
void selectAndCallUBackendFunc(const size_t max, UBackendFunc& func) {
    if constexpr (sizeof...(Us) == 0) {
        selectAndCallUBackendFunc<UBackendFunc, Backend, uint8_t, uint16_t, uint32_t, uint64_t>(max, func);
    } else {
        const bool built = (tryCallUBackendFunc<Us, Backend>(max, func) || ...);
        if (!built) throw std::runtime_error("selectAndCall failed: size is too big");
    }
}
