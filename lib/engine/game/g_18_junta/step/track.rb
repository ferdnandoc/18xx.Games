# frozen_string_literal: true

require_relative '../../../step/track'

module Engine
  module Game
    module G18Junta
      module Step
        # Responsabilidades extras além do Track padrão do motor:
        # - Veto (18Junta Regras 2.1, 4.9): bloqueia o hexágono vetado nesta
        #   rodada de operação.
        # - Licença de Aprimoramento (18Junta Regras 2.1, 8.4.2/8.5): consome
        #   a licença ativa (se houver) ao aprimorar um trilho, em vez de
        #   sortear ficha de corrupção do saco.
        # - Hexágonos de paramilitar (18Junta Regras 2.1, 4.2/4.10): sinaliza
        #   que a companhia deve escolher lado (civil/militar) quando
        #   constrói/aprimora um trilho num hexágono de paramilitar ainda não
        #   reclamado; a resolução em si acontece no passo ParamilitarChoice.
        class Track < Engine::Step::Track


# ## Leandro tentou inserir por sugestão do Chatgpt, para permitir passar sem colocar track... NÃO FUNCIONOU
# def actions(entity)
#   return [] unless entity == current_entity
#   return [] if entity.company?

#   if can_lay_tile?(entity)
#     ACTIONS
#   else
#     ['pass']
#   end
# end



          def available_hex(entity_or_entities, hex)
            entity = Array(entity_or_entities).first
            return false if entity.corporation? && @game.vetoed_hex_for(entity) == hex.id

            super
          end

          def process_lay_tile(action)
            super

            consume_license_if_upgraded(action)
            flag_paramilitar_hex_if_needed(action)
            expire_license_if_turn_ended(action.entity)
          end

          # Sugestão Claude - 20/09/2026: garante que a expiração (com
          # log) também dispare quando a companhia passa a vez de
          # construir trilho sem sequer ter usado a licença, não só
          # quando ela constrói algo.
          def process_pass(action)
            super

            expire_license_if_turn_ended(action.entity)
          end

          private

          # Sugestão Claude - 20/09/2026: chamado após lay_tile ou pass;
          # só expira a licença quando a companhia não tem mais nenhuma
          # ação de construção disponível nesta rodada (ou seja, o
          # "turno de lay/upgrade track" dela realmente terminou).
          def expire_license_if_turn_ended(entity)
            return if can_lay_tile?(entity)

            @game.expire_upgrade_license_if_unused!(entity)
          end

            #Correção sugerida pelo Claude para todo upgrade precisar de licença ou ganhar corrupção.
            def consume_license_if_upgraded(action)
              return unless @round.upgraded_track

              entity = action.entity
              if @game.consume_upgrade_license!(entity)
                @log << "#{entity.name} usa a licença de aprimoramento (não sorteia ficha de corrupção)"
              else
                draw_corruption_token_for_upgrade!(entity)
              end
            end


          # Iteração onde upgrades só precisavam de licença depois do golpe
          # def consume_license_if_upgraded(action)
          #   return unless @round.upgraded_track

          #   entity = action.entity
          #   if @game.consume_upgrade_license!(entity)
          #     @log << "#{entity.name} usa a licença de aprimoramento (não sorteia ficha de corrupção)"
          #   elsif @game.coup_resolved?
          #     draw_corruption_token_for_upgrade!(entity)
          #   end
          # end




          def draw_corruption_token_for_upgrade!(entity)
            president = entity.owner
            colors = @game.draw_corruption_tokens!(president, max_draws: 1)
            return if colors.empty?

            color_name = colors.first == :white ? 'branca' : 'preta'
            @log << "#{president.name} recebe ficha aleatória de corrupção por fazer upgrade sem licença: "\
                    "Sorteada ficha #{color_name}"
          end

          def flag_paramilitar_hex_if_needed(action)
            hex = action.hex
            return unless @game.paramilitar_hex_unclaimed?(hex)

            @game.flag_paramilitar_hex_pending!(hex, action.entity)
          end
        end
      end
    end
  end
end
