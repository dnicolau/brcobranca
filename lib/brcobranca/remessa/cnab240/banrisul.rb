# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab240
      class Banrisul < Brcobranca::Remessa::Cnab240::Base
        attr_accessor :digito_agencia, :digito_agencia_conta, :codigo_especie_cobranca,
                      :autoriza_pagamento_parcial

        validates_presence_of :convenio, :codigo_especie_cobranca, message: 'não pode estar em branco.'
        validates_length_of :agencia, maximum: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :conta_corrente, maximum: 12, message: 'deve ter 12 dígitos.'
        validates_length_of :convenio, is: 13, message: 'deve ter 13 dígitos.'
        validates_length_of :digito_agencia, maximum: 1, message: 'deve ter 1 dígito.'
        validates_length_of :digito_conta, maximum: 1, message: 'deve ter 1 dígito.'
        validates_length_of :digito_agencia_conta, maximum: 1, message: 'deve ter 1 dígito.'
        validates_length_of :codigo_especie_cobranca, maximum: 10, message: 'deve ter 10 dígitos.'
        validates_length_of :autoriza_pagamento_parcial, is: 1, message: 'deve ter 1 dígito.'
        validates_inclusion_of :autoriza_pagamento_parcial, in: %w[1 2], message: 'deve ser 1 ou 2.'

        def initialize(campos = {})
          campos = {
            emissao_boleto: '2',
            distribuicao_boleto: '2',
            especie_titulo: '02',
            tipo_documento: '2',
            codigo_especie_cobranca: '805076',
            autoriza_pagamento_parcial: '1'
          }.merge!(campos)
          super(campos)
        end

        def convenio=(valor)
          @convenio = valor.to_s.rjust(13, '0') if valor
        end

        def agencia=(valor)
          @agencia = valor.to_s if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s if valor
        end

        def digito_agencia=(valor)
          @digito_agencia = valor.to_s if valor
        end

        def digito_agencia
          digito_agencia_value
        end

        def digito_conta=(valor)
          @digito_conta = valor.to_s if valor
        end

        def digito_agencia_conta=(valor)
          @digito_agencia_conta = valor.to_s if valor
        end

        def codigo_especie_cobranca=(valor)
          @codigo_especie_cobranca = valor.to_s if valor
        end

        def autoriza_pagamento_parcial=(valor)
          @autoriza_pagamento_parcial = valor.to_s if valor
        end

        def cod_banco
          '041'
        end

        def nome_banco
          'BANRISUL'.ljust(30, ' ')
        end

        def versao_layout_arquivo
          '103'
        end

        def versao_layout_lote
          '060'
        end

        def codigo_convenio
          convenio.ljust(20, ' ')
        end

        alias convenio_lote codigo_convenio

        def info_conta
          "#{agencia.to_s.rjust(5, '0')}#{digito_agencia_value}"\
            "#{conta_corrente.to_s.rjust(12, '0')}#{digito_conta_value}#{agencia_conta_corrente_dv}"
        end

        def digito_agencia_value
          @digito_agencia.to_s.empty? ? ' ' : @digito_agencia.to_s
        end

        def digito_conta_value
          digito_conta.to_s.empty? ? ' ' : digito_conta.to_s
        end

        def agencia_conta_corrente_dv
          digito_agencia_conta.to_s.empty? ? ' ' : digito_agencia_conta.to_s
        end

        def dv_agencia_cobradora
          ' '
        end

        def uso_exclusivo_banco
          ''.rjust(20, ' ')
        end

        def uso_exclusivo_empresa
          ''.rjust(20, ' ')
        end

        def complemento_header
          ''.rjust(29, ' ')
        end

        def complemento_trailer
          total_cobranca_simples    = totalizacao_carteira('1')
          total_cobranca_vinculada  = totalizacao_carteira('2')
          total_cobranca_caucionada = totalizacao_carteira('3')
          total_cobranca_descontada = totalizacao_carteira('4')

          "#{total_cobranca_simples}#{total_cobranca_vinculada}#{total_cobranca_caucionada}"\
          "#{total_cobranca_descontada}#{''.rjust(8, ' ')}#{''.rjust(117, ' ')}"
        end

        def complemento_p(pagamento)
          "#{conta_corrente.to_s.rjust(12, '0')}#{digito_conta_value}"\
            "#{agencia_conta_corrente_dv}#{formata_nosso_numero(pagamento.nosso_numero)}"
        end

        def formata_nosso_numero(nosso_numero)
          base = base_nosso_numero(nosso_numero)
          "#{base}#{digito_nosso_numero(base)}".ljust(20, ' ')
        end

        def digito_nosso_numero(nosso_numero)
          nosso_numero.duplo_digito
        end

        def numero(pagamento)
          "#{formata_numero_documento(pagamento, 13)}#{''.rjust(2, ' ')}"
        end

        def identificacao_titulo_empresa(pagamento)
          formata_numero_documento(pagamento, 25)
        end

        def codigo_especie_cobranca_formatado
          codigo_especie_cobranca.to_s.rjust(10, '0')
        end

        def data_mora(pagamento)
          return ''.rjust(8, '0') unless %w[1 2].include? pagamento.tipo_mora

          data = pagamento.data_mora || pagamento.data_vencimento.next_day
          data.strftime('%d%m%Y')
        end

        def data_multa(pagamento)
          return ''.rjust(8, '0') if pagamento.codigo_multa == '0'

          data = pagamento.data_multa || pagamento.data_vencimento.next_day
          data.strftime('%d%m%Y')
        end

        def monta_segmento_p(pagamento, nro_lote, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          segmento_p = ''
          segmento_p += cod_banco
          segmento_p << nro_lote.to_s.rjust(4, '0')
          segmento_p << '3'
          segmento_p << sequencial.to_s.rjust(5, '0')
          segmento_p << 'P'
          segmento_p << ' '
          segmento_p << pagamento.identificacao_ocorrencia
          segmento_p << agencia.to_s.rjust(5, '0')
          segmento_p << digito_agencia_value
          segmento_p << complemento_p(pagamento)
          segmento_p << codigo_carteira
          segmento_p << forma_cadastramento
          segmento_p << tipo_documento
          segmento_p << emissao_boleto
          segmento_p << distribuicao_boleto
          segmento_p << numero(pagamento)
          segmento_p << pagamento.data_vencimento.strftime('%d%m%Y')
          segmento_p << pagamento.formata_valor(15)
          segmento_p << ''.rjust(5, '0')
          segmento_p << dv_agencia_cobradora
          segmento_p << especie_titulo
          segmento_p << aceite
          segmento_p << pagamento.data_emissao.strftime('%d%m%Y')
          segmento_p << pagamento.tipo_mora
          segmento_p << data_mora(pagamento)
          segmento_p << pagamento.formata_valor_mora(15)
          segmento_p << codigo_desconto(pagamento)
          segmento_p << pagamento.formata_data_desconto('%d%m%Y')
          segmento_p << pagamento.formata_valor_desconto(15)
          segmento_p << pagamento.formata_valor_iof(15)
          segmento_p << pagamento.formata_valor_abatimento(15)
          segmento_p << identificacao_titulo_empresa(pagamento)
          segmento_p << pagamento.codigo_protesto
          segmento_p << pagamento.dias_protesto.to_s.rjust(2, '0')
          segmento_p << codigo_baixa(pagamento)
          segmento_p << dias_baixa(pagamento)
          segmento_p << '09'
          segmento_p << codigo_especie_cobranca_formatado
          segmento_p << autoriza_pagamento_parcial
          segmento_p
        end

        def monta_segmento_q(pagamento, nro_lote, sequencial)
          segmento_q = super
          segmento_q[153..208] = ''.rjust(56, ' ')
          segmento_q
        end

        private

        def base_nosso_numero(nosso_numero)
          numero = nosso_numero.to_s.somente_numeros
          return numero[0...8] if numero.size == 10 && numero[8..9] == digito_nosso_numero(numero[0...8])

          numero.rjust(8, '0')[-8, 8]
        end

        def formata_numero_documento(pagamento, tamanho)
          documento = pagamento.documento_ou_numero.to_s.gsub(/[^0-9A-Za-z ]/, '')
          documento.ljust(tamanho, ' ')[0...tamanho]
        end

        def totalizacao_carteira(codigo)
          return ''.rjust(23, '0') unless codigo_carteira == codigo

          "#{quantidade_titulos_cobranca}#{valor_titulos_carteira}"
        end
      end
    end
  end
end
