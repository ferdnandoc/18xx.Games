# frozen_string_literal: true

require_relative '../../../step/token'

module Engine
  module Game
    module G18Junta
      module Step
        # Aplica o veto (18Junta Regras 2.1, 4.9) a colocações de estação.
        class Token < Engine::Step::Token
          def available_hex(entity, hex)
            return false if entity.corporation? && @game.vetoed_hex_for(entity) == hex.id

            super
          end
        end
      end
    end
  end
end
