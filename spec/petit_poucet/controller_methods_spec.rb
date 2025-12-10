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

    it 'clears breadcrumbs only for specified actions with :only' do
      parent_class = Class.new(base_controller_class) { breadcrumb 'Home', '/' }
      child_class = Class.new(parent_class) do
        clear_breadcrumbs only: :edit
        breadcrumb 'Child', '/child'
      end

      controller = child_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(%w[Home Child])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Child'])
    end

    it 'clears breadcrumbs except for specified actions with :except' do
      parent_class = Class.new(base_controller_class) { breadcrumb 'Home', '/' }
      child_class = Class.new(parent_class) do
        clear_breadcrumbs except: :index
        breadcrumb 'Child', '/child'
      end

      controller = child_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(%w[Home Child])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Child'])
    end
  end

  describe '.breadcrumb_group' do
    it 'applies :only option to all breadcrumbs in block' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb_group only: %i[edit update] do
          breadcrumb 'Edit Section', '/edit-section'
          breadcrumb 'Form', '/form'
        end
      end

      controller = controller_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs).to be_empty

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Edit Section', 'Form'])
    end

    it 'applies :except option to all breadcrumbs in block' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb_group except: :index do
          breadcrumb 'Details', '/details'
          breadcrumb 'Info', '/info'
        end
      end

      controller = controller_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs).to be_empty

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'show'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(%w[Details Info])
    end

    it 'allows individual breadcrumbs to override group options' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb_group only: %i[edit update] do
          breadcrumb 'Common', '/common'
          breadcrumb 'Edit Only', '/edit-only', only: :edit
        end
      end

      controller = controller_class.new
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Common', 'Edit Only'])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'update'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Common'])
    end

    it 'can be nested and merges options' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb_group except: :index do
          breadcrumb 'Outer', '/outer'
          breadcrumb_group only: %i[edit update] do
            breadcrumb 'Inner', '/inner'
          end
        end
      end

      controller = controller_class.new
      controller.action_name = 'show'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Outer'])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(%w[Outer Inner])

      # Inner should still respect parent's except: :index
      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'index'
      expect(controller.breadcrumbs).to be_empty
    end

    it 'merges :only options with intersection' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb_group only: %i[edit update destroy] do
          breadcrumb 'Group', '/group'
          breadcrumb 'Edit Only', '/edit-only', only: %i[edit show]
        end
      end

      controller = controller_class.new
      controller.action_name = 'edit'
      # 'Edit Only' should appear: intersection of [edit, update, destroy] & [edit, show] = [edit]
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Group', 'Edit Only'])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'update'
      # 'Edit Only' should NOT appear: update is not in the intersection
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Group'])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'show'
      # Neither should appear: show is not in group's only
      expect(controller.breadcrumbs).to be_empty
    end

    it 'merges :except options with union' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb_group except: :index do
          breadcrumb 'Group', '/group'
          breadcrumb 'Not Destroy', '/not-destroy', except: :destroy
        end
      end

      controller = controller_class.new
      controller.action_name = 'show'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Group', 'Not Destroy'])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'index'
      # Both excluded by group's except: :index
      expect(controller.breadcrumbs).to be_empty

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'destroy'
      # 'Not Destroy' excluded by its own except: :destroy (union with :index)
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Group'])
    end

    it 'can be combined with regular breadcrumbs' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb 'Home', '/'
        breadcrumb_group only: :edit do
          breadcrumb 'Edit Section', '/edit-section'
        end
        breadcrumb 'Footer', '/footer'
      end

      controller = controller_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(%w[Home Footer])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Home', 'Edit Section', 'Footer'])
    end

    it 'supports clear_breadcrumbs inside group' do
      parent_class = Class.new(base_controller_class) { breadcrumb 'Home', '/' }
      child_class = Class.new(parent_class) do
        breadcrumb_group only: :edit do
          clear_breadcrumbs
          breadcrumb 'Edit Only', '/edit-only'
        end
      end

      controller = child_class.new
      controller.action_name = 'index'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Home'])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Edit Only'])
    end
  end

  describe 'real-world scenarios' do
    it 'handles typical CRUD controller setup' do
      controller_class = Class.new(base_controller_class) do
        breadcrumb 'Articles', '/articles'

        breadcrumb_group only: %i[show edit update destroy] do
          breadcrumb -> { @article&.title || 'Article' }, -> { "/articles/#{@article&.id}" }
        end

        breadcrumb_group only: %i[edit update] do
          breadcrumb 'Edit'
        end

        breadcrumb 'New Article', only: %i[new create]
      end

      controller = controller_class.new

      # Index
      controller.action_name = 'index'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Articles'])

      # Show
      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.instance_variable_set(:@article, double(title: 'My Post', id: 1))
      controller.action_name = 'show'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Articles', 'My Post'])

      # Edit
      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Articles', 'My Post', 'Edit'])

      # New
      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.instance_variable_set(:@article, nil)
      controller.action_name = 'new'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Articles', 'New Article'])
    end

    it 'handles admin namespace with cleared parent breadcrumbs' do
      app_controller = Class.new(base_controller_class) { breadcrumb 'Home', '/' }
      admin_controller = Class.new(app_controller) do
        clear_breadcrumbs
        breadcrumb 'Admin', '/admin'
      end
      admin_users_controller = Class.new(admin_controller) do
        breadcrumb 'Users', '/admin/users'
        breadcrumb_group only: %i[edit update] do
          breadcrumb 'Edit User'
        end
      end

      controller = admin_users_controller.new

      controller.action_name = 'index'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(%w[Admin Users])

      controller.instance_variable_set(:@breadcrumbs, nil)
      controller.action_name = 'edit'
      expect(controller.breadcrumbs.map { _1[:name] }).to eq(['Admin', 'Users', 'Edit User'])
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
