# frozen_string_literal: true

require "json"
require "objspace"
require "rdoc/rdoc"
require "rdoc/parser/ruby"

module RDocProfile
  module_function

  def sample(label, rdoc)
    GC.start
    status = File.read("/proc/self/status")
    store = rdoc.instance_variable_get(:@store)

    samples << {
      label:,
      rss_kb: status[/^VmRSS:\s+(\d+)/, 1].to_i,
      peak_rss_kb: status[/^VmHWM:\s+(\d+)/, 1].to_i,
      heap_live_slots: GC.stat(:heap_live_slots),
      colored_tokens: ObjectSpace.each_object(RDoc::Parser::RubyColorizer::ColoredToken).count,
      methods: ObjectSpace.each_object(RDoc::AnyMethod).count,
      classes_and_modules: store.all_classes_and_modules.size,
      files: store.all_files.size
    }

    File.write(ENV.fetch("RDOC_PROFILE_PATH"), JSON.pretty_generate(samples))
  end

  def samples = @samples ||= []

  module Lifecycle
    def parse_files(files)
      RDocProfile.sample("before_parse", self)
      super.tap { RDocProfile.sample("after_parse", self) }
    end

    def generate
      RDocProfile.sample("before_generate", self)
      super.tap { RDocProfile.sample("after_generate", self) }
    end
  end
end

RDoc::RDoc.prepend(RDocProfile::Lifecycle)
