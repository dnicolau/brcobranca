# frozen_string_literal: true

module Brcobranca
  module Boleto
    # Banrisul
    class Banrisul < Base
      # <b>REQUERIDO</b>: digito verificador do convenio
      attr_writer :digito_convenio

      validates_length_of :agencia, maximum: 4, message: 'deve ser menor ou igual a 4 dígitos.'
      validates_length_of :conta_corrente, maximum: 8, message: 'deve ser menor ou igual a 8 dígitos.'
      validates_length_of :nosso_numero, maximum: 8, message: 'deve ser menor ou igual a 8 dígitos.'
      validates_length_of :carteira, maximum: 1, message: 'deve ser menor ou igual a 1 dígitos.'
      validates_length_of :convenio, is: 13, message: 'deve ter 13 dígitos.'
      validates_length_of :digito_convenio, maximum: 2, message: 'deve ser menor ou igual a 2 dígitos.'

      def initialize(campos = {})
        campos = {
          carteira: '2',
          local_pagamento: 'Pagável preferencialmente na rede integrada Banrisul'
        }.merge!(campos)
        super(campos)
      end

      # Codigo do banco emissor (3 dígitos sempre)
      #
      # @return [String] 3 caracteres numéricos.
      def banco
        '041'
      end

      # Dígito verificador do banco
      #
      # @return [String] 1 caractere.
      def banco_dv
        '8'
      end

      # Agência
      #
      # @return [String] 4 caracteres numéricos.
      def agencia=(valor)
        @agencia = valor.to_s.rjust(4, '0') if valor
      end

      # Conta
      #
      # @return [String] 8 caracteres numéricos.
      def conta_corrente=(valor)
        @conta_corrente = valor.to_s.rjust(8, '0') if valor
      end

      # Número documento
      #
      # @return [String] 8 caracteres numéricos.
      def nosso_numero=(valor)
        @nosso_numero = valor.to_s.rjust(8, '0') if valor
      end

      # Código do beneficiário junto ao banco.
      # @return [String] 13 caracteres numéricos.
      def convenio=(valor)
        @convenio = valor.to_s.rjust(13, '0') if valor
      end

      # Digito do convênio do cliente junto ao banco.
      # @return [String] 2 caracteres numéricos.
      def digito_convenio=(valor)
        @digito_convenio = valor.to_s.rjust(2, '0') if valor
      end

      def digito_convenio
        @digito_convenio || codigo_beneficiario_controle if convenio
      end

      # Nosso número para exibição no boleto.
      #
      # @return [String] caracteres numéricos.
      def nosso_numero_boleto
        "#{nosso_numero}-#{nosso_numero.duplo_digito}"
      end

      def agencia_conta_boleto
        "#{codigo_beneficiario_agencia} / #{codigo_beneficiario[0..5]}.#{codigo_beneficiario[6]}.#{digito_convenio}"
      end

      # Posição 20 a 20 - Constante 2
      # Posição 21 a 21 - Constante 1
      # Posição 22 a 25 - 4 primeiras posições do Código de Beneficiário.
      # Posição 26 a 32 - Posições 5 a 11 do Código de Beneficiário sem Número de Controle.
      # Posição 33 a 40 - Nosso Número sem Número de Controle.
      # Posição 41 a 42 - Constante 40.
      # Posição 43 a 44 - Duplo Dígito referente às posições 20 a 42 (módulos 10 e 11).
      def codigo_barras_segunda_parte
        campo_livre = "21#{codigo_beneficiario_agencia}#{codigo_beneficiario}#{nosso_numero}40"
        campo_livre + campo_livre.duplo_digito
      end

      private

      def codigo_beneficiario_agencia
        convenio[0..3]
      end

      def codigo_beneficiario
        convenio[4..10]
      end

      def codigo_beneficiario_controle
        convenio[11..12]
      end
    end
  end
end
