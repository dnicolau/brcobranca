# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Retorno::Cnab400::Daycoval do
  def arquivo_daycoval
    @arquivo_daycoval ||= begin
      arquivo = Tempfile.new('CNAB400DAYCOVAL')
      arquivo.write("#{header_daycoval}\n#{detalhe_daycoval}\n#{trailer_daycoval}\n")
      arquivo.close
      arquivo
    end
  end

  def header_daycoval
    "#{'0'.ljust(76)}707#{''.ljust(321)}"
  end

  def detalhe_daycoval
    detalhe = +'1'
    detalhe << '02'
    detalhe << '12345678000199'
    detalhe << '00000000000000012345'
    detalhe << 'USO EMPRESA'.ljust(25)
    detalhe << '00043095408'
    detalhe << ''.ljust(9)
    detalhe << '121'
    detalhe << ''.ljust(9)
    detalhe << ''.ljust(13)
    detalhe << '6'
    detalhe << '02'
    detalhe << '170526'
    detalhe << 'NF123'.ljust(10)
    detalhe << ''.ljust(20)
    detalhe << '230526'
    detalhe << '0000000019990'
    detalhe << '707'
    detalhe << '0001'
    detalhe << '9'
    detalhe << '01'
    detalhe << '0000000000123'
    detalhe << ''.ljust(26)
    detalhe << '0000000000000'
    detalhe << '0000000000000'
    detalhe << '0000000000000'
    detalhe << '0000000019990'
    detalhe << '0000000000000'
    detalhe << ''.rjust(13, '0')
    detalhe << ''.rjust(84, ' ')
    detalhe << '1'
    detalhe << '03000000'
    detalhe << '170526'
    detalhe << '000'
    detalhe << '000002'
    detalhe
  end

  def trailer_daycoval
    '9' + '2' + '01' + '707' + ''.rjust(98, '0') + ''.rjust(289, '0') + '000003'
  end

  after do
    @arquivo_daycoval&.unlink
  end

  it 'Ignora primeira linha que é header' do
    pagamentos = described_class.load_lines(arquivo_daycoval.path)
    pagamento = pagamentos.first
    expect(pagamento.sequencial).to eql('000002')
  end

  it 'Transforma arquivo de retorno em objetos de retorno' do
    pagamentos = described_class.load_lines(arquivo_daycoval.path)
    expect(pagamentos.size).to eq(1)

    pagamento = pagamentos.first
    expect(pagamento.codigo_registro).to eql('1')
    expect(pagamento.codigo_empresa).to eql('00000000000000012345')
    expect(pagamento.uso_empresa).to eql('USO EMPRESA')
    expect(pagamento.nosso_numero).to eql('00043095408')
    expect(pagamento.carteira).to eql('121')
    expect(pagamento.codigo_carteira).to eql('6')
    expect(pagamento.codigo_operacao_cobranca).to eql('6')
    expect(pagamento.codigo_ocorrencia).to eql('02')
    expect(pagamento.data_ocorrencia).to eql('170526')
    expect(pagamento.documento_numero).to eql('NF123')
    expect(pagamento.data_vencimento).to eql('230526')
    expect(pagamento.valor_titulo).to eql('0000000019990')
    expect(pagamento.banco_recebedor).to eql('707')
    expect(pagamento.agencia_recebedora_com_dv).to eql('00019')
    expect(pagamento.especie_documento).to eql('01')
    expect(pagamento.valor_tarifa).to eql('0000000000123')
    expect(pagamento.iof).to eql('0000000000000')
    expect(pagamento.valor_abatimento).to eql('0000000000000')
    expect(pagamento.desconto).to eql('0000000000000')
    expect(pagamento.valor_recebido).to eql('0000000019990')
    expect(pagamento.juros_mora).to eql('0000000000000')
    expect(pagamento.codigo_moeda).to eql('1')
    expect(pagamento.motivo_ocorrencia).to eql(['03'])
    expect(pagamento.data_gravacao).to eql('170526')
    expect(pagamento.data_credito).to eql('170526')
    expect(pagamento.agencia_sem_dv).to eql('')
    expect(pagamento.agencia_com_dv).to eql('')
    expect(pagamento.cedente_com_dv).to eql('')
    expect(pagamento.sequencial).to eql('000002')
  end
end
