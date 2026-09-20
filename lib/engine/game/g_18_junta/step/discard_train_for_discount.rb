# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (D) Ferramenteria Ochoa (18Junta Regras 2.1, Apêndice 1):
        # uma vez por partida, na hora de comprar um trem, a companhia
        # proprietária pode descartar um trem 2 ou 3, recebendo o valor de
        # face do trem descartado como dinheiro no caixa -- efetivamente um
        # desconto na compra do trem seguinte, já que o caixa fica maior
        # antes da compra de verdade. Aparece de novo após cada trem
        # comprado na mesma rodada, enquanto a habilidade não for usada.
        class DiscardTrainForDiscount < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          SKIP_CHOICE = 'skip'
          DISCARDABLE_NAMES = %w[2 3].freeze

          def description
            'Privada (D): Descartar Trem por Desconto'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless @game.private_d_usable?(entity)

            ACTIONS
          end

          # Desativado por sugestão do Claude para evitar erro
          # def blocks?
          #   false
          # end

          def log_skip(_entity); end

          def choice_name
            'Habilidade Privada (D): deseja descartar um trem 2 ou 3 para receber o valor dele em caixa?'
          end

          def choices
            trains = discardable_trains(current_entity)

            choice_hash = trains.to_h do |train|
              [train.id, "Descartar #{train.name} (recebe #{@game.format_currency(train.price)})"]
            end
            choice_hash[SKIP_CHOICE] = 'Não usar agora'
            choice_hash
          end

          def process_choose(action)
            unless action.choice == SKIP_CHOICE
              train = discardable_trains(action.entity).find { |t| t.id == action.choice }
              raise GameError, 'Trem inválido para descarte' unless train

              @game.discard_train_for_private_d!(action.entity, train)
            end
            pass!
          end

          private

          def discardable_trains(entity)
            entity.trains.select { |t| DISCARDABLE_NAMES.include?(t.name) }
          end
        end
      end
    end
  end
end
