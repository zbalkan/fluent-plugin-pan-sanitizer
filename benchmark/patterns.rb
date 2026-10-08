# Run: ruby -Ilib benchmark/patterns.rb [iterations]
require 'benchmark'
require 'fluent/plugin/pan/patterns'
require 'fluent/plugin/pan/masker'

iterations = Integer(ARGV.fetch(0, '10000'))
raise ArgumentError, 'iterations must be positive' unless iterations.positive?

maskers = Fluent::PAN::Patterns::DEFINITIONS.keys.map do |brand|
  Fluent::PAN::Masker.new(Fluent::PAN::Patterns.for_brand(brand), :luhn, '****')
end
samples = [
  'user 4111111111111111 updated card',
  'ordinary request with status=200 latency=38ms',
  'user 5555555555554444 updated card',
  'account 1234567890123456 in audit record'
].freeze

Benchmark.bm(16) do |x|
  x.report('all brands') do
    iterations.times do
      samples.each { |message| maskers.reduce(message) { |value, masker| masker.mask_if_found_pan(value) } }
    end
  end
  x.report('visa only') do
    iterations.times do
      samples.each { |message| maskers[1].mask_if_found_pan(message) }
    end
  end
end
