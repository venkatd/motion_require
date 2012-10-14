require 'pathname'
require 'tsort'

module MotionRequire

  class DependencyHash < Hash
    include TSort

    alias tsort_each_node each_key

    def tsort_each_child(k)
      self[k].each { |p| yield p } if has_key?(k)
    end

  end

  class DependencyGraph

    def self.build(app)
      builder = new(app, app.files + app.spec_files, ['app', 'lib', 'vendor'])
      app.files = [kernel_require_path] + builder.files - app.spec_files
      #app.files_dependencies(builder.dependencies)
    end

    def initialize(app, start_files, load_paths)
      @app = app
      @start_files = start_files
      @load_paths = load_paths.map { |path| File.join(@app.project_dir, path) }

      @dependencies = DependencyHash.new []
      @files = []

      @resolved = false
    end

    def files
      rebuild
      @files
    end

    def dependencies
      rebuild
      @dependencies
    end

    private

    def self.kernel_require_path
      File.join(File.dirname(__FILE__), 'kernel_require.rb')
    end

    def rebuild
      return if @resolved

      unprocessed = Array.new @start_files

      while unprocessed.count > 0
        cur_file = unprocessed.pop
        @dependencies[cur_file] += dependencies_for_file(cur_file) unless @dependencies.include?(cur_file)

        @dependencies[cur_file].each do |dependency|
          @dependencies[dependency] = [] unless @dependencies.include?(dependency)
        end
      end

      @files = @dependencies.tsort
      @dependencies.delete_if { |_, v| v.empty? }

      @resolved = true
    end

    def dependencies_for_file(file_name)
      deps = []

      File.open(file_name, 'r') do |f|
        f.each_line do |line|
          if match = line.match(/^\s*require ([\"'])([^']+)\1\s*$/)
            deps << match[2]
          end
        end
      end

      deps.map { |file| find_file(file) }
    end

    def find_file(file)
      (@load_paths + $:).each do |path|
        file_name = File.join(path, file + '.rb')
        return file_name if File.exist?(file_name)
      end

      raise "Can't locate file #{file}"
    end

  end
end
