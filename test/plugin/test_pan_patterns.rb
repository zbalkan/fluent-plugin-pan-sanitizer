require_relative '../helper'
require 'fluent/plugin/pan/patterns'
require 'fluent/plugin/pan/masker'

class PANPatternsTest < Test::Unit::TestCase
  CASES = {
    'mastercard' => '5555555555554444',
    'visa' => '4111111111111111',
    'amex' => '378282246310005',
    'dinersclub' => '30569309025904',
    'discover' => '6011111111111117',
    'jcb' => '3530111333300000'
  }.freeze

  def test_known_scheme_vectors
    CASES.each do |brand, pan|
      masker = Fluent::PAN::Masker.new(Fluent::PAN::Patterns.for_brand(brand), :luhn, '****')
      assert_equal('****', masker.mask_if_found_pan(pan), brand)
      assert_equal("abc #{'****'} xyz", masker.mask_if_found_pan("abc #{pan} xyz"), brand)
      assert_equal("prefix_#{pan}", masker.mask_if_found_pan("prefix_#{pan}"), brand)
    end
  end

  def test_variable_length_schemes
    {'maestro' => '6759649826438453', 'unionpay' => '6221261234567890'}.each do |brand, prefix|
      digits = prefix[0...-1].chars.map(&:to_i)
      check = (0..9).find do |candidate|
        sequence = digits + [candidate]
        Fluent::PAN::Masker::CHECKSUM_FUNC[:luhn].call(sequence)
      end
      pan = prefix[0...-1] + check.to_s
      masker = Fluent::PAN::Masker.new(Fluent::PAN::Patterns.for_brand(brand), :luhn, '****')
      assert_equal('****', masker.mask_if_found_pan(pan), brand)
    end
  end

  def test_invalid_checksum_and_boundaries
    masker = Fluent::PAN::Masker.new(Fluent::PAN::Patterns.for_brand('visa'), :luhn, '****')
    assert_equal('4111111111111112', masker.mask_if_found_pan('4111111111111112'))
    assert_equal('a4111111111111111', masker.mask_if_found_pan('a4111111111111111'))
    assert_equal('4111111111111111_abc', masker.mask_if_found_pan('4111111111111111_abc'))
    assert_equal('94111111111111111', masker.mask_if_found_pan('94111111111111111'))
    assert_equal('****!', masker.mask_if_found_pan('4111111111111111!'))
  end

  def test_separated_numbers
    masker = Fluent::PAN::Masker.new(Fluent::PAN::Patterns.for_brand('visa'), :luhn, '****')
    assert_equal('****', masker.mask_if_found_pan('4111-1111-1111-1111'))
    assert_equal('****', masker.mask_if_found_pan('4111 1111 1111 1111'))
    assert_equal('4111-1111-1111-1111-2', masker.mask_if_found_pan('4111-1111-1111-1111-2'))
  end

  def test_bad_brand
    assert_raise(KeyError) { Fluent::PAN::Patterns.for_brand('unknown') }
  end

  def test_unsupported_separators_are_not_silently_removed
    masker = Fluent::PAN::Masker.new(/4111x1111x1111x1111/, :luhn, '****')
    assert_equal('4111x1111x1111x1111', masker.mask_if_found_pan('4111x1111x1111x1111'))
  end
end
