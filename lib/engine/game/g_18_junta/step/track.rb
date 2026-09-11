# frozen_string_literal: true

require_relative '../../../step/track'

module Engine
  module Game
    module G18Junta
      module Step
        # Consome a licença de aprimoramento (se a companhia tiver uma) assim
        # que ela aprimora um trilho, em vez de sortear ficha de corrupção do
        # saco (18Junta Regras 2.1, 8.4.2). O sorteio em si será acrescentado
        # quando o saco de corrupção for implementado; por ora este passo só
        # controla o consumo/validade da licença.
        class Track < Engine::Step::Track
          def process_lay_tile(action)
            super

            return unless @round.upgraded_track

            entity = action.entity
            return unless @game.consume_upgrade_license!(entity)

            @log << "#{entity.name} usa a licença de aprimoramento (não sorteia ficha de corrupção)"
          end
        end
      end
    end
  end
end
