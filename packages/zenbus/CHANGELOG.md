# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-02-03

### Added
- Initial release of ZenBus
- Three implementation strategies:
  - Stream-based implementation
  - Signal-based implementation  
  - Alien Signal-based implementation (recommended)
- Type-safe event bus with generics support
- Event filtering with `where` parameter
- Comprehensive performance benchmarks
- Comprehensive memory benchmarks
- Detailed documentation with examples
- Performance and memory benchmark reports

### Performance Highlights
- Alien Signal implementation: Up to 8.6M ops/s with 100 listeners
- Stream implementation: 1.9M ops/s baseline performance
- Signal implementation: 6.9M ops/s with good scaling

### Memory Efficiency
- Alien Signal: Most memory efficient (3.4KB per listener)
- Stream: Good listener memory (3.1KB per listener)
- Signal: Higher memory usage (8.3KB per listener)

[0.0.1]: https://github.com/definev/zenquery/releases/tag/zenbus-v0.0.1
