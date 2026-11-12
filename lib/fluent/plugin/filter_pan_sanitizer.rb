require 'fluent/plugin/filter'
require 'fluent/plugin/pan/masker'
require 'fluent/plugin/pan/patterns'

module Fluent::Plugin
  class PANSanitizerFilter < Filter
    Fluent::Plugin.register_filter("pan_sanitizer", self)

    config_section :pan, param_name: :pan_configs, required: false, multi: true do
      config_param :formats,            :array,  value_type: :regexp, default: []
      config_param :checksum_algorithm, :enum,   list: Fluent::PAN::Masker::CHECKSUM_FUNC.keys, default: :luhn
      config_param :mask,               :string, default: "****"
      config_param :allow_embedded,     :bool,   default: false
    end
    config_param :ignore_keys,          :array,  default: []
    config_param :brands,               :array,  default: []
    config_param :mask,                 :string, default: '****'
    config_param :on_error,             :enum, list: [:mask_field, :drop_record], default: :mask_field

    ERROR_MARKER = '[PAN_SANITIZATION_FAILED]'.freeze
    class DropUnsafeRecord < StandardError; end
    attr_reader :sanitization_errors

    def initialize
      super
      @sanitization_errors = 0
    end

    def configure(conf)
      super

      @pan_configs ||= []
      unknown = @brands.map(&:downcase) - Fluent::PAN::Patterns::DEFINITIONS.keys
      unless unknown.empty?
        raise Fluent::ConfigError, "Unknown PAN brands: #{unknown.join(', ')}"
      end
      if @brands.empty? && @pan_configs.empty?
        raise Fluent::ConfigError, 'Specify brands or at least one <pan> section'
      end
      if @pan_configs.any? { |pan| pan[:formats].empty? }
        raise Fluent::ConfigError, 'Each <pan> section must define at least one format'
      end

      @pan_masker = @brands.map do |name|
        Fluent::PAN::Masker.new(Fluent::PAN::Patterns.for_brand(name), :luhn, @mask)
      end
      @pan_configs.each do |pan|
        pan[:formats].each do |format|
          @pan_masker << Fluent::PAN::Masker.new(
            format, pan[:checksum_algorithm], pan[:mask], pan[:allow_embedded]
          )
        end
      end
    end

    def filter(tag, time, record)
      sanitize_value(record)
    rescue DropUnsafeRecord
      nil
    rescue StandardError => error
      record_error(error)
      @on_error == :drop_record ? nil : { 'pan_sanitizer_error' => ERROR_MARKER }
    end

    private

    def sanitize_value(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, item), result|
          result[key] = @ignore_keys.include?(key.to_s) ? item : sanitize_value(item)
        end
      when Array
        value.map { |item| sanitize_value(item) }
      when String, Integer
        raise ArgumentError, 'Invalid string encoding' if value.is_a?(String) && !value.valid_encoding?
        @pan_masker.reduce(value) { |current, masker| masker.mask_if_found_pan(current) }
      else
        value
      end
    rescue DropUnsafeRecord
      raise
    rescue StandardError => error
      record_error(error)
      raise DropUnsafeRecord if @on_error == :drop_record
      ERROR_MARKER
    end

    def record_error(error)
      @sanitization_errors += 1
      # Never include exception messages, record values or regex captures.
      log.warn('PAN sanitizer failed closed', error_class: error.class.name)
    end
  end
end
