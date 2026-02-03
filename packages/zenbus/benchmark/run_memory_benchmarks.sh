#!/bin/bash

# Script to run all memory benchmarks in isolation and generate a report

echo "========================================================================"
echo "ZenBus Memory Benchmarks - Running All Tests in Isolation"
echo "========================================================================"
echo ""

# Run each benchmark and capture output
echo "Running Bus Creation benchmark..."
dart run --observe benchmark/memory_bus_creation.dart > /tmp/zenbus_mem_bus_creation.txt 2>&1
echo "✓ Bus Creation complete"
echo ""

echo "Running Listener Registration benchmark..."
dart run --observe benchmark/memory_listeners.dart > /tmp/zenbus_mem_listeners.txt 2>&1
echo "✓ Listener Registration complete"
echo ""

echo "Running Filtered Listener Registration benchmark..."
dart run --observe benchmark/memory_filtered_listeners.dart > /tmp/zenbus_mem_filtered_listeners.txt 2>&1
echo "✓ Filtered Listener Registration complete"
echo ""

# Display results
echo "========================================================================"
echo "MEMORY BENCHMARK RESULTS"
echo "========================================================================"
echo ""

echo "1. BUS CREATION (1000 instances)"
echo "------------------------------------------------------------------------"
cat /tmp/zenbus_mem_bus_creation.txt | grep -A 5 "Testing each implementation"
echo ""

echo "2. LISTENER REGISTRATION (1000 listeners per bus)"
echo "------------------------------------------------------------------------"
cat /tmp/zenbus_mem_listeners.txt | grep -A 5 "Testing each implementation"
echo ""

echo "3. FILTERED LISTENER REGISTRATION (1000 listeners per bus)"
echo "------------------------------------------------------------------------"
cat /tmp/zenbus_mem_filtered_listeners.txt | grep -A 5 "Testing each implementation"
echo ""

echo "========================================================================"
echo "✅ All memory benchmarks complete!"
echo "========================================================================"
echo ""
echo "Full logs saved to:"
echo "  - /tmp/zenbus_mem_bus_creation.txt"
echo "  - /tmp/zenbus_mem_listeners.txt"
echo "  - /tmp/zenbus_mem_filtered_listeners.txt"
