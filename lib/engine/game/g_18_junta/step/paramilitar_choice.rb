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
            "Ficha de paramilitar em #{hex&.name}: apoiar quem?"
          end

          def choices
            choice_hash = {
              'civil' => "Apoiar os civis (azul) — paga #{@game.format_currency(G18Junta::Game::PARAMILITAR_FEE)}, "\
                         'trilha política anda para o lado civil',
              'militar' => "Apoiar os paramilitares (verde) — paga #{@game.format_currency(G18Junta::Game::PARAMILITAR_FEE)}, "\
                           'trilha política anda para o lado militar',
            }
            if @game.discard_paramilitar_free?(current_entity)
              choice_hash['descartar'] = 'Descartar a ficha sem custo (privada (C))'
            end
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
