require 'fileutils'

module Rip
  def self.dir
    return @dir if @dir

    dir = ENV['RIPDIR'].to_s

    if dir.empty?
      abort "RIPDIR env variable not found. did you run setup.rb?"
    end

    dir = File.expand_path(dir)
    FileUtils.mkdir_p dir unless File.exists? dir
    @dir = dir
  end

  def self.dir=(dir)
    @dir = dir
  end
end

# load rip files

require 'rip/env'
require 'rip/memoize'
require 'rip/installer'
require 'rip/package_api'
require 'rip/package'
require 'rip/package_manager'
require 'rip/setup'
require 'rip/sh/git'
require 'rip/commands'

# load package types, (git, gem, etc)

Dir[File.dirname(__FILE__) + '/rip/packages/*_package.rb'].each do |file|
  require file
end
