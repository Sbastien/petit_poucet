# frozen_string_literal: true

require 'spec_helper'
require 'petit_poucet/test_helpers'

RSpec.describe PetitPoucet::TestHelpers do
  include described_class

  let(:controller_class) do
    Class.new do
      include PetitPoucet::Controller
    end
  end

  let(:controller) { controller_class.new }

  before do
    controller.breadcrumbs.add('Home', '/')
    controller.breadcrumbs.add('Articles', '/articles')
  end

  describe '#have_breadcrumb' do
    it 'passes when breadcrumb exists' do
      expect(controller).to have_breadcrumb('Home')
      expect(controller).to have_breadcrumb('Articles')
    end

    it 'fails when breadcrumb does not exist' do
      expect(controller).not_to have_breadcrumb('Admin')
      expect(controller).not_to have_breadcrumb('Unknown')
    end

    describe 'failure messages' do
      let(:matcher) { have_breadcrumb('Missing') }

      before { matcher.matches?(controller) }

      it 'provides helpful failure message' do
        expect(matcher.failure_message).to include('Missing')
        expect(matcher.failure_message).to include('["Home", "Articles"]')
      end

      it 'provides helpful negated failure message' do
        matcher = have_breadcrumb('Home')
        matcher.matches?(controller)
        expect(matcher.failure_message_when_negated).to include('Home')
      end

      it 'has description' do
        expect(matcher.description).to eq('have breadcrumb "Missing"')
      end
    end
  end

  describe '#have_breadcrumbs' do
    it 'passes when breadcrumbs match exactly' do
      expect(controller).to have_breadcrumbs(%w[Home Articles])
    end

    it 'fails when order differs' do
      expect(controller).not_to have_breadcrumbs(%w[Articles Home])
    end

    it 'fails when missing breadcrumbs' do
      expect(controller).not_to have_breadcrumbs(['Home'])
    end

    it 'fails when extra breadcrumbs' do
      expect(controller).not_to have_breadcrumbs(%w[Home Articles Extra])
    end

    describe 'failure messages' do
      let(:matcher) { have_breadcrumbs(%w[Wrong Order]) }

      before { matcher.matches?(controller) }

      it 'provides helpful failure message' do
        expect(matcher.failure_message).to include('["Wrong", "Order"]')
        expect(matcher.failure_message).to include('["Home", "Articles"]')
      end

      it 'provides helpful negated failure message' do
        matcher = have_breadcrumbs(%w[Home Articles])
        matcher.matches?(controller)
        expect(matcher.failure_message_when_negated).to include('["Home", "Articles"]')
      end

      it 'has description' do
        expect(matcher.description).to eq('have breadcrumbs ["Wrong", "Order"]')
      end
    end
  end

  context 'with empty breadcrumbs' do
    let(:empty_controller) { controller_class.new }

    it 'have_breadcrumb fails' do
      expect(empty_controller).not_to have_breadcrumb('Any')
    end

    it 'have_breadcrumbs passes for empty array' do
      expect(empty_controller).to have_breadcrumbs([])
    end
  end

  describe 'Minitest assertions' do
    # Simulate Minitest's assert methods
    def assert(condition, message = nil)
      raise message || 'Assertion failed' unless condition
    end

    def assert_equal(expected, actual, message = nil)
      raise message || "Expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
    end

    def refute(condition, message = nil)
      raise message || 'Refutation failed' if condition
    end

    describe '#assert_breadcrumb' do
      it 'passes when breadcrumb exists' do
        expect { assert_breadcrumb('Home', controller) }.not_to raise_error
      end

      it 'fails when breadcrumb does not exist' do
        expect { assert_breadcrumb('Admin', controller) }.to raise_error(/Expected breadcrumbs to include/)
      end

      it 'uses @controller by default' do
        @controller = controller
        expect { assert_breadcrumb('Home') }.not_to raise_error
      end
    end

    describe '#assert_breadcrumbs' do
      it 'passes when breadcrumbs match exactly' do
        expect { assert_breadcrumbs(%w[Home Articles], controller) }.not_to raise_error
      end

      it 'fails when breadcrumbs do not match' do
        expect { assert_breadcrumbs(%w[Wrong], controller) }.to raise_error(/Expected breadcrumbs to be/)
      end

      it 'uses @controller by default' do
        @controller = controller
        expect { assert_breadcrumbs(%w[Home Articles]) }.not_to raise_error
      end
    end

    describe '#refute_breadcrumb' do
      it 'passes when breadcrumb does not exist' do
        expect { refute_breadcrumb('Admin', controller) }.not_to raise_error
      end

      it 'fails when breadcrumb exists' do
        expect { refute_breadcrumb('Home', controller) }.to raise_error(/Expected breadcrumbs not to include/)
      end

      it 'uses @controller by default' do
        @controller = controller
        expect { refute_breadcrumb('Admin') }.not_to raise_error
      end
    end

    describe '#refute_breadcrumbs' do
      it 'passes when breadcrumbs do not match' do
        expect { refute_breadcrumbs(%w[Wrong Order], controller) }.not_to raise_error
      end

      it 'fails when breadcrumbs match exactly' do
        expect { refute_breadcrumbs(%w[Home Articles], controller) }.to raise_error(/Expected breadcrumbs not to be/)
      end

      it 'uses @controller by default' do
        @controller = controller
        expect { refute_breadcrumbs(%w[Wrong]) }.not_to raise_error
      end
    end
  end
end
