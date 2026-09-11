# frozen_string_literal: true

require_relative 'entities'
require_relative 'map'
require_relative 'meta'
require_relative 'step/dividend'
require_relative 'step/paramilitar_choice'
require_relative 'step/track'
require_relative 'step/upgrade_license'
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

        # Saco de corrupção (18Junta Regras 2.1, 4.8): composição inicial, e
        # fichas que entram no saco quando cada uma das três primeiras pilhas
        # de trem se esgota.
        CORRUPTION_BAG_INITIAL = { white: 28, black: 7 }.freeze
        CORRUPTION_REFILL_ON_TRAIN_DEPLETED = {
          '2' => { white: 2, black: 2 },
          '3' => { white: 1, black: 3 },
          '4' => { white: 0, black: 4 },
        }.freeze

        # Custo para tomar a ficha de um hexágono de paramilitar (18Junta
        # Regras 2.1, 4.2), além do custo normal do terreno.
        PARAMILITAR_FEE = 30

        # Trilha política (18Junta Regras 2.1, 4.10 / tabuleiro): de -4
        # (Mil4) a +4 (Civ4), 0 é o espaço Neutro inicial.
        POLITICAL_TRACK_LIMIT = 4

        # TODO: (próxima camada): fazendas devem somar receita extra ao trem
        # que as atravessa sem contar como parada nem poder ser início/fim
        # de rota (18Junta Regras 2.1, 8.7.1/8.7.2). Vai exigir uma lógica de
        # distância/rota dedicada (visit: 0 para hexágonos com label 'F').

        def operating_round(round_num)
          @or_round_number += 1
          expire_stale_upgrade_licenses!

          Round::Operating.new(self, [
            Engine::Step::Bankrupt,
            Engine::Step::Exchange,
            Engine::Step::SpecialTrack,
            Engine::Step::BuyCompany,
            G18Junta::Step::Track,
            G18Junta::Step::ParamilitarChoice,
            G18Junta::Step::UpgradeLicense,
            Engine::Step::Token,
            Engine::Step::Route,
            G18Junta::Step::Dividend,
            Engine::Step::DiscardTrain,
            Engine::Step::BuyTrain,
            [Engine::Step::BuyCompany, { blocks: true }],
          ], round_num: round_num)
        end

        def setup
          @or_round_number = 0
          @upgrade_licenses = {}
          @coup_resolved = false

          # Sorteia 1 corporação para ficar fora da partida.
          removed_corporation = @corporations.delete(@corporations.sample)
          @log << "Corporation not used in this game: #{removed_corporation.name}"

          # Sorteia as privadas que entram em jogo (6 para 3-4 jogadores, 5 para 2).
          privates_in_play = two_player? ? 5 : 6
          @companies.shuffle!
          selected = @companies.take(privates_in_play)
          (@companies - selected).each { |c| remove_company(c) }
          @log << "Private companies in this game: #{selected.map(&:name).join(', ')}"

          setup_corruption_bag!
          setup_political_track!

          # TODO: (próxima camada): Veto (simplificado, ver conversa com o
          # designer) e a tentativa de golpe em si (resolução da carta de
          # situação política, efeitos de Democracia/Ditadura, indenização
          # por corrupção no fim de jogo).
        end

        def remove_company(company)
          company.close!
          @companies.delete(company)
        end

        # --- Saco de corrupção (18Junta Regras 2.1, 4.8) ---

        def setup_corruption_bag!
          @corruption_bag = []
          self.class::CORRUPTION_BAG_INITIAL.each { |color, count| count.times { @corruption_bag << color } }
          @corruption_bag.shuffle!
          @corruption_tokens = Hash.new { |h, k| h[k] = { white: 0, black: 0 } }
        end

        # Chamado quando a última unidade de um tipo de trem é comprada, para
        # acrescentar ao saco as fichas que estavam guardadas sob aquela
        # pilha (ver 18Junta Regras 2.1, 4.8, e confirmação do designer).
        def buy_train(operator, train, price = nil)
          depleting = train.from_depot? && @depot.upcoming.count { |t| t.name == train.name } == 1
          super
          refill_corruption_bag!(train.name) if depleting
        end

        def refill_corruption_bag!(train_name)
          refill = self.class::CORRUPTION_REFILL_ON_TRAIN_DEPLETED[train_name]
          return unless refill

          refill.each { |color, count| count.times { @corruption_bag << color } }
          @corruption_bag.shuffle!
          @log << "Trem #{train_name} esgotado: #{refill[:white]} ficha(s) branca(s) e #{refill[:black]} "\
                  'ficha(s) preta(s) entram no saco de corrupção'
        end

        def draw_corruption_token!
          if @corruption_bag.empty?
            @log << 'Saco de corrupção está vazio'
            return nil
          end

          @corruption_bag.pop
        end

        def give_corruption_token!(holder, color)
          return unless holder

          @corruption_tokens[holder][color] += 1
          color_name = color == :black ? 'preta' : 'branca'
          @log << "#{holder.name} recebe 1 ficha #{color_name} de corrupção"
        end

        def corruption_tokens(holder)
          @corruption_tokens[holder]
        end

        def coup_resolved?
          @coup_resolved
        end

        # --- Hexágonos de paramilitar e trilha política (18Junta Regras 2.1, 4.2/4.10) ---

        def setup_political_track!
          @political_track = 0
          @corporation_alignment = Hash.new { |h, k| h[k] = { civil: 0, militar: 0 } }
          @paramilitar_hexes_remaining = self.class::PARAMILITAR_HEXES.dup
          @pending_paramilitar_choice = nil
          @pending_paramilitar_hex = nil

          militar_corps, civil_corps = @corporations.sample(4).each_slice(2).to_a
          militar_corps.each { |c| @corporation_alignment[c][:militar] += 1 }
          civil_corps.each { |c| @corporation_alignment[c][:civil] += 1 }
          @log << "Ficha inicial militar: #{militar_corps.map(&:name).join(', ')}; "\
                  "ficha inicial civil: #{civil_corps.map(&:name).join(', ')}"
        end

        def paramilitar_hex_unclaimed?(hex)
          @paramilitar_hexes_remaining.include?(hex.id)
        end

        def flag_paramilitar_hex_pending!(hex, corporation)
          @paramilitar_hexes_remaining.delete(hex.id)
          @pending_paramilitar_choice = corporation
          @pending_paramilitar_hex = hex
        end

        def pending_paramilitar_choice_for?(entity)
          @pending_paramilitar_choice == entity
        end

        attr_reader :pending_paramilitar_hex

        def discard_paramilitar_free?(corporation)
          return false unless corporation.respond_to?(:companies)

          corporation.companies.any? { |c| c.sym == '(C)' }
        end

        def resolve_paramilitar_choice!(corporation, choice)
          hex = @pending_paramilitar_hex
          @pending_paramilitar_choice = nil
          @pending_paramilitar_hex = nil

          case choice
          when 'descartar'
            @log << "#{corporation.name} descarta a ficha de paramilitar em #{hex.name} (privada (C), sem custo)"
          when 'civil', 'militar'
            corporation.spend(self.class::PARAMILITAR_FEE, @bank)
            side = choice.to_sym
            @corporation_alignment[corporation][side] += 1
            move_political_track!(side)
            side_name = side == :civil ? 'civis' : 'paramilitares'
            @log << "#{corporation.name} paga #{format_currency(self.class::PARAMILITAR_FEE)} e apoia os "\
                    "#{side_name} em #{hex.name}"
          else
            raise GameError, "Invalid paramilitar choice: #{choice}"
          end
        end

        def corporation_alignment(corporation)
          @corporation_alignment[corporation]
        end

        def move_political_track!(side)
          limit = self.class::POLITICAL_TRACK_LIMIT
          radical_opposite = side == :civil ? @political_track <= -limit : @political_track >= limit
          delta = (radical_opposite ? 2 : 1) * (side == :civil ? 1 : -1)
          @political_track = (@political_track + delta).clamp(-limit, limit)
          @log << "Trilha política agora em #{political_track_label}"
        end

        def political_track_label
          return 'Neutro' if @political_track.zero?

          @political_track.positive? ? "Civ#{@political_track}" : "Mil#{@political_track.abs}"
        end

        # Licença de Aprimoramento (18Junta Regras 2.1, 8.5): concedida numa
        # rodada de operação em que a companhia não construiu/aprimorou
        # nenhum trilho, só é válida na rodada de operação SEGUINTE (senão
        # expira sem uso).
        def upgrade_license?(corporation)
          @upgrade_licenses[corporation] == @or_round_number
        end

        def grant_upgrade_license!(corporation)
          @upgrade_licenses[corporation] = @or_round_number + 1
        end

        def consume_upgrade_license!(corporation)
          return false unless upgrade_license?(corporation)

          @upgrade_licenses.delete(corporation)
          true
        end

        def expire_stale_upgrade_licenses!
          @upgrade_licenses.reject! { |_corporation, valid_on_round| valid_on_round < @or_round_number }
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
