# frozen_string_literal: true

module Brcobranca
  module Boleto
    # Banco Daycoval
    class Daycoval < Base
      # Código da empresa fornecido pelo Banco Daycoval para a remessa.
      # Mantido aqui por compatibilidade com os dados bancários enviados para
      # boleto, mas não compõe o campo livre do código de barras.
      #
      # Operação compõe o campo livre do código de barras.
      attr_accessor :codigo_empresa, :operacao

      # Dígitos usados na impressão do boleto. Quando não informados, seguem o
      # cálculo padrão da classe base.
      attr_writer :agencia_dv, :conta_corrente_dv

      validates_presence_of :carteira, :operacao, message: 'não pode estar em branco.'
      validates_numericality_of :carteira, :operacao, message: 'não é um número.'
      validates_length_of :agencia, maximum: 4, message: 'deve ser menor ou igual a 4 dígitos.'
      validates_length_of :carteira, maximum: 3, message: 'deve ser menor ou igual a 3 dígitos.'
      validates_length_of :operacao, maximum: 7, message: 'deve ser menor ou igual a 7 dígitos.'
      validates_length_of :nosso_numero, maximum: 10, message: 'deve ser menor ou igual a 10 dígitos.'

      # Nova instancia do Daycoval.
      # @param (see Brcobranca::Boleto::Base#initialize)
      def initialize(campos = {})
        campos = {
          carteira: '121',
          local_pagamento: 'PAGAVEL EM QUALQUER AGENCIA BANCARIA, MESMO APOS VENCIMENTO'
        }.merge!(campos)

        super(campos)
      end

      # Codigo do banco emissor.
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '707'
      end

      # Agência do título, sem DV.
      # @return [String] 4 caracteres numéricos.
      def agencia=(valor)
        @agencia = valor.to_s.rjust(4, '0') if valor
      end

      # Carteira de cobrança enviada pelo banco.
      # @return [String] 3 caracteres numéricos.
      def carteira=(valor)
        @carteira = valor.to_s.rjust(3, '0') if valor
      end

      # Operação de cobrança enviada pelo banco.
      # @return [String] 7 caracteres numéricos.
      def operacao=(valor)
        @operacao = valor.to_s.rjust(7, '0') if valor
      end

      # Nosso número Daycoval, sem DV.
      # @return [String] 10 caracteres numéricos.
      def nosso_numero=(valor)
        @nosso_numero = valor.to_s.rjust(10, '0') if valor
      end

      # Dígito da agência para exibição no boleto.
      # @return [String] 1 caractere numérico.
      def agencia_dv
        @agencia_dv || super
      end

      # Dígito da conta corrente para exibição no boleto.
      # @return [String] 1 caractere numérico.
      def conta_corrente_dv
        @conta_corrente_dv || super
      end

      # Dígito verificador do nosso número.
      #
      # Calculado sobre agência sem DV + carteira + nosso número, com a sequência
      # de pesos 2,1,2,1,2,1... da direita para a esquerda e soma dos dígitos dos
      # produtos.
      #
      # @return [Integer] 1 caractere numérico.
      def nosso_numero_dv
        base = "#{agencia}#{carteira}#{nosso_numero}"
        total = base.multiplicador(fatores: [2, 1]) do |caracter, fator|
          (caracter.to_i * fator).soma_digitos
        end

        resto = total % 10
        resto.zero? ? 0 : 10 - resto
      end

      # Nosso número para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.nosso_numero_boleto #=> "00019/121/0004309540-8"
      def nosso_numero_boleto
        "#{agencia}#{agencia_dv}/#{carteira}/#{nosso_numero}-#{nosso_numero_dv}"
      end

      # Agência + conta corrente para exibir no boleto.
      # @return [String]
      # @example
      #  boleto.agencia_conta_boleto #=> "00019 / 00123456"
      def agencia_conta_boleto
        "#{agencia}#{agencia_dv} / #{conta_corrente}#{conta_corrente_dv}"
      end

      # Segunda parte do código de barras, chamada de campo livre.
      # 9(04) | Agência sem DV
      # 9(03) | Carteira
      # 9(07) | Operação
      # 9(11) | Nosso número com DV
      #
      # @return [String] 25 caracteres numéricos.
      def codigo_barras_segunda_parte
        "#{agencia}#{carteira}#{operacao}#{nosso_numero}#{nosso_numero_dv}"
      end
    end
  end
end
