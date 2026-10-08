module Fluent
  module PAN
    class Masker
      CHECKSUM_FUNC = {
        luhn: ->(digits) {
          return false unless digits.length.between?(12, 19)
          sum = 0
          digits.reverse.each_with_index do |digit, index|
            digit *= 2 if index.odd?
            sum += digit > 9 ? digit - 9 : digit
          end
          (sum % 10).zero?
        },
        none: ->(digits) { !digits.empty? }
      }.freeze

      FULLWIDTH_ZERO = '０'.ord

      def self.decimal_digit?(char)
        return false unless char
        code = char.ord
        (code >= 48 && code <= 57) || (code >= FULLWIDTH_ZERO && code <= FULLWIDTH_ZERO + 9)
      end

      def initialize(regexp, checksum_algorithm, mask, allow_embedded = false)
        @regexp = regexp
        @mask = mask.to_s
        @checksum_func = CHECKSUM_FUNC.fetch(checksum_algorithm)
        @allow_embedded = allow_embedded
      end

      def mask_if_found_pan(value)
        return value unless value.is_a?(String) || value.is_a?(Integer)

        original = value.to_s
        sanitized = original.gsub(@regexp) do |match|
          position = Regexp.last_match
          left = position.begin(0).zero? ? nil : original[position.begin(0) - 1]
          right = original[position.end(0)]
          if !@allow_embedded && (self.class.decimal_digit?(left) || self.class.decimal_digit?(right))
            next match
          end
          invalid = false
          digits = match.each_char.map do |char|
            code = char.ord
            if code >= 48 && code <= 57
              code - 48
            elsif code >= FULLWIDTH_ZERO && code <= FULLWIDTH_ZERO + 9
              code - FULLWIDTH_ZERO
            elsif char == ' ' || char == '-'
              nil
            else
              invalid = true
              nil
            end
          end.compact
          !invalid && @checksum_func.call(digits) ? match.sub(@regexp, @mask) : match
        end
        sanitized == original ? value : sanitized
      end

      def valid?(digits)
        @checksum_func.call(digits)
      end
    end
  end
end
