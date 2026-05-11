# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'rails/generators'
require 'generators/petit_poucet/install/install_generator'

RSpec.describe PetitPoucet::Generators::InstallGenerator do
  let(:destination) { File.expand_path('../../tmp/install_generator_test', __dir__) }
  let(:partial_path) { File.join(destination, 'app/views/petit_poucet/_breadcrumbs.html.erb') }

  before do
    FileUtils.rm_rf(destination)
    FileUtils.mkdir_p(destination)
  end

  after { FileUtils.rm_rf(destination) }

  def run_generator(args = [])
    original = $stdout
    $stdout = StringIO.new
    described_class.start(args, destination_root: destination)
    $stdout.string
  ensure
    $stdout = original
  end

  it 'copies the breadcrumbs partial into app/views/petit_poucet' do
    run_generator

    expect(File).to exist(partial_path)
  end

  it 'copies a partial with ARIA-compliant markup' do
    run_generator

    expect(File.read(partial_path)).to include("aria-label=\"<%= t('petit_poucet.aria_label'")
  end

  it 'prints next-step instructions' do
    output = run_generator

    expect(output).to include('Petit Poucet installed')
    expect(output).to include('render "petit_poucet/breadcrumbs"')
    expect(output).to include('breadcrumbs "Articles"')
  end

  it 'mentions the theme in the output' do
    output = run_generator

    expect(output).to include('theme: default')
  end

  it 'the bundled default partial exists on disk' do
    default_partial = File.expand_path(
      '../../lib/petit_poucet/views/petit_poucet/_breadcrumbs.html.erb',
      __dir__
    )

    expect(File).to exist(default_partial)
  end

  context 'with --theme=tailwind' do
    it 'copies the Tailwind partial' do
      run_generator(['--theme=tailwind'])

      content = File.read(partial_path)
      expect(content).to include('hover:text-gray-700')
    end

    it 'mentions tailwind theme in the output' do
      output = run_generator(['--theme=tailwind'])

      expect(output).to include('theme: tailwind')
    end
  end

  context 'with --theme=bootstrap' do
    it 'copies the Bootstrap partial' do
      run_generator(['--theme=bootstrap'])

      content = File.read(partial_path)
      expect(content).to include('class="breadcrumb"')
    end
  end

  context 'with --theme=unknown' do
    around do |example|
      original = ENV.fetch('THOR_DEBUG', nil)
      ENV['THOR_DEBUG'] = '1'
      example.run
    ensure
      ENV['THOR_DEBUG'] = original
    end

    it 'raises a Thor::Error' do
      expect do
        run_generator(['--theme=unknown'])
      end.to raise_error(Thor::Error, /Unknown theme/)
    end
  end
end
