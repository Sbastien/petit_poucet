# frozen_string_literal: true

require 'spec_helper'
require 'abstract_controller'
require 'abstract_controller/callbacks'

RSpec.describe PetitPoucet::Controller do
  let(:base_controller_class) do
    Class.new(AbstractController::Base) do
      include AbstractController::Callbacks
      include PetitPoucet::Controller

      attr_accessor :action_name

      def initialize
        super
        @action_name = 'index'
      end

      def root_path = '/'
      def articles_path = '/articles'
    end
  end

  def run_for(klass, action: 'index')
    controller = klass.new
    controller.action_name = action.to_s
    controller.run_callbacks(:process_action) { :ok }
    controller
  end

  describe '.breadcrumbs (class-level declaration)' do
    it 'registers a single static crumb' do
      klass = Class.new(base_controller_class) { breadcrumbs 'Home', '/' }

      expect(run_for(klass).breadcrumbs.names).to eq(['Home'])
    end

    it 'resolves a Symbol path via send on the controller' do
      klass = Class.new(base_controller_class) { breadcrumbs 'Home', :root_path }

      expect(run_for(klass).breadcrumbs.first.path).to eq('/')
    end

    it 'evaluates a Proc path in the controller context' do
      klass = Class.new(base_controller_class) do
        attr_accessor :id

        breadcrumbs 'Item', -> { "/items/#{id}" }
      end

      controller = klass.new
      controller.id = 42
      controller.run_callbacks(:process_action) { :ok }

      expect(controller.breadcrumbs.first.path).to eq('/items/42')
    end

    it 'uses a String path verbatim' do
      klass = Class.new(base_controller_class) { breadcrumbs 'Home', '/literal' }

      expect(run_for(klass).breadcrumbs.first.path).to eq('/literal')
    end

    it 'allows nil path' do
      klass = Class.new(base_controller_class) { breadcrumbs 'Current' }

      expect(run_for(klass).breadcrumbs.first.path).to be_nil
    end
  end

  describe 'inheritance' do
    it 'runs parent declarations before child declarations' do
      parent = Class.new(base_controller_class) { breadcrumbs 'Home', :root_path }
      child  = Class.new(parent) { breadcrumbs 'Articles', :articles_path }

      expect(run_for(child).breadcrumbs.names).to eq(%w[Home Articles])
    end

    it 'allows clearing inherited declarations from within an action' do
      parent = Class.new(base_controller_class) { breadcrumbs 'Home', :root_path }
      child  = Class.new(parent)

      controller = run_for(child)
      controller.breadcrumbs.clear
      controller.breadcrumbs.add 'Admin', '/admin'

      expect(controller.breadcrumbs.names).to eq(['Admin'])
    end
  end

  describe 'filter options (delegated to before_action)' do
    it 'passes only: through to before_action' do
      klass = Class.new(base_controller_class) do
        breadcrumbs 'Show only', :root_path, only: :show
      end

      expect(run_for(klass, action: 'index').breadcrumbs.names).to eq([])
      expect(run_for(klass, action: 'show').breadcrumbs.names).to eq(['Show only'])
    end

    it 'passes if: through to before_action' do
      klass = Class.new(base_controller_class) do
        attr_accessor :enabled

        breadcrumbs 'Maybe', :root_path, if: -> { enabled }
      end

      controller = klass.new
      controller.enabled = false
      controller.run_callbacks(:process_action) { :ok }
      expect(controller.breadcrumbs.names).to eq([])

      controller = klass.new
      controller.enabled = true
      controller.run_callbacks(:process_action) { :ok }
      expect(controller.breadcrumbs.names).to eq(['Maybe'])
    end
  end

  describe '#breadcrumbs (instance method)' do
    it 'returns a memoized Breadcrumbs collection' do
      controller = base_controller_class.new

      expect(controller.breadcrumbs).to be_a(PetitPoucet::Breadcrumbs)
      expect(controller.breadcrumbs).to be(controller.breadcrumbs)
    end

    it 'yields the collection when a block is given (runtime mutation)' do
      controller = base_controller_class.new

      controller.breadcrumbs do |crumbs|
        crumbs.add 'First', '/first'
        crumbs.add 'Second', '/second'
      end

      expect(controller.breadcrumbs.names).to eq(%w[First Second])
    end

    it 'allows runtime mutation from within an action' do
      klass = Class.new(base_controller_class) { breadcrumbs 'Home', :root_path }
      controller = run_for(klass)

      controller.breadcrumbs.add 'Dynamic', '/dynamic'

      expect(controller.breadcrumbs.names).to eq(%w[Home Dynamic])
    end
  end

  describe 'process_action re-dispatch (rescue_from / retry safety)' do
    it 'starts each dispatch with a fresh collection (no duplication)' do
      klass = Class.new(base_controller_class) { breadcrumbs 'Home', :root_path }

      controller = klass.new
      2.times { controller.run_callbacks(:process_action) { :ok } }

      expect(controller.breadcrumbs.names).to eq(['Home'])
    end
  end

  describe 'helper_method registration' do
    it 'registers breadcrumbs as a helper method when the host class supports it' do
      registered = []
      klass = Class.new(AbstractController::Base) do
        include AbstractController::Callbacks

        define_singleton_method(:helper_method) { |name| registered << name }
      end

      klass.include(PetitPoucet::Controller)

      expect(registered).to eq([:breadcrumbs])
    end

    it 'is a no-op on classes without helper_method (e.g., AbstractController::Base)' do
      klass = Class.new(AbstractController::Base) do
        include AbstractController::Callbacks
        include PetitPoucet::Controller
      end

      expect(klass.new.breadcrumbs).to be_a(PetitPoucet::Breadcrumbs)
    end
  end
end
