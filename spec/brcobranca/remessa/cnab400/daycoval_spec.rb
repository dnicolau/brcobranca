# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::Daycoval do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 199.9,
                                       data_vencimento: Date.parse('2025-02-23'),
                                       data_emissao: Date.parse('2025-01-20'),
                                       numero: 'NF123',
                                       nosso_numero: '0004309540',
                                       documento: '6969',
                                       documento_sacado: '12345678901',
                                       nome_sacado: 'Cliente Teste de Cobrança Daycoval',
                                       endereco_sacado: 'Rua Rio Grande do Sul',
                                       numero_endereco_sacado: '123',
                                       complemento_endereco_sacado: 'Sala 4',
                                       bairro_sacado: 'Centro',
                                       cep_sacado: '12345678',
                                       cidade_sacado: 'São Paulo',
                                       uf_sacado: 'SP')
  end

  let(:params) do
    {
      carteira: '121',
      codigo_empresa: '12345',
      empresa_mae: 'Empresa Teste Daycoval Ltda',
      documento_cedente: '12345678000199',
      pagamentos: [pagamento]
    }
  end

  let(:daycoval) { described_class.new(params) }

  context 'validacoes dos campos' do
    it 'deve ser invalido se nao possuir documento cedente' do
      objeto = described_class.new(params.merge(documento_cedente: nil))
      expect(objeto.invalid?).to be true
      expect(objeto.errors.full_messages).to include('Documento cedente não pode estar em branco.')
    end

    it 'deve ser invalido se nao possuir codigo da empresa' do
      objeto = described_class.new(params.merge(codigo_empresa: nil))
      expect(objeto.invalid?).to be true
      expect(objeto.errors.full_messages).to include('Codigo empresa não pode estar em branco.')
    end
  end

  context 'formatacoes dos valores' do
    it 'cod_banco deve ser 707' do
      expect(daycoval.cod_banco).to eq '707'
    end

    it 'nome_banco deve ser BANCO DAYCOVAL com 15 posicoes' do
      nome_banco = daycoval.nome_banco
      expect(nome_banco.size).to eq 15
      expect(nome_banco.strip).to eq 'BANCO DAYCOVAL'
    end

    it 'info_conta deve retornar o codigo da empresa com 20 posicoes' do
      expect(daycoval.info_conta).to eq '12345'.ljust(20)
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab400'

    context 'header' do
      it 'informacoes devem estar posicionadas corretamente no header' do
        header = daycoval.monta_header
        expect(header[1]).to eq '1'
        expect(header[2..8]).to eq 'REMESSA'
        expect(header[26..45]).to eq daycoval.info_conta
        expect(header[76..78]).to eq '707'
        expect(header[79..93]).to eq 'BANCO DAYCOVAL '
      end
    end

    context 'detalhe' do
      it 'informacoes devem estar posicionadas corretamente no detalhe' do
        detalhe = daycoval.monta_detalhe(pagamento, 2)
        expect(detalhe[1..2]).to eq '02'
        expect(detalhe[3..16]).to eq '12345678000199'
        expect(detalhe[17..36]).to eq daycoval.codigo_empresa
        expect(detalhe[37..61]).to eq '6969'.ljust(25)
        expect(detalhe[62..69]).to eq '04309540'
        expect(detalhe[107]).to eq '6'
        expect(detalhe[108..109]).to eq '01'
        expect(detalhe[110..119]).to eq 'NF123'.ljust(10)
        expect(detalhe[120..125]).to eq '230225'
        expect(detalhe[126..138]).to eq '0000000019990'
        expect(detalhe[149]).to eq 'N'
        expect(detalhe[274..313]).to eq 'Rua Rio Grande do Sul 123 Sala 4'.ljust(40)
        expect(detalhe[351..380]).to eq 'Empresa Teste Daycoval Ltda'.ljust(30)
        expect(detalhe[393]).to eq '0'
        expect(detalhe[394..399]).to eq '000002'
      end

      it 'permite enviar titulo por CNPJ de sacador avalista' do
        pagamento.documento_avalista = '99887766000155'
        pagamento.nome_avalista = 'Filial Teste Daycoval'

        detalhe = daycoval.monta_detalhe(pagamento, 2)
        expect(detalhe[1..2]).to eq '04'
        expect(detalhe[3..16]).to eq '99887766000155'
        expect(detalhe[351..380]).to eq 'Filial Teste Daycoval'.ljust(30)
      end
    end
  end
end
