# frozen_string_literal: true

require_relative 'entities'
require_relative 'map'
require_relative 'meta'
require_relative 'step/coup_private_i_choice'
require_relative 'step/dividend'
require_relative 'step/paramilitar_choice'
require_relative 'step/private_auction'
require_relative 'step/remove_paramilitar_token'
require_relative 'step/token'
require_relative 'step/track'
require_relative 'step/upgrade_license'
require_relative 'step/veto_declaration'
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
        # Democracia vencer — a pilha perdedora é removida do depot em
        # resolve_coup_attempt! quando a Tentativa de Golpe é resolvida.
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

        # Indenização por corrupção (18Junta Regras 2.1, Apêndice — tabela
        # "Corrupção"): no fim de jogo, o total de fichas (brancas + pretas)
        # tiradas do saco durante a partida inteira define, pela linha da
        # tabela, o valor pago ao banco POR FICHA PRETA em posse de cada
        # jogador — a coluna usada depende de qual lado venceu o golpe.
        CORRUPTION_INDEMNITY_TABLE = [
          { max: 4, ditadura: 4, democracia: 8 },
          { max: 8, ditadura: 7, democracia: 11 },
          { max: 12, ditadura: 11, democracia: 16 },
          { max: 18, ditadura: 15, democracia: 21 },
          { max: 24, ditadura: 18, democracia: 25 },
          { max: 30, ditadura: 22, democracia: 30 },
          { max: 37, ditadura: 26, democracia: 36 },
          { max: 45, ditadura: 32, democracia: 42 },
          { max: Float::INFINITY, ditadura: 40, democracia: 50 },
        ].freeze

        # Custo para tomar a ficha de um hexágono de paramilitar (18Junta
        # Regras 2.1, 4.2), além do custo normal do terreno.
        PARAMILITAR_FEE = 30

        # Trilha política (18Junta Regras 2.1, 4.10 / tabuleiro): de -4
        # (Mil4) a +4 (Civ4), 0 é o espaço Neutro inicial.
        POLITICAL_TRACK_LIMIT = 4

        # Bônus por ficha verde (Ditadura) na tentativa de golpe (18Junta
        # Regras 2.1, 4.10.2).
        MILITAR_BONUS_PER_TOKEN = 80

        # Fazenda não pode ser início/fim de rota (18Junta Regras 2.1, 8.7.1).
        # A receita extra e a isenção do limite de distância já vêm do
        # visit_cost:0 nos tiles de fazenda (ver map.rb).
        def check_other(route)
          stops = route.visited_stops
          return if stops.empty?

          raise GameError, 'A fazenda não pode ser o início ou o fim da rota' if farm_stop?(stops.first) || farm_stop?(stops.last)
        end

        def farm_stop?(stop)
          stop.tile.label.to_s == 'F'
        end

        def operating_round(round_num)
          @or_round_number += 1
          expire_stale_upgrade_licenses!

          Round::Operating.new(self, [
            G18Junta::Step::CoupPrivateIChoice,
            Engine::Step::Bankrupt,
            Engine::Step::Exchange,
            Engine::Step::SpecialTrack,
            Engine::Step::BuyCompany,
            G18Junta::Step::VetoDeclaration,
            G18Junta::Step::Track,
            G18Junta::Step::ParamilitarChoice,
            G18Junta::Step::RemoveParamilitarToken,
            G18Junta::Step::UpgradeLicense,
            G18Junta::Step::Token,
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
          @private_n_used = false
          @veto_offered = {}
          @vetoed_hex = {}
          @pending_coup_i_choice = nil

          setup_corruption_bag!
          setup_political_track!
          @political_situation_deck = %i[calmaria calmaria golpe].shuffle

          # TODO: (próxima camada, fora do escopo atual): variante de 2 jogadores.
        end

        # Sorteia a corporação fora da partida e as privadas em jogo. Precisa
        # rodar ANTES do leilão inicial ser montado (new_auction_round), não
        # em #setup: Round::Base#initialize já chama Step#setup pra cada
        # step assim que a rodada é construída (em init_round, que roda
        # antes de #setup) -- se essa seleção rodasse só em #setup, o
        # PrivateAuction já teria tirado sua foto de @game.companies com as
        # 13 privadas, e a redução pra 6 (ou 5) nunca apareceria na tela.
        def select_game_entities!
          # Sorteia 1 corporação para ficar fora da partida.
          removed_corporation = @corporations.delete(@corporations.sample)
          @log << "Corporation not used in this game: #{removed_corporation.name}"

          # Sorteia as privadas que entram em jogo (6 para 3-4 jogadores, 5 para 2).
          privates_in_play = two_player? ? 5 : 6
          @companies.shuffle!
          selected = @companies.take(privates_in_play)
          (@companies - selected).each { |c| remove_company(c) }
          @log << "Private companies in this game: #{selected.map(&:name).join(', ')}"
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
        # Também é aqui que a compra de um trem-5 revela a carta de situação
        # política (18Junta Regras 2.1, 4.10/5, fase 5).
        def buy_train(operator, train, price = nil)
          depleting = train.from_depot? && @depot.upcoming.count { |t| t.name == train.name } == 1
          super
          refill_corruption_bag!(train.name) if depleting
          reveal_political_situation_card! if train.name == '5' && !coup_resolved?
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

          color = swap_black_via_private_k(holder, color) if color == :black

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

        # Privada (K) Hernandez Abogados: toda ficha preta que o presidente
        # da companhia proprietária receberia é automaticamente trocada por
        # outra sorteada do saco (mantida mesmo se também for preta).
        def swap_black_via_private_k(holder, color)
          return color unless holder.is_a?(Player)
          return color unless presides_company_owning?(holder, '(K)')

          new_color = draw_corruption_token!
          return color unless new_color

          @log << "#{holder.name} troca a ficha preta de corrupção (privada (K) Hernandez Abogados)"
          new_color
        end

        def presides_company_owning?(player, private_sym)
          @corporations.any? { |c| c.owner == player && owns_private?(c, private_sym) }
        end

        # --- Veto simplificado (18Junta Regras 2.1, 4.9) ---
        #
        # Versão acordada com o designer: em vez do maior acionista
        # minoritário reagir a uma ação já anunciada pelo presidente, ele
        # trava às cegas um hexágono específico ANTES da companhia agir
        # nesta rodada. O presidente então aceita ou recusa o veto.

        MINORITY_VETO_THRESHOLD = 20

        def veto_eligible_shareholder(corporation)
          return nil if corporation.operating_history.empty? # 1ª OR nunca pode ser vetada
          return nil if veto_offered_this_turn?(corporation)
          return nil if pending_veto_response_for?(corporation)

          president = corporation.owner
          minority = (@players - [president]).max_by { |p| p.percent_of(corporation) }
          return nil unless minority
          return nil if minority.percent_of(corporation) < self.class::MINORITY_VETO_THRESHOLD

          minority
        end

        def veto_offered_this_turn?(corporation)
          @veto_offered[corporation] == @or_round_number
        end

        def mark_veto_offered!(corporation)
          @veto_offered[corporation] = @or_round_number
        end

        def veto_target_hexes(corporation)
          reachable = graph_for_entity(corporation).reachable_hexes(corporation)
          reachable = reachable.respond_to?(:keys) ? reachable.keys : Array(reachable)
          reachable.empty? ? hexes : reachable
        end

        def declare_veto!(corporation, hex_id)
          declarer = veto_eligible_shareholder(corporation)
          mark_veto_offered!(corporation)
          @vetoed_hex[corporation] = { hex: hex_id, round: @or_round_number, declarer: declarer }
          @log << "#{declarer&.name} declara veto ao hexágono #{hex_id} de #{corporation.name}"
        end

        def pending_veto_response_for?(corporation)
          entry = @vetoed_hex[corporation]
          entry && entry[:round] == @or_round_number && !entry[:responded]
        end

        def pending_veto_hex(corporation)
          @vetoed_hex[corporation]&.dig(:hex)
        end

        def vetoed_hex_for(corporation)
          entry = @vetoed_hex[corporation]
          return nil unless entry
          return nil unless entry[:round] == @or_round_number

          entry[:hex]
        end

        def resolve_veto_response!(corporation, choice)
          entry = @vetoed_hex[corporation]
          return unless entry

          entry[:responded] = true
          president = corporation.owner
          declarer = entry[:declarer]

          if choice == 'accept'
            @corruption_tokens[declarer][:black] += 1 if declarer
            @log << "#{president&.name} aceita o veto: #{corporation.name} não pode agir no hexágono "\
                    "#{entry[:hex]} nesta rodada; #{declarer&.name} recebe 1 ficha preta de corrupção"
          else
            @corruption_tokens[president][:black] += 1 if president
            entry[:hex] = nil
            @log << "#{president&.name} recusa o veto: #{corporation.name} age normalmente; "\
                    "#{president&.name} recebe 1 ficha preta de corrupção"
          end
        end

        # --- Tentativa de Golpe (18Junta Regras 2.1, 4.10 / 5) ---

        # A cada trem-5 comprado, revela a carta do topo do baralho de
        # situação política (2 Calmaria + 1 Tentativa de Golpe). Calmaria não
        # tem efeito; a Tentativa de Golpe é resolvida imediatamente.
        def reveal_political_situation_card!
          card = @political_situation_deck.shift
          return unless card

          if card == :calmaria
            @log << 'Carta de situação política: Calmaria — o jogo segue normalmente.'
          else
            @log << 'Carta de situação política: TENTATIVA DE GOLPE!'
            start_coup_attempt!
          end
        end

        attr_reader :coup_outcome, :pending_paramilitar_hex, :pending_coup_i_choice

        # NOTA: a trilha política não define explicitamente o resultado
        # quando está em Neutro (0); assumindo Democracia nesse caso até
        # confirmação do designer.
        def start_coup_attempt!
          @coup_outcome = @political_track.negative? ? :ditadura : :democracia

          i_owner = @corporations.find { |c| owns_private?(c, '(I)') }
          if i_owner
            @pending_coup_i_choice = i_owner
          else
            finalize_coup_attempt!
          end
        end

        # Privada (I) Orejuela Abogados: descarta 1 ficha de apoio/rejeição
        # da companhia dona antes do golpe ser apurado (ver CoupPrivateIChoice).
        def resolve_private_i_choice!(choice)
          corp = @pending_coup_i_choice
          if corp && %w[civil militar].include?(choice)
            side = choice.to_sym
            if @corporation_alignment[corp][side].positive?
              @corporation_alignment[corp][side] -= 1
              @log << "#{corp.name} descarta 1 ficha #{choice} (privada (I) Orejuela Abogados)"
            end
          end
          @pending_coup_i_choice = nil
          finalize_coup_attempt!
        end

        def finalize_coup_attempt!
          @coup_resolved = true
          outcome_label = @coup_outcome == :ditadura ? 'DITADURA (golpe militar vence)' : 'DEMOCRACIA (golpe fracassa)'
          @log << "Resultado da Tentativa de Golpe: #{outcome_label}"

          close_all_private_companies!
          cancel_alignment_token_pairs!

          if @coup_outcome == :democracia
            apply_democracia_effects!
          else
            apply_ditadura_effects!
          end
        end

        def close_all_private_companies!
          @companies.dup.each { |c| remove_company(c) }
          @log << 'Todas as empresas privadas fecham, sem compensação (Tentativa de Golpe).'
        end

        def cancel_alignment_token_pairs!
          @corporation_alignment.each_value do |alignment|
            pairs = [alignment[:civil], alignment[:militar]].min
            alignment[:civil] -= pairs
            alignment[:militar] -= pairs
          end
        end

        def floated_corporations
          @corporations.select(&:floated?)
        end

        def apply_democracia_effects!
          remove_train_type_from_depot!('8')

          floated_corporations.each do |corp|
            blue = @corporation_alignment[corp][:civil]
            next unless blue.positive?

            blue.times { stock_market.move_right(corp) }
            @log << "#{corp.name} avança #{blue} espaço(s) no mercado (#{blue} ficha(s) civil(is))"
          end

          punish_least_aligned!(:democracia)
        end

        def apply_ditadura_effects!
          remove_train_type_from_depot!('D')

          replace_border_hexes_for_ditadura!

          floated_corporations.each do |corp|
            green = @corporation_alignment[corp][:militar]
            next unless green.positive?

            amount = green * self.class::MILITAR_BONUS_PER_TOKEN
            @bank.spend(amount, corp)
            @log << "#{corp.name} recebe #{format_currency(amount)} do banco (#{green} ficha(s) verde(s))"
          end

          punish_least_aligned!(:ditadura)
        end

        def remove_train_type_from_depot!(train_name)
          @depot.upcoming.select { |t| t.name == train_name }.dup.each { |t| @depot.remove_train(t) }
        end

        # Ditadura (18Junta Regras 2.1, Apêndice): as 4 fronteiras (hexágonos
        # vermelhos) trocam de tile, passando de um offboard de valor duplo
        # (civil, por fase) para um trilho militar de valor único, mantendo
        # as mesmas conexões/bordas.
        def replace_border_hexes_for_ditadura!
          self.class::DITADURA_BORDER_TILES.each do |hex_id, code|
            hex = hex_by_id(hex_id)
            next unless hex

            old_tile = hex.tile
            new_tile = Tile.from_code(hex_id, :red, code)
            update_tile_lists(new_tile, old_tile)
            hex.lay(new_tile)
            @log << "Hexágono #{hex_id} (#{hex.location_name}) vira trilho militar "\
                    "(#{format_currency(new_tile.offboards.first.max_revenue)})"
          end
          clear_graph
        end

        # Empresa menos alinhada ao lado vencedor; em caso de empate, pune a
        # de maior valor de mercado (confirmado pelo designer).
        def punish_least_aligned!(outcome)
          corps = floated_corporations
          return if corps.empty?

          net_alignment = lambda do |corp|
            alignment = @corporation_alignment[corp]
            outcome == :democracia ? alignment[:civil] - alignment[:militar] : alignment[:militar] - alignment[:civil]
          end

          min_value = corps.map(&net_alignment).min
          candidates = corps.select { |c| net_alignment.call(c) == min_value }
          target = candidates.max_by { |c| c.share_price.price }

          outcome == :democracia ? devalue_company!(target) : punish_ditadura_dissenter!(target)
        end

        # 18Junta Regras 2.1, 4.10.1: empresa menos alinhada à democracia cai
        # para metade do valor de mercado atual (arredondado pra baixo, mais
        # à esquerda em caso de empate de espaço).
        def devalue_company!(corporation)
          return unless corporation.share_price

          target_price = corporation.share_price.price / 2
          new_price = find_share_price_at_or_below(target_price)
          return unless new_price

          @log << "#{corporation.name} é a companhia menos alinhada à democracia: valor de mercado cai para "\
                  "#{format_currency(new_price.price)}"
          stock_market.move(corporation, new_price.coordinates, force: true)
        end

        def find_share_price_at_or_below(target_price)
          candidates = stock_market.market.flatten.compact.select { |sp| sp.price <= target_price }
          return nil if candidates.empty?

          max_price = candidates.map(&:price).max
          candidates.select { |sp| sp.price == max_price }.min_by { |sp| sp.coordinates[1] }
        end

        # 18Junta Regras 2.1, 4.10.2: presidente da empresa menos alinhada
        # aos militares recebe 10 fichas pretas diretamente do estoque, os
        # demais acionistas recebem 2 cada.
        def punish_ditadura_dissenter!(corporation)
          @log << "#{corporation.name} é a companhia menos alinhada aos militares: punição de corrupção"

          president = corporation.owner
          if president
            @corruption_tokens[president][:black] += 10
            @log << "#{president.name} (presidente) recebe 10 fichas pretas de corrupção diretamente do estoque"
          end

          other_shareholders(corporation, president).each do |player|
            @corruption_tokens[player][:black] += 2
            @log << "#{player.name} recebe 2 fichas pretas de corrupção diretamente do estoque"
          end
        end

        def other_shareholders(corporation, president)
          @players.select { |p| p != president && p.num_shares_of(corporation).positive? }
        end

        def owns_private?(corporation, private_sym)
          corporation.companies.any? { |c| c.sym == private_sym }
        end

        # --- Indenização por corrupção (18Junta Regras 2.1, Apêndice) ---

        def end_game!(game_end_reason)
          return if @finished

          pay_corruption_indemnity!
          super
        end

        def total_corruption_tokens
          @corruption_tokens.values.sum { |tokens| tokens[:white] + tokens[:black] }
        end

        # Valor pago ao banco por ficha preta; 0 se ninguém nunca tirou uma
        # ficha do saco. Se a Tentativa de Golpe nunca foi resolvida, usa a
        # coluna Democracia (confirmado pelo designer).
        def corruption_indemnity_rate
          total = total_corruption_tokens
          return 0 if total.zero?

          outcome = @coup_outcome || :democracia
          row = self.class::CORRUPTION_INDEMNITY_TABLE.find { |r| total <= r[:max] }
          row[outcome]
        end

        def pay_corruption_indemnity!
          rate = corruption_indemnity_rate
          return unless rate.positive?

          outcome = @coup_outcome || :democracia
          @log << "-- Indenização por corrupção: #{total_corruption_tokens} ficha(s) no total, "\
                  "#{format_currency(rate)} por ficha preta (#{outcome}) --"

          @corruption_tokens.each do |player, tokens|
            next unless tokens[:black].positive?

            amount = rate * tokens[:black]
            player.spend(amount, @bank, check_cash: false, check_positive: false)
            @log << "#{player.name} paga #{format_currency(amount)} de indenização "\
                    "(#{tokens[:black]} ficha(s) preta(s))"
          end
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
          remove_paramilitar_icon!(hex)
          @pending_paramilitar_choice = corporation
          @pending_paramilitar_hex = hex
        end

        def remove_paramilitar_icon!(hex)
          hex.tile.icons.reject! { |icon| icon.name == 'paramilitar' }
        end

        def pending_paramilitar_choice_for?(entity)
          @pending_paramilitar_choice == entity
        end

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

        # Neutro (0) só existe como posição inicial da trilha — depois da
        # primeira movimentação ela desaparece, então um movimento que
        # pousaria exatamente em Neutro passa direto para o primeiro espaço
        # do lado escolhido (confirmado pelo designer).
        def move_political_track!(side)
          limit = self.class::POLITICAL_TRACK_LIMIT
          radical_opposite = side == :civil ? @political_track <= -limit : @political_track >= limit
          delta = (radical_opposite ? 2 : 1) * (side == :civil ? 1 : -1)
          new_position = @political_track + delta
          new_position += (side == :civil ? 1 : -1) if new_position.zero? && !@political_track.zero?
          @political_track = new_position.clamp(-limit, limit)
          @log << "Trilha política agora em #{political_track_label}"
        end

        def political_track_label
          return 'Neutro' if @political_track.zero?

          @political_track.positive? ? "Civ#{@political_track}" : "Mil#{@political_track.abs}"
        end

        def remaining_paramilitar_hexes
          @paramilitar_hexes_remaining
        end

        # Privada (N) Emisarios de las Sombras: uma vez por partida, durante
        # uma ação da companhia proprietária, remove 1 ficha de paramilitar
        # de qualquer hexágono ainda não reclamado. O presidente paga 2
        # fichas pretas de corrupção diretamente do estoque (não do saco).
        def private_n_usable?(corporation)
          !@private_n_used && owns_private?(corporation, '(N)') && !@paramilitar_hexes_remaining.empty?
        end

        def use_private_n!(corporation, hex_id)
          @private_n_used = true
          @paramilitar_hexes_remaining.delete(hex_id)
          remove_paramilitar_icon!(hex_by_id(hex_id))

          president = corporation.owner
          @corruption_tokens[president][:black] += 2
          @log << "#{corporation.name} usa a privada (N) Emisarios de las Sombras: remove a ficha de paramilitar "\
                  "em #{hex_id}, e #{president.name} pega 2 fichas pretas de corrupção do estoque"
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

        # Leilão inicial das empresas privadas (18Junta Regras 2.1, 6.1).
        def new_auction_round
          select_game_entities!
          Round::Auction.new(self, [G18Junta::Step::PrivateAuction])
        end
      end
    end
  end
end
