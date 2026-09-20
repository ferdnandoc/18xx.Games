# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (A): se o preço de Oferta Inicial de uma companhia já foi
        # fixado (ver FixParPrice), só esse preço pode ser usado ao parar a
        # companhia de verdade -- ninguém mais escolhe livremente.
        class BuySellParShares < Engine::Step::BuySellParShares
          def get_par_prices(entity, corporation)
            fixed = @game.fixed_par_price_for(corporation)
            return [fixed] if fixed

            super
          end
        end
      end
    end
  end
end
