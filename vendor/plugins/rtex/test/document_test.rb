require File.dirname(__FILE__) << '/test_helper'

context "Document Generation" do
  
  def setup
    change_tmpdir_for_testing
  end
  
  specify "documents have a to_pdf method" do
    assert document(:first).respond_to?(:to_pdf)
  end
  
  specify "can escape characters" do
    assert_equal '\textbackslash{}\textasciitilde{}', RTeX::Document.escape('\~')
  end
  
  specify "documents can use a to_pdf block to move a file to a relative path" do
    begin
      path = File.expand_path(File.dirname(__FILE__) << '/tmp/this_is_relative_to_pwd.pdf')
      document(:first).to_pdf do |filename|
        assert_nothing_raised do
          FileUtils.move filename, path
        end
        assert File.exists?(path)
      end
    ensure
      FileUtils.rm path rescue nil
    end
  end
  
  specify "can generate PDF and return as a string" do
    @author = 'Foo'
    assert_equal '%PDF', document(:first).to_pdf(binding)[0, 4]
  end
  
  specify "can generate TeX source and return as a string with debug option" do
    @author = 'Foo'
    assert_not_equal '%PDF', document(:first, :tex => true).to_pdf(binding)[0, 4]    
  end
  
  specify "can generate PDF and give access to file directly" do
    @author = 'Foo'
    data_read = nil
    invocation_result = document(:first).to_pdf(binding) do |filename|
      data_read = File.open(filename, 'rb') { |f| f.read }
      :not_the_file_contents
    end
    assert_equal '%PDF', data_read[0, 4]
    assert_equal :not_the_file_contents, invocation_result
  end
  
  specify "can generate TeX source and give access to file directly" do
    @author = 'Foo'
    data_read = nil
    invocation_result = document(:first, :tex => true).to_pdf(binding) do |filename|
      data_read = File.open(filename, 'rb') { |f| f.read }
      :not_the_file_contents
    end
    assert_not_equal '%PDF', data_read[0, 4]
    assert_equal :not_the_file_contents, invocation_result
  end
  
  specify "can wrap in a layout using `yield'" do
    doc = document(:fragment, :layout => 'testing_layout[<%= yield %>]')
    @name = 'ERB'
    source = doc.source(binding)
    assert source =~ /^testing_layout.*?ERB, Fragmented/
  end
  
end