require 'spec_helper'
require 'tilt'
require 'pakunok/haml_js_template'

describe 'HAML-JS processor' do
  def template haml, file = "file.js.hamljs"
    Pakunok::HamlJsTemplate.new(file) { haml }
  end

  def render haml, file = "file.js.hamljs"
    template(haml, file).render
  end

  it 'should have default mime type' do
    Pakunok::HamlJsTemplate.default_mime_type.should == 'application/javascript'
  end

  describe 'rendering' do
    subject { render "#main= 'quotes'\n  #inner= name", 'myTemplate.js.hamljs' }

    it { should include "function (locals) {" }

    it 'should make template available for JavaScript' do
      context = ExecJS.compile(subject)
      html = context.eval("Templates.myTemplate({name: 'dima'})")
      html.should include '<div id="main">'
      html.should include 'dima'
    end

  end

  describe 'template naming for' do
    {
      'file'                => 'file',
      'file.js.erb.hamljs'  => 'file'
    }.each_pair do |file, name|
      it "#{file} should be #{name}" do
        template('#main', file).client_name.should == name
      end
    end

  end

end
