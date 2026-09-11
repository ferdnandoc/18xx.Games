# frozen_string_literal: true

require_relative 'entities'
require_relative 'map'
require_relative 'meta'
require_relative 'step/dividend'
require_relative '../base'

module Engine
  module Game
    module G18Junta
      class Game < Game::Base
        include_meta(G18Junta::Meta)
        include Entities
        include Map

        CURRENCY_FORMAT_STR = '$%s'

        BANK_CASH = 7_000

        CERT_LIMIT = { 2 => 22, 3 => 16, 4 => 14 }.freeze

        STARTING_CASH = { 2 => 580, 3 => 520, 4 => 450 }.freeze

        CAPITALIZATION = :full

        MUST_SELL_IN_BLOCKS = false

        SELL_BUY_ORDER = :any_order

        POOL_SHARE_LIMIT = 50 # 5 certificados por companhia no banco

        SOLD_OUT_INCREASE = true

        GAME_END_CHECK = { bankrupt: :immediate, bank: :full_or, stock_market: :current_or }.freeze

        # Mercado de Ações (18Junta Regras 2.1, 4.3 / referência visual do tabuleiro).
        # 'p' = célula de Valor Inicial (par); 'e' = gatilho de fim de jogo (área azul).
        MARKET = [
          %w[105 115 130 145 160 180 205 230 260 290 320 350e],
          %w[90 100 110 125 140 155 175 200 225 250 275 300 330e],
          %w[70 80 90 100p 110 125 140 155 175 200 225 250 280],
          %w[55 65 70 80p 90p 100 110 125 140 155 175 200],
          %w[50 55 65 70p 80 90 100 110 125 140],
          %w[45 50 60 65p 70 80 90 100],
          %w[35 45 55 60 65 70],
          %w[30 40 50 55],
          %w[15 30 40],
        ].freeze

        PHASES = [
          {
            name: '2',
            train_limit: 4,
            tiles: [:yellow],
            operating_rounds: 1,
          },
          {
            name: '3',
            on: '3',
            train_limit: 4,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '4',
            on: '4',
            train_limit: 3,
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_buy_companies'],
          },
          {
            name: '5',
            on: '5',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
            status: ['can_buy_companies'],
          },
          {
            name: '6',
            on: '6',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
            status: ['can_buy_companies'],
          },
          {
            name: '8',
            on: '8',
            train_limit: 2,
            tiles: %i[yellow green brown],
            operating_rounds: 3,
          },
          {
            name: 'D',
            on: 'D',
            train_limit: 2,
            tiles: %i[yellow green brown gray],
            operating_rounds: 3,
          },
        ].freeze

        # Trem 8 só entra se a Ditadura vencer o golpe; trem D só entra se a
        # Democracia vencer. Por ora (esqueleto sem o sistema de golpe), os
        # dois ficam disponíveis; isso será restringido quando o golpe for
        # implementado (ver TODOs no fim do arquivo).
        TRAINS = [
          { name: '2', distance: 2, price: 80, rusts_on: '4', num: 6 },
          { name: '3', distance: 3, price: 180, rusts_on: '6', num: 5 },
          { name: '4', distance: 4, price: 300, rusts_on: '8', num: 4 },
          { name: '5', distance: 5, price: 450, num: 3 },
          { name: '6', distance: 6, price: 630, num: 2 },
          {
            name: '8',
            distance: 8,
            price: 900,
            num: 9,
            discount: { '4' => 750, '5' => 750, '6' => 750 },
          },
          {
            name: 'D',
            distance: 999,
            price: 1_100,
            num: 9,
            discount: { '4' => 800, '5' => 800, '6' => 800 },
          },
        ].freeze

        EBUY_PRES_SWAP = false
        EBUY_FROM_OTHERS = :never
        HOME_TOKEN_TIMING = :float

        # TODO: (próxima camada): fazendas devem somar receita extra ao trem
        # que as atravessa sem contar como parada nem poder ser início/fim
        # de rota (18Junta Regras 2.1, 8.7.1/8.7.2). Vai exigir uma lógica de
        # distância/rota dedicada (visit: 0 para hexágonos com label 'F').

        def operating_round(round_num)
          Round::Operating.new(self, [
            Engine::Step::Bankrupt,
            Engine::Step::Exchange,
            Engine::Step::SpecialTrack,
            Engine::Step::BuyCompany,
            Engine::Step::Track,
            Engine::Step::Token,
            Engine::Step::Route,
            G18Junta::Step::Dividend,
            Engine::Step::DiscardTrain,
            Engine::Step::BuyTrain,
            [Engine::Step::BuyCompany, { blocks: true }],
          ], round_num: round_num)
        end

        def setup
          # Sorteia 1 corporação para ficar fora da partida.
          removed_corporation = @corporations.delete(@corporations.sample)
          @log << "Corporation not used in this game: #{removed_corporation.name}"

          # Sorteia as privadas que entram em jogo (6 para 3-4 jogadores, 5 para 2).
          privates_in_play = two_player? ? 5 : 6
          @companies.shuffle!
          selected = @companies.take(privates_in_play)
          (@companies - selected).each { |c| remove_company(c) }
          @log << "Private companies in this game: #{selected.map(&:name).join(', ')}"

          # TODO: (próxima camada): distribuir 2 fichas insurgentes + 2 democráticas
          # aleatoriamente entre 4 das corporações restantes (ver 18Junta Regras
          # 2.1, seção 3 e 4.10); implementar trilha política, hexágonos de
          # paramilitar (PARAMILITAR_HEXES em map.rb), saco de corrupção, veto,
          # licença de aprimoramento, e a tentativa de golpe em si.
        end

        def remove_company(company)
          company.close!
          @companies.delete(company)
        end

        # TODO: (próxima camada): o leilão inicial do 18Junta (Regras 2.1, 6.1)
        # não é o waterfall padrão do motor — é "jogador escolhe uma privada
        # disponível, lance ascendente em incrementos de $5 até sobrar 1
        # interessado; se ninguém escolher uma privada pra leiloar, o jogador
        # da vez pode abrir um leilão forçado por metade do valor (arred.
        # pra cima); se mesmo assim ninguém quiser, as privadas remanescentes
        # saem do jogo". Por ora o leilão padrão do motor (WaterfallAuction)
        # está sendo usado como placeholder.
      end
    end
  end
end
