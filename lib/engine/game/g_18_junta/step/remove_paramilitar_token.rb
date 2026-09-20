# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (N) Emisarios de las Sombras: uma vez por partida, durante
        # uma ação da companhia proprietária, remove 1 ficha de paramilitar
        # de qualquer hexágono do tabuleiro ainda não reclamada. O
        # presidente paga 2 fichas pretas de corrupção diretamente do
        # estoque (não sorteadas do saco).
        class RemoveParamilitarToken < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          SKIP_CHOICE = 'skip'

          # blocks? é sempre false aqui, então este passo nunca vira o
          # active_step da rodada -- mas Step::Base#description por
          # padrão só dá "raise NotImplementedError", e outros passos
          # deste jogo (ParamilitarChoice, VetoDeclaration,
          # CoupPrivateIChoice) já quebraram o jogo por essa mesma lacuna
          # quando blocks? virou true. Definido aqui também, por
          # segurança, caso isso mude no futuro.
          def description
            'Privada (N): Remover Ficha de Paramilitar'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless entity.corporation?
            return [] unless @game.private_n_usable?(entity)

            ACTIONS
          end
          
#Sugestão Claude para não aparecer no log a mensagem de skip
def log_skip(_entity); end


          # Leandro removeu a pedido do Claude, para tentar consertar erro do Skip Track
          # def blocks?
          #   false
          # end

          def choice_name
            'Emisarios de las Sombras: remover ficha de paramilitar (1x por partida)'
          end

          def choices
            hex_choices = @game.remaining_paramilitar_hexes.to_h { |hex_id| [hex_id, "Remover ficha em #{hex_id}"] }
            hex_choices.merge(SKIP_CHOICE => 'Não usar agora')
          end

          def process_choose(action)
            @game.use_private_n!(action.entity, action.choice) unless action.choice == SKIP_CHOICE
            pass!
          end
        end
      end
    end
  end
end
