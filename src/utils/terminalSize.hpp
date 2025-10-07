#pragma once

#include <tuple>
#include <iosfwd>

std::tuple<size_t, size_t> getTerminalSize(const std::ostream& os);
