# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (A) Investidores Unidos (18Junta Regras 2.1, Apêndice 1):
        # uma vez por partida, no início de uma Fase de Mercado, o jogador
        # proprietário pode fixar antecipadamente o preço de Oferta Inicial
        # de uma companhia que ainda não teve nenhuma ação adquirida. Este
        # passo assume o controle da rodada para o dono da privada, do
        # mesmo jeito que CoupPrivateIChoice faz para a privada (I).
        #
        # A primeira interação é uma escolha simples (usar/não usar); só
        # depois de escolher "usar" o passo libera a ação 'par' de verdade,
        # reaproveitando a tela padrão de Par do motor.
        class FixParPrice < Engine::Step::Base
          USE_CHOICE = 'use'
          SKIP_CHOICE = 'skip'

          def description
            'Privada (A): Fixar Preço de Oferta Inicial'
          end

          def actions(entity)
            return [] unless entity
            return [] unless entity == pending_actor

            @accepted ? %w[par] : %w[choose]
          end

          def active_entities
            actor = pending_actor
            actor ? [actor] : super
          end

          def blocks?
            !pending_actor.nil?
          end

          def choice_available?(entity)
            !@accepted && entity == pending_actor
          end

          def choice_name
            'Habilidade Privada (A): Deseja arbitrar o preço de Oferta Inicial de alguma companhia não pareada?'
          end

          def choices
            {
              USE_CHOICE => 'Sim',
              SKIP_CHOICE => 'Não',
            }
          end

          def ipo_type(_corporation)
            :par
          end

          def get_par_prices(_entity, _corporation)
            @game.stock_market.par_prices
          end

          def process_choose(action)
            if action.choice == USE_CHOICE
              @accepted = true
            else
              @game.skip_private_a!(action.entity)
              @round.private_a_resolved = true
              pass!
            end
          end

          def process_par(action)
            corporation = action.corporation
            share_price = action.share_price
            raise GameError, "#{corporation.name} não pode ser fixada (já pareada)" if corporation.ipoed

            @game.use_private_a!(corporation, share_price)
            @round.private_a_resolved = true
            pass!
          end

          def round_state
            { private_a_resolved: false }
          end

          private

          def pending_actor
            return nil unless @game.private_a_usable_this_stock_round?
            return nil if @round.private_a_resolved

            @game.private_a_owner
          end
        end
      end
    end
  end
end