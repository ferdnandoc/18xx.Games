# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # 18Junta Regras 2.1, 4.2 / tabuleiro: ao construir num hexágono de
        # paramilitar ainda não reclamado, a companhia deve pagar $30 e
        # escolher que lado apoiar (civil/azul ou militar/verde), o que move
        # a trilha política — a menos que possua a privada (C), que permite
        # descartar a ficha de graça, sem custo e sem mover a trilha.
        class ParamilitarChoice < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          # Round::Base#description (chamado pela view a cada render, pra
          # mostrar o cabeçalho da rodada) faz active_step.description --
          # e Step::Base#description por padrão só dá "raise
          # NotImplementedError". Sem isso sobrescrito aqui, o jogo
          # quebrava (tela inteira) no exato instante em que este passo
          # vira o bloqueador, ou seja, assim que um trilho é construído
          # num hexágono de paramilitar -- por fora parecia que "o jogo
          # trava ao colocar um tile em locais militares".
          def description
            'Ficha de Paramilitar'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless @game.pending_paramilitar_choice_for?(entity)

            ACTIONS
          end

          def blocks?
            @game.pending_paramilitar_choice_for?(current_entity)
          end

          def choice_name
            hex = @game.pending_paramilitar_hex
            "Foi identificado um grupo paramilitar em #{hex&.name}: Qual lado a companhia vai apoiar nesse momento?"
          end

          def choices
            choice_hash = {
              'civil' => 'Apoiar os civis',
              'militar' => 'Apoiar os militares',
            }
            choice_hash['descartar'] = 'Descartar a ficha [Private (C)]' if @game.discard_paramilitar_free?(current_entity)
            choice_hash
          end

          def process_choose(action)
            @game.resolve_paramilitar_choice!(action.entity, action.choice)
            pass!
          end
        end
      end
    end
  end
end
