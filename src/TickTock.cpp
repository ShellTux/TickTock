#include "TickTock.hpp"
#include <chrono>
#include <fstream>
#include <iostream>
#include <ostream>
#include <utility>

TickTock &TickTock::add_algorithm(const std::function<void()> &function,
                                  const std::vector<size_t> &all_iterations) {
  IterationsToDurationsMap map = {};
  for (const size_t &iterations : all_iterations) {
    map[iterations] = {};
  }

  measurements.push_back(std::make_pair(function, map));
  return *this;
}

void TickTock::measure() {
  for (size_t i = 0; i < measurements.size(); ++i) {
    const std::function<void()> function = measurements.at(i).first;
    IterationsToDurationsMap &map = measurements.at(i).second;
    for (auto &[iterations, durations] : map) {
      using std::chrono::duration_cast;
      using std::chrono::milliseconds;
      using std::chrono::time_point;

      const time_point start = std::chrono::high_resolution_clock::now();
      for (size_t iteration = 0; iteration < iterations; ++iteration) {
        function();
      }
      const time_point end = std::chrono::high_resolution_clock::now();

      const long duration = duration_cast<Duration>(end - start).count();
      durations.push_back(duration);
    }
  }
}

void TickTock::printStats() const {
  if (measurements.size() == 0) {
    // TODO: Implement this case
    std::cerr << "No measurements" << std::endl;
    return;
  }

  for (size_t index = 0; index < measurements.size(); ++index) {
    const IterationsToDurationsMap &map = measurements.at(index).second;
    for (const auto &[iterations, actualMeasuredIterations] : map) {
      for (const auto &time : actualMeasuredIterations) {
        std::cout << "Algorithm " << index + 1 << ", Iterations: " << iterations
                  << ", Time: " << time << "ms" << std::endl;
      }
    }
  }
}

bool TickTock::save(const std::filesystem::path &path) const {
  std::ofstream outputFile(path);

  if (!outputFile.is_open()) {
    std::cerr << "Error opening file: " << path << std::endl;
    return false;
  }

  // TODO: Replace Hardcoded string
  outputFile << "Algorithm;Iterations;Time(ms)" << std::endl;

  for (size_t index = 0; index < measurements.size(); ++index) {
    const IterationsToDurationsMap &map = measurements.at(index).second;
    for (const auto &[iterations, actualMeasuredIterations] : map) {
      for (const auto &time : actualMeasuredIterations) {
        outputFile << index + 1 << ";" << iterations << ";" << time
                   << std::endl;
      }
    }
  }

  outputFile.close();
  std::cout << "File written successfully." << std::endl;

  return true;
}
