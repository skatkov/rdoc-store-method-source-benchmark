# frozen_string_literal: true

require "rdoc/rdoc"
require "rdoc/parser/ruby"
require "rdoc/generator/ri"
require "rdoc/generator/pot"

class RDoc::Generator::RI
  def self.store_method_source? = false
end

class RDoc::Generator::POT
  def self.store_method_source? = false
end

module RDoc::StoreMethodSource
  def syntax_highlighted_tokens(node)
    return [] unless store_method_source?

    super
  end

  private

  def store_method_source?
    return false if @options.coverage_report

    generator = @options.generator
    !generator.respond_to?(:store_method_source?) || generator.store_method_source?
  end
end

RDoc::Parser::Ruby.prepend(RDoc::StoreMethodSource)
