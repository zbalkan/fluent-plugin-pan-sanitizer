# fluent-plugin-pan-sanitizer

A Fluentd filter that sanitizes payment card numbers (PANs) in log records. Built-in issuer-specific candidates must pass both a brand regex and the Luhn algorithm. Custom patterns may explicitly opt out of Luhn.

## Origin and attribution

This project is a fork of [kanmu/fluent-plugin-pan-anonymizer](https://github.com/kanmu/fluent-plugin-pan-anonymizer), originally developed by Kanmu, Inc. The fork has been renamed to `fluent-plugin-pan-sanitizer` and includes subsequent changes to PAN detection, validation, configuration, and testing. We acknowledge and thank the original authors and contributors for their work.

The original Kanmu copyright notice is retained in [LICENSE](LICENSE). Both the original project and this fork are distributed under the Apache License, Version 2.0.

## Installation

```sh
gem install fluent-plugin-pan-sanitizer
```

## Configuration

Use an explicit list of supported card brands; unmatched numeric sequences are never sent through a generic PAN detector:

```xml
<filter **>
  @type pan_sanitizer
  brands mastercard, visa, amex, dinersclub, discover, jcb, maestro, unionpay
  mask ****
  ignore_keys event_time
</filter>
```

The bundled catalog is derived from PANHunt's eight issuer-specific families and is intended as a conservative set of candidate patterns, not an authoritative current BIN registry. Brand matching is followed by the Luhn checksum. Brands can be individually enabled; unspecified brands are not detected. Brand names are case-insensitive.

Custom patterns are still supported, separately or alongside built-in brands:

```xml
<filter **>
  @type pan_sanitizer
  brands visa, mastercard
  <pan>
    formats /４[０-９]{15}/
    checksum_algorithm luhn
    mask REDACTED
  </pan>
</filter>
```

### Behavior

- The filter recursively processes strings inside hashes and arrays, preserving the shape and types of unaffected values.
- A matched PAN inside an integer is converted to a masked string. This intentional type change prevents exposing a detected number.
- A top-level or nested hash key listed in `ignore_keys` is excluded along with its entire value subtree.
- By default, custom patterns reject matches adjacent to ASCII or full-width decimal digits; built-in brands also reject surrounding ASCII letters and underscores. Set `allow_embedded true` in a `<pan>` section to permit those matches.
- Each `<pan>` section requires one or more `formats` expressions. At least one built-in brand or custom `<pan>` section must be provided.
- `checksum_algorithm` accepts `luhn` (default) or `none`. Luhn accepts candidate digit lengths from 12 to 19. ASCII and full-width digits are supported. Other Unicode numeral scripts are not currently normalized. Only spaces and hyphens are accepted as separators in custom pattern candidates.
- `mask` defaults to `****`. Replacement backreferences such as `\\1` are supported. Matching integers are converted to masked strings.

### Security limitations

Regex selection determines which PAN formats can be detected. Luhn is a checksum, not proof that a number is an issued card. Unsupported formats, card data outside configured fields, invalid-Luhn numbers, and values under ignored keys may remain unmasked. This is not a complete PCI DSS compliance solution. For strict data protection, combine the filter with an upstream policy that prevents unsanitized sensitive data from entering logs.

Avoid excessively broad or catastrophically backtracking regex patterns. A large number of expressions increases per-record processing costs.

### Detection policy

- A configured brand pattern **and** a valid Luhn checksum are required to sanitize a built-in-brand candidate.
- Brand patterns deliberately constrain prefixes and PAN lengths; newly introduced or unrecognized BIN conventions can be missed.
- Built-in patterns use non-consuming alphanumeric boundaries, so adjacent letters, digits, and underscores prevent a match.
- Custom patterns may use `checksum_algorithm none` explicitly, but built-in brands always enforce Luhn.
- Checksum validation is a screening step, not proof of issuance or compliance.

## Development

```sh
bundle install
bundle exec rake test
gem build fluent-plugin-pan-sanitizer.gemspec
```

CI runs on every push, pull request, and manual `workflow_dispatch`. It tests Fluentd 1.16.5, 1.17.1, and 1.18.0 on Ruby 2.7/3.1, and Fluentd 1.18.0 and 1.19.3 on Ruby 3.2–3.4. Fluentd 1.19 requires Ruby 3.2 or later. The gem declares support for Fluentd 1.x from 1.16 onward; compatibility with additional 1.x releases is not individually verified.

## License

Apache License 2.0.
