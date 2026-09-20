# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (E) Casa Ruiz de Assistencia (18Junta Regras 2.1, Apêndice
        # 1): a partir da Fase 3, o jogador proprietário -- desde que seja
        # presidente da companhia operando -- pode doar a privada para ela
        # em vez de vendê-la; a companhia recebe $150 do banco, e a privada
        # continua ativa e gerando receita normalmente (agora pertencendo
        # à companhia, não mais ao jogador).
        class DonatePrivate < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          SKIP_CHOICE = 'skip'

          def description
            'Privada (E): Doar para a Companhia'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless @game.private_e_donatable?(entity)

            ACTIONS
          end

          def blocks?
            false
          end

          def log_skip(_entity); end

          def choice_name
            'Doar a privada (E) Casa Ruiz de Assistencia para esta companhia? A companhia recebe $150 do banco.'
          end

          def choices
            {
              'donate' => 'Sim, doar a privada para esta companhia ($150 do banco)',
              SKIP_CHOICE => 'Não doar agora',
            }
          end

          def process_choose(action)
            @game.donate_private_e!(action.entity) unless action.choice == SKIP_CHOICE
            pass!
          end
        end
      end
    end
  end
end
