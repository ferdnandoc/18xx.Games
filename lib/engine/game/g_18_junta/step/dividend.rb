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

          # Sugestão Claude - 20/09/2026: privada (H) Muñoz Investimentos --
          # movido de share_price_change (que é chamado várias vezes só
          # para montar a prévia/chart de Pay Out vs Withhold na tela,
          # antes de qualquer confirmação -- causava o bônus disparar cedo
          # demais) para process_dividend, que só roda quando a ação é
          # DE FATO confirmada pelo jogador. Só paga o bônus quando o tipo
          # escolhido foi realmente "payout" (não "withhold") e o valor
          # pago é >= 2x o valor de mercado atual (mesma condição da
          # mudança de preço direita+acima).
          def process_dividend(action)
            entity = action.entity
            revenue = total_revenue

            if action.kind.to_s == 'payout' && @game.owns_private?(entity, '(H)') &&
               entity.share_price && revenue >= entity.share_price.price * 2
              pay_private_h_bonus!(entity, revenue)
            end

            super
          end

          private

          def pay_private_h_bonus!(entity, revenue)
            bonus = (revenue * 0.10).round
            return unless bonus.positive?

            @game.bank.spend(bonus, entity)
            @log << "A Cia #{entity.name} recebe #{@game.format_currency(bonus)} extras do banco por pagar altos dividendos "\
                    '[privada (H) Muñoz Investimentos].'
          end
        end
      end
    end
  end
end
