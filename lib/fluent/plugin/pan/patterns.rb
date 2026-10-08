module Fluent
  module PAN
    # Issuer-specific candidates. Prefixes and lengths are deliberately explicit.
    # These are detection heuristics, not an authoritative list of issued BINs.
    module Patterns
      DEFINITIONS = {
        'mastercard' => /(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)(?:[ -]?[0-9]{4}){3}/,
        'visa' => /4[0-9]{3}(?:[ -]?[0-9]{4}){3}|4[0-9]{12}|4[0-9]{18}/,
        'amex' => /3[47][0-9]{2}(?:[ -]?[0-9]{11}|[- ][0-9]{6}[- ][0-9]{5})/,
        'dinersclub' => /(?:30[0-5][0-9]|3095|36[0-9]{2}|3[89][0-9]{2})(?:[ -]?[0-9]){10}/,
        'discover' => /(?:6011|65[0-9]{2}|64[4-9][0-9])(?:[ -]?[0-9]{4}){3}|622(?:12[6-9]|1[3-9][0-9]|[2-8][0-9]{2}|9[01][0-9]|92[0-5])[0-9]{10}/,
        'jcb' => /(?:2131|1800)(?:[ -]?[0-9]){11}|35(?:2[89]|[3-8][0-9])(?:[ -]?[0-9]){12}/,
        'maestro' => /(?:5[0678][0-9]{2}|6013|6[237][0-9]{2})(?:[ -]?[0-9]){8,15}/,
        'unionpay' => /622(?:[ -]?[0-9]){13,16}|(?:621977|60(?:1428|2969|3265|3367|3601|3694|3708))(?:[ -]?[0-9]){10}/
      }.freeze

      # Anchor the candidate without consuming surrounding log characters.
      BOUNDARY_LEFT = '(?<![A-Za-z0-9_])'.freeze
      BOUNDARY_RIGHT = '(?![A-Za-z0-9_]|[ -][0-9])'.freeze

      def self.for_brand(name)
        body = DEFINITIONS.fetch(name.to_s.downcase)
        Regexp.new("#{BOUNDARY_LEFT}(?:#{body.source})#{BOUNDARY_RIGHT}")
      end
    end
  end
end
