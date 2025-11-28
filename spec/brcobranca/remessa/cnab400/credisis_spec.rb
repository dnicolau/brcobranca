# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab400::Credisis do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 199.9,
                                       data_vencimento: Date.current,
                                       nosso_numero: 123,
                                       documento: 6969,
                                       dias_protesto: '6',
                                       valor_mora: '8.00',
                                       percentual_multa: '2.00',
                                       documento_sacado: '12345678901',
                                       nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO,!^.?\/@  DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
                                       endereco_sacado: 'RUA RIO GRANDE DO SUL,!^.?\/@ São paulo Minas caçapa da silva junior',
                                       bairro_sacado: 'São josé dos quatro apostolos magros',
                                       cep_sacado: '12345678',
                                       cidade_sacado: 'Santa rita de cássia maria da silva',
                                       uf_sacado: 'SP')
  end
  let(:params) do
    {
      carteira: '18',
      agencia: '1',
      conta_corrente: '2',
      codigo_cedente: '0027',
      documento_cedente: '12345678901234',
      digito_conta: '7',
      sequencial_remessa: '3',
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      pagamentos: [pagamento]
    }
  end
  let(:credisis) { subject.class.new(params) }

  context 'validações dos campos' do
    context '@agencia' do
      it 'deve ser inválido se não possuir uma agência' do
        object = subject.class.new(params.merge!(agencia: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Agencia não pode estar em branco.')
      end

      it 'deve ser invalido se a agencia tiver mais de 4 dígitos' do
        credisis.agencia = '12345'
        expect(credisis.invalid?).to be true
        expect(credisis.errors.full_messages).to include('Agencia deve ter 4 dígitos.')
      end
    end

    context '@digito_conta' do
      it 'deve ser inválido se não possuir um dígito da conta corrente' do
        objeto = subject.class.new(params.merge!(digito_conta: nil))
        expect(objeto.invalid?).to be true
        expect(objeto.errors.full_messages).to include('Digito conta não pode estar em branco.')
      end

      it 'deve ser inválido se o dígito da conta tiver mais de 1 dígito' do
        credisis.digito_conta = '12'
        expect(credisis.invalid?).to be true
        expect(credisis.errors.full_messages).to include('Digito conta deve ter 1 dígito.')
      end
    end

    context '@conta_corrente' do
      it 'deve ser inválido se não possuir uma conta corrente' do
        object = subject.class.new(params.merge!(conta_corrente: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Conta corrente não pode estar em branco.')
      end

      it 'deve ser inválido se a conta corrente tiver mais de 8 dígitos' do
        credisis.conta_corrente = '123456789'
        expect(credisis.invalid?).to be true
        expect(credisis.errors.full_messages).to include('Conta corrente deve ter 8 dígitos.')
      end
    end

    context '@codigo_cedente' do
      it 'deve ser inválido se não possuir código do cedente' do
        object = subject.class.new(params.merge!(codigo_cedente: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Codigo cedente não pode estar em branco.')
      end

      it 'deve ser inválido se o código do cedente tiver mais de 4 dígitos' do
        credisis.codigo_cedente = '12345333'
        expect(credisis.invalid?).to be true
        expect(credisis.errors.full_messages).to include('Codigo cedente deve ter 4 dígitos.')
      end
    end

    context '@carteira' do
      it 'deve ser inválido se não possuir uma carteira' do
        object = subject.class.new(params.merge!(carteira: nil))
        expect(object.invalid?).to be true
        expect(object.errors.full_messages).to include('Carteira não pode estar em branco.')
      end

      it 'deve ser inválido se a carteira tiver mais de 2 dígitos' do
        credisis.carteira = '123'
        expect(credisis.invalid?).to be true
        expect(credisis.errors.full_messages).to include('Carteira deve ter 2 dígitos.')
      end
    end

    context '@sequencial_remessa' do
      it 'deve ser inválido se a sequencial remessa tiver mais de 7 dígitos' do
        credisis.sequencial_remessa = '12345678'
        expect(credisis.invalid?).to be true
        expect(credisis.errors.full_messages).to include('Sequencial remessa deve ter 7 dígitos.')
      end
    end
  end

  context 'formatacoes dos valores' do
    it 'cod_banco deve ser 097' do
      expect(credisis.cod_banco).to eq '097'
      expect(credisis.nome_banco.strip).to eq 'CENTRALCREDI'
    end

    it 'info_conta deve retornar com 20 posicoes as informacoes da conta' do
      info_conta = credisis.info_conta
      expect(info_conta.size).to eq 20
      expect(info_conta[0..3]).to eq '0001'          # num. da agencia
      expect(info_conta[5..12]).to eq '00000002'     # num. da conta
      expect(info_conta[13]).to eq '7'               # dígito da conta
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab400'

    context 'header' do
      it 'informacoes devem estar posicionadas corretamente no header' do
        header = credisis.monta_header
        expect(header[1]).to eq '1'                                   # tipo operacao (1 = remessa)
        expect(header[2..8]).to eq 'REMESSA'                          # literal da operacao
        expect(header[26..45]).to eq credisis.info_conta              # informacoes da conta
        expect(header[76..78]).to eq '097'                            # codigo do banco
        expect(header[100..106]).to eq '0000003'                      # sequencial da remessa
      end
    end

    context 'detalhe' do
      it 'informacoes devem estar posicionadas corretamente no detalhe' do
        detalhe = credisis.monta_detalhe pagamento, 2

        expect(detalhe[0]).to eq '1'                                               # registro detalhe
        expect(detalhe[1..2]).to eq '02'                                           # tipo do documento do cedente
        expect(detalhe[3..16]).to eq '12345678901234'                              # documento do cedente
        expect(detalhe[17..20]).to eq '0001'                                       # agência
        expect(detalhe[21..28]).to eq '00000002'                                   # conta corrente
        expect(detalhe[29]).to eq '7'                                              # dígito da conta corrente
        expect(detalhe[30..55]).to eq ''.rjust(26, ' ')                            # complemento (brancos)
        expect(detalhe[56..75]).to eq '00000000000000000123'                       # nosso numero
        expect(detalhe[76..77]).to eq '01'                                         # código da operação
        expect(detalhe[78..83]).to eq Date.current.strftime('%d%m%y')              # data da operação (data emissão)
        expect(detalhe[84..89]).to eq ''.rjust(6, ' ')                             # brancos
        expect(detalhe[90..91]).to eq '01'                                         # número da parcela
        expect(detalhe[92]).to eq '3'                                              # tipo pagamento
        expect(detalhe[93]).to eq '3'                                              # tipo recebimento
        expect(detalhe[94..95]).to eq '01'                                         # espécie de título
        expect(detalhe[96]).to eq ' '                                              # branco
        expect(detalhe[97..98]).to eq '06'                                         # dias para envio a protesto
        expect(detalhe[99..100]).to eq '00'                                        # código primeira instrução / protesto
        expect(detalhe[101..109]).to eq ''.rjust(9, ' ')                           # brancos
        expect(detalhe[110..119]).to eq '0000000000'                               # número do documento
        expect(detalhe[120..125]).to eq Date.current.strftime('%d%m%y')            # data de vencimento
        expect(detalhe[126..138]).to eq '0000000019990'                            # valor do título (1999,01)
        expect(detalhe[139..144]).to eq Date.current.strftime('%d%m%y')            # data limite pagamento
        expect(detalhe[145..149]).to eq ''.rjust(5, ' ')                           # brancos
        expect(detalhe[150..155]).to eq Date.current.strftime('%d%m%y')            # data emissão título
        expect(detalhe[156]).to eq ' '                                             # branco
        expect(detalhe[157..158]).to eq '01'                                       # tipo documento sacado
        expect(detalhe[159..172]).to eq '00012345678901'                           # documento sacado
        expect(detalhe[173..212]).to eq 'PABLO DIEGO JOSE FRANCISCO DE PAULA JUAN' # nome sacado (40)
        expect(detalhe[213..237]).to eq ''.rjust(25, ' ')                          # brancos
        expect(detalhe[238..272]).to eq 'RUA RIO GRANDE DO SUL Sao paulo Min'      # endereco sacado (35)
        expect(detalhe[273..278]).to eq '      '                                   # numero endereco (6)
        expect(detalhe[279..303]).to eq 'Sao jose dos quatro apost'                # bairro sacado (25)
        expect(detalhe[304..328]).to eq 'Santa rita de cassia mari'                # cidade sacado (25)
        expect(detalhe[329..330]).to eq 'SP'                                       # uf sacado
        expect(detalhe[331..338]).to eq '12345678'                                 # cep sacado
        expect(detalhe[339..349]).to eq ''.rjust(11, ' ')                          # brancos
        expect(detalhe[350..392]).to eq ''.rjust(43, ' ')                          # brancos
        expect(detalhe[393]).to eq ' '                                             # branco
        expect(detalhe[394..399]).to eq '000002'                                   # sequencial no arquivo (6)
      end
    end

    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }

      after { Timecop.return }

      it {
        expect(credisis.gera_arquivo).to eq(read_remessa('remessa-credisis-cnab400.rem', credisis.gera_arquivo))
      }
    end
  end
end
