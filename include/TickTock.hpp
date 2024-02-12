#ifndef TICK_TOCK_HPP
#define TICK_TOCK_HPP

#include <chrono>
#include <filesystem>
#include <functional>
#include <map>
#include <utility>

#define DEFAULT_ITERATIONS 1000000

using TickTock = struct TickTock {
public:
  using Duration = std::chrono::milliseconds;
  using DurationUnit = long;
  using IterationsToDurationsMap = std::map<size_t, std::vector<DurationUnit>>;
  using AlgorithmInfoPair =
      std::pair<std::function<void()>, IterationsToDurationsMap>;

  TickTock() = default;
  ~TickTock() = default;

  static constexpr const char *const time_unit_string = "ms";

private:
  std::vector<AlgorithmInfoPair> measurements{};

public:
  void measure();
  void printStats() const;
  double average() const;
  bool save(const std::filesystem::path &path) const;
  TickTock &add_algorithm(const std::function<void()> &function,
                          const std::vector<size_t> &iterations);
};

#endif // !TICK_TOCK_HPP
