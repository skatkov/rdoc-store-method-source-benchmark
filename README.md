# RDoc Store Method Source Benchmark

Measures the cost of RDoc eagerly syntax-highlighting and retaining every Ruby method body when the selected generator does not render method source.

The benchmark uses RDoc's built-in `ri` generator by default.

## Optimization

Unknown and source-rendering generators keep the current behavior. RDoc's built-in RI and POT generators opt out because neither consumes `RDoc::AnyMethod#token_stream`; coverage mode also opts out because it generates no source pages.

```ruby
class RDoc::Generator::RI
  def self.store_method_source? = false
end

def syntax_highlighted_tokens(node)
  return [] unless store_method_source?

  super
end
```

Returning an empty stream preserves the existing method/token-stream shape while avoiding millions of `ColoredToken` objects and their fragmented source strings.

## Setup

```sh
bundle install
```

GNU `/usr/bin/time` and Linux `/proc/self/status` are required for peak and phase RSS measurements.

## Quick Check

```sh
bin/benchmark --source fixtures
```

## Full Benchmark

The default downloads and benchmarks `google-api-client` 0.53.0:

```sh
bin/benchmark
```

Benchmark another gem or format:

```sh
bin/benchmark --gem azure_mgmt_network --version 0.24.0
bin/benchmark --format pot --limit 100
bin/benchmark --gem rake --version 13.4.2 --format darkfish
bin/benchmark --source /path/to/project --format ri
```

`--limit` selects the first N Ruby files in sorted order. It is useful for comparing generators such as POT whose own output phase can be prohibitively slow on the complete Google client corpus.

`darkfish` is a useful control: it renders method source, so the optimized run should retain tokens and produce no meaningful memory reduction.

## Measurements

Each variant runs in a separate process. The profiler forces a full GC at phase boundaries and records:

- RSS and peak RSS from `/proc/self/status`
- GNU Time maximum RSS and elapsed time
- retained `ColoredToken` objects
- live Ruby heap slots
- parsed methods, classes/modules, and files

Results and generated output are stored under `tmp/results/<format>/`. The benchmark hashes every generated file except `created.rid` and fails if baseline and optimized output differ.

The baseline and optimized runs use the same locked RDoc version and inputs. Their only difference is loading `lib/store_method_source.rb` in the optimized process.

## Reference Result

RDoc 8.0.0 and `google-api-client` 0.53.0 on Ruby 4.0.6:

| Variant | Parse RSS | Peak RSS | Colored tokens | Live heap slots | Time |
| --- | ---: | ---: | ---: | ---: | ---: |
| Baseline | 1,069.4 MiB | 1,508.4 MiB | 3,900,930 | 10,031,484 | 61.72s |
| Optimized | 463.6 MiB | 730.0 MiB | 0 | 2,229,446 | 51.62s |

- Parse RSS reduction: 56.6%
- Peak RSS reduction: 51.6%
- Generated RI output: identical

POT on the first 100 sorted Google client Ruby files:

| Variant | Parse RSS | Peak RSS | Colored tokens | Time |
| --- | ---: | ---: | ---: | ---: |
| Baseline | 114.9 MiB | 198.4 MiB | 253,392 | 4.88s |
| Optimized | 75.1 MiB | 193.8 MiB | 0 | 3.62s |

The complete Google POT baseline did not finish within 20 minutes. That is a separate POT extraction bottleneck; use `--limit` to measure method-source retention without waiting for the full translation catalog.
