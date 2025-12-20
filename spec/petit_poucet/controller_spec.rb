# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PetitPoucet::Controller do
  let(:base_controller_class) do
    Class.new do
      include PetitPoucet::Controller

      attr_accessor :action_name

      def initialize
        @action_name = 'index'
      end

      def root_path
        '/'
      end

      def articles_path
        '/articles'
      end

      def article_path(article)
        "/articles/#{article.id}"
      end
    end
  end

  describe '.breadcrumbs (class method)' do
    it 'registers a block for building breadcrumbs' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
        end
      end

      expect(controller_class._breadcrumb_blocks.size).to eq(1)
    end

    it 'inherits blocks from parent without modifying it' do
      parent_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
        end
      end

      child_class = Class.new(parent_class) do
        breadcrumbs do |trail|
          trail.add 'Articles', '/articles'
        end
      end

      expect(parent_class._breadcrumb_blocks.size).to eq(1)
      expect(child_class._breadcrumb_blocks.size).to eq(2)
    end

    it 'allows multiple blocks in same class' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
        end

        breadcrumbs do |trail|
          trail.add 'Section', '/section'
        end
      end

      expect(controller_class._breadcrumb_blocks.size).to eq(2)
    end

    it 'ignores calls without a block' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
        end

        breadcrumbs # no block - should be ignored
      end

      expect(controller_class._breadcrumb_blocks.size).to eq(1)
    end

    describe 'only: option' do
      it 'only runs block for specified actions' do
        controller_class = Class.new(base_controller_class) do
          breadcrumbs do |trail|
            trail.add 'Home', '/'
          end

          breadcrumbs only: %i[show edit] do |trail|
            trail.add 'Details'
          end
        end

        # index - should not have Details
        controller = controller_class.new
        controller.action_name = 'index'
        expect(controller.breadcrumbs.names).to eq(['Home'])

        # show - should have Details
        controller = controller_class.new
        controller.action_name = 'show'
        expect(controller.breadcrumbs.names).to eq(%w[Home Details])

        # edit - should have Details
        controller = controller_class.new
        controller.action_name = 'edit'
        expect(controller.breadcrumbs.names).to eq(%w[Home Details])
      end

      it 'accepts a single symbol' do
        controller_class = Class.new(base_controller_class) do
          breadcrumbs only: :show do |trail|
            trail.add 'Show Only'
          end
        end

        controller = controller_class.new
        controller.action_name = 'show'
        expect(controller.breadcrumbs.names).to eq(['Show Only'])

        controller = controller_class.new
        controller.action_name = 'index'
        expect(controller.breadcrumbs.names).to eq([])
      end
    end

    describe 'except: option' do
      it 'runs block for all actions except specified ones' do
        controller_class = Class.new(base_controller_class) do
          breadcrumbs except: :index do |trail|
            trail.add 'Not Index'
          end
        end

        # index - should be empty
        controller = controller_class.new
        controller.action_name = 'index'
        expect(controller.breadcrumbs.names).to eq([])

        # show - should have the crumb
        controller = controller_class.new
        controller.action_name = 'show'
        expect(controller.breadcrumbs.names).to eq(['Not Index'])
      end

      it 'accepts an array' do
        controller_class = Class.new(base_controller_class) do
          breadcrumbs except: %i[index new create] do |trail|
            trail.add 'Existing Record'
          end
        end

        controller = controller_class.new
        controller.action_name = 'index'
        expect(controller.breadcrumbs.names).to eq([])

        controller = controller_class.new
        controller.action_name = 'show'
        expect(controller.breadcrumbs.names).to eq(['Existing Record'])

        controller = controller_class.new
        controller.action_name = 'edit'
        expect(controller.breadcrumbs.names).to eq(['Existing Record'])
      end
    end

    describe 'combining only/except with inheritance' do
      it 'works with inherited blocks' do
        parent_class = Class.new(base_controller_class) do
          breadcrumbs do |trail|
            trail.add 'Home', '/'
          end
        end

        child_class = Class.new(parent_class) do
          breadcrumbs only: :edit do |trail|
            trail.add 'Edit'
          end
        end

        controller = child_class.new
        controller.action_name = 'index'
        expect(controller.breadcrumbs.names).to eq(['Home'])

        controller = child_class.new
        controller.action_name = 'edit'
        expect(controller.breadcrumbs.names).to eq(%w[Home Edit])
      end
    end
  end

  describe '.clear_breadcrumbs' do
    it 'clears inherited breadcrumb blocks' do
      parent_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
        end
      end

      child_class = Class.new(parent_class) do
        clear_breadcrumbs
        breadcrumbs do |trail|
          trail.add 'Admin', '/admin'
        end
      end

      expect(child_class._breadcrumb_blocks.size).to eq(1)
    end
  end

  describe '#breadcrumbs (instance method)' do
    it 'returns a Trail object' do
      controller = base_controller_class.new

      expect(controller.breadcrumbs).to be_a(PetitPoucet::Trail)
    end

    it 'evaluates blocks in controller context' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', root_path
        end
      end

      controller = controller_class.new

      expect(controller.breadcrumbs.first.path).to eq('/')
    end

    it 'evaluates blocks lazily on first access' do
      call_count = 0

      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          call_count += 1
          trail.add 'Home', '/'
        end
      end

      controller = controller_class.new
      expect(call_count).to eq(0)

      controller.breadcrumbs
      expect(call_count).to eq(1)

      controller.breadcrumbs
      expect(call_count).to eq(1)
    end

    it 'has access to instance variables' do
      controller_class = Class.new(base_controller_class) do
        attr_accessor :article

        breadcrumbs do |trail|
          trail.add 'Home', '/'
          trail.add @article.title if @article
        end
      end

      controller = controller_class.new
      controller.article = double(title: 'My Article', id: 1)

      expect(controller.breadcrumbs.names).to eq(['Home', 'My Article'])
    end

    it 'can use conditional logic based on action' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
          trail.add 'Edit' if action_name == 'edit'
        end
      end

      controller = controller_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs.names).to eq(['Home'])

      controller.instance_variable_set(:@_trail, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.names).to eq(%w[Home Edit])
    end

    it 'supports next to skip conditionally' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          next if action_name == 'index'

          trail.add 'Details', '/details'
        end
      end

      controller = controller_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs).to be_empty

      controller.instance_variable_set(:@_trail, nil)
      controller.action_name = 'show'
      expect(controller.breadcrumbs.names).to eq(['Details'])
    end

    it 'executes blocks in definition order' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'First', '/first'
        end

        breadcrumbs do |trail|
          trail.add 'Second', '/second'
        end
      end

      expect(controller_class.new.breadcrumbs.names).to eq(%w[First Second])
    end

    it 'is memoized' do
      controller = base_controller_class.new

      expect(controller.breadcrumbs).to be(controller.breadcrumbs)
    end
  end

  describe 'trail manipulation in actions' do
    it 'allows adding breadcrumbs in actions' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
        end
      end

      controller = controller_class.new
      controller.breadcrumbs.add 'Dynamic', '/dynamic'

      expect(controller.breadcrumbs.names).to eq(%w[Home Dynamic])
    end

    it 'allows clearing in actions' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
        end
      end

      controller = controller_class.new
      controller.breadcrumbs.clear
      controller.breadcrumbs.add 'Fresh', '/fresh'

      expect(controller.breadcrumbs.names).to eq(['Fresh'])
    end

    it 'allows prepending in actions' do
      controller_class = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Content', '/content'
        end
      end

      controller = controller_class.new
      controller.breadcrumbs.prepend 'Admin', '/admin'

      expect(controller.breadcrumbs.names).to eq(%w[Admin Content])
    end

    it 'allows block syntax in actions' do
      controller = base_controller_class.new

      controller.breadcrumbs do |trail|
        trail.add 'First', '/first'
        trail.add 'Second', '/second'
      end

      expect(controller.breadcrumbs.names).to eq(%w[First Second])
    end

    it 'allows mixing block and direct syntax in actions' do
      controller = base_controller_class.new

      controller.breadcrumbs.add 'Direct', '/direct'
      controller.breadcrumbs do |trail|
        trail.add 'Block', '/block'
      end
      controller.breadcrumbs.add 'Direct Again', '/direct-again'

      expect(controller.breadcrumbs.names).to eq(['Direct', 'Block', 'Direct Again'])
    end
  end

  describe 'real-world scenarios' do
    it 'handles typical CRUD controller setup' do
      controller_class = Class.new(base_controller_class) do
        attr_accessor :article

        breadcrumbs do |trail|
          trail.add 'Articles', articles_path

          if @article
            trail.add @article.title, article_path(@article)
            trail.add 'Edit' if action_name.in?(%w[edit update])
          end

          trail.add 'New Article' if action_name.in?(%w[new create])
        end
      end

      # Index
      controller = controller_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs.names).to eq(['Articles'])

      # Show
      controller = controller_class.new
      controller.action_name = 'show'
      controller.article = double(title: 'My Post', id: 1)
      expect(controller.breadcrumbs.names).to eq(['Articles', 'My Post'])

      # Edit
      controller = controller_class.new
      controller.action_name = 'edit'
      controller.article = double(title: 'My Post', id: 1)
      expect(controller.breadcrumbs.names).to eq(['Articles', 'My Post', 'Edit'])

      # New
      controller = controller_class.new
      controller.action_name = 'new'
      expect(controller.breadcrumbs.names).to eq(['Articles', 'New Article'])
    end

    it 'handles admin namespace with cleared parent breadcrumbs' do
      app_controller = Class.new(base_controller_class) do
        breadcrumbs do |trail|
          trail.add 'Home', '/'
        end
      end

      admin_controller = Class.new(app_controller) do
        clear_breadcrumbs
        breadcrumbs do |trail|
          trail.add 'Admin', '/admin'
        end
      end

      admin_users_controller = Class.new(admin_controller) do
        breadcrumbs do |trail|
          trail.add 'Users', '/admin/users'
          trail.add 'Edit User' if action_name == 'edit'
        end
      end

      # Index
      controller = admin_users_controller.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs.names).to eq(%w[Admin Users])

      # Edit
      controller = admin_users_controller.new
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.names).to eq(['Admin', 'Users', 'Edit User'])
    end
  end
end
