# frozen_string_literal: true

require_relative '../../../round/draft'

module Engine
  module Game
    module G1835
      module Round
        class Draft < Engine::Round::Draft
          def setup
            return unless first_round_in_a_clemens_draft

            @first_round_in_first_draft_round = true
            @entity_index = @entities.size - 1
          end

          def first_round_in_a_clemens_draft
            round_num == 1 && @game.option_clemens?
          end

          def select_entities
            @game.players
          end

          def next_entity!
            next_entity_index!
            return if finished?

            @steps.each(&:unpass!)
            skip_steps
            next_entity! unless active_step
          end

          def finished?
            @game.all_drafted? || @entities.all?(&:passed?)
          end

          def next_entity_index!
            return super if round_num > 1 || !@first_round_in_first_draft_round || !@game.option_clemens?

            if @entity_index.zero?
              @first_round_in_first_draft_round = false
            else
              @game.next_turn!
              @entity_index -= 1
            end
          end
        end
      end
    end
  end
end
