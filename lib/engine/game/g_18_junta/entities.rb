# frozen_string_literal: true

module Engine
  module Game
    module G18Junta
      module Entities
        COMPANIES = [
          {
            name: '(A) Investidores Unidos',
            sym: '(A)',
            value: 35,
            revenue: 15,
            desc: 'Uma vez por partida, o jogador proprietário pode, no início de uma Fase de Mercado, fixar '\
                  'antecipadamente o valor do preço de Oferta Inicial de alguma companhia que não teve nenhuma ação '\
                  'adquirida até aquele momento.',
            color: nil,
            meta: { present: false },
          },
          {
            name: '(B) Empreiteiros Montoya',
            sym: '(B)',
            value: 40,
            revenue: 10,
            desc: 'Uma vez por partida, a companhia proprietária pode, na etapa de construção de trilhos, além de '\
                  'colocar um trilho normal, construir o trilho especial "Laguna" (E11), sem pagar nenhum custo por '\
                  'isto, mesmo que a companhia não tenha acesso àquele hexágono.',
            color: nil,
            meta: { present: false },
            abilities: [
              {
                type: 'tile_lay',
                owner_type: 'corporation',
                hexes: ['E11'],
                tiles: ['lag1'],
                when: 'owning_corp_or_turn',
                count: 1,
                free: true,
                special: true,
              },
            ],
          },
          {
            name: '(C) Misioneros Campesinos',
            sym: '(C)',
            value: 45,
            revenue: 10,
            desc: 'Sempre que a companhia proprietária for construir um trilho em um local com paramilitares, ela '\
                  'pode fazê-lo sem pegar a ficha, descartando-a do jogo. Nesse caso, a companhia não pagará o custo '\
                  'de $30, nem haverá qualquer mudança na trilha de estabilidade política.',
            color: nil,
            meta: { present: true },
          },
                    {
                name: '(D) Ferramenteria Ochoa',
                sym: '(D)',
                value: 50,
                revenue: 5,
                desc: 'Uma vez por partida, na hora de comprar um trem, a companhia proprietária pode descartar um trem '\
                      '2 ou 3, e receber o valor de custo do trem descartado como desconto na compra do trem atual, '\
                      'pagando apenas a diferença de valor entre eles.',
                color: nil,
                meta: { present: false },
                abilities: [
                  {
                    type: 'choose_ability',
                    owner_type: 'corporation',
                    when: 'buy_train',
                    count: 1,
                    choices: {},
                  },
                ],
              },

              {
             name: '(E) Casa Ruiz de Assistencia',
              sym: '(E)',
              value: 55,
              revenue: 10,
              desc: 'A partir da Fase 3, o jogador proprietário, em vez de vender essa empresa privada, pode doá-la '\
                    'para uma companhia, que receberá $150 do banco. A empresa continua ativa e gerando receita.',
              color: nil,
              meta: { present: false },
              abilities: [
                {
                  type: 'choose_ability',
                  owner_type: 'player',
                  when: 'any',
                  choices: {},
                },
              ],
            },

          # {
          #   name: '(E) Casa Ruiz de Assistencia',
          #   sym: '(E)',
          #   value: 55,
          #   revenue: 10,
          #   desc: 'A partir da Fase 3, o jogador proprietário, em vez de vender essa empresa privada, pode doá-la '\
          #         'para uma companhia, que receberá $150 do banco. A empresa continua ativa e gerando receita.',
          #   color: nil,
          # },
          {
            name: '(F) Ingeniería Real',
            sym: '(F)',
            value: 60,
            revenue: 10,
            desc: 'Na etapa de construção de trilhos, a companhia proprietária pode construir um trilho amarelo '\
                  'extra, pagando um custo adicional de $25 (mais eventuais custos de terreno).',
            color: nil,
            meta: { present: false },
              #Sugestão do Claude implementada por Leandro 20-09-26
              abilities: [{      
              type: 'tile_lay',
              owner_type: 'corporation',
              hexes: [],           # [] = qualquer hex acessível
              tiles: [],           # [] = qualquer tile normal
              when: 'track',    #teste do Claude para só aparecer na fase de construção
              count: 1,
              cost: 25,
              reachable: true,
              special: false,
            },],
          },
          {
            name: '(G) Expresso Resplandor',
            sym: '(G)',
            value: 65,
            revenue: 10,
            desc: 'Durante as rodadas de operação, ao calcular o alcance e receita de suas rotas, a companhia '\
                  'proprietária pode ignorar a contagem de hexágonos de vila, para um ou mais de seus trens.',
            color: nil,
            meta: { present: true },
          },
          {
            name: '(H) Muñoz Investimentos',
            sym: '(H)',
            value: 70,
            revenue: 15,
            desc: 'Sempre que a companhia proprietária pagar dividendos em valor igual ou maior que o dobro de seu '\
                  'valor de mercado, o banco paga 10% extra diretamente para o caixa da companhia.',
            color: nil,
            meta: { present: true },
          },
          {
            name: '(I) Orejuela Abogados',
            sym: '(I)',
            value: 75,
            revenue: 20,
            desc: 'No momento da resolução do golpe, a companhia proprietária pode descartar uma de suas fichas de '\
                  'apoio/rejeição ao golpe.',
            color: nil,
            meta: { present: true },
          },
          {
            name: '(J) Sanchez Ingeniería',
            sym: '(J)',
            value: 80,
            revenue: 20,
            desc: 'Na etapa de construção de trilhos, a companhia proprietária sempre recebe um desconto para '\
                  'construir em montanhas (-$25) e fazendas (-$15). No caso das fazendas, o desconto também se '\
                  'aplica aos melhoramentos de trilhos.',
            abilities: [
              { type: 'tile_discount', discount: 25, terrain: 'mountain', owner_type: 'corporation', exact_match: false },
              { type: 'tile_discount', discount: 15, terrain: 'farm', owner_type: 'corporation', exact_match: false },
            ],
            color: nil,
            meta: { present: false },
          },
          {
            name: '(K) Hernandez Abogados',
            sym: '(K)',
            value: 85,
            revenue: 5,
            desc: 'Sempre que o presidente da companhia proprietária receber uma ficha preta de corrupção, ela é '\
                  'automaticamente trocada por outra ficha sorteada do saco (que é mantida, mesmo se também for preta).',
            color: nil,
            meta: { present: :never },
          },
          {
            name: '(L) Banco de La Nación',
            sym: '(L)',
            value: 150,
            revenue: 40,
            desc: 'Esta empresa privada nunca poderá ser vendida para uma companhia.',
            color: nil,
            meta: { present: false },
            # Sugestão do Claude implantada por Leandro 19-09-26
            abilities: [{ type: 'no_buy' }],
          },
          {
            name: '(N) Emisarios de las Sombras',
            sym: '(N)',
            value: 60,
            revenue: 15,
            desc: 'Uma vez por partida, durante uma ação de sua companhia proprietária, pode remover 1 ficha de '\
                  'paramilitar de qualquer hexágono do tabuleiro. Ao fazer '\
                  'isso, o presidente da companhia pega 2 fichas pretas de corrupção diretamente do estoque.',
            color: nil,
          meta: { present: false },
          abilities: [
            {
              type: 'choose_ability',
              owner_type: 'corporation',
              when: 'owning_corp_or_turn',
              count: 1,
              choices: {},
            },
          ],
         }, 

        ].freeze


        CORPORATIONS = [
          {
            sym: 'A',
            name: 'Amarilla',
            logo: '18_junta/A',
            simple_logo: '18_junta/A.alt',
            tokens: [0, 40],
            max_ownership_percent: 60,
            float_percent: 50,
            coordinates: 'L6',
            color: '#fcf75e',
            text_color: 'black',
          },
          {
            sym: 'B',
            name: 'Barrizal',
            logo: '18_junta/B',
            simple_logo: '18_junta/B.alt',
            tokens: [0, 40, 80, 80],
            max_ownership_percent: 60,
            float_percent: 50,
            coordinates: 'D10',
            color: '#0099ff',
          },
          {
            sym: 'C',
            name: 'Campesina',
            logo: '18_junta/C',
            simple_logo: '18_junta/C.alt',
            tokens: [0, 40, 80],
            max_ownership_percent: 60,
            float_percent: 50,
            coordinates: 'E3',
            color: '#ff2200',
          },
          {
            sym: 'E',
            name: 'Estelar',
            logo: '18_junta/E',
            simple_logo: '18_junta/E.alt',
            tokens: [0, 40],
            max_ownership_percent: 60,
            float_percent: 50,
            coordinates: 'E13',
            color: '#9900cc',
          },
          {
            sym: 'F',
            name: 'Ferrocarrillera',
            logo: '18_junta/F',
            simple_logo: '18_junta/F.alt',
            tokens: [0, 40, 80],
            max_ownership_percent: 60,
            float_percent: 50,
            coordinates: 'I11',
            color: '#ff9966',
            text_color: 'black',
          },
          {
            sym: 'H',
            name: 'Hijos Muñoz',
            logo: '18_junta/H',
            simple_logo: '18_junta/H.alt',
            tokens: [0, 40, 80],
            max_ownership_percent: 60,
            float_percent: 50,
            coordinates: 'H2',
            color: '#ff99ff',
            text_color: 'black',
          },
          {
            sym: 'M',
            name: 'Montañera',
            logo: '18_junta/M',
            simple_logo: '18_junta/M.alt',
            tokens: [0, 40, 80],
            max_ownership_percent: 60,
            float_percent: 50,
            coordinates: 'J8',
            color: '#9c661f',
          },
          {
            sym: 'V',
            name: 'Valle-verdiana',
            logo: '18_junta/V',
            simple_logo: '18_junta/V.alt',
            tokens: [0, 40, 80],
            max_ownership_percent: 60,
            float_percent: 50,
            coordinates: 'G7',
            color: '#61b229',
          },
        ].freeze
      end
    end
  end
end
