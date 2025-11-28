# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab400
      class Credisis < Brcobranca::Remessa::Cnab400::Base
        attr_accessor :codigo_cedente, :documento_cedente, :convenio

        validates_presence_of :agencia, :conta_corrente, :codigo_cedente, :digito_conta,
                              message: 'não pode estar em branco.'
        validates_length_of :agencia, maximum: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :codigo_cedente, maximum: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :conta_corrente, maximum: 8, message: 'deve ter 8 dígitos.'
        validates_length_of :carteira, maximum: 2, message: 'deve ter 2 dígitos.'
        validates_length_of :digito_conta, maximum: 1, message: 'deve ter 1 dígito.'
        validates_length_of :sequencial_remessa, :convenio, maximum: 7, message: 'deve ter 7 dígitos.'

        # Nova instancia do CrediSIS
        def initialize(campos = {})
          campos = { aceite: 'N' }.merge!(campos)
          super
        end

        def agencia=(valor)
          @agencia = valor.to_s.rjust(4, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(8, '0') if valor
        end

        def carteira=(valor)
          @carteira = valor.to_s.rjust(2, '0') if valor
        end

        def sequencial_remessa=(valor)
          @sequencial_remessa = valor.to_s.rjust(7, '0') if valor
        end

        def codigo_cedente=(valor)
          @codigo_cedente = valor.to_s.rjust(4, '0') if valor
        end

        def cod_banco
          '097'
        end

        def nome_banco
          'CENTRALCREDI'.ljust(15, ' ')
        end

        # Header do arquivo remessa
        #
        # @return [String]
        #
        def monta_header
          header = +'0'                         # tipo do registro      [01]   0
          header << '1'                         # operacao              [01]   1
          header << 'REMESSA'                   # literal remessa       [07]   REMESSA
          header << '01'                        # Código do serviço     [02]   01
          header << 'COBRANCA'                  # cod. servico          [08]   COBRANCA
          header << ''.rjust(7, ' ')            # brancos               [07]
          header << info_conta                  # info. conta           [20]
          header << empresa_mae.format_size(30) # empresa mae           [30]
          header << "#{cod_banco}#{nome_banco}" # identificação banco   [18]
          header << data_geracao                # data geracao          [06]   Formato DDMMAA
          header << sequencial_header           # sequencial remessa    [07]
          header << complemento                 # complemento registro  [284]
          header << '001'                       # versão do arquivo     [03]   001
          header << '000001'                    # num. sequencial       [06]   000001
          header
        end

        # Informacoes da conta corrente do cedente
        #
        # @return [String]
        #
        def info_conta
          # CAMPO            TAMANHO
          # agencia          [04]
          # complemento      [01]
          # conta corrente   [08]
          # digito da conta  [01]
          # complemento      [06]
          "#{agencia} #{conta_corrente}#{digito_conta}#{''.rjust(6, ' ')}"
        end

        # Complemento do header
        #
        # @return [String]
        #
        def complemento
          ''.rjust(284, ' ')
        end

        def sequencial_header
          sequencial_remessa.to_s.ljust(7, ' ')
        end

        def data_limite_pagamento(pagamento)
          (pagamento.data_vencimento + pagamento.dias_limite_pagamento.to_i).strftime('%d%m%y')
        end

        # Detalhe do arquivo
        #
        # @param pagamento [PagamentoCnab400]
        #   objeto contendo as informacoes referentes ao boleto (valor, vencimento, cliente)
        # @param sequencial
        #   num. sequencial do registro no arquivo
        #
        # @return [String]
        #

        def monta_detalhe(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          detalhe = '1'                                                     # identificacao transacao               9[01]
          detalhe += Brcobranca::Util::Empresa.new(documento_cedente).tipo  # tipo de identificacao da empresa      9[02]
          detalhe << documento_cedente.to_s.rjust(14, '0')                  # cpf/cnpj da empresa                   9[14]
          detalhe << agencia                                                # agencia                               9[04]
          detalhe << conta_corrente                                         # conta corrente                        9[08]
          detalhe << digito_conta                                           # dv conta                              9[01]
          detalhe << ''.rjust(26, ' ')                                      # complemento do registro (brancos)     X[26]
          detalhe << pagamento.nosso_numero.to_s.rjust(20, '0')             # nosso numero                          9[20]
          detalhe << '01'                                                   # código da operação (01 - inclusão)    9[02]
          detalhe << pagamento.data_emissao.strftime('%d%m%y')              # data da operação                      D[06]
          detalhe << ''.rjust(6, ' ')                                       # brancos                               X[06]
          detalhe << '01'                                                   # Número da parcela                     9[02]
          detalhe << '3'                                                    # Tipo pagamento                        9[01]
          detalhe << '3'                                                    # Tipo recebimento                      9[01]
          detalhe << pagamento.especie_titulo                               # Espécie de documento                  9[02]
          detalhe << ''.rjust(1, ' ')                                       # complemento do registro (brancos)     X[01]
          detalhe << pagamento.dias_protesto.rjust(2, '0')                  # quantidade de dias do prazo           9[02]
          detalhe << pagamento.cod_primeira_instrucao.rjust(2, '0')         # Tipo de protesto                      X[02] - 01 = Cartório, 02 = Serasa, 03 = Nenhum
          detalhe << ''.rjust(9, ' ')                                       # brancos                               X[09]
          detalhe << pagamento.numero.to_s.rjust(10, '0')                   # numero do documento                   A[10]
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')           # data do vencimento                    D[06]
          detalhe << pagamento.formata_valor                                # valor do documento                    V[13]
          detalhe << data_limite_pagamento(pagamento)                       # data limite pagamento                 D[06]
          detalhe << ''.rjust(5, ' ')                                       # brancos                               X[05]
          detalhe << pagamento.data_emissao.strftime('%d%m%y')              # data de emissao                       D[06]
          detalhe << ''.rjust(1, ' ')                                       # brancos                               X[01]
          detalhe << pagamento.identificacao_sacado                         # identificacao do pagador              9[02]
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')         # documento do pagador                  9[14]
          detalhe << pagamento.nome_sacado.format_size(40)                  # nome do pagador                       A[40]
          detalhe << ''.rjust(25, ' ')                                      # brancos                               X[25]
          detalhe << pagamento.endereco_sacado.format_size(35)              # endereco do pagador                   A[35]
          detalhe << pagamento.numero_endereco_sacado.to_s.rjust(6, ' ')    # numero endereco do pagador            9[06]
          detalhe << pagamento.bairro_sacado.format_size(25)                # bairro do pagador                     X[25]
          detalhe << pagamento.cidade_sacado.format_size(25)                # cidade do pagador                     A[25]
          detalhe << pagamento.uf_sacado                                    # uf do pagador                         A[02]
          detalhe << pagamento.cep_sacado                                   # cep do pagador                        9[08]
          detalhe << ''.rjust(11, ' ')                                      # brancos                               X[11]
          detalhe << ''.rjust(43, ' ')                                      # brancos                               X[43]
          detalhe << ''.rjust(1, ' ')                                       # brancos                               X[01]
          detalhe << sequencial.to_s.rjust(6, '0')                          # numero do registro no arquivo         9[06]
          detalhe
        end

        def monta_detalhe_multa(pagamento, sequencial)
          detalhe = '2'
          detalhe += ''.rjust(283, ' ')
          detalhe << pagamento.format_value(:valor_mora, 15, '4')
          detalhe << 'P'
          detalhe << '2'
          detalhe << pagamento.dias_carencia_juros.to_s.somente_numeros.last(2).rjust(2, '0')
          detalhe << pagamento.format_value(:percentual_multa, 15, '4')
          detalhe << 'P'
          detalhe << '2'
          detalhe << pagamento.dias_carencia_multa.to_s.somente_numeros.last(2).rjust(2, '0')
          detalhe << ''.rjust(72, ' ')
          detalhe << sequencial.to_s.rjust(6, '0')

          detalhe
        end
      end
    end
  end
end
