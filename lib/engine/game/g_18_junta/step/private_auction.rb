# frozen_string_literal: true

require_relative '../../../step/base'
require_relative '../../../step/passable_auction'

module Engine
  module Game
    module G18Junta
      module Step
        # Leilão inicial das empresas privadas (18Junta Regras 2.1, 6.1):
        # o jogador da vez escolhe uma privada disponível pra dar lance
        # (mínimo o valor impresso, incrementos de $5) ou passa a escolha
        # pro próximo jogador. Uma vez escolhida, os demais jogadores
        # (em sentido horário) dão lances maiores ou passam, até sobrar um
        # interessado, que paga seu lance e leva a carta — e passa a
        # escolher a próxima privada a ser leiloada.
        #
        # Se todos os jogadores passarem a escolha sem leiloar nada, o
        # jogador da vez pode abrir um leilão forçado por até metade do
        # valor da privada (arredondado pra cima). Se ele também recusar,
        # as privadas remanescentes saem do jogo.
        class PrivateAuction < Engine::Step::Base
          include Engine::Step::PassableAuction

          ACTIONS = %w[bid pass].freeze

          attr_reader :companies

          def description
            'Leilão das Empresas Privadas'
          end

          def available
            @companies
          end

          def may_bid?(company)
            return false unless @companies.include?(company)

            super
          end

          # Sem compra direta por preço fixo aqui -- só lance competitivo
          # (leilão inglês simples, Regras 2.1, 6.1). A view compartilhada
          # (assets/app/view/game/round/auction.rb#render_company_actions)
          # chama isso incondicionalmente (sem respond_to?) assim que o
          # jogador seleciona uma privada; sem esse método definido, o clique
          # derrubava o render inteiro com NoMethodError -- por fora parecia
          # que "clicar na privada não fazia nada".
          def may_purchase?(_company)
            false
          end

          def active_entities
            return super unless auctioning

            winning_bid = highest_bid(auctioning)
            return [@active_bidders[0]] unless winning_bid

            next_index = (@active_bidders.index(winning_bid.entity) + 1) % @active_bidders.size
            [@active_bidders[next_index]]
          end

          def min_increment
            5
          end

          def min_bid(company)
            return unless company

            return forced_min_bid(company) if !@bids[company] || @bids[company].empty?

            highest_bid(company).price + min_increment
          end

          def max_bid(player, company)
            opening_bid = !@bids[company] || @bids[company].empty?
            return [forced_max_bid(company), player.cash].min if @forced_round && opening_bid

            player.cash
          end

          def actions(entity)
            return [] if @companies.empty?
            return [] unless entity == current_entity

            ACTIONS
          end

          def setup
            setup_auction
            @companies = @game.companies.reject(&:closed?).dup
            @consecutive_choosing_passes = 0
            @forced_round = false
          end

          def process_pass(action)
            entity = action.entity

            if auctioning
              pass_auction(entity)
              resolve_bids
            else
              @log << "#{entity.name} passa a escolha do leilão"

              # Uma volta completa da mesa sem ninguém iniciar um leilão
              # normal: dá a cada jogador, em ordem de turno A PARTIR de
              # quem começou esta volta, a chance de abrir um leilão com
              # desconto (até metade do valor). Uma volta INTEIRA sem
              # ninguém topar -- inclusive já em modo "leilão com
              # desconto" -- é que tira as privadas remanescentes do
              # jogo. (Antes disso, um único jogador recusando a oferta
              # com desconto já zerava as privadas sem dar chance aos
              # demais -- bug reportado pelo designer.)
              @consecutive_choosing_passes += 1

              if @consecutive_choosing_passes < entities.size
                @round.next_entity_index!
              elsif @forced_round
                @log << 'Nenhum jogador quis iniciar outro leilão — as empresas privadas remanescentes saem do jogo'
                @companies.each { |c| @game.remove_company(c) }
                @companies = []
              else
                @forced_round = true
                @consecutive_choosing_passes = 0
                @round.next_entity_index!
                @log << "#{entities[entity_index].name} pode abrir um leilão por até metade do valor de uma "\
                        'privada remanescente'
              end
            end
          end

          def process_bid(action)
            action.entity.unpass!

            if auctioning
              add_bid(action)
            else
              @consecutive_choosing_passes = 0
              was_forced = @forced_round
              selection_bid(action)
              @forced_round = false
              @log << "#{action.entity.name} usa o leilão com desconto (metade do valor)" if was_forced
            end
          end

          private

          def forced_min_bid(company)
            @forced_round ? 1 : company.min_bid
          end

          def forced_max_bid(company)
            (company.min_bid / 2.0).ceil
          end

          def add_bid(bid)
            super
            @log << "#{bid.entity.name} dá lance de #{@game.format_currency(bid.price)} por #{bid.company.name}"
          end

          def win_bid(winner, company)
            player = winner.entity
            price = winner.price

            company.owner = player
            player.companies << company
            player.spend(price, @game.bank) if price.positive?
            @log << "#{player.name} vence o leilão de #{company.name} por #{@game.format_currency(price)}"

            @companies.delete(company)
            @round.entity_index = entities.index(player) || 0
          end
        end
      end
    end
  end
end
