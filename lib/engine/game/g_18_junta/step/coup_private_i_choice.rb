# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (I) Orejuela Abogados (18Junta Regras 2.1, Apêndice 1): no
        # momento da resolução da Tentativa de Golpe, a companhia
        # proprietária pode descartar uma de suas fichas de apoio/rejeição.
        # Como isso pode acontecer no meio do turno de outra companhia (a
        # tentativa de golpe é disparada pela compra de um trem-5, por
        # qualquer companhia), este passo assume o controle da rodada para
        # o presidente da companhia dona da privada (I), do mesmo jeito que
        # o VetoDeclaration faz para o acionista minoritário.
        class CoupPrivateIChoice < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          SKIP_CHOICE = 'skip'

          def actions(entity)
            return [] unless entity
            return [] unless entity == pending_actor

            ACTIONS
          end

          def active_entities
            actor = pending_actor
            actor ? [actor] : super
          end

          def blocks?
            !pending_actor.nil?
          end

          def choice_name
            'Privada (I) Orejuela Abogados: descartar 1 ficha de apoio/rejeição ao golpe?'
          end

          def choices
            corp = @game.pending_coup_i_choice
            return {} unless corp

            alignment = @game.corporation_alignment(corp)
            choice_hash = { SKIP_CHOICE => 'Não descartar' }
            choice_hash['civil'] = "Descartar 1 ficha civil (tem #{alignment[:civil]})" if alignment[:civil].positive?
            choice_hash['militar'] = "Descartar 1 ficha militar (tem #{alignment[:militar]})" if alignment[:militar].positive?
            choice_hash
          end

          def process_choose(action)
            @game.resolve_private_i_choice!(action.choice)
            pass!
          end

          private

          def pending_actor
            @game.pending_coup_i_choice&.owner
          end
        end
      end
    end
  end
end
