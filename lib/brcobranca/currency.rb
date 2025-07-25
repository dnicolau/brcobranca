# frozen_string_literal: true

# @author Fernando Vieira do http://simplesideias.com.br
module Brcobranca # :nodoc:[all]
  module Currency # :nodoc:[all]
    # Implementação feita por Fernando Vieira do http://simplesideias.com.br
    # post http://simplesideias.com.br/usando-number_to_currency-em-modelos-no-rails
    BRL = { delimiter: '.', separator: ',', unit: 'R$', precision: 2, position: 'before' }.freeze
    USD = { delimiter: ',', separator: '.', unit: 'US$', precision: 2, position: 'before' }.freeze
    DEFAULT = BRL.merge(unit: '')

    module String # :nodoc:[all]
      def to_number(_options = {})
        return tr(',', '.').to_f if numeric?

        nil
      end

      def numeric?
        /^(\+|-)?[0-9]+((\.|,)[0-9]+)?$/.match?(self)
      end
    end

    module Number # :nodoc:[all]
      def to_currency(options = {})
        number = self
        default   = Brcobranca::Currency::DEFAULT
        options   = default.merge(options)
        precision = options[:precision] || default[:precision]
        unit      = options[:unit] || default[:unit]
        position  = options[:position] || default[:position]
        separator = precision.positive? ? options[:separator] || default[:separator] : ''
        delimiter = options[:delimiter] || default[:delimiter]

        begin
          parts = number.with_precision(precision).split('.')
          is_negative = parts[0].include?('-')
          parts[0] = parts[0].gsub('-', '') if is_negative
          number = parts[0].to_i.with_delimiter(delimiter) + separator + parts[1].to_s
          number = "-#{number}" if is_negative
          position == 'before' ? unit + number : number + unit
        rescue StandardError
          number
        end
      end

      def with_delimiter(delimiter = ',', separator = '.')
        number = self
        begin
          parts = number.to_s.split(separator)
          parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
          parts.join separator
        rescue StandardError
          self
        end
      end

      def with_precision(precision = 3)
        number = self
        "%01.#{precision}f" % number
      end
    end
  end
end

[Numeric, String].each do |klass|
  klass.class_eval { include Brcobranca::Currency::Number }
end

[String].each do |klass|
  klass.class_eval { include Brcobranca::Currency::String }
end
