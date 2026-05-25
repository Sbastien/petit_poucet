# frozen_string_literal: true

require 'spec_helper'
require 'petit_poucet/capybara_matchers'

RSpec.describe PetitPoucet::CapybaraMatchers do
  include described_class

  # Build a fake "page" object that responds to find_all and has? like Capybara
  let(:page) do
    html = <<~HTML
      <nav aria-label="Breadcrumb">
        <ol>
          <li><a href="/">Home</a></li>
          <li><a href="/articles">Articles</a></li>
          <li aria-current="page">My Article</li>
        </ol>
      </nav>
    HTML

    fake = Object.new
    fake.define_singleton_method(:html) { html }
    fake
  end

  describe '#have_breadcrumb_text' do
    it 'passes when the breadcrumb text exists in the rendered nav' do
      expect(page).to have_breadcrumb_text('Articles')
    end

    it 'matches the current (last) breadcrumb' do
      expect(page).to have_breadcrumb_text('My Article')
    end

    it 'fails when the text is not in any breadcrumb' do
      expect(page).not_to have_breadcrumb_text('Admin')
    end

    it 'does not match text outside the breadcrumb nav' do
      page.define_singleton_method(:html) do
        '<p>Articles</p><nav aria-label="Breadcrumb"><ol><li>Home</li></ol></nav>'
      end

      expect(page).not_to have_breadcrumb_text('Articles')
    end

    it 'has a sensible failure message' do
      matcher = have_breadcrumb_text('Missing')
      matcher.matches?(page)

      expect(matcher.failure_message).to include('Missing')
      expect(matcher.failure_message).to include('Home')
    end

    it 'has a description' do
      expect(have_breadcrumb_text('Articles').description).to eq('have breadcrumb text "Articles"')
    end

    it 'has a sensible negated failure message' do
      matcher = have_breadcrumb_text('Home')
      matcher.matches?(page)

      expect(matcher.failure_message_when_negated).to include('Home')
      expect(matcher.failure_message_when_negated).to include('not to be present')
    end
  end

  describe '#have_breadcrumb_list' do
    it 'passes when the list matches exactly' do
      expect(page).to have_breadcrumb_list(['Home', 'Articles', 'My Article'])
    end

    it 'fails when order differs' do
      expect(page).not_to have_breadcrumb_list(['Articles', 'Home', 'My Article'])
    end

    it 'fails when entries are missing' do
      expect(page).not_to have_breadcrumb_list(%w[Home Articles])
    end

    it 'fails when there is no breadcrumb nav at all' do
      page.define_singleton_method(:html) { '<p>nothing</p>' }

      expect(page).not_to have_breadcrumb_list(['Home'])
    end

    it 'has a sensible failure message' do
      matcher = have_breadcrumb_list(%w[Wrong Order])
      matcher.matches?(page)

      expect(matcher.failure_message).to include('Wrong')
      expect(matcher.failure_message).to include('Home')
    end

    it 'has a description' do
      expect(have_breadcrumb_list(%w[Home Articles]).description)
        .to eq('have breadcrumb list ["Home", "Articles"]')
    end

    it 'has a sensible negated failure message' do
      matcher = have_breadcrumb_list(['Home', 'Articles', 'My Article'])
      matcher.matches?(page)

      expect(matcher.failure_message_when_negated).to include('Home')
      expect(matcher.failure_message_when_negated).to include('not to match')
    end
  end

  describe 'Extraction' do
    describe '.breadcrumb_texts' do
      it 'returns empty array when HTML is unparseable' do
        texts = PetitPoucet::CapybaraMatchers::Extraction.breadcrumb_texts('<<invalid&xml')
        expect(texts).to eq([])
      end

      it 'ignores non-element, non-text nodes (e.g. XML comments) inside li' do
        html = <<~HTML
          <nav aria-label="Breadcrumb">
            <ol>
              <li><!-- comment -->Home</li>
            </ol>
          </nav>
        HTML

        texts = PetitPoucet::CapybaraMatchers::Extraction.breadcrumb_texts(html)
        expect(texts).to eq(['Home'])
      end
    end
  end
end
