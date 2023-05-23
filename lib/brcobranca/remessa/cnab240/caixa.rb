# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab240
      class Caixa < Brcobranca::Remessa::Cnab240::Base
        # digito da agencia
        attr_accessor :digito_agencia
        # versao do aplicativo da CAIXA
        attr_accessor :versao_aplicativo
        # modalidade da carteira
        #   opcoes:
        #     11: título Registrado emissão CAIXA
        #     14: título Registrado emissão Cedente
        #     21: título Sem Registro emissão CAIXA
        attr_accessor :modalidade_carteira
        # identificacao da emissao do boleto (attr na classe base)
        #   opcoes:
        #     ‘1’ = Banco Emite
        #     ‘2’ = Cliente Emite ou para Bloqueto Pré-Impresso Registrado (entrega do bloqueto pelo Cedente)
        #     ‘4’ = Banco Reemite
        #     ‘5’ = Banco Não Reemite
        #
        # identificacao da distribuicao do boleto (attr na classe base)
        #   opcoes:
        #     ‘0’ = Postagem pelo Cedente
        #     ‘1’ = Sacado via Correios
        #     ‘2’ = Cedente via Agência CAIXA
        #     ‘3’ = Sacado via e-mail
        #     ‘4’ = Sacado via SMS

        validates_presence_of :digito_agencia, :convenio, message: 'não pode estar em branco.'
        validates_length_of :convenio, maximum: 7, message: 'deve ter 7 dígitos.'
        validates_length_of :versao_aplicativo, maximum: 4, message: 'deve ter 4 dígitos.'
        validates_length_of :digito_agencia, is: 1, message: 'deve ter 1 dígito.'
        validates_length_of :modalidade_carteira, is: 2, message: 'deve ter 2 dígitos.'

        def initialize(campos = {})
          # Modalidade carteira: 14 (título Registrado emissão Cedente)
          campos = { modalidade_carteira: '14',
                     emissao_boleto: '2',
                     codigo_baixa: '2',
                     dias_baixa: '000',
                     distribuicao_boleto: '0',
                     especie_titulo: '99' }.merge!(campos)
          super(campos)
        end

        # Monta o registro segmento Q do arquivo
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        #   objeto contendo os detalhes do boleto (valor, vencimento, sacado, etc)
        # @param nro_lote [Integer]
        #   numero do lote que o segmento esta inserido
        # @param sequencial [Integer]
        #   numero sequencial do registro no lote
        #
        # @return [String]
        #
        def monta_segmento_q(pagamento, nro_lote, sequencial)
          segmento_q = ''                                               # CAMPO                                TAMANHO
          segmento_q << cod_banco                                       # codigo banco                         3
          segmento_q << nro_lote.to_s.rjust(4, '0')                     # lote de servico                      4
          segmento_q << '3'                                             # tipo de registro                     1
          segmento_q << sequencial.to_s.rjust(5, '0')                   # num. sequencial do registro no lote  5
          segmento_q << 'Q'                                             # cod. segmento                        1
          segmento_q << ' '                                             # uso exclusivo                        1
          segmento_q << pagamento.identificacao_ocorrencia              # cod. movimento remessa               2
          segmento_q << pagamento.identificacao_sacado(false)           # tipo insc. sacado                    1
          segmento_q << pagamento.documento_sacado.to_s.rjust(15, '0')  # documento sacado                     14
          segmento_q << pagamento.nome_sacado.format_size(40)           # nome cliente                         40
          segmento_q << pagamento.endereco_sacado.format_size(40)       # endereco cliente                     40
          segmento_q << pagamento.bairro_sacado.format_size(15)         # bairro                               15
          segmento_q << pagamento.cep_sacado[0..4]                      # cep                                  5
          segmento_q << pagamento.cep_sacado[5..7]                      # sufixo cep                           3
          segmento_q << pagamento.cidade_sacado.format_size(15)         # cidade                               15
          segmento_q << pagamento.uf_sacado                             # uf                                   2
          segmento_q << pagamento.identificacao_avalista(false)         # identificacao do sacador             1
          segmento_q << pagamento.documento_avalista.to_s.rjust(15, '0')# documento sacador                    15
          segmento_q << pagamento.nome_avalista.format_size(40)         # nome avalista                        40
          segmento_q << ''.rjust(3, ' ')                                # cod. banco correspondente            3
          segmento_q << ''.rjust(20, ' ')                               # nosso numero banco correspondente    20
          segmento_q << ''.rjust(8, ' ')                                # uso exclusivo                        8
          segmento_q
        end

        def convenio=(valor)
          @convenio = valor.to_s.rjust(7, '0') if valor
        end

        def versao_aplicativo=(valor)
          @versao_aplicativo = valor.to_s.rjust(4, '0') if valor
        end

        def cod_banco
          '104'
        end

        def nome_banco
          'CAIXA ECONOMICA FEDERAL'.ljust(30, ' ')
        end

        def versao_layout_arquivo
          '050' if convenio.to_s.size > 6

          '101'
        end

        def versao_layout_lote
          '030' if convenio.to_s.size > 6

          '060'
        end

        def codigo_convenio
          ''.rjust(20, '0')
        end

        def uso_exclusivo_banco
          ''.rjust(20, ' ')
        end

        def uso_exclusivo_empresa
          'REMESSA-PRODUCAO'.ljust(20, ' ')
        end

        def convenio_lote
          "#{convenio.rjust(6, '0')}#{''.rjust(14, '0')}"
        end

        def info_conta
          # CAMPO            # TAMANHO
          # agencia          5
          # digito agencia   1
          # cod. convenio    6
          # uso CAIXA        7
          # uso CAIXA        1
          "#{agencia.to_s.rjust(5, '0')}#{digito_agencia}#{convenio}#{''.rjust(7, '0')}0"
        end

        def complemento_header
          versao = versao_aplicativo || ''
          "#{versao.rjust(4, ' ')}#{''.rjust(25, ' ')}"
        end

        def exclusivo_servico
          "00"
        end

        def complemento_trailer
          "#{''.rjust(69, '0')}#{''.rjust(148, ' ')}"
        end

        def tipo_documento
          "2"
        end

        def complemento_p(pagamento)
          # CAMPO                 TAMANHO
          # convenio              6
          # uso CAIXA             11
          # modalidade carteira   2
          # ident. titulo         15
          "#{convenio.rjust(6, '0')}#{''.rjust(11, '0')}#{modalidade_carteira}#{pagamento.nosso_numero.to_s.rjust(15, '0')}"
        end

        def complemento_r
          segmento_r = ''
          segmento_r << ''.rjust(50, ' ')  # e-mail do sacado     50
          segmento_r << ''.rjust(11, ' ')  # exclusivo FEBRABAN   11
          segmento_r
        end

        def numero(pagamento)
          "#{pagamento.formata_documento_ou_numero(11, "0")}#{''.rjust(4, ' ')}"
        end

        def identificacao_titulo_empresa(pagamento)
          "#{pagamento.formata_documento_ou_numero(11, "0")}#{''.rjust(14, ' ')}"
        end

        def data_multa(pagamento)
          return ''.rjust(8, '0') if pagamento.codigo_multa == '0'
          data_multa = pagamento.data_vencimento + 1
          data_multa.strftime('%d%m%Y')
        end

        def codigo_baixa(pagamento)
          return "1" if pagamento.codigo_protesto.to_s == "3"
          "2"
        end

        def dias_baixa(pagamento)
          return "120" if pagamento.codigo_protesto.to_s == "3"
          "000"
        end

        def data_mora(pagamento)
          return "".rjust(8, "0") unless %w( 1 2 ).include? pagamento.tipo_mora
          data_mora = pagamento.data_vencimento + 1
          data_mora.strftime("%d%m%Y")
        end
      end
    end
  end
end
