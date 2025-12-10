# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PetitPoucet::BreadcrumbGroupBuilder do
  let(:controller_class) do
    Class.new do
      include PetitPoucet::ControllerMethods
    end
  end

  describe '#breadcrumb' do
    it 'adds breadcrumb with group options' do
      described_class.new(controller_class, only: :edit).instance_eval do
        breadcrumb 'Edit', '/edit'
      end

      crumb = controller_class._breadcrumb_definitions.first
      expect(crumb.name).to eq('Edit')
      expect(crumb.applies_to_action?('edit')).to be true
      expect(crumb.applies_to_action?('index')).to be false
    end

    it 'merges breadcrumb options with group options' do
      described_class.new(controller_class, only: %i[edit update]).instance_eval do
        breadcrumb 'Edit Only', '/edit', only: :edit
      end

      crumb = controller_class._breadcrumb_definitions.first
      expect(crumb.applies_to_action?('edit')).to be true
      expect(crumb.applies_to_action?('update')).to be false
    end
  end

  describe '#breadcrumb_group' do
    it 'supports nesting with merged options' do
      described_class.new(controller_class, except: :index).instance_eval do
        breadcrumb_group only: %i[edit update] do
          breadcrumb 'Nested', '/nested'
        end
      end

      crumb = controller_class._breadcrumb_definitions.first
      expect(crumb.applies_to_action?('edit')).to be true
      expect(crumb.applies_to_action?('index')).to be false
      expect(crumb.applies_to_action?('show')).to be false
    end
  end

  describe '#clear_breadcrumbs' do
    it 'adds clear crumb with group options' do
      controller_class.breadcrumb 'Home', '/'

      described_class.new(controller_class, only: :edit).instance_eval do
        clear_breadcrumbs
      end

      clear_crumb = controller_class._breadcrumb_definitions.last
      expect(clear_crumb.clear?).to be true
      expect(clear_crumb.applies_to_action?('edit')).to be true
      expect(clear_crumb.applies_to_action?('index')).to be false
    end

    it 'merges clear options with group options' do
      controller_class.breadcrumb 'Home', '/'

      described_class.new(controller_class, except: :index).instance_eval do
        clear_breadcrumbs except: :show
      end

      clear_crumb = controller_class._breadcrumb_definitions.last
      expect(clear_crumb.applies_to_action?('edit')).to be true
      expect(clear_crumb.applies_to_action?('index')).to be false
      expect(clear_crumb.applies_to_action?('show')).to be false
    end
  end

  describe 'thread safety' do
    it 'does not share state between builders' do
      builder1 = described_class.new(controller_class, only: :edit)
      builder2 = described_class.new(controller_class, only: :show)

      builder1.breadcrumb('Edit', '/edit')
      builder2.breadcrumb('Show', '/show')

      crumbs = controller_class._breadcrumb_definitions
      expect(crumbs[0].applies_to_action?('edit')).to be true
      expect(crumbs[0].applies_to_action?('show')).to be false
      expect(crumbs[1].applies_to_action?('show')).to be true
      expect(crumbs[1].applies_to_action?('edit')).to be false
    end
  end

  describe 'edge cases' do
    it 'handles empty group' do
      described_class.new(controller_class, only: :edit).instance_eval do
        # Empty block
      end

      expect(controller_class._breadcrumb_definitions).to be_empty
    end

    it 'handles group with no options' do
      described_class.new(controller_class, {}).instance_eval do
        breadcrumb 'Always', '/always'
      end

      crumb = controller_class._breadcrumb_definitions.first
      expect(crumb.applies_to_action?('index')).to be true
      expect(crumb.applies_to_action?('edit')).to be true
    end

    it 'handles deeply nested groups' do
      described_class.new(controller_class, only: %i[edit update destroy]).instance_eval do
        breadcrumb_group only: %i[edit update] do
          breadcrumb_group only: :edit do
            breadcrumb 'Deep', '/deep'
          end
        end
      end

      crumb = controller_class._breadcrumb_definitions.first
      expect(crumb.applies_to_action?('edit')).to be true
      expect(crumb.applies_to_action?('update')).to be false
      expect(crumb.applies_to_action?('destroy')).to be false
    end

    it 'handles mixed only and except in nested groups' do
      described_class.new(controller_class, except: :index).instance_eval do
        breadcrumb_group only: %i[show edit update] do
          breadcrumb 'Mixed', '/mixed'
        end
      end

      crumb = controller_class._breadcrumb_definitions.first
      expect(crumb.applies_to_action?('show')).to be true
      expect(crumb.applies_to_action?('edit')).to be true
      expect(crumb.applies_to_action?('index')).to be false
      expect(crumb.applies_to_action?('destroy')).to be false
    end
  end
end
