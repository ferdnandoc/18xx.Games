# frozen_string_literal: true

module Engine
  module Game
    module G18Junta
      module Map
        # TODO: confirm exact counts/paths for the gray city-specific tiles
        # (Monterrey/Valle Verde/San Isidro upgrades, tile "123") and the extra
        # brown "216" tile from the tile manifest appendix before locking this.
        TILES = {
          '3' => 2,
          '4' => 2,
          '5' => 2,
          '6' => 4,
          '7' => 2,
          '8' => 4,
          '9' => 4,
          '14' => 2,
          '15' => 2,
          '16' => 1,
          '19' => 1,
          '20' => 1,
          '23' => 2,
          '24' => 2,
          '25' => 1,
          '26' => 1,
          '27' => 1,
          '28' => 1,
          '29' => 1,
          '39' => 1,
          '40' => 1,
          '41' => 1,
          '42' => 1,
          '43' => 1,
          '44' => 1,
          '45' => 1,
          '46' => 1,
          '47' => 1,
          '57' => 4,
          '58' => 2,
          '205' => 1,
          '206' => 1,
          '448' => 2,
          '449' => 2,

          # Fazendas (farm hexes): custo próprio de aprimoramento (terrain:farm
          # permite o desconto da privada J também nos melhoramentos).
          # visit_cost:0 faz o motor não contar a fazenda como parada pro
          # limite de distância do trem (18Junta Regras 2.1, 8.7.1) — a
          # receita continua somando normalmente. Fazenda como início/fim de
          # rota é bloqueada em Game#check_other.
          'faz1' => {
            'count' => 2,
            'color' => 'yellow',
            'code' => 'town=revenue:10,visit_cost:0;path=a:0,b:_0;path=a:2,b:_0;label=F;'\
                      'icon=image:18_junta/fazenda,large:2;upgrade=cost:25,terrain:farm',
          },
          'faz2' => {
            'count' => 2,
            'color' => 'yellow',
            'code' => 'town=revenue:10,visit_cost:0;path=a:0,b:_0;path=a:1,b:_0;label=F;'\
                      'icon=image:18_junta/fazenda,large:2;upgrade=cost:25,terrain:farm',
          },
          'faz3' => {
            'count' => 2,
            'color' => 'yellow',
            'code' => 'town=revenue:10,visit_cost:0;path=a:0,b:_0;path=a:3,b:_0;label=F;'\
                      'icon=image:18_junta/fazenda,large:2;upgrade=cost:25,terrain:farm',
          },
          'faz4' => {
            'count' => 2,
            'color' => 'green',
            'code' => 'town=revenue:20,visit_cost:0;path=a:0,b:_0;path=a:3,b:_0;path=a:2,b:_0;label=F;'\
                      'icon=image:18_junta/fazenda,large:2;upgrade=cost:25,terrain:farm',
          },
          'faz5' => {
            'count' => 2,
            'color' => 'green',
            'code' => 'town=revenue:20,visit_cost:0;path=a:0,b:_0;path=a:3,b:_0;path=a:4,b:_0;label=F;'\
                      'icon=image:18_junta/fazenda,large:2;upgrade=cost:25,terrain:farm',
          },
          'faz6' => {
            'count' => 2,
            'color' => 'brown',
            'code' => 'town=revenue:30,visit_cost:0;path=a:0,b:_0;path=a:3,b:_0;path=a:4,b:_0;path=a:1,b:_0;'\
                      'label=F;icon=image:18_junta/fazenda,large:2;upgrade=cost:25,terrain:farm',
          },
          'faz7' => {
            'count' => 2,
            'color' => 'brown',
            'code' => 'town=revenue:30,visit_cost:0;path=a:0,b:_0;path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;'\
                      'label=F;icon=image:18_junta/fazenda,large:2;upgrade=cost:25,terrain:farm',
          },

          # Laguna (E11): trilho especial, só sai pela habilidade da privada (B).
          'lag1' => {
            'count' => 1,
            'color' => 'yellow',
            'code' => 'path=a:0,b:2;frame=color:#0099ff;label=L;upgrade=cost:80,terrain:river',
          },
        }.freeze

        LOCATION_NAMES = {
          'L6' => 'Monterrey',
          'G7' => 'Valle Verde',
          'F10' => 'San Isidro',
          'A13' => 'Navidad',
          'D4' => 'Don Ramón',
          'K3' => 'San Miguel',
          'L12' => 'Puerto Viejo',
          'E11' => 'Laguna',
        }.freeze

        # Hexágonos com ficha de paramilitar no início da partida (ver 18Junta
        # Regras 2.1, seção 4.2 e 4.10). Custo de construção nesses hexágonos:
        # custo normal do terreno + $30 para tomar a ficha e escolher lado.
        PARAMILITAR_HEXES = %w[B14 C11 E7 F4 G13 I3 I9 K11 L8].freeze

        HEXES = {
          white: {
            %w[C9 D8 D14 H4 J4] => '', # terrenos livres
            %w[B14 C11 E7 F4 G13 I3 I9 L8] => 'icon=image:18_junta/paramilitar', # terrenos livres com paramilitar
            %w[C15 G1 G11 J2 K13] => 'town=revenue:0,hide:0;label=.;icon=image:18_junta/fazenda;'\
                                     'upgrade=cost:25,terrain:farm', # terrenos livres com fazenda
            %w[C13 E5 D10 E3 E13 F12 H2 I1 I5 I11 J12 K5 K9] => 'city=revenue:0', # cidades
            %w[F2 H12] => 'town=revenue:0', # vilas
            %w[F6 G5 G9 H10 L10 I7] => 'upgrade=cost:50,terrain:mountain', # montanhas
            ['K11'] => 'upgrade=cost:50,terrain:mountain;icon=image:18_junta/paramilitar', # montanha com paramilitar
            %w[B10 E9 G3 H6 J6 H8 J10] => 'town=revenue:0;label=.;icon=image:18_junta/fazenda,loc:15;'\
                                          'upgrade=cost:75,terrain:mountain|farm', # montanhas com fazendas
            %w[D12 F8 K7] => 'town=revenue:0;upgrade=cost:50,terrain:mountain', # vilas em montanha
            ['J8'] => 'city=revenue:0;upgrade=cost:50,terrain:mountain', # cidade-sede da Montañera, em montanha
            ['E11'] => 'label=L;frame=color:#0099ff;upgrade=cost:100,terrain:river', # Laguna
          },
          green: {
            ['G7'] => 'city=revenue:30,slots:2;path=a:1,b:_0;path=a:2,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=V',
            ['L6'] => 'city=revenue:30,slots:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;label=M',
          },
          brown: {
            ['F10'] => 'city=revenue:yellow_40|brown_60,slots:2;path=a:1,b:_0;path=a:5,b:_0;label=S',
          },
          gray: {
            ['B12'] => 'path=a:1,b:3;path=a:3,b:6',
            ['D6'] => 'city=revenue:20,slots:1;path=a:0,b:_0;path=a:4,b:_0',
          },
          red: {
            ['A13'] => 'offboard=revenue:yellow_40|brown_60;path=a:4,b:_0;path=a:5,b:_0',
            ['D4'] => 'offboard=revenue:yellow_30|brown_60;path=a:4,b:_0;path=a:5,b:_0',
            ['L12'] => 'offboard=revenue:yellow_30|brown_50;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0',
            ['K3'] => 'offboard=revenue:yellow_30|brown_60;path=a:1,b:_0;path=a:2,b:_0;'\
                      'border=edge:0,type:impassable,color:black',
          },
        }.freeze

        # Trilhos militares (18Junta Regras 2.1, Apêndice — resultado
        # "Ditadura" da Tentativa de Golpe): substituem os 4 hexágonos de
        # fronteira, trocando o valor duplo civil por um valor único (mesmas
        # conexões/bordas dos offboards atuais; valores confirmados pelo
        # designer, com o "90" impresso no hexágono base de Navidad sendo um
        # erro de arte — o valor correto é 50, igual ao da peça de tile).
        DITADURA_BORDER_TILES = {
          'A13' => 'offboard=revenue:50;path=a:4,b:_0;path=a:5,b:_0', # Navidad
          'D4' => 'offboard=revenue:50;path=a:4,b:_0;path=a:5,b:_0', # Don Ramón
          'L12' => 'offboard=revenue:40;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0', # Puerto Viejo
          'K3' => 'offboard=revenue:40;path=a:1,b:_0;path=a:2,b:_0;'\
                  'border=edge:0,type:impassable,color:black', # San Miguel
        }.freeze

        LAYOUT = :flat
      end
    end
  end
end
