require 'yaml'

module Rip
  class Parser
    def self.parse(content, path = nil)
      new(content, path).parse
    end

    def initialize(content, path = nil)
      @content = content
      @path = File.dirname(path) if path
      @packages = []
      @last_package = nil

      @stack = []
      @indent = 0
    end

    def parse(content = @content)
      content.split("\n").each do |line|
        package = parse_package(line)
        @packages << package if package
      end

      @packages.to_yaml
    end

    def parse_dependency(line)
      indent = line.count('*')

      if indent > @indent
        @indent = indent
        @stack << @last_package
      elsif indent < @indent
        @indent = indent
        @stack.pop
      end

      target = @stack.last

      target[:dependencies] ||= []
      target[:dependencies] << parse_package(line.gsub('*', ''))
    end

    def parse_package(line)
      # Strip comments.
      line = line.sub(/#.*/, '').strip

      # Nada.
      return nil if line.empty?

      # This is a dependency.
      if line[0] == ?*
        parse_dependency(line)
        return nil
      end

      source, *rest = line.split(' ')

      if source =~ /\.rip$/
        if source.include?('/')
          file = source
        elsif @path
          file = File.join(@path, source)
        else
          file = source
        end

        parse File.read(file)
        return nil
      end

      package = {}
      package[:source] = source

      if rest.any? { |arg| arg =~ /^([a-z0-9](.+))/ }
        package[:version] = $1
      end

      if rest.any? { |arg| arg =~ /^@(.+)/ }
        package[:reported_version] = $1
      end

      if rest.any? { |arg| arg =~ /^=>(.+)/ }
        package[:name] = $1
      end

      if rest.any? { |arg| arg =~ /^\/(.+)/ }
        package[:path] = $1
      end

      @last_package = package
    end
  end
end
