# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Retorno::Cnab240::Banrisul do
  before do
    @arquivo = File.join(File.dirname(__FILE__), '..', '..', '..', 'arquivos', 'CNAB240BANRISUL.RET')
  end

  it 'transforma arquivo de retorno em objetos usando os segmentos T e U do Banrisul' do
    pagamentos = described_class.load_lines(@arquivo)

    expect(pagamentos.size).to eq(1)

    pagamento = pagamentos.first
    expect(pagamento.codigo_registro).to eql('3')
    expect(pagamento.codigo_ocorrencia).to eql('06')
    expect(pagamento.agencia_com_dv).to eql('01102')
    expect(pagamento.cedente_com_dv).to eql('0000000123456')
    expect(pagamento.nosso_numero).to eql('2283256351')
    expect(pagamento.carteira).to eql('1')
    expect(pagamento.documento_numero).to eql('1')
    expect(pagamento.data_vencimento).to eql('14072015')
    expect(pagamento.valor_titulo).to eql('000000000019990')
    expect(pagamento.banco_recebedor).to eql('041')
    expect(pagamento.agencia_recebedora_com_dv).to eql('01102')
    expect(pagamento.sequencial).to eql('00001')
    expect(pagamento.valor_tarifa).to eql('000000000000170')
    expect(pagamento.motivo_ocorrencia).to eql(['03'])
    expect(pagamento.juros_mora).to eql('000000000000010')
    expect(pagamento.desconto_concedito).to eql('000000000000020')
    expect(pagamento.valor_abatimento).to eql('000000000000030')
    expect(pagamento.iof_desconto).to eql('000000000000040')
    expect(pagamento.valor_recebido).to eql('000000000020000')
    expect(pagamento.valor_liquido).to eql('000000000019700')
    expect(pagamento.outras_despesas).to eql('000000000000050')
    expect(pagamento.outros_recebimento).to eql('000000000000060')
    expect(pagamento.data_ocorrencia).to eql('15072015')
    expect(pagamento.data_credito).to eql('16072015')
    expect(pagamento.complemento_ocorrencia).to eql('CONTRATO CREDITO 123')
    expect(pagamento.banco_correspondente).to eql('000')
    expect(pagamento.nosso_numero_banco_correspondente).to eql('00000000000000000000')
  end
end
