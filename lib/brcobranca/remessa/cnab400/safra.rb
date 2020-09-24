# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab400
      class Safra < Brcobranca::Remessa::Cnab400::Base
        # codigo da empresa (informado pelo Safra no cadastramento)
        attr_accessor :codigo_empresa
        attr_accessor :banco_cobranca
        attr_accessor :agencia_cobranca

        validates_presence_of :agencia, :conta_corrente, message: 'não pode estar em branco.'
        validates_presence_of :codigo_empresa, :sequencial_remessa,
          :digito_conta, message: 'não pode estar em branco.'
        validates_length_of :codigo_empresa, maximum: 14, message: 'deve ser igual a 14 dígitos.'
        validates_length_of :agencia, maximum: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :conta_corrente, maximum: 7, message: 'deve ter 7 dígitos.'
        validates_length_of :sequencial_remessa, maximum: 7, message: 'deve ter 7 dígitos.'
        validates_length_of :carteira, maximum: 1, message: 'deve ter no máximo 1 dígito.'
        validates_length_of :digito_conta, maximum: 1, message: 'deve ter 1 dígito.'
        validates_length_of :banco_cobranca, maximum: 3, message: 'deve ter 3 dígitos.'
        validates_length_of :agencia_cobranca, maximum: 5, message: 'deve ter 5 dígitos.'

        def monta_header
          # Tipo de Registro        Identificação Registro Header 9(01) 1 1 "0"
          # Cód. Arquivo            Identificação Arquivo REMESSA 9(01) 2 2 "1"
          # Ident. Arquivo          Identificação Arquivo REMESSA P/EXTENSO X(07) 3 9 "REMESSA"
          # Cód. Serviço Código     Identificação Do Serviço 9(02) 10 11 "01"
          # Ident. Serviço          Identificação Do Serviço P/ Extenso X(08) 12 19 "Cobrança"
          # Brancos                 Brancos X(07) 20 26 Brancos
          # Cód. Empresa            Ident. Empresa No Banco (Fornecido Pelo Banco) 9(14) 27 40 Cod. do Beneficiário (5 primeiras posições agência + 9 posições conta) Ag (5) + Cta Cob (9)
          # Brancos                 Brancos X(06) 41 46 Brancos
          # Nome Empresa            Nome Da Empresa Beneficiária X(30) 47 76 Razão Social
          # Cód. Banco              Código De Identificação Do Banco 9(03) 77 79 "422"
          # Nome Banco              Nome Do Banco Por Extenso X(11) 80 90 "SAFRA" ou "BANCO SAFRA"
          # Brancos                 Brancos X(04) 91 94 Brancos
          # Data Gravação           Data Da Geração Do Arquivo REMESSA 9(06) 95 100 dd/mm/aa
          # Brancos                 Brancos X(291) 101 391 Brancos
          # Núm. Arquivo            Número Seqüencial De Geração Do Arquivo 9(03) 392 394 Num. Arquivo
          # Núm. Registro           Número Seqüencial Do Registro No Arquivo 9(06) 395 400 "000001" 

          "01REMESSA01Cobrança       #{info_conta}      #{empresa_mae.format_size(30)}#{cod_banco}#{nome_banco}    #{data_geracao}#{complemento}#{sequencial_remessa}000001"
        end

        def agencia=(valor)
          @agencia = valor.to_s.rjust(5, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(7, '0') if valor
        end

        def codigo_empresa=(valor)
          @codigo_empresa = valor.to_s.rjust(14, '0') if valor
        end

        def sequencial_remessa=(valor)
          @sequencial_remessa = valor.to_s.rjust(3, '0') if valor
        end

        def info_conta
          codigo_empresa
        end

        def cod_banco
          '422'
        end

        def nome_banco
          'SAFRA'.ljust(11  , ' ')
        end

        def complemento
          "#{''.rjust(291, ' ')}"
        end

        def identificacao_empresa
          # identificacao da empresa no banco
          identificacao = '0'                            # vazio                       [1]
          identificacao << carteira.to_s.rjust(3, '0')   # carteira                    [3]
          identificacao << agencia                       # codigo da agencia (sem dv)  [5]
          identificacao << conta_corrente                # codigo da conta             [7]
          identificacao << digito_conta                  # digito da conta             [1]
        end

        def digito_nosso_numero(nosso_numero)
          nosso_numero.modulo11(
            reverse: false,
            mapeamento: { 10 => 0, 11 => 1 }
          ) { |total| 11 - (total % 11) }
        end

        # Formata o endereco do sacado
        # de acordo com os caracteres disponiveis (40)
        # concatenando o endereco, cidade e uf
        #
        def formata_endereco_sacado(pgto)
          endereco = "#{pgto.endereco_sacado}, #{pgto.cidade_sacado}/#{pgto.uf_sacado}"
          return endereco.ljust(40, ' ') if endereco.size <= 40
          "#{pgto.endereco_sacado[0..19]} #{pgto.cidade_sacado[0..14]}/#{pgto.uf_sacado}".format_size(40)
        end

        def monta_detalhe(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          detalhe = '1'                                               # identificacao do registro                   9[01]       001 a 001
          detalhe << '02'                                             # Tipo De Inscrição Da Empresa CNPJ 02        9[02]       002 a 003
          detalhe << documento_cedente                                # CNPJ 02                                     9[14]       004 a 017
          detalhe << info_conta                                       # Identificação Da Empresa No Banco           9[14]       018 a 031
          detalhe << ''.rjust(6, ' ')                                 # Brancos                                     X[06]       032 a 037
          detalhe << ''.rjust(25, ' ')                                # Uso Exclusivo Da Empresa                    X[25]       038 a 062
          detalhe << pagamento.nosso_numero[0..7].to_s.rjust(8, '0')  # identificacao do titulo (nosso numero)      9[08]       063 a 070
          detalhe << pagamento.nosso_numero[8].to_s                   # dv nosso numero                             9[01]       070 a 071
          detalhe << ''.rjust(30, ' ')                                # Brancos                                     X[30]       072 a 101
          detalhe << '0'                                              # Código Iof Operações De Seguro              9[01]       102 a 102
          detalhe << '00'                                             # Identificação Do Tipo De Moeda              9[02]       103 a 104
          detalhe << ''.rjust(1, ' ')                                 # Brancos                                     X[01]       105 a 105
          detalhe << pagamento.dias_protesto.to_s.ljust(2, '0')       # Terceira Instrução De Cobrança              9[02]       106 a 107
          detalhe << carteira                                         # carteira                                    9[01]       108 a 108
          detalhe << pagamento.identificacao_ocorrencia               # identificacao ocorrencia                    9[02]       109 a 110
          detalhe << pagamento.documento_ou_numero.to_s.ljust(10, ' ').format_size(10)# num. controle                         X[10]       111 a 120
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')     # data de vencimento                          9[06]       121 a 126
          detalhe << pagamento.formata_valor                          # valor do titulo                             9[13]       127 a 139
          detalhe << banco_cobranca.presence || '422'                 # Código Do Banco Encarregado Da Cobrança     9[03]       140 a 142
          detalhe << agencia_cobranca.to_s.ljust(5, '0')              # Agência Encarregada Da Cobrança             9[05]       143 a 147
          detalhe << pagamento.especie_titulo                         # especie do titulo                           9[02]       148 a 149
          detalhe << 'N'                                              # aceite (A=A/N=N)                            X[01]       150 a 150
          detalhe << pagamento.data_emissao.strftime('%d%m%y')        # data de emissao                             9[06]       151 a 156
          detalhe << ''.rjust(2, '0')                                 # 1a instrucao                                9[02]       157 a 158
          detalhe << ''.rjust(2, '0')                                 # 2a instrucao                                9[02]       159 a 160
          detalhe << pagamento.formata_valor_mora                     # mora                                        9[13]       161 a 173
          detalhe << pagamento.formata_data_desconto                  # data desconto                               9[06]       174 a 179
          detalhe << pagamento.formata_valor_desconto                 # valor desconto                              9[13]       180 a 192
          detalhe << pagamento.formata_valor_iof                      # valor iof                                   9[13]       193 a 205
          detalhe << pagamento.formata_valor_abatimento               # valor abatimento                            9[13]       206 a 218
          detalhe << pagamento.identificacao_sacado                   # identificacao do pagador                    9[02]       219 a 220
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')   # cpf/cnpj do pagador                         9[14]       221 a 234
          detalhe << pagamento.nome_sacado.format_size(40)            # nome do pagador                             9[40]       235 a 274
          detalhe << formata_endereco_sacado(pagamento)               # endereco do pagador                         X[40]       275 a 314
          detalhe << pagamento.bairro_sacado.format_size(10)          # bairro do pagador                           X[10]       315 a 324
          detalhe << ''.rjust(2, ' ')                                 # brancos                                     X[02]       325 a 326
          detalhe << pagamento.cep_sacado[0..4]                       # cep do pagador                              9[05]       327 a 331
          detalhe << pagamento.cep_sacado[5..7]                       # sufixo do cep do pagador                    9[03]       332 a 334
          detalhe << pagamento.cidade_sacado.format_size(15)          # cidade do pagador                           X[15]       335 a 349
          detalhe << pagamento.uf_sacado                              # UF do pagador                               X[02]       350 a 351
          detalhe << ''.rjust(30, ' ')                                # sacador/2a mensagem - verificar             X[30]       352 a 381
          detalhe << ''.rjust(7, ' ')                                 # brancos                                     X[07]       382 a 388
          detalhe << '422'                                            # Banco Emitente do Boleto                    9[03]       389 a 391
          detalhe << sequencial_remessa.to_s.rjust(3, '0')            # Numero Seqüencial Geração Arquivo Remessa   9[03]       392 a 394
          detalhe << sequencial.to_s.rjust(6, '0')                    # numero do registro do arquivo               9[06]       395 a 400

          detalhe
        end

        # Tipo de Registro Identificação Registro Trailler 9(01) 1 1 9 (Nove)
        # Brancos Brancos X(367) 2 368 Brancos
        # Quantidade Quantidade De Títulos Existentes Arquivo 9(08) 369 376
        # Valor Total Valor Total Dos Títulos 9(13)V99 377 391
        # Núm. Arquivo Número Seqüencial De Geração Do Arquivo 9(03) 392 394
        # Último Numero Num. Seqüencial Número Seqüencial Do Registro No Arquivo 9(06) 395 400 De Seq + 1 

        # Trailer do arquivo remessa
        #
        # @param sequencial
        #   num. sequencial do registro no arquivo
        #
        # @return [String]
        #
        def monta_trailer(sequencial)
          # CAMPO                   TAMANHO  VALOR
          # identificacao registro  [1]      9
          # complemento             [393]
          # num. sequencial         [6]
          "9#{''.rjust(367, ' ')}#{pagamentos.count.to_s.rjust(8, '0')}#{format_value(pagamentos.sum(&:valor), 13)}#{sequencial_remessa.to_s.rjust(3, '0')}#{sequencial.to_s.rjust(6, '0')}"
        end
      end
    end
  end
end
