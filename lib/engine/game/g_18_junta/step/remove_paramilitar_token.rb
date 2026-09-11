# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (N) Emisarios de las Sombras: uma vez por partida, durante
        # uma ação da companhia proprietária, remove 1 ficha de paramilitar
        # de qualquer hexágono do tabuleiro ainda não reclamada. O
        # presidente paga 2 fichas pretas de corrupção diretamente do
        # estoque (não sorteadas do saco).
        class RemoveParamilitarToken < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          SKIP_CHOICE = 'skip'

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless entity.corporation?
            return [] unless @game.private_n_usable?(entity)

            ACTIONS
          end

          def blocks?
            false
          end

          def choice_name
            'Emisarios de las Sombras: remover ficha de paramilitar (1x por partida)'
          end

          def choices
            hex_choices = @game.remaining_paramilitar_hexes.to_h { |hex_id| [hex_id, "Remover ficha em #{hex_id}"] }
            hex_choices.merge(SKIP_CHOICE => 'Não usar agora')
          end

          def process_choose(action)
            @game.use_private_n!(action.entity, action.choice) unless action.choice == SKIP_CHOICE
            pass!
          end
        end
      end
    end
  end
end
