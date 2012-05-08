require 'erb'
require 'rubygems/dependency_installer'

module Bundler
  class Installer < Environment
    class << self
      attr_accessor :post_install_messages
    end

    def self.install(root, definition, options = {})
      installer = new(root, definition)
      installer.run(options)
      installer
    end

    def run(options)
      # Create the BUNDLE_PATH directory
      begin
        Bundler.bundle_path.mkpath unless Bundler.bundle_path.exist?
      rescue Errno::EEXIST
        raise PathError, "Could not install to path `#{Bundler.settings[:path]}` " +
          "because of an invalid symlink. Remove the symlink so the directory can be created."
      end

      if Bundler.settings[:frozen]
        @definition.ensure_equivalent_gemfile_and_lockfile(options[:deployment])
      end

      if dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
        lock
        return
      end

      if Bundler.default_lockfile.exist? && !options["update"]
        begin
          tmpdef = Definition.build(Bundler.default_gemfile, Bundler.default_lockfile, nil)
          local = true unless tmpdef.new_platform? || tmpdef.missing_specs.any?
        rescue BundlerError
        end
      end

      # Since we are installing, we can resolve the definition
      # using remote specs
      unless local
        options["local"] ?
          @definition.resolve_with_cache! :
          @definition.resolve_remotely!
      end

      # Must install gems in the order that the resolver provides
      # as dependencies might actually affect the installation of
      # the gem.
      Installer.post_install_messages = {}
      specs.each do |spec|
        install_gem_from_spec(spec, options[:standalone])
      end

      lock
      generate_standalone(options[:standalone]) if options[:standalone]
    end

  private

    def install_gem_from_spec(spec, standalone = false)
      # Download the gem to get the spec, because some specs that are returned
      # by rubygems.org are broken and wrong.
      Bundler::Fetcher.fetch(spec) if spec.source.is_a?(Bundler::Source::Rubygems)

      # Fetch the build settings, if there are any
      settings = Bundler.settings["build.#{spec.name}"]
      Bundler.rubygems.with_build_args [settings] do
        spec.source.install(spec)
        Bundler.ui.debug "from #{spec.loaded_from} "
      end

      # newline comes after installing, some gems say "with native extensions"
      Bundler.ui.info ""
      if Bundler.settings[:bin]
        standalone ? generate_standalone_bundler_executable_stubs(spec) : generate_bundler_executable_stubs(spec)
      end

      FileUtils.rm_rf(Bundler.tmp)
    rescue Exception => e
      # install hook failed
      raise e if e.is_a?(Bundler::InstallHookError)

      # other failure, likely a native extension build failure
      Bundler.ui.info ""
      Bundler.ui.warn "#{e.class}: #{e.message}"
      msg = "An error occured while installing #{spec.name} (#{spec.version}),"
      msg << " and Bundler cannot continue.\nMake sure that `gem install"
      msg << " #{spec.name} -v '#{spec.version}'` succeeds before bundling."
      raise Bundler::InstallError, msg
    end

    def generate_bundler_executable_stubs(spec)
      bin_path = Bundler.bin_path
      template = File.read(File.expand_path('../templates/Executable', __FILE__))
      relative_gemfile_path = Bundler.default_gemfile.relative_path_from(bin_path)
      ruby_command = Thor::Util.ruby_command

      spec.executables.each do |executable|
        next if executable == "bundle"
        File.open "#{bin_path}/#{executable}", 'w', 0755 do |f|
          f.puts ERB.new(template, nil, '-').result(binding)
        end
      end
    end

    def generate_standalone_bundler_executable_stubs(spec)
      bin_path = Bundler.bin_path
      template = File.read(File.expand_path('../templates/Executable.standalone', __FILE__))
      ruby_command = Thor::Util.ruby_command

      spec.executables.each do |executable|
        next if executable == "bundle"
        standalone_path = Pathname(Bundler.settings[:path]).expand_path.relative_path_from(bin_path)
        executable_path = Pathname(spec.full_gem_path).join(spec.bindir, executable).relative_path_from(bin_path)
        File.open "#{bin_path}/#{executable}", 'w', 0755 do |f|
          f.puts ERB.new(template, nil, '-').result(binding)
        end
      end
    end

    def generate_standalone(groups)
      standalone_path = Bundler.settings[:path]
      bundler_path = File.join(standalone_path, "bundler")
      FileUtils.mkdir_p(bundler_path)

      paths = []

      if groups.empty?
        specs = Bundler.definition.requested_specs
      else
        specs = Bundler.definition.specs_for groups.map { |g| g.to_sym }
      end

      specs.each do |spec|
        next if spec.name == "bundler"

        spec.require_paths.each do |path|
          full_path = File.join(spec.full_gem_path, path)
          paths << Pathname.new(full_path).relative_path_from(Bundler.root.join(bundler_path))
        end
      end


      File.open File.join(bundler_path, "setup.rb"), "w" do |file|
        file.puts "path = File.expand_path('..', __FILE__)"
        paths.each do |path|
          file.puts %{$:.unshift File.expand_path("\#{path}/#{path}")}
        end
      end
    end
  end
end
