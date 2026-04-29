# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::Banrisul do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 199.9,
      data_vencimento: Date.current,
      nosso_numero: 22_832_563,
      documento: '1',
      documento_sacado: '12345678901',
      nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO,!^.?\/@  DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
      endereco_sacado: 'RUA RIO GRANDE DO SUL,!^.?\/@ São paulo Minas caçapa da silva junior',
      bairro_sacado: 'São josé dos quatro apostolos magros',
      cep_sacado: '12345678',
      cidade_sacado: 'Santa rita de cássia maria da silva',
      percentual_multa: 2.0,
      codigo_multa: '2',
      uf_sacado: 'SP'
    )
  end

  let(:params) do
    {
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      agencia: '1102',
      conta_corrente: '12345',
      digito_conta: '6',
      documento_cedente: '12345678901',
      convenio: '1102900015046',
      sequencial_remessa: '1',
      mensagem_1: 'Campo destinado ao preenchimento no momento do pagamento.',
      mensagem_2: 'Campo destinado ao preenchimento no momento do pagamento.',
      pagamentos: [pagamento]
    }
  end

  let(:banrisul) { subject.class.new(params) }

  before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }

  after { Timecop.return }

  context 'validacoes' do
    context '@convenio' do
      it 'deve ser invalido se nao possuir convenio' do
        objeto = subject.class.new(params.merge(convenio: nil))

        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Convenio não pode estar em branco.')
      end

      it 'deve ser invalido se o convenio tiver mais de 13 digitos' do
        banrisul.convenio = '12345678901234'

        expect(banrisul.invalid?).to be true
        expect(banrisul.errors.full_messages).to include('Convenio deve ter 13 dígitos.')
      end
    end

    context '@codigo_especie_cobranca' do
      it 'deve ser invalido se nao possuir codigo de especie de cobranca' do
        objeto = subject.class.new(params.merge(codigo_especie_cobranca: nil))

        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Codigo especie cobranca não pode estar em branco.')
      end

      it 'deve ser invalido se o codigo tiver mais de 10 digitos' do
        banrisul.codigo_especie_cobranca = '12345678901'

        expect(banrisul.invalid?).to be true
        expect(banrisul.errors.full_messages).to include('Codigo especie cobranca deve ter 10 dígitos.')
      end
    end

    context '@autoriza_pagamento_parcial' do
      it 'deve ser invalido se o codigo for diferente de 1 ou 2' do
        banrisul.autoriza_pagamento_parcial = '3'

        expect(banrisul.invalid?).to be true
        expect(banrisul.errors.full_messages).to include('Autoriza pagamento parcial deve ser 1 ou 2.')
      end
    end
  end

  context 'formatacoes' do
    it 'codigo do banco deve ser 041' do
      expect(banrisul.cod_banco).to eq '041'
    end

    it 'nome do banco deve ser BANRISUL com 30 posicoes' do
      expect(banrisul.nome_banco.size).to eq 30
      expect(banrisul.nome_banco.strip).to eq 'BANRISUL'
    end

    it 'versao do layout do arquivo deve ser 103' do
      expect(banrisul.versao_layout_arquivo).to eq '103'
    end

    it 'versao do layout do lote deve ser 060' do
      expect(banrisul.versao_layout_lote).to eq '060'
    end

    it 'codigo do convenio deve ser o codigo do beneficiario com 13 digitos' do
      expect(banrisul.codigo_convenio).to eq '1102900015046       '
    end

    it 'calcula o duplo digito do nosso numero' do
      expect(banrisul.digito_nosso_numero('22832563')).to eq '51'
      expect(banrisul.formata_nosso_numero(22_832_563)).to eq '2283256351          '
    end

    it 'formata o codigo de especie de cobranca' do
      expect(banrisul.codigo_especie_cobranca_formatado).to eq '0000805076'
    end
  end

  context 'geracao remessa' do
    it_behaves_like 'cnab240'

    context 'segmento P' do
      it 'preenche os campos especificos do Banrisul' do
        segmento_p = banrisul.monta_segmento_p(pagamento, 1, 1)

        expect(segmento_p[23..56]).to eq '0000000123456 2283256351          '
        expect(segmento_p[62..76]).to eq '1              '
        expect(segmento_p[229..238]).to eq '0000805076'
        expect(segmento_p[239]).to eq '1'
      end
    end

    context 'segmento Q' do
      it 'nao informa sacador/avalista no segmento Q' do
        pagamento.documento_avalista = '12345678901'
        pagamento.nome_avalista = 'AVALISTA TESTE'

        segmento_q = banrisul.monta_segmento_q(pagamento, 1, 2)

        expect(segmento_q[153..208]).to eq ''.rjust(56, ' ')
      end
    end

    context 'arquivo' do
      it { expect(banrisul.gera_arquivo).to eq(read_remessa('remessa-banrisul-cnab240.rem', banrisul.gera_arquivo)) }
    end
  end
end
