# frozen_string_literal: true

require 'rails/generators/base'

module PetitPoucet
  module Generators
    # Friendly entry point for setting up Petit Poucet in a Rails app.
    # Copies the default partial (or a themed variant) and prints instructions
    # for wiring it into the layout.
    #
    # @example
    #   $ rails generate petit_poucet:install
    #   $ rails generate petit_poucet:install --theme=tailwind
    #   $ rails generate petit_poucet:install --theme=bootstrap
    class InstallGenerator < Rails::Generators::Base
      THEMES = %w[default tailwind bootstrap].freeze

      class_option :theme, type: :string, default: 'default',
                           desc: "Partial theme to install (#{THEMES.join(', ')})"

      desc 'Set up Petit Poucet: copy the breadcrumbs partial and show next steps'

      def copy_views
        validate_theme!
        self.class.source_root(theme_source_root)
        copy_file '_breadcrumbs.html.erb', 'app/views/petit_poucet/_breadcrumbs.html.erb'
      end

      def show_next_steps
        say <<~MESSAGE

          Petit Poucet installed (theme: #{options[:theme]}).

          Next steps:

          1. Render the partial in your layout (e.g. app/views/layouts/application.html.erb):

               <%= render "petit_poucet/breadcrumbs" %>

          2. Declare breadcrumbs in your controllers:

               class ArticlesController < ApplicationController
                 breadcrumbs "Articles", :articles_path
               end

          3. Customize the copied partial freely. To translate the aria-label
             for a non-English app, edit it directly.

          See https://github.com/Sbastien/petit_poucet#readme for the full guide.
        MESSAGE
      end

      private

      def validate_theme!
        return if THEMES.include?(options[:theme])

        raise Thor::Error, "Unknown theme '#{options[:theme]}'. Valid: #{THEMES.join(', ')}"
      end

      def theme_source_root
        if options[:theme] == 'default'
          File.expand_path('../../../petit_poucet/views/petit_poucet', __dir__)
        else
          File.expand_path("../../../petit_poucet/themes/#{options[:theme]}", __dir__)
        end
      end
    end
  end
end
