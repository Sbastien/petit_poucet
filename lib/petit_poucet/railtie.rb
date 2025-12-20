# frozen_string_literal: true

module PetitPoucet
  class Railtie < Rails::Railtie
    initializer 'petit_poucet.configure' do
      ActiveSupport.on_load(:action_controller) do
        include PetitPoucet::Controller
      end

      ActiveSupport.on_load(:action_view) do
        include PetitPoucet::ViewHelpers
      end
    end
  end
end
