#pragma once
#include <concepts>

struct Backend {};

template <typename T>
concept Backend_T = std::derived_from<T, Backend> && !std::same_as<Backend, T>;

struct BackendCUDA : Backend {};
struct BackendCPU : Backend {};