# frozen_string_literal: true

require_relative '../../../step/dividend'

module Engine
  module Game
    module G18Junta
      module Step
        class Dividend < Engine::Step::Dividend
          # 18Junta Regras 2.1, 8.8.3:
          # - reter receita (ou receita zero) -> esquerda
          # - pagar dividendo (< 2x valor de mercado atual) -> direita
          # - pagar dividendo (>= 2x valor de mercado atual) -> direita + acima
          def share_price_change(entity, revenue = 0)
            return { share_direction: :left, share_times: 1 } unless revenue.positive?
            return { share_direction: :right, share_times: 1 } unless revenue >= entity.share_price.price * 2

            { share_direction: %i[right up], share_times: [1, 1] }
          end
        end
      end
    end
  end
end
