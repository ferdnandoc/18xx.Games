# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (D) Ferramenteria Ochoa: uma vez por partida, na hora de
        # comprar um trem, a companhia proprietária pode descartar um trem 2
        # ou 3 e receber o valor de custo do trem descartado como desconto na
        # compra do trem atual.
        class TrainDiscardDiscount < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          def description
            'Privada (D): Descartar Trem'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless entity.corporation?
            return [] unless @game.private_d_usable?(entity)

            ACTIONS
          end

          def blocks?
            false
          end

          def choice_name
            'Ferramenteria Ochoa: descartar um trem 2 ou 3 para obter desconto na próxima compra de trem'
          end

          def choices
            hash = @game.discardable_trains_for_private_d(current_entity).to_h do |train|
              [train.id, "Descartar #{train.name} (desconto de #{@game.format_currency(train.price)})"]
            end
            hash.merge('skip' => 'Não usar agora')
          end

          def process_choose(action)
            @game.use_private_d!(action.entity, action.choice) unless action.choice == 'skip'
            pass!
          end
        end
      end
    end
  end
end
