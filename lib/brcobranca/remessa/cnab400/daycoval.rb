# frozen_string_literal: true

module Brcobranca
  module Remessa
    module Cnab400
      # Banco Daycoval - CNAB400
      class Daycoval < Brcobranca::Remessa::Cnab400::Base
        # Código da empresa é fornecido pelo Banco Daycoval e ocupa 20 posições.
        # Operação e DV da agência não participam do layout de remessa, mas são
        # recebidos por compatibilidade com os dados bancários usados no boleto.
        attr_reader :codigo_empresa
        attr_accessor :operacao, :agencia_dv

        validates_presence_of :documento_cedente, :codigo_empresa, message: 'não pode estar em branco.'
        validates_length_of :documento_cedente, minimum: 11, maximum: 14, message: 'deve ter entre 11 e 14 dígitos.'
        validates_length_of :codigo_empresa, is: 20, message: 'deve ter 20 posições.'
        validates_length_of :carteira, maximum: 3, message: 'deve ter no máximo 3 dígitos.'

        # Nova instancia de remessa CNAB400 do Daycoval.
        # @param (see Brcobranca::Remessa::Base#initialize)
        def initialize(campos = {})
          campos = { aceite: 'N', carteira: '121' }.merge!(campos)
          super
        end

        # Codigo do banco na câmara de compensação.
        # @return [String] 3 caracteres numéricos.
        def cod_banco
          '707'
        end

        # Nome do banco no header do arquivo.
        # @return [String] 15 caracteres alfanuméricos.
        def nome_banco
          'BANCO DAYCOVAL'.format_size(15)
        end

        # Código da empresa no banco.
        # @return [String] 20 caracteres alfanuméricos.
        def codigo_empresa=(valor)
          @codigo_empresa = valor.to_s.format_size(20) if valor
        end

        # Carteira de cobrança.
        # @return [String] 3 caracteres numéricos.
        def carteira=(valor)
          @carteira = valor.to_s.rjust(3, '0') if valor
        end

        # Informações da conta no header.
        #
        # CAMPO             TAMANHO
        # codigo_empresa    20
        def info_conta
          codigo_empresa
        end

        # Complemento em branco do header.
        # @return [String] 294 caracteres alfanuméricos.
        def complemento
          ''.rjust(294, ' ')
        end

        # Detalhe tipo 1 do arquivo remessa.
        #
        # @param pagamento [Brcobranca::Remessa::Pagamento]
        #   objeto contendo as informações do título e do sacado.
        # @param sequencial
        #   número sequencial do registro no arquivo.
        #
        # @return [String] 400 bytes.
        def monta_detalhe(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

          detalhe = '1'                                           # 001-001 Código do registro
          detalhe += codigo_inscricao_empresa(pagamento)          # 002-003 Tipo inscrição cedente/sacador
          detalhe << documento_empresa(pagamento)                 # 004-017 CPF/CNPJ cedente/sacador
          detalhe << codigo_empresa                               # 018-037 Código da empresa no banco
          detalhe << uso_empresa(pagamento)                       # 038-062 Uso da empresa
          detalhe << nosso_numero_remessa(pagamento)              # 063-070 Nosso número sem DV
          detalhe << ''.rjust(13, ' ')                            # 071-083 Brancos
          detalhe << ''.rjust(24, ' ')                            # 084-107 Uso do banco
          detalhe << '6'                                          # 108-108 Código de remessa

          # Código de ocorrência:
          # 01 = Remessa
          # 02 = Pedido de baixa
          # 04 = Concessão de abatimento
          # 06 = Alteração de vencimento
          # 09 = Protestar
          # 10 = Pedido de não protestar
          detalhe << pagamento.identificacao_ocorrencia           # 109-110 Código de ocorrência
          detalhe << numero_documento(pagamento)                  # 111-120 Seu número
          detalhe << pagamento.data_vencimento.strftime('%d%m%y') # 121-126 Vencimento
          detalhe << pagamento.formata_valor                      # 127-139 Valor do título
          detalhe << cod_banco                                    # 140-142 Código do banco
          detalhe << ''.rjust(4, '0')                             # 143-146 Agência cobradora
          detalhe << '0'                                          # 147-147 DAC agência cobradora

          # Espécie de título:
          # 01 = Duplicata
          # 05 = Recibo
          # 12 = Duplicata de serviço
          # 99 = Outros
          detalhe << pagamento.especie_titulo                     # 148-149 Espécie
          detalhe << 'N'                                          # 150-150 Aceite
          detalhe << pagamento.data_emissao.strftime('%d%m%y')    # 151-156 Data de emissão
          detalhe << ''.rjust(2, '0')                             # 157-158 Zeros
          detalhe << ''.rjust(2, '0')                             # 159-160 Zeros
          detalhe << ''.rjust(13, '0')                            # 161-173 Juros de 1 dia
          detalhe << pagamento.formata_data_desconto              # 174-179 Desconto até
          detalhe << pagamento.formata_valor_desconto             # 180-192 Valor do desconto
          detalhe << ''.rjust(13, '0')                            # 193-205 Uso do banco
          detalhe << valor_abatimento(pagamento)                  # 206-218 Valor de abatimento
          detalhe << pagamento.identificacao_sacado               # 219-220 Tipo inscrição sacado
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0') # 221-234 Documento sacado
          detalhe << pagamento.nome_sacado.format_size(30)        # 235-264 Nome sacado
          detalhe << ''.rjust(10, ' ')                            # 265-274 Brancos
          detalhe << endereco_completo_sacado(pagamento)          # 275-314 Rua, número e complemento
          detalhe << pagamento.bairro_sacado.format_size(12)      # 315-326 Bairro
          detalhe << pagamento.cep_sacado                         # 327-334 CEP
          detalhe << pagamento.cidade_sacado.format_size(15)      # 335-349 Cidade
          detalhe << pagamento.uf_sacado                          # 350-351 UF
          detalhe << sacador_avalista(pagamento)                  # 352-381 Sacador avalista
          detalhe << ''.rjust(4, ' ')                             # 382-385 Brancos
          detalhe << ''.rjust(6, ' ')                             # 386-391 Brancos
          detalhe << ''.rjust(2, '0')                             # 392-393 Prazo protesto
          detalhe << '0'                                          # 394-394 Moeda corrente nacional
          detalhe << sequencial.to_s.rjust(6, '0')                # 395-400 Sequencial
          detalhe
        end

        private

        # Tipo de inscrição usado nas posições 002-003.
        # 01 = CPF cedente, 02 = CNPJ cedente, 03 = CPF sacador, 04 = CNPJ sacador.
        def codigo_inscricao_empresa(pagamento)
          codigo = Brcobranca::Util::Empresa.new(documento_base_empresa(pagamento)).tipo.to_i
          codigo += 2 if sacador_avalista_informado?(pagamento)
          codigo.to_s.rjust(2, '0')
        end

        # CPF/CNPJ usado nas posições 004-017.
        # Para títulos de terceiros, usa o documento do sacador/avalista.
        def documento_empresa(pagamento)
          documento_base_empresa(pagamento).to_s.somente_numeros.rjust(14, '0')
        end

        # Documento base para identificar cedente ou sacador/avalista.
        def documento_base_empresa(pagamento)
          return pagamento.documento_avalista if sacador_avalista_informado?(pagamento)

          documento_cedente
        end

        # Indica se a remessa deve sair como título de terceiros.
        def sacador_avalista_informado?(pagamento)
          pagamento.documento_avalista.present?
        end

        # Campo livre do cliente, retornado pelo banco no arquivo retorno.
        def uso_empresa(pagamento)
          pagamento.documento_ou_numero.to_s.format_size(25)
        end

        # Nosso número Daycoval sem DV nas posições 063-070.
        def nosso_numero_remessa(pagamento)
          pagamento.nosso_numero.to_s.somente_numeros.rjust(8, '0')[-8..]
        end

        # Número do documento de cobrança nas posições 111-120.
        def numero_documento(pagamento)
          (pagamento.numero.presence || pagamento.documento_ou_numero).to_s.format_size(10)
        end

        # Valor de abatimento só deve ser informado para ocorrência 04.
        def valor_abatimento(pagamento)
          return pagamento.formata_valor_abatimento if pagamento.identificacao_ocorrencia == '04'

          ''.rjust(13, '0')
        end

        # Nome da rua/avenida, número e complemento nas posições 275-314.
        def endereco_completo_sacado(pagamento)
          [
            pagamento.endereco_sacado,
            pagamento.numero_endereco_sacado,
            pagamento.complemento_endereco_sacado
          ].map(&:to_s).reject(&:blank?).join(' ').format_size(40)
        end

        # Sacador/avalista nas posições 352-381.
        # Se não houver sacador, enviar o nome do cedente.
        def sacador_avalista(pagamento)
          nome = sacador_avalista_informado?(pagamento) ? pagamento.nome_avalista : empresa_mae
          nome.to_s.format_size(30)
        end
      end
    end
  end
end
