# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18Junta
      module Step
        # Privada (E) Casa Ruiz de Assistencia: a partir da Fase 3, em vez de
        # vender a privada para uma companhia (fluxo normal de
        # Engine::Step::BuyCompany, corporação paga o dono), o jogador
        # proprietário pode doá-la para uma companhia à sua escolha -- a
        # companhia não paga nada ao jogador, mas recebe $150 do banco. A
        # privada continua ativa e gerando receita normalmente.
        #
        # Ação do JOGADOR dono (não da companhia), por isso segue o mesmo
        # padrão usado em CoupPrivateIChoice/VetoDeclaration para permitir
        # que uma entidade fora da ordem normal de turno da rodada de
        # operação (aqui, o jogador) tenha uma ação disponível.
        class DonatePrivate < Engine::Step::Base
          ACTIONS = %w[choose].freeze
          DONATABLE_SYM = '(E)'

          def description
            'Privada (E): Doação'
          end

          def actions(entity)
            return [] unless entity == donor
            return [] unless donor

            ACTIONS
          end

          def active_entities
            donor ? [donor] : super
          end

          def blocks?
            false
          end

          def choice_name
            'Casa Ruiz de Assistencia: doar a privada para uma companhia (o banco paga $150 à companhia)'
          end

          def choices
            hash = @game.floated_corporations.to_h { |c| [c.id, "Doar para #{c.name}"] }
            hash['skip'] = 'Não doar agora'
            hash
          end

          def process_choose(action)
            @game.donate_private_e!(action.choice) unless action.choice == 'skip'
            pass!
          end

          private

          def donor
            @game.private_e_donor
          end
        end
      end
    end
  end
end
