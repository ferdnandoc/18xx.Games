# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module G18Junta
      module Meta
        include Game::Meta

        DEV_STAGE = :prealpha
        PROTOTYPE = true

        GAME_SUBTITLE = 'V2'
        GAME_DESIGNER = 'Leandro Pires'
        GAME_LOCATION = 'Costaguana (fictional Central America)'

        PLAYER_RANGE = [2, 4].freeze
      end
    end
  end
end
