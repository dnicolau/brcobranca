# frozen_string_literal: true

require 'parseline'

module Brcobranca
  module Retorno
    module Cnab240
      class Banrisul < Brcobranca::Retorno::Cnab240::Base
        REGEX_DE_EXCLUSAO_DE_REGISTROS_NAO_T_OU_U = /^((?!^.{7}3.{5}[T|U].*$).)*$/.freeze

        attr_accessor :documento_numero, :valor_liquido, :codigo_ocorrencia_pagador,
                      :data_ocorrencia_pagador, :valor_ocorrencia_pagador,
                      :complemento_ocorrencia, :banco_correspondente,
                      :nosso_numero_banco_correspondente

        def self.load_lines(file, options = {})
          default_options = { except: REGEX_DE_EXCLUSAO_DE_REGISTROS_NAO_T_OU_U }
          options = default_options.merge!(options)

          Line.load_lines(file, options).each_slice(2).reduce([]) do |retornos, cnab_lines|
            retornos << generate_retorno_based_on_cnab_lines(cnab_lines)
          end
        end

        def self.generate_retorno_based_on_cnab_lines(cnab_lines)
          retorno = new
          cnab_lines.each do |line|
            fields = line.tipo_registro == 'T' ? Line::REGISTRO_T_FIELDS : Line::REGISTRO_U_FIELDS

            fields.each do |attr|
              retorno.send("#{attr}=", line.send(attr))
            end
          end
          retorno
        end

        class Line < Base
          extend ParseLine::FixedWidth

          REGISTRO_T_FIELDS = %w[codigo_registro codigo_ocorrencia agencia_com_dv cedente_com_dv
                                 nosso_numero carteira documento_numero data_vencimento valor_titulo
                                 banco_recebedor agencia_recebedora_com_dv sequencial valor_tarifa
                                 motivo_ocorrencia].freeze
          REGISTRO_U_FIELDS = %w[desconto_concedito valor_abatimento iof_desconto juros_mora
                                 valor_recebido valor_liquido outras_despesas outros_recebimento
                                 data_ocorrencia data_credito codigo_ocorrencia_pagador
                                 data_ocorrencia_pagador valor_ocorrencia_pagador complemento_ocorrencia
                                 banco_correspondente nosso_numero_banco_correspondente].freeze

          attr_accessor :tipo_registro, :valor_liquido, :codigo_ocorrencia_pagador,
                        :data_ocorrencia_pagador, :valor_ocorrencia_pagador,
                        :complemento_ocorrencia, :banco_correspondente,
                        :nosso_numero_banco_correspondente

          fixed_width_layout do |parse|
            parse.field :codigo_registro, 7..7
            parse.field :tipo_registro, 13..13
            parse.field :sequencial, 8..12
            parse.field :codigo_ocorrencia, 15..16
            parse.field :agencia_com_dv, 17..22
            parse.field :cedente_com_dv, 23..35
            parse.field :nosso_numero, 37..56
            parse.field :carteira, 57..57
            parse.field :documento_numero, 58..72
            parse.field :data_vencimento, 73..80
            parse.field :valor_titulo, 81..95
            parse.field :banco_recebedor, 96..98
            parse.field :agencia_recebedora_com_dv, 99..104
            parse.field :juros_mora, 17..31
            parse.field :desconto_concedito, 32..46
            parse.field :valor_abatimento, 47..61
            parse.field :iof_desconto, 62..76
            parse.field :valor_recebido, 77..91
            parse.field :valor_liquido, 92..106
            parse.field :outras_despesas, 107..121
            parse.field :outros_recebimento, 122..136
            parse.field :data_ocorrencia, 137..144
            parse.field :data_credito, 145..152
            parse.field :codigo_ocorrencia_pagador, 153..156
            parse.field :data_ocorrencia_pagador, 157..164
            parse.field :valor_ocorrencia_pagador, 165..179
            parse.field :complemento_ocorrencia, 180..209
            parse.field :banco_correspondente, 210..212
            parse.field :nosso_numero_banco_correspondente, 213..232
            parse.field :valor_tarifa, 198..212
            parse.field :motivo_ocorrencia, 213..222, lambda { |motivos|
              motivos.scan(/.{2}/).reject { |motivo| motivo.strip.empty? || motivo == '00' }
            }
          end
        end
      end
    end
  end
end
