# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (A) Investidores Unidos: uma vez por partida, o jogador
        # proprietário pode, no início de uma rodada de ações, fixar
        # antecipadamente o preço de Oferta Inicial de uma companhia que
        # ainda não teve nenhuma ação comprada (ainda não foi fundada).
        #
        # Implementado como uma ação opcional (não bloqueia a rodada) --
        # "no início" descreve quando é válido usar (numa rodada de ações
        # ainda sem nenhuma companhia fundada por essa ação), não que
        # precise travar a vez de todo mundo esperando essa decisão; fica
        # disponível na própria vez do jogador dono da privada na rodada de
        # ações. O preço efetivamente fixado é aplicado/validado em
        # Step::BuySellParShares (ver esse arquivo) no momento em que a
        # companhia é de fato fundada.
        class FixParPrice < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def description
            'Privada (A): Fixar Oferta Inicial'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless @game.private_a_usable?(entity)

            ACTIONS
          end

          def blocks?
            false
          end

          def choice_name
            'Investidores Unidos: fixar antecipadamente o preço de Oferta Inicial de uma companhia'
          end

          def choices
            hash = {}
            @game.unparred_corporations.each do |corporation|
              @game.stock_market.par_prices.each do |share_price|
                hash["#{corporation.id}:#{share_price.price}"] =
                  "Fixar #{corporation.name} em #{@game.format_currency(share_price.price)}"
              end
            end
            hash['skip'] = 'Não usar agora'
            hash
          end

          def process_choose(action)
            return pass! if action.choice == 'skip'

            corporation_id, price = action.choice.split(':')
            @game.use_private_a!(action.entity, corporation_id, price.to_i)
            pass!
          end
        end
      end
    end
  end
end
