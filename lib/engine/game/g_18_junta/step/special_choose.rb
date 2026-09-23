# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18Junta
      module Step
        # Privadas (N) Emisarios de las Sombras, (D) Ferramenteria Ochoa e
        # (E) Casa Ruiz de Assistencia (18Junta Regras 2.1, Apêndice 1):
        # todas usam o mecanismo genérico de "Abilities" do motor
        # (choose_ability), sempre disponível durante a rodada da
        # companhia proprietária, sem interromper nenhum outro passo -- em
        # vez de um step próprio na sequência.
        #
        # (E): diferente de (N)/(D), o dono da ability continua sendo o
        # JOGADOR (owner_type: 'player'), não a companhia -- por isso
        # quando: 'any' (sem restrição de timing do motor) e toda a
        # checagem real (fase 3+, jogador ainda dono, presidente da
        # companhia que está operando agora) fica em
        # @game.private_e_donatable?, chamado manualmente aqui.
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
            when '(E)'
              corporation = current_entity
              return {} unless @game.private_e_donatable?(corporation)

              { 'donate' => "Doar para #{corporation.name} (recebe #{@game.format_currency(150)} do banco)" }
            else
              {}
            end
          end

          def process_choose_ability(action)
            entity = action.entity

            case entity.sym
            when '(N)'
              @game.use_private_n!(entity.owner, action.choice)
              @game.abilities(entity, :choose_ability).use!
            when '(D)'
              corporation = entity.owner
              old_train = discardable_trains(corporation).find { |t| t.id == action.choice }
              @game.exchange_train_for_private_d!(corporation, old_train) if old_train
              @game.abilities(entity, :choose_ability).use!
            when '(E)'
              # Sugestão Claude - 20/09/2026: NÃO chama .use! aqui -- ao
              # doar, donate_private_e! já muda entity.owner de jogador
              # para companhia; como a ability é owner_type: 'player', ela
              # já deixa de ser encontrada por @game.abilities (o motor
              # filtra por dono correspondente), então chamar .use! num
              # resultado nil quebrava a ação inteira no meio (bug real:
              # "undefined method 'use!' for nil", visto tanto no console
              # do navegador quanto reproduzido isoladamente). A mudança de
              # dono já desativa a ability sozinha, sem precisar de count/
              # use! explícito.
              corporation = current_entity
              @game.donate_private_e!(corporation) if @game.private_e_donatable?(corporation)
            end
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
