# frozen_string_literal: true

require_relative '../../../step/special_choose'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (N) Emisarios de las Sombras (18Junta Regras 2.1, Apêndice
        # 1): ao contrário dos outros poderes de privada do 18Junta, este
        # usa o mecanismo genérico de "Abilities" do motor (choose_ability),
        # que fica sempre disponível durante toda a rodada da companhia
        # proprietária, sem interromper nenhum outro passo -- em vez de um
        # step próprio na sequência, como os demais. Não há opção de "não
        # usar": o jogador simplesmente não clica na ability se não quiser
        # usá-la agora, e ela continua disponível até ser usada de verdade.
        # Se não houver nenhum hexágono de paramilitar restante, a ability
        # não aparece.
        class SpecialChoose < Engine::Step::SpecialChoose
          def actions(entity)
            return [] if @game.remaining_paramilitar_hexes.empty?

            super
          end

          def choices_ability(entity)
            @game.remaining_paramilitar_hexes.to_h { |hex_id| [hex_id, "Remover ficha em #{hex_id}"] }
          end

          # Correção sugerida pelo Claude para o jogador não receber fichas pretas
          def process_choose_ability(action)
            corporation = action.entity.owner
            @game.use_private_n!(corporation, action.choice)
            @game.abilities(action.entity, :choose_ability).use!
          end


          # def process_choose_ability(action)
          #   @game.use_private_n!(action.entity, action.choice)
          #   @game.abilities(action.entity, :choose_ability).use!
          # end
        end
      end
    end
  end
end
