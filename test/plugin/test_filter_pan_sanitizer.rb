require_relative '../helper'
require 'fluent/test/driver/filter'
require 'fluent/plugin/filter_pan_sanitizer'

class PANSanitizerFilterTest < Test::Unit::TestCase
  CONFIG = %[
    <pan>
      formats /4[0-9]{15}/
      checksum_algorithm luhn
      mask ****
    </pan>
    ignore_keys excluded
  ]

  def setup
    Fluent::Test.setup
  end

  def driver(conf = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::PANSanitizerFilter).configure(conf)
  end

  def sanitize(record, conf = CONFIG)
    d = driver(conf)
    d.run(default_tag: 'test') { d.feed(record) }
    d.filtered_records.first
  end

  def test_scalar_type_and_nested_structure_preservation
    record = {
      'enabled' => true, 'null' => nil, 'count' => 1.5,
      'nested' => {'pan' => '4019249331712145', 'ok' => false},
      'array' => ['4019249331712145', 42, {'pan' => '4019249331712145'}]
    }
    result = sanitize(record)
    assert_equal(true, result['enabled'])
    assert_nil(result['null'])
    assert_equal(1.5, result['count'])
    assert_equal({'pan' => '****', 'ok' => false}, result['nested'])
    assert_equal(['****', 42, {'pan' => '****'}], result['array'])
  end

  def test_integer_and_ignore_keys
    record = {'card' => 4019249331712145, 'excluded' => {'card' => '4019249331712145'}}
    assert_equal({'card' => '****', 'excluded' => {'card' => '4019249331712145'}}, sanitize(record))
  end

  def test_no_matching_pan_preserves_input
    record = {'message' => 'hello', 'number' => 100, 'flag' => false}
    assert_equal(record, sanitize(record))
  end

  def test_empty_formats_fail_configuration
    assert_raise(Fluent::ConfigError) { driver("<pan>\n</pan>") }
  end


  def test_brand_only_configuration
    result = sanitize({'card' => '4111111111111111', 'other' => 'hello'}, "brands visa\n")
    assert_equal({'card' => '****', 'other' => 'hello'}, result)
  end

  def test_brand_selection_is_conservative
    result = sanitize({'card' => '5555555555554444'}, "brands visa\n")
    assert_equal({'card' => '5555555555554444'}, result)
  end

  def test_brand_and_custom_patterns
    conf = %[
      brands mastercard
      <pan>
        formats /4019[0-9]{12}/
        mask REDACTED
      </pan>
    ]
    assert_equal('****', sanitize({'card' => '5555555555554444'}, conf)['card'])
    assert_equal('REDACTED', sanitize({'card' => '4019249331712145'}, conf)['card'])
  end

  def test_unknown_brand_is_configuration_error
    assert_raise(Fluent::ConfigError) { driver("brands imaginary\n") }
  end

  def test_missing_pan_fails_configuration
    assert_raise(Fluent::ConfigError) { driver('') }
  end
end
