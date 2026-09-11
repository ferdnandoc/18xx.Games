# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Veto (18Junta Regras 2.1, 4.9) — versão simplificada acordada com
        # o designer: antes da companhia agir na rodada, o maior acionista
        # minoritário (>= 20%, se a companhia já operou ao menos uma vez)
        # pode travar às cegas um hexágono específico (construção de trilho
        # ou colocação de estação). Declarado o veto, o presidente aceita
        # (hexágono bloqueado nesta rodada; quem vetou pega 1 ficha preta)
        # ou recusa (companhia age normalmente; presidente pega 1 ficha
        # preta). Este passo assume o controle da rodada para o jogador
        # certo em cada uma das duas fases, do mesmo jeito que o
        # Engine::Step::DiscardTrain assume o controle para companhias
        # fora da ordem normal de turno.
        class VetoDeclaration < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          PASS_CHOICE = 'pass'
          ACCEPT_CHOICE = 'accept'
          REJECT_CHOICE = 'reject'

          def actions(entity)
            return [] unless entity
            return [] unless entity == current_veto_actor

            ACTIONS
          end

          def active_entities
            actor = current_veto_actor
            actor ? [actor] : super
          end

          def blocks?
            !current_veto_actor.nil?
          end

          def choice_name
            corp = operating_corporation
            return '' unless corp

            if @game.pending_veto_response_for?(corp)
              "#{corp.name}: aceitar o veto ao hexágono #{@game.pending_veto_hex(corp)}?"
            else
              "#{corp.name}: acionista minoritário quer vetar algum hexágono nesta rodada?"
            end
          end

          def choices
            corp = operating_corporation
            return {} unless corp

            if @game.pending_veto_response_for?(corp)
              {
                ACCEPT_CHOICE => 'Aceitar o veto (hexágono bloqueado; quem vetou recebe 1 ficha preta)',
                REJECT_CHOICE => 'Recusar o veto (companhia age normalmente; presidente recebe 1 ficha preta)',
              }
            else
              hexes = @game.veto_target_hexes(corp)
              hex_choices = hexes.to_h { |hex| [hex.id, "Vetar construção/estação em #{hex.id}"] }
              hex_choices.merge(PASS_CHOICE => 'Não vetar')
            end
          end

          def process_choose(action)
            corp = operating_corporation
            if @game.pending_veto_response_for?(corp)
              # Presidente respondeu: a interação termina aqui.
              @game.resolve_veto_response!(corp, action.choice)
              pass!
            elsif action.choice == PASS_CHOICE
              @game.mark_veto_offered!(corp)
              pass!
            else
              # Veto declarado: NÃO passa ainda — falta a resposta do
              # presidente (current_veto_actor passa a apontar pra ele).
              @game.declare_veto!(corp, action.choice)
            end
          end

          private

          def operating_corporation
            entities[entity_index]
          end

          def current_veto_actor
            corp = operating_corporation
            return nil unless corp

            return corp.owner if @game.pending_veto_response_for?(corp)

            @game.veto_eligible_shareholder(corp)
          end
        end
      end
    end
  end
end
