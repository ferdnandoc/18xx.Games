# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'

module Engine
  module Game
    module G18Junta
      module Step
        # Aplica o preço de Oferta Inicial fixado antecipadamente pela
        # privada (A) Investidores Unidos (ver FixParPrice/Game#use_private_a!):
        # restringe as opções de preço mostradas e valida a fundação real.
        class BuySellParShares < Engine::Step::BuySellParShares
          def get_par_prices(entity, corp)
            fixed = @game.fixed_par_price(corp)
            return [fixed] if fixed

            super
          end

          def process_par(action)
            fixed = @game.fixed_par_price(action.corporation)
            if fixed && action.share_price != fixed
              raise GameError, "#{action.corporation.name} tem o preço de Oferta Inicial fixado em "\
                               "#{@game.format_currency(fixed.price)} pela privada (A) Investidores Unidos"
            end

            super
            @game.clear_fixed_par_price!(action.corporation) if fixed
          end
        end
      end
    end
  end
end
