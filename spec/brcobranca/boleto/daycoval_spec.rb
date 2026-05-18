# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Boleto::Daycoval do
  before do
    @valid_attributes = {
      valor: 180.84,
      cedente: 'Empresa Teste',
      documento_cedente: '12345678000199',
      sacado: 'Cliente Teste',
      sacado_documento: '12345678901',
      agencia: '0001',
      agencia_dv: '9',
      conta_corrente: '12345',
      conta_corrente_dv: '6',
      carteira: '121',
      operacao: '1234567',
      nosso_numero: '0004309540'
    }
  end

  it 'Criar nova instancia com atributos padrões' do
    boleto_novo = described_class.new
    expect(boleto_novo.banco).to eql('707')
    expect(boleto_novo.especie_documento).to eql('DM')
    expect(boleto_novo.especie).to eql('R$')
    expect(boleto_novo.moeda).to eql('9')
    expect(boleto_novo.data_processamento).to eql(Date.current)
    expect(boleto_novo.data_vencimento).to eql(Date.current)
    expect(boleto_novo.aceite).to eql('S')
    expect(boleto_novo.quantidade).to be(1)
    expect(boleto_novo.valor).to eq(0.0)
    expect(boleto_novo.valor_documento).to eq(0.0)
    expect(boleto_novo.local_pagamento).to eql('PAGAVEL EM QUALQUER AGENCIA BANCARIA, MESMO APOS VENCIMENTO')
    expect(boleto_novo.carteira).to eql('121')
  end

  it 'Criar nova instancia com atributos válidos' do
    boleto_novo = described_class.new(@valid_attributes)
    expect(boleto_novo).to be_valid
    expect(boleto_novo.agencia).to eql('0001')
    expect(boleto_novo.conta_corrente).to eql('0012345')
    expect(boleto_novo.carteira).to eql('121')
    expect(boleto_novo.operacao).to eql('1234567')
    expect(boleto_novo.nosso_numero).to eql('0004309540')
  end

  it 'Gerar boleto' do
    @valid_attributes[:data_vencimento] = Date.parse('2025-02-23')
    boleto_novo = described_class.new(@valid_attributes)

    expect(boleto_novo.nosso_numero_dv).to eq(8)
    expect(boleto_novo.codigo_barras_segunda_parte).to eql('0001121123456700043095408')
    expect(boleto_novo.codigo_barras).to eql('70791100100000180840001121123456700043095408')
    expect(boleto_novo.codigo_barras.linha_digitavel).to eql('70790.00118 21123.456705 00430.954081 1 10010000018084')
  end

  it 'Não permitir gerar boleto com atributos inválido' do
    boleto_novo = described_class.new
    expect { boleto_novo.codigo_barras }.to raise_error(Brcobranca::BoletoInvalido)
  end

  it 'Montar nosso_numero_boleto' do
    boleto_novo = described_class.new(@valid_attributes)
    expect(boleto_novo.nosso_numero_boleto).to eql('121/0004309540-8')
  end

  it 'Montar agencia_conta_boleto' do
    boleto_novo = described_class.new(@valid_attributes)
    expect(boleto_novo.agencia_conta_boleto).to eql('00019 / 00123456')
  end

  describe 'Busca logotipo do banco' do
    it_behaves_like 'busca_logotipo'
  end
end
