# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PetitPoucet::Crumb do
  describe '#initialize' do
    it 'stores name and path' do
      crumb = described_class.new('Home', '/')

      expect(crumb.name).to eq('Home')
      expect(crumb.path).to eq('/')
    end

    it 'allows nil path' do
      crumb = described_class.new('Current')

      expect(crumb.name).to eq('Current')
      expect(crumb.path).to be_nil
    end

    it 'freezes name and path strings' do
      crumb = described_class.new('Home', '/')

      expect(crumb.name).to be_frozen
      expect(crumb.path).to be_frozen
    end

    it 'converts name to string' do
      crumb = described_class.new(:home, '/home')

      expect(crumb.name).to eq('home')
    end

    it 'raises ArgumentError when name is nil' do
      expect { described_class.new(nil, '/') }.to raise_error(ArgumentError, /name cannot be nil or empty/)
    end

    it 'raises ArgumentError when name is empty string' do
      expect { described_class.new('', '/') }.to raise_error(ArgumentError, /name cannot be nil or empty/)
    end

    it 'raises ArgumentError when name is blank' do
      expect { described_class.new('   ', '/') }.to raise_error(ArgumentError, /name cannot be nil or empty/)
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      crumb = described_class.new('Home', '/')

      expect(crumb.to_h).to eq({ name: 'Home', path: '/' })
    end

    it 'includes nil path' do
      crumb = described_class.new('Current')

      expect(crumb.to_h).to eq({ name: 'Current', path: nil })
    end
  end

  describe '#==' do
    let(:crumb) { described_class.new('Home', '/') }

    it 'equals another crumb with same values' do
      other = described_class.new('Home', '/')

      expect(crumb).to eq(other)
    end

    it 'differs from crumb with different values' do
      expect(crumb).not_to eq(described_class.new('Other', '/'))
      expect(crumb).not_to eq(described_class.new('Home', '/other'))
    end

    it 'differs from other types' do
      expect(crumb).not_to eq({ name: 'Home', path: '/' })
      expect(crumb).not_to eq('Home')
      expect(crumb).not_to eq(nil)
    end
  end
end
