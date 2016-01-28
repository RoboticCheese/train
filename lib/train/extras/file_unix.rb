# encoding: utf-8
# author: Dominik Richter
# author: Christoph Hartmann

require 'shellwords'
require 'train/extras/stat'

module Train::Extras
  class UnixFile < FileCommon
    attr_reader :path
    def initialize(backend, path)
      @backend = backend
      @path = path
      @spath = Shellwords.escape(@path)
    end

    def content
      @content ||= case
                   when !exist?, directory?
                     nil
                   when size.nil?, size == 0
                     ''
                   else
                     @backend.run_command("cat #{@spath}").stdout || ''
                   end
    end

    def exist?
      @exist ||= (
        @backend.run_command("test -e #{@spath}")
                .exit_status == 0
      )
    end

    def link_target
      return @link_target if defined? @link_target
      return @link_target = nil if link_path.nil?
      @link_target = @backend.file(link_path)
    end

    def link_path
      return nil unless symlink?
      @link_path ||= (
        @backend.run_command("readlink #{@spath}").stdout.chomp
      )
    end

    def mounted
      @mounted ||= (
        @backend.run_command("mount | grep -- ' on #{@spath}'")
      )
    end

    %w{
      type mode owner group mtime size selinux_label
    }.each do |field|
      define_method field.to_sym do
        stat[field.to_sym]
      end
    end

    def product_version
      nil
    end

    def file_version
      nil
    end

    def stat
      return @stat if defined?(@stat)
      @stat = Train::Extras::Stat.stat(@spath, @backend)
    end
  end
end
