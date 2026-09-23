# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # 18Junta Regras 2.1, 8.5: se a companhia não construiu/aprimorou
        # nenhum trilho nesta rodada de operação, ela pode obter uma licença
        # de aprimoramento gratuita, utilizável na sua PRÓXIMA rodada de
        # operação para aprimorar um trilho sem sortear ficha de corrupção.
        # Só pode haver uma licença por vez, e ela expira se não for usada
        # na rodada seguinte.
        class UpgradeLicense < Engine::Step::Base
          ACTIONS = %w[choose].freeze

          # blocks? é sempre false aqui, então este passo nunca vira o
          # active_step da rodada -- mas Step::Base#description por
          # padrão só dá "raise NotImplementedError", e outros passos
          # deste jogo (ParamilitarChoice, VetoDeclaration,
          # CoupPrivateIChoice) já quebraram o jogo por essa mesma lacuna
          # quando blocks? virou true. Definido aqui também, por
          # segurança, caso isso mude no futuro.
          def description
            'Licença de Aprimoramento'
          end

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless entity.corporation?
            return [] unless @round.laid_hexes.empty?
            return [] if @game.upgrade_license?(entity)

            ACTIONS
          end

          # Leandro removeu a pedido do Claude para tentar consertar o erro em Skip Track
          # def blocks?
          #   false
          # end

          # Sugestão Claude para não aparecer no log a mensagem de skip
          def log_skip(_entity); end

          def choice_name
            'Licença de Aprimoramento'
          end

          def choices
            { 'license' => 'Obter licença de aprimoramento (grátis; só vale na próxima rodada de operação)' }
          end

          def process_choose(action)
            entity = action.entity
            @game.grant_upgrade_license!(entity)
            @log << "#{entity.name} obtém uma licença de aprimoramento para a próxima rodada de operação"
            pass!
          end
        end
      end
    end
  end
end
