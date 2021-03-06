$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'appscale_tools'


require 'rubygems'
require 'flexmock/test_unit'


class TestAppScaleAddKeypair < Test::Unit::TestCase
  def setup
    # mock out stdout to prevent cluttering up our test output
    flexmock(Kernel).should_receive(:puts).and_return()

    # make the user tell us which shell calls are ok
    flexmock(CommonFunctions).should_receive(:shell).with("").and_return()

    # disable fileuilts commands unless the tests override it
    flexmock(FileUtils).should_receive(:cp).with("", "").and_return()

    @options_no_auto = {}
    @options_w_auto = {"auto" => "true"}
  end

  def test_not_having_ssh_copy_id_in_path
    commonfunctions = flexmock(CommonFunctions)
    commonfunctions.should_receive(:shell).with("which ssh-keygen").and_return("/usr/bin/ssh-keygen")
    commonfunctions.should_receive(:shell).with("which ssh-copy-id").and_return("")

    assert_raises(BadConfigurationException) {
      AppScaleTools.add_keypair(@options_no_auto)
    }
  end

  def test_not_having_expect_in_path
    commonfunctions = flexmock(CommonFunctions)
    commonfunctions.should_receive(:shell).with("which ssh-keygen").and_return("/usr/bin/ssh-keygen")
    commonfunctions.should_receive(:shell).with("which ssh-copy-id").and_return("/usr/bin/ssh-copy-id")
    commonfunctions.should_receive(:shell).with("which expect").and_return("")

    assert_raises(BadConfigurationException) {
      AppScaleTools.add_keypair(@options_w_auto)
    }

    # TODO(cgb) - add a test where auto isn't used - it shouldn't throw an error
  end

  def test_usage_is_up_to_date
    AppScaleTools::ADD_KEYPAIR_FLAGS.each { |flag|
      assert_equal(true, AppScaleTools::ADD_KEYPAIR_USAGE.include?("-#{flag}"),
        "No usage text for #{flag}.")
    } 
  end

  def test_adding_one_key_to_existing_deployment
    # suppose that we have all the right ssh commands installed
    commonfunctions = flexmock(CommonFunctions)
    commonfunctions.should_receive(:shell).with("which ssh-keygen").and_return("/usr/bin/ssh-keygen")
    commonfunctions.should_receive(:shell).with("which ssh-copy-id").and_return("/usr/bin/ssh-copy-id")

    # and suppose that ssh-copy-id execs ok
    key = File.expand_path("~/.appscale/appscale")
    commonfunctions.should_receive(:shell).
      with(/ssh-copy-id -i #{key} root@1.2.3.4/).and_return()

    # next, assume that we are able to copy over the ssh keys fine
    commonfunctions.should_receive(:shell).
      with(/scp -i #{key} #{key} root@1.2.3.4:.ssh\/id_[d|r]sa/).
      and_return()

    # and the same for the public key
    pub_key = "#{key}.pub"
    commonfunctions.should_receive(:shell).
      with(/scp -i #{key} #{pub_key} root@1.2.3.4:.ssh\/id_rsa.pub/).
      and_return()

    # finally, we copy the key to another file, so mock that out too
    backup_key = key + ".key"
    flexmock(FileUtils).should_receive(:cp).with(key, backup_key).and_return()

    one_node = {:appengine => '1.2.3.4'}
    options = {"ips" => one_node, "add_to_existing" => true}
    expected = {'success' => true}
    actual = AppScaleTools.add_keypair(options)
    assert_equal(expected, actual)
  end

  def test_adding_two_keys_to_existing_deployment
    # suppose that we have all the right ssh commands installed
    commonfunctions = flexmock(CommonFunctions)
    commonfunctions.should_receive(:shell).with("which ssh-keygen").and_return("/usr/bin/ssh-keygen")
    commonfunctions.should_receive(:shell).with("which ssh-copy-id").and_return("/usr/bin/ssh-copy-id")

    # and suppose that ssh-copy-id execs ok
    key = File.expand_path("~/.appscale/appscale")
    commonfunctions.should_receive(:shell).
      with(/ssh-copy-id -i #{key} root@1.2.3.[4|5]/).and_return()

    # next, assume that we are able to copy over the ssh keys fine
    commonfunctions.should_receive(:shell).
      with(/scp -i #{key} #{key} root@1.2.3.[4|5]:.ssh\/id_[d|r]sa/).
      and_return()

    # and the same for the public key
    pub_key = "#{key}.pub"
    commonfunctions.should_receive(:shell).
      with(/scp -i #{key} #{pub_key} root@1.2.3.[4|5]:.ssh\/id_rsa.pub/).
      and_return()

    # finally, we copy the key to another file, so mock that out too
    backup_key = key + ".key"
    flexmock(FileUtils).should_receive(:cp).with(key, backup_key).and_return()

    two_nodes = {:appengine => ['1.2.3.4'], :database => '1.2.3.5'}
    options = {"ips" => two_nodes, "add_to_existing" => true}
    expected = {'success' => true}
    actual = AppScaleTools.add_keypair(options)
    assert_equal(expected, actual)
  end
end
