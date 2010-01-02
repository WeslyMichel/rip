require 'test/unit'
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'rip'
require 'fileutils'

class Rip::Test < Test::Unit::TestCase
  include FileUtils

  # Setup test/ripdir for testing as a valid rip directory.
  # Remove it after test runs.
  def setup
    @ripdir = File.expand_path(File.dirname(__FILE__) + "/ripdir")
    rm_rf @ripdir
    ENV['RIPDIR'] = @ripdir
    rip "setup"
  end

  def teardown
    rm_rf @ripdir
  end

  # Needed when subclassing Test::Unit::TestCase
  def test_ok
    assert true
  end

  def self.test(name, &block)
    define_method("test_#{name.gsub(/\W/, '_')}", &block) if block
  end

  # Asserts that `haystack` includes `needle`.
  def assert_includes(needle, haystack, message = nil)
    message = build_message(message, '<?> is not in <?>.', needle, haystack)
    assert_block message do
      haystack.include? needle
    end
  end

  # Asserts that `haystack` does not include `needle`.
  def assert_not_includes(needle, haystack, message = nil)
    message = build_message(message, '<?> is in <?>.', needle, haystack)
    assert_block message do
      !haystack.include? needle
    end
  end

  # Asserts that the last exited child process (probably `rip`) exited
  # successfully.
  def assert_exited_successfully(message = nil)
    actual = $?.exitstatus
    message = build_message(message, 'rip exited with <?>, not 0', actual)
    assert_block message do
      $?.success?
    end
  end

  # Asserts that the last exited child process (probably `rip`) did
  # not exit successfully.
  def assert_exited_with_error(message = nil)
    message = build_message(message, 'rip exited with 0, not > 0')
    assert_block message do
      !$?.success?
    end
  end

  # Shortcut for running the `rip` command in a subprocess. Returns
  # STDOUT as a string. Pass it what you would normally pass `rip` on
  # the command line, e.g.
  #
  # shell: rip create github
  #  test: rip("create github")
  #
  # If a block is given it will be run in the child process before
  # execution begins. You can use this to monkeypatch or fudge the
  # environment before running `rip`.
  def rip(subcommand, *args)
    parent_read, child_write = IO.pipe

    pid = fork do
      yield if block_given?
      $stdout.reopen(child_write)
      $stderr.reopen(child_write)
      ENV['PATH'] = "bin/:#{ENV['PATH']}"
      exec "rip-#{subcommand}", *args
    end

    # Wait for the process to exit so we can use $?
    # in our tests.
    Process.waitpid(pid)

    child_write.close
    out = parent_read.read

    # Set the PRINT env variable to see rip command output during
    # test execution.
    if ENV['PRINT'] && !out.empty?
      puts
      puts ['$ rip', subcommand, *args].join(' ')
      puts out
    end

    out
  end
end
