require_relative '../helper'
require 'fluent/plugin/pan/masker'

class PANMaskerTest < Test::Unit::TestCase
  VALID = '4019249331712145'.freeze

  def masker(pattern = /4[0-9]{15}/, algorithm = :luhn, mask = '****')
    Fluent::PAN::Masker.new(pattern, algorithm, mask)
  end

  def test_luhn
    assert_equal(true, masker.valid?(VALID.chars.map(&:to_i)))
    assert_equal(false, masker.valid?('4019249331712146'.chars.map(&:to_i)))
    assert_equal(false, masker.valid?([]))
    assert_equal(false, masker.valid?([0]))
  end

  def test_preserve_unmatched_scalars
    m = masker
    [nil, true, false, 2.5, 123, ['a'], {'a' => 'b'}].each do |value|
      assert_equal(value, m.mask_if_found_pan(value))
      assert_equal(value.class, m.mask_if_found_pan(value).class)
    end
  end

  def test_string_masking_and_idempotence
    m = masker
    assert_equal('prefix **** suffix', m.mask_if_found_pan("prefix #{VALID} suffix"))
    assert_equal('****', m.mask_if_found_pan(m.mask_if_found_pan(VALID)))
  end

  def test_integer_masking_never_passes_through
    assert_equal('****', masker.mask_if_found_pan(VALID.to_i))
  end

  def test_longer_numeric_identifier_is_not_partially_masked
    assert_equal('9994019249331712145999', masker.mask_if_found_pan('9994019249331712145999'))
  end

  def test_capture_group_replacement
    m = masker(/(4019)[0-9]{8}([0-9]{4})/, :luhn, '\\1********\\2')
    assert_equal('4019********2145', m.mask_if_found_pan(VALID))
  end

  def test_fullwidth_digits_validate
    m = masker(/４[０-９]{15}/)
    assert_equal('****', m.mask_if_found_pan('４０１９２４９３３１７１２１４５'))
    assert_equal('４０１９２４９３３１７１２１４６', m.mask_if_found_pan('４０１９２４９３３１７１２１４６'))
  end

  def test_no_checksum_rejects_empty_digit_matches
    m = masker(/ABC/, :none)
    assert_equal('ABC', m.mask_if_found_pan('ABC'))
  end
end
