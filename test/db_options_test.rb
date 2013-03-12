require 'test/unit'
require File.expand_path("../../lib/leveldb", __FILE__)
require 'fileutils'
require 'snappy'

class DBOptionsTest < Test::Unit::TestCase
  def setup
    @path = File.expand_path(File.join('..', 'db_test.db'), __FILE__)
    @dbs = []
  end

  def teardown
    @dbs.each(&:close!)
    @dbs = []
    FileUtils.rm_rf @path
  end

  def assert_false x; assert !x end

  def test_create_if_missing_behavior
    assert_raises(LevelDB::Error) { LevelDB::DB.make(@path, {}) } # create if missing is false
    db = LevelDB::DB.make @path, :create_if_missing => true
    @dbs << db
    assert db.options.create_if_missing
    db.close!
    db2 = LevelDB::DB.make @path, {} # should work the second time
    @dbs << db2
    assert_false db2.options.create_if_missing
    db2.close!

    FileUtils.rm_rf @path
    assert_nothing_raised { @dbs << LevelDB::DB.new(@path) } # by default should set create_if_missing to true
  end

  def test_error_if_exists_behavior
    db = LevelDB::DB.make @path, :create_if_missing => true
    @dbs << db
    assert_false db.options.error_if_exists
    db.close

    assert_raises(LevelDB::Error) { @dbs << LevelDB::DB.make(@path, :create_if_missing => true, :error_if_exists => true) }
  end

  def test_paranoid_check_default
    db = LevelDB::DB.new @path
    @dbs << db
    assert_false db.options.paranoid_checks
  end

  def test_paranoid_check_on
    db = LevelDB::DB.new @path, :paranoid_checks => true
    @dbs << db
    assert db.options.paranoid_checks
  end

  def test_paranoid_check_off
    db = LevelDB::DB.new @path, :paranoid_checks => false
    @dbs << db
    assert_false db.options.paranoid_checks
  end

  def test_write_buffer_size_default
    db = LevelDB::DB.new @path
    @dbs << db
    assert_equal LevelDB::Options::DEFAULT_WRITE_BUFFER_SIZE, db.options.write_buffer_size
  end

  def test_write_buffer_size
    db = LevelDB::DB.new @path, :write_buffer_size => 10 * 1042
    @dbs << db
    assert_equal (10 * 1042), db.options.write_buffer_size
  end

  def test_write_buffer_size_invalid
    assert_raises(TypeError) { @dbs << LevelDB::DB.new(@path, :write_buffer_size => "1234") }
  end

  def test_max_open_files_default
    db = LevelDB::DB.new @path
    @dbs << db
    assert_equal LevelDB::Options::DEFAULT_MAX_OPEN_FILES, db.options.max_open_files
  end

  def test_max_open_files
    db = LevelDB::DB.new(@path, :max_open_files => 2000)
    @dbs << db
    assert_equal db.options.max_open_files, 2000
  end

  def test_max_open_files_invalid
    assert_raises(TypeError) { @dbs << LevelDB::DB.new(@path, :max_open_files => "2000") }
  end

  def test_cache_size_default
    db = LevelDB::DB.new @path
    @dbs << db
    assert_nil db.options.block_cache_size
  end

  def test_cache_size
    db = LevelDB::DB.new @path, :block_cache_size => 10 * 1024 * 1024
    @dbs << db
    assert_equal (10 * 1024 * 1024), db.options.block_cache_size
  end

  def test_cache_size_invalid
    assert_raises(TypeError) { @dbs << LevelDB::DB.new(@path, :block_cache_size => false) }
  end

  def test_block_size_default
    db = LevelDB::DB.new @path
    @dbs << db
    assert_equal LevelDB::Options::DEFAULT_BLOCK_SIZE, db.options.block_size
  end

  def test_block_size
    db = LevelDB::DB.new @path, :block_size => (2 * 1024)
    @dbs << db
    assert_equal (2 * 1024), db.options.block_size
  end

  def test_block_size_invalid
    assert_raises(TypeError) { LevelDB::DB.new @path, :block_size => true }
  end

  def test_block_restart_interval_default
    db = LevelDB::DB.new @path
    @dbs << db
    assert_equal LevelDB::Options::DEFAULT_BLOCK_RESTART_INTERVAL, db.options.block_restart_interval
  end

  def test_block_restart_interval
    db = LevelDB::DB.new @path, :block_restart_interval => 32
    @dbs << db
    assert_equal 32, db.options.block_restart_interval
  end

  def test_block_restart_interval_invalid
    assert_raises(TypeError) { @dbs << LevelDB::DB.new(@path, :block_restart_interval => "abc") }
  end

  def test_compression_default
    db = LevelDB::DB.new @path
    @dbs << db
    assert_equal LevelDB::Options::DEFAULT_COMPRESSION, db.options.compression
  end

  def test_compression
    db = LevelDB::DB.new @path, :compression => LevelDB::CompressionType::NoCompression
    @dbs << db
    assert_equal LevelDB::CompressionType::NoCompression, db.options.compression
  end

  def test_compression_invalid_type
    assert_raises(TypeError) { @dbs << LevelDB::DB.new(@path, :compression => "1234") }
    assert_raises(TypeError) { @dbs << LevelDB::DB.new(@path, :compression => 999) }
  end

  def test_filter_policy_default
    db = LevelDB::DB.new @path
    @dbs << db
    assert_equal nil, db.options.bloom_filter_policy
  end

  def test_filter_policy
    db = LevelDB::DB.new @path, :bloom_filter_policy => 10
    @dbs << db
    assert_equal 10, db.options.bloom_filter_policy
  end

  def test_filter_policy_invalid_type
    assert_raises(ArgumentError) { @dbs << LevelDB::DB.new(@path, :bloom_filter_policy => 0) }
    assert_raises(TypeError) { @dbs << LevelDB::DB.new(@path, :bloom_filter_policy => "1234") }
    assert_raises(TypeError) { @dbs << LevelDB::DB.new(@path, :bloom_filter_policy => Object.new) }
  end
end
