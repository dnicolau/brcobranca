# frozen_string_literal: true

require 'parseline'

module Brcobranca
  module Retorno
    module Cnab400
      # Banco Daycoval - CNAB400
      class Daycoval < Brcobranca::Retorno::Cnab400::Base
        extend ParseLine::FixedWidth

        # Campos exclusivos do retorno Daycoval que não existem na classe base.
        attr_accessor :codigo_inscricao, :numero_inscricao, :codigo_empresa, :uso_empresa, :codigo_carteira,
                      :codigo_operacao_cobranca, :codigo_moeda, :data_gravacao

        # Load lines
        #
        # Por padrão ignora o header e mantém os demais registros.
        # O TMS ignora o trailer ao processar o retorno CNAB400.
        def self.load_lines(file, options = {})
          default_options = { except: [1] }
          options = default_options.merge!(options)
          super
        end

        fixed_width_layout do |parse|
          # Todos os campos descritos no registro de transação.
          # O layout é 1-indexado; os ranges abaixo são 0-indexados.
          parse.field :codigo_registro, 0..0                 # 001-001 Código do registro
          parse.field :codigo_inscricao, 1..2                # 002-003 Tipo inscrição empresa
          parse.field :numero_inscricao, 3..16               # 004-017 CPF/CNPJ empresa
          parse.field :codigo_empresa, 17..36                # 018-037 Uso do banco / identificação empresa
          parse.field :uso_empresa, 37..61                   # 038-062 Identificação do título na empresa
          parse.field :nosso_numero, 62..72                  # 063-073 Nosso número Daycoval com DV
          parse.field :carteira, 82..84                      # 083-085 Nossa carteira
          parse.field :codigo_carteira, 107..107             # 108-108 Código da carteira
          parse.field :codigo_operacao_cobranca, 107..107    # 108-108 Código da operação de cobrança
          parse.field :codigo_ocorrencia, 108..109           # 109-110 Código da ocorrência
          parse.field :data_ocorrencia, 110..115             # 111-116 Data da ocorrência
          parse.field :documento_numero, 116..125            # 117-126 Seu número
          parse.field :data_vencimento, 146..151             # 147-152 Vencimento
          parse.field :valor_titulo, 152..164                # 153-165 Valor do título
          parse.field :banco_recebedor, 165..167             # 166-168 Código do banco
          parse.field :agencia_recebedora_com_dv, 168..172   # 169-173 Agência cobradora + DAC
          parse.field :especie_documento, 173..174           # 174-175 Espécie
          parse.field :valor_tarifa, 175..187                # 176-188 Tarifa de cobrança
          parse.field :iof, 214..226                         # 215-227 Valor do IOF
          parse.field :valor_abatimento, 227..239            # 228-240 Valor do abatimento
          parse.field :desconto, 240..252                    # 241-253 Desconto concedido
          parse.field :valor_recebido, 253..265              # 254-266 Valor principal pago
          parse.field :juros_mora, 266..278                  # 267-279 Juros de mora / multa
          parse.field :codigo_moeda, 376..376                # 377-377 Código da moeda
          parse.field :motivo_ocorrencia, 377..384, lambda { |motivos|
            motivos.scan(/.{2}/).reject(&:blank?).reject { |motivo| motivo == '00' }
          }                                                  # 378-385 Até 4 códigos de erro
          parse.field :data_gravacao, 385..390               # 386-391 Data de gravação do arquivo
          parse.field :data_credito, 385..390                # 386-391 Compatibilidade com fluxo genérico
          parse.field :sequencial, 394..399                  # 395-400 Sequencial do registro
        end

        def agencia_sem_dv
          ''
        end

        def agencia_com_dv
          ''
        end

        def cedente_com_dv
          ''
        end
      end
    end
  end
end
