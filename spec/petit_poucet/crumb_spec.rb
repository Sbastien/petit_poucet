# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PetitPoucet::Crumb do
  let(:context) do
    double('Controller',
           current_user: double(name: 'John'),
           article_path: '/articles/1',
           article_name: 'My Article')
  end

  describe '#resolve_name' do
    it 'returns string as-is' do
      expect(described_class.new('Home').resolve_name(context)).to eq('Home')
    end

    it 'evaluates proc in context' do
      crumb = described_class.new(-> { current_user.name })
      expect(crumb.resolve_name(context)).to eq('John')
    end

    it 'calls symbol as method on context' do
      expect(described_class.new(:article_name).resolve_name(context)).to eq('My Article')
    end

    it 'converts other types to string' do
      expect(described_class.new(123).resolve_name(context)).to eq('123')
    end

    it 'handles empty string' do
      expect(described_class.new('').resolve_name(context)).to eq('')
    end

    it 'handles html safe strings' do
      name = '<i class="fa fa-home"></i>Home'.html_safe
      expect(described_class.new(name).resolve_name(context)).to eq(name)
    end
  end

  describe '#resolve_path' do
    it 'returns nil when path is nil' do
      expect(described_class.new('Home', nil).resolve_path(context)).to be_nil
    end

    it 'returns string as-is' do
      expect(described_class.new('Home', '/').resolve_path(context)).to eq('/')
    end

    it 'evaluates proc in context' do
      crumb = described_class.new('Article', -> { article_path })
      expect(crumb.resolve_path(context)).to eq('/articles/1')
    end

    it 'calls symbol as method on context' do
      expect(described_class.new('Article', :article_path).resolve_path(context)).to eq('/articles/1')
    end

    it 'handles empty string path' do
      expect(described_class.new('Home', '').resolve_path(context)).to eq('')
    end
  end

  describe '#applies_to_action?' do
    it 'applies to any action without filters' do
      crumb = described_class.new('Home', '/')
      expect(crumb.applies_to_action?('index')).to be true
      expect(crumb.applies_to_action?('show')).to be true
    end

    it 'applies only to specified actions with only filter' do
      crumb = described_class.new('Edit', '/edit', only: %i[edit update])
      expect(crumb.applies_to_action?('edit')).to be true
      expect(crumb.applies_to_action?('show')).to be false
    end

    it 'handles single action in only filter' do
      crumb = described_class.new('New', '/new', only: :new)
      expect(crumb.applies_to_action?('new')).to be true
      expect(crumb.applies_to_action?('create')).to be false
    end

    it 'excludes specified actions with except filter' do
      crumb = described_class.new('List', '/list', except: :index)
      expect(crumb.applies_to_action?('index')).to be false
      expect(crumb.applies_to_action?('show')).to be true
    end

    it 'handles string action names in only filter' do
      crumb = described_class.new('Edit', '/edit', only: %w[edit update])
      expect(crumb.applies_to_action?('edit')).to be true
      expect(crumb.applies_to_action?('show')).to be false
    end

    it 'handles mixed symbol/string in except filter' do
      crumb = described_class.new('List', '/list', except: [:index, 'destroy'])
      expect(crumb.applies_to_action?('index')).to be false
      expect(crumb.applies_to_action?('destroy')).to be false
      expect(crumb.applies_to_action?('show')).to be true
    end

    it 'handles empty only array' do
      crumb = described_class.new('Never', '/never', only: [])
      expect(crumb.applies_to_action?('index')).to be false
    end

    it 'handles empty except array' do
      crumb = described_class.new('Always', '/always', except: [])
      expect(crumb.applies_to_action?('index')).to be true
    end
  end
end
