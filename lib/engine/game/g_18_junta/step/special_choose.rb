# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18Junta
      module Step
        # Privadas (N) Emisarios de las Sombras e (D) Ferramenteria Ochoa
        # (18Junta Regras 2.1, Apêndice 1): ambas usam o mecanismo genérico
        # de "Abilities" do motor (choose_ability), sempre disponível
        # durante a rodada da companhia proprietária, sem interromper
        # nenhum outro passo -- em vez de um step próprio na sequência.
        #
        # (D): descartar + comprar são uma ÚNICA transação (não duas
        # separadas com uma etapa intermediária de dinheiro) -- cada opção
        # já representa "descartar X para comprar Y por Z", contra o trem
        # mais barato disponível no depot no momento, com o preço final já
        # descontado do valor de face do trem descartado. Só aparece se o
        # desconto realmente compensa (preço final < preço cheio do trem
        # novo).
        class SpecialChoose < Engine::Step::SpecialChoose
          def choices_ability(entity)
            case entity.sym
            when '(N)'
              @game.remaining_paramilitar_hexes.to_h { |hex_id| [hex_id, "Remover ficha em #{hex_id}"] }
            when '(D)'
              corporation = entity.owner
              target = @game.depot.min_depot_train
              return {} unless target

              discardable_trains(corporation).to_h do |old_train|
                final_price = [target.price - old_train.price, 0].max
                next [old_train.id, nil] if final_price >= target.price

                [old_train.id, "Descartar #{old_train.name} para comprar #{target.name} por "\
                                "#{@game.format_currency(final_price)} (em vez de "\
                                "#{@game.format_currency(target.price)})"]
              end.compact
            else
              {}
            end
          end

          def process_choose_ability(action)
            entity = action.entity
            corporation = entity.owner

            case entity.sym
            when '(N)'
              @game.use_private_n!(corporation, action.choice)
            when '(D)'
              old_train = discardable_trains(corporation).find { |t| t.id == action.choice }
              @game.exchange_train_for_private_d!(corporation, old_train) if old_train
            end

            @game.abilities(entity, :choose_ability).use!
          end

          private

          def discardable_trains(corporation)
            corporation.trains.select { |t| %w[2 3].include?(t.name) }
          end
        end
      end
    end
  end
end