require 'test/unit'

require 'rubygems' rescue nil
require 'test/spec'
require 'flexmock'
require 'flexmock/test_unit'

require File.dirname(__FILE__) << '/../lib/rtex'

class Test::Unit::TestCase
  
  def change_tmpdir_for_testing
    flexmock(Dir).should_receive(:tmpdir).and_return(File.dirname(__FILE__) << '/tmp')
  end

  def document(name, options={})
    name = name.kind_of?(Symbol) ? "#{name}.tex.erb" : name
    template = File.read(File.dirname(__FILE__) << "/fixtures/#{name}")
    RTeX::Document.new(template, options)
  end

end
  