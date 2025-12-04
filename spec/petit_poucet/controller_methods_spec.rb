# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PetitPoucet::ControllerMethods do
  let(:base_controller_class) do
    Class.new do
      include PetitPoucet::ControllerMethods

      attr_accessor :action_name

      def initialize
        @action_name = 'index'
      end
    end
  end

  describe '.breadcrumb' do
    it 'adds breadcrumb definition to class' do
      controller_class = Class.new(base_controller_class) { breadcrumb 'Home', '/' }

      expect(controller_class._breadcrumb_definitions.size).to eq(1)
      expect(controller_class._breadcrumb_definitions.first.name).to eq('Home')
    end

    it 'inherits breadcrumbs from parent without modifying it' do
      parent_class = Class.new(base_controller_class) { breadcrumb 'Home', '/' }
      child_class = Class.new(parent_class) { breadcrumb 'Articles', '/articles' }

      expect(parent_class._breadcrumb_definitions.size).to eq(1)
      expect(child_class._breadcrumb_definitions.size).to eq(2)
    end

    it 'accepts options without path' do
      controller_class = Class.new(base_controller_class) { breadcrumb 'Edit Only', only: :edit }

      expect(controller_class._breadcrumb_definitions.first.path).to be_nil
    end
  end

  describe '.clear_breadcrumbs' do
    it 'clears inherited breadcrumbs' do
      parent_class = Class.new(base_controller_class) { breadcrumb 'Home', '/' }
      child_class = Class.new(parent_class) do
        clear_breadcrumbs
        breadcrumb 'Admin', '/admin'
      end

      expect(child_class._breadcrumb_definitions.map(&:name)).to eq(['Admin'])
    end
  end

  describe '#breadcrumb (instance method)' do
    it 'adds runtime breadcrumb' do
      controller = base_controller_class.new
      controller.breadcrumb('Dynamic', '/dynamic')

      expect(controller.breadcrumbs).to eq([{ name: 'Dynamic', path: '/dynamic' }])
    end

    it 'combines with class-level breadcrumbs' do
      controller_class = Class.new(base_controller_class) { breadcrumb 'Home', '/' }
      controller = controller_class.new
      controller.breadcrumb('Dynamic', '/dynamic')

      expect(controller.breadcrumbs.map { _1[:name] }).to eq(%w[Home Dynamic])
    end
  end

  describe '#breadcrumbs' do
    it 'resolves static breadcrumbs' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb 'Home', '/'
        breadcrumb 'Articles', '/articles'
      end

      expect(controller_class.new.breadcrumbs).to eq([
                                                       { name: 'Home', path: '/' },
                                                       { name: 'Articles', path: '/articles' }
                                                     ])
    end

    it 'resolves lambda breadcrumbs in controller context' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb -> { "Action: #{action_name}" }, -> { "/#{action_name}" }
      end

      controller = controller_class.new
      controller.action_name = 'show'

      expect(controller.breadcrumbs.first).to eq({ name: 'Action: show', path: '/show' })
    end

    it 'resolves symbol breadcrumbs by calling methods' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb :computed_name, :computed_path

        def computed_name = 'Computed'
        def computed_path = '/computed'
      end

      expect(controller_class.new.breadcrumbs.first).to eq({ name: 'Computed', path: '/computed' })
    end

    it 'filters by only option' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb 'Home', '/'
        breadcrumb 'Edit', '/edit', only: %i[edit update]
      end

      controller = controller_class.new
      expect(controller.breadcrumbs.size).to eq(1)

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.size).to eq(2)
    end

    it 'filters by except option' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb 'Home', '/'
        breadcrumb 'Details', '/details', except: :index
      end

      controller = controller_class.new
      expect(controller.breadcrumbs.size).to eq(1)

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'show'
      expect(controller.breadcrumbs.size).to eq(2)
    end

    it 'handles nil paths' do
      controller_class = Class.new(base_controller_class) { breadcrumb 'Current Page' }

      expect(controller_class.new.breadcrumbs.first).to eq({ name: 'Current Page', path: nil })
    end

    it 'accepts options without path' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb 'Edit Only', only: :edit
      end

      controller = controller_class.new
      expect(controller.breadcrumbs).to be_empty

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.first).to eq({ name: 'Edit Only', path: nil })
    end

    it 'is memoized' do
      controller_class = Class.new(base_controller_class) { breadcrumb 'Home', '/' }
      controller = controller_class.new

      expect(controller.breadcrumbs).to be(controller.breadcrumbs)
    end
  end

  describe '#clear_breadcrumbs (instance)' do
    it 'clears runtime breadcrumbs' do
      controller = base_controller_class.new
      controller.breadcrumb('First', '/first')
      controller.clear_breadcrumbs
      controller.breadcrumb('Second', '/second')
      controller.instance_variable_set(:@breadcrumbs, nil)

      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Second'])
    end
  end
end
