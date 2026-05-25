# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PetitPoucet::Breadcrumbs do
  subject(:crumbs) { described_class.new }

  describe 'fluent API' do
    it 'returns self from every mutating method' do
      crumbs.add('Home', '/')

      expect(crumbs.add('A', '/a')).to be(crumbs)
      expect(crumbs.prepend('B', '/b')).to be(crumbs)
      expect(crumbs.insert_after('A', 'C', '/c')).to be(crumbs)
      expect(crumbs.insert_before('A', 'D', '/d')).to be(crumbs)
      expect(crumbs.replace('A', 'E', '/e')).to be(crumbs)
      expect(crumbs.remove('E')).to be(crumbs)
      expect(crumbs.clear).to be(crumbs)
    end
  end

  describe '#add' do
    it 'adds a crumb at the end' do
      crumbs.add('Home', '/').add('Articles', '/articles')

      expect(crumbs.names).to eq(%w[Home Articles])
    end

    it 'allows nil path' do
      crumbs.add('Current Page')

      expect(crumbs[-1].path).to be_nil
    end
  end

  describe '#prepend' do
    it 'adds a crumb at the beginning' do
      crumbs.add('Articles', '/articles')
      crumbs.prepend('Home', '/')

      expect(crumbs.names).to eq(%w[Home Articles])
    end
  end

  describe '#insert_after' do
    before { crumbs.add('Home', '/').add('Articles', '/articles') }

    it 'inserts a crumb after the target' do
      crumbs.insert_after('Home', 'Dashboard', '/dashboard')

      expect(crumbs.names).to eq(%w[Home Dashboard Articles])
    end

    it 'is a no-op when target not found' do
      crumbs.insert_after('NonExistent', 'New', '/new')

      expect(crumbs.names).to eq(%w[Home Articles])
    end

    it 'inserts after the first match when target appears twice' do
      crumbs.add('Home', '/again')
      crumbs.insert_after('Home', 'X', '/x')

      expect(crumbs.names).to eq(%w[Home X Articles Home])
    end
  end

  describe '#insert_before' do
    before { crumbs.add('Home', '/').add('Articles', '/articles') }

    it 'inserts a crumb before the target' do
      crumbs.insert_before('Articles', 'Dashboard', '/dashboard')

      expect(crumbs.names).to eq(%w[Home Dashboard Articles])
    end

    it 'is a no-op when target not found' do
      crumbs.insert_before('NonExistent', 'New', '/new')

      expect(crumbs.names).to eq(%w[Home Articles])
    end

    it 'inserts before the first match when target appears twice' do
      crumbs.add('Articles', '/again')
      crumbs.insert_before('Articles', 'X', '/x')

      expect(crumbs.names).to eq(%w[Home X Articles Articles])
    end
  end

  describe '#remove' do
    before { crumbs.add('Home', '/').add('Articles', '/articles').add('Show') }

    it 'removes a crumb by name' do
      crumbs.remove('Articles')

      expect(crumbs.names).to eq(%w[Home Show])
    end

    it 'is a no-op when name not found' do
      crumbs.remove('NonExistent')

      expect(crumbs.names).to eq(%w[Home Articles Show])
    end

    it 'removes every crumb matching the name when there are duplicates' do
      crumbs.add('Articles', '/again')
      crumbs.remove('Articles')

      expect(crumbs.names).to eq(%w[Home Show])
    end
  end

  describe '#clear' do
    it 'removes all crumbs' do
      crumbs.add('Home', '/').add('Articles', '/articles').clear

      expect(crumbs).to be_empty
    end
  end

  describe '#replace' do
    before { crumbs.add('Home', '/').add('Articles', '/articles') }

    it 'replaces a crumb by name' do
      crumbs.replace('Articles', 'Blog', '/blog')

      expect(crumbs.names).to eq(%w[Home Blog])
      expect(crumbs[-1].path).to eq('/blog')
    end

    it 'is a no-op when target not found' do
      crumbs.replace('NonExistent', 'New', '/new')

      expect(crumbs.names).to eq(%w[Home Articles])
    end

    it 'replaces only the first match when target appears twice' do
      crumbs.add('Articles', '/again')
      crumbs.replace('Articles', 'Blog', '/blog')

      expect(crumbs.names).to eq(%w[Home Blog Articles])
    end
  end

  describe '#exists?' do
    before { crumbs.add('Home', '/').add('Articles', '/articles') }

    it 'returns true when breadcrumb exists' do
      expect(crumbs.exists?('Home')).to be true
    end

    it 'returns false when breadcrumb does not exist' do
      expect(crumbs.exists?('Admin')).to be false
    end
  end

  describe '#find_by_name' do
    before { crumbs.add('Home', '/').add('Articles', '/articles') }

    it 'returns the crumb when found' do
      crumb = crumbs.find_by_name('Articles')

      expect(crumb.name).to eq('Articles')
      expect(crumb.path).to eq('/articles')
    end

    it 'returns nil when not found' do
      expect(crumbs.find_by_name('Admin')).to be_nil
    end

    it 'returns the first match when there are duplicates' do
      crumbs.add('Articles', '/different')

      expect(crumbs.find_by_name('Articles').path).to eq('/articles')
    end
  end

  describe 'Enumerable' do
    before { crumbs.add('Home', '/').add('Articles', '/articles') }

    it 'iterates with #each' do
      expect(crumbs.map(&:name)).to eq(%w[Home Articles])
    end

    it 'returns an enumerator when no block given' do
      expect(crumbs.each).to be_a(Enumerator)
    end

    it 'supports Enumerable methods like #select' do
      expect(crumbs.select { |c| c.name == 'Home' }.size).to eq(1)
    end
  end

  describe '#size' do
    it 'returns the number of crumbs' do
      crumbs.add('Home', '/').add('Articles', '/articles')

      expect(crumbs.size).to eq(2)
    end
  end

  describe '#empty?' do
    it 'returns true for empty crumbs' do
      expect(crumbs).to be_empty
    end

    it 'returns false when crumbs has crumbs' do
      crumbs.add('Home', '/')

      expect(crumbs).not_to be_empty
    end
  end

  describe '#last' do
    it 'returns nil when empty' do
      expect(crumbs.last).to be_nil
    end

    it 'returns the last crumb' do
      crumbs.add('Home', '/').add('Articles', '/articles')

      expect(crumbs.last.name).to eq('Articles')
    end

    it 'returns the last n crumbs as an Array when count given' do
      crumbs.add('Home', '/').add('Articles', '/articles').add('Show')

      result = crumbs.last(2)
      expect(result).to be_a(Array)
      expect(result.map(&:name)).to eq(%w[Articles Show])
    end
  end

  describe '#[]' do
    before { crumbs.add('Home', '/').add('Articles', '/articles') }

    it 'returns crumb at index' do
      expect(crumbs[0].name).to eq('Home')
    end

    it 'returns nil for out of bounds' do
      expect(crumbs[99]).to be_nil
    end

    it 'supports negative indices' do
      expect(crumbs[-1].name).to eq('Articles')
    end
  end

  describe '#names' do
    it 'returns array of crumb names' do
      crumbs.add('Home', '/').add('Articles', '/articles')

      expect(crumbs.names).to eq(%w[Home Articles])
    end
  end

  describe '#to_a' do
    before { crumbs.add('Home', '/').add('Articles', '/articles') }

    it 'returns an array of crumbs' do
      expect(crumbs.to_a).to all(be_a(PetitPoucet::Breadcrumb))
    end

    it 'returns a copy, not the internal array' do
      crumbs.to_a.clear

      expect(crumbs.size).to eq(2)
    end
  end

  describe '#inspect' do
    it 'returns a readable representation' do
      expect(crumbs.inspect).to eq('#<PetitPoucet::Breadcrumbs []>')

      crumbs.add('Home', '/').add('Current')
      expect(crumbs.inspect).to eq('#<PetitPoucet::Breadcrumbs ["Home"=>"/", "Current"=>nil]>')
    end
  end

  describe '#==' do
    it 'is true when both collections have the same crumbs in the same order' do
      other = described_class.new.add('Home', '/')
      crumbs.add('Home', '/')

      expect(crumbs).to eq(other)
    end

    it 'is false when crumbs differ' do
      other = described_class.new.add('Home', '/other')
      crumbs.add('Home', '/')

      expect(crumbs).not_to eq(other)
    end

    it 'is false when compared to a non-Breadcrumbs object' do
      crumbs.add('Home', '/')

      expect(crumbs).not_to eq([PetitPoucet::Breadcrumb.new('Home', '/')])
      expect(crumbs).not_to eq(nil)
    end
  end

  describe 'complex chaining' do
    it 'supports mixed operations' do
      crumbs
        .add('Home', '/')
        .add('Articles', '/articles')
        .prepend('Root', '/root')
        .insert_after('Home', 'Dashboard', '/dashboard')
        .remove('Articles')

      expect(crumbs.names).to eq(%w[Root Home Dashboard])
    end
  end
end
