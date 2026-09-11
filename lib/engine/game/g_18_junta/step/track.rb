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
          def available_hex(entity_or_entities, hex)
            entity = Array(entity_or_entities).first
            return false if entity.corporation? && @game.vetoed_hex_for(entity) == hex.id

            super
          end

          def process_lay_tile(action)
            super

            consume_license_if_upgraded(action)
            flag_paramilitar_hex_if_needed(action)
          end

          private

          def consume_license_if_upgraded(action)
            return unless @round.upgraded_track

            entity = action.entity
            if @game.consume_upgrade_license!(entity)
              @log << "#{entity.name} usa a licença de aprimoramento (não sorteia ficha de corrupção)"
            elsif @game.coup_resolved?
              draw_corruption_token_for_upgrade!(entity)
            end
          end

          def draw_corruption_token_for_upgrade!(entity)
            color = @game.draw_corruption_token!
            return unless color

            president = entity.owner
            @game.give_corruption_token!(president, color)
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
