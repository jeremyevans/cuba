require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  for lib in %w'tilt tilt/sass tilt/coffee'
    require lib
  end
  run_tests = true
rescue LoadError
  warn "#{lib} not installed, skipping assets plugin test"
rescue
  # ExecJS::RuntimeUnavailable may or may not be defined, so can't use do:
  #   rescue ExecJS::RuntimeUnavailable'
  if $!.class.name == 'ExecJS::RuntimeUnavailable'
    warn "#{$!.to_s}: skipping assets plugin tests"
  else
    raise
  end
end

if run_tests
  describe 'assets plugin' do
    before do
      app(:bare) do
        plugin(:assets, {
          :path => './spec/dummy/assets',
          :compiled_path => './spec/dummy/assets',
          :headers => {
            "Cache-Control"             => 'public, max-age=2592000, no-transform',
            'Connection'                => 'keep-alive',
            'Age'                       => '25637',
            'Strict-Transport-Security' => 'max-age=31536000',
            'Content-Disposition'       => 'inline'
          }
        })

        assets_opts[:css] = ['app', '../raw.css']
        assets_opts[:js]  = { :head => ['app'] }

        route do |r|
          r.assets

          r.is 'test' do
            response.write assets :css
            response.write assets [:js, :head]
          end
        end
      end
    end

    it 'should contain proper configuration' do
      app.assets_opts[:path].should == './spec/dummy/assets'
      app.assets_opts[:css].should include('app')
    end

    it 'should serve proper assets' do
      body('/assets/css/app.css').should include('color: red')
      # body('/assets/css/%242E%242E/raw.css').should include('color: blue')
      # body('/assets/js/head/app.js').should include('console.log')
    end

    it 'should contain proper assets html tags' do
      html = body '/test'
      html.scan(/<link/).length.should == 2
      html.scan(/<script/).length.should == 1
      html.should include('link')
      html.should include('script')
    end

    it 'should only show one link when :compiled is true' do
      app.assets_opts[:compiled] = true
      html = body '/test'
      html.scan(/<link/).length.should == 1
    end

    it 'should write compiled files' do
      app.compile_assets
      app.assets_opts[:compiled].should == true
      app.new.assets(:css) =~ %r{href="(/assets/css/app\.[a-f0-9]{40}\.css)"}
      css = $1
      File.read("spec/dummy#{css}").should =~ /color: red;/
      File.read("spec/dummy#{css}").should =~ /color: blue;/
      app.new.assets([:js, :head]) =~ %r{src="(/assets/js/app\.head\.[a-f0-9]{40}\.js)"}
      js = $1
      File.read("spec/dummy#{js}").should include('console.log')
    end

    it 'should only allow files in your list' do
      body('/assets/css/%242E%242E/%242E%242E/no_access.css').should_not include('no access')
    end
  end
end
