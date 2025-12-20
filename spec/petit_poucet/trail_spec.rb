# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PetitPoucet::Trail do
  subject(:trail) { described_class.new }

  shared_examples 'chainable method' do
    it 'returns self for chaining' do
      expect(result).to be(trail)
    end
  end

  describe '#initialize' do
    it 'creates an empty trail' do
      expect(trail).to be_empty
    end
  end

  describe '#add' do
    it 'adds a crumb at the end' do
      trail.add('Home', '/').add('Articles', '/articles')

      expect(trail.names).to eq(%w[Home Articles])
    end

    it 'allows nil path' do
      trail.add('Current Page')

      expect(trail.last.path).to be_nil
    end

    include_examples 'chainable method' do
      let(:result) { trail.add('Home', '/') }
    end
  end

  describe '#prepend' do
    it 'adds a crumb at the beginning' do
      trail.add('Articles', '/articles')
      trail.prepend('Home', '/')

      expect(trail.names).to eq(%w[Home Articles])
    end

    include_examples 'chainable method' do
      let(:result) { trail.prepend('Home', '/') }
    end
  end

  describe '#insert_after' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'inserts a crumb after the target' do
      trail.insert_after('Home', 'Dashboard', '/dashboard')

      expect(trail.names).to eq(%w[Home Dashboard Articles])
    end

    it 'is a no-op when target not found' do
      trail.insert_after('NonExistent', 'New', '/new')

      expect(trail.names).to eq(%w[Home Articles])
    end

    include_examples 'chainable method' do
      let(:result) { trail.insert_after('Home', 'Dashboard', '/dashboard') }
    end
  end

  describe '#insert_before' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'inserts a crumb before the target' do
      trail.insert_before('Articles', 'Dashboard', '/dashboard')

      expect(trail.names).to eq(%w[Home Dashboard Articles])
    end

    it 'is a no-op when target not found' do
      trail.insert_before('NonExistent', 'New', '/new')

      expect(trail.names).to eq(%w[Home Articles])
    end

    include_examples 'chainable method' do
      let(:result) { trail.insert_before('Articles', 'Dashboard', '/dashboard') }
    end
  end

  describe '#remove' do
    before do
      trail.add('Home', '/').add('Articles', '/articles').add('Show')
    end

    it 'removes a crumb by name' do
      trail.remove('Articles')

      expect(trail.names).to eq(%w[Home Show])
    end

    it 'is a no-op when name not found' do
      trail.remove('NonExistent')

      expect(trail.names).to eq(%w[Home Articles Show])
    end

    include_examples 'chainable method' do
      let(:result) { trail.remove('Articles') }
    end
  end

  describe '#clear' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'removes all crumbs' do
      trail.clear

      expect(trail).to be_empty
    end

    include_examples 'chainable method' do
      let(:result) { trail.clear }
    end
  end

  describe '#replace' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'replaces a crumb by name' do
      trail.replace('Articles', 'Blog', '/blog')

      expect(trail.names).to eq(%w[Home Blog])
      expect(trail.last.path).to eq('/blog')
    end

    it 'is a no-op when target not found' do
      trail.replace('NonExistent', 'New', '/new')

      expect(trail.names).to eq(%w[Home Articles])
    end

    include_examples 'chainable method' do
      let(:result) { trail.replace('Articles', 'Blog', '/blog') }
    end
  end

  describe '#include?' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'returns true when breadcrumb exists' do
      expect(trail.include?('Home')).to be true
      expect(trail.include?('Articles')).to be true
    end

    it 'returns false when breadcrumb does not exist' do
      expect(trail.include?('Admin')).to be false
    end
  end

  describe '#find' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'returns the crumb when found' do
      crumb = trail.find('Articles')

      expect(crumb).to be_a(PetitPoucet::Crumb)
      expect(crumb.name).to eq('Articles')
      expect(crumb.path).to eq('/articles')
    end

    it 'returns nil when not found' do
      expect(trail.find('Admin')).to be_nil
    end
  end

  describe 'Enumerable' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'iterates over crumbs with #each' do
      expect(trail.map(&:name)).to eq(%w[Home Articles])
    end

    it 'returns an enumerator when no block given' do
      expect(trail.each).to be_a(Enumerator)
    end

    it 'supports Enumerable methods like #select' do
      expect(trail.select { |c| c.name == 'Home' }.size).to eq(1)
    end
  end

  describe '#size' do
    it 'returns 0 for empty trail' do
      expect(trail.size).to eq(0)
    end

    it 'returns the number of crumbs' do
      trail.add('Home', '/').add('Articles', '/articles')

      expect(trail.size).to eq(2)
    end

    it 'has #length alias' do
      expect(trail.method(:length)).to eq(trail.method(:size))
    end
  end

  describe '#empty?' do
    it 'returns true for empty trail' do
      expect(trail).to be_empty
    end

    it 'returns false when trail has crumbs' do
      trail.add('Home', '/')

      expect(trail).not_to be_empty
    end
  end

  describe '#first / #last' do
    it 'returns nil for empty trail' do
      expect(trail.first).to be_nil
      expect(trail.last).to be_nil
    end

    it 'returns first and last crumbs' do
      trail.add('Home', '/').add('Articles', '/articles')

      expect(trail.first.name).to eq('Home')
      expect(trail.last.name).to eq('Articles')
    end
  end

  describe '#[]' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'returns crumb at index' do
      expect(trail[0].name).to eq('Home')
      expect(trail[1].name).to eq('Articles')
    end

    it 'returns nil for out of bounds' do
      expect(trail[99]).to be_nil
    end

    it 'supports negative indices' do
      expect(trail[-1].name).to eq('Articles')
    end
  end

  describe '#names' do
    it 'returns array of crumb names' do
      trail.add('Home', '/').add('Articles', '/articles')

      expect(trail.names).to eq(%w[Home Articles])
    end

    it 'returns empty array for empty trail' do
      expect(trail.names).to eq([])
    end
  end

  describe '#to_a' do
    before do
      trail.add('Home', '/').add('Articles', '/articles')
    end

    it 'returns an array of crumbs' do
      expect(trail.to_a).to all(be_a(PetitPoucet::Crumb))
      expect(trail.to_a.size).to eq(2)
    end

    it 'returns a copy (not the internal array)' do
      trail.to_a.clear

      expect(trail.size).to eq(2)
    end
  end

  describe '#inspect' do
    it 'returns a readable representation' do
      expect(trail.inspect).to eq('#<PetitPoucet::Trail []>')

      trail.add('Home', '/').add('Current')
      expect(trail.inspect).to eq('#<PetitPoucet::Trail ["Home"=>"/", "Current"=>nil]>')
    end
  end

  describe '#==' do
    it 'compares trails by content' do
      other = described_class.new
      trail.add('Home', '/')
      other.add('Home', '/')

      expect(trail).to eq(other)
    end
  end

  describe 'complex chaining' do
    it 'supports mixed operations' do
      trail
        .add('Home', '/')
        .add('Articles', '/articles')
        .prepend('Root', '/root')
        .insert_after('Home', 'Dashboard', '/dashboard')
        .remove('Articles')

      expect(trail.names).to eq(%w[Root Home Dashboard])
    end
  end
end
