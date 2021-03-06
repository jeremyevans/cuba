require_relative "spec_helper"

[true, false].each do |frozen|
  describe(frozen ? "optimized matchers for frozen applications" : "matchers") do
    if frozen
      def app(*)
        super.freeze
      end
    end

    it "r.is without arguments should only match if already matched" do
      app do |r|
        r.is do |*args|
          args.length.to_s
        end
        ''
      end

      body('').must_equal '0'
      body.must_equal ''
      body('fo').must_equal ''
      body('foo').must_equal ''
      body('/fo').must_equal ''
      body('/foo').must_equal ''
      body('/foo/').must_equal ''
      body('/foo/1').must_equal ''
    end

    it "r.get and r.post without arguments should only match if already matched" do
      app do |r|
        r.get do |*args|
          "get-#{args.length}"
        end
        r.post do |*args|
          "post-#{args.length}"
        end
        ''
      end

      body('').must_equal 'get-0'
      body('', 'REQUEST_METHOD'=>'POST').must_equal 'post-0'
      body('', 'REQUEST_METHOD'=>'PUT').must_equal ''
    end

    [:is, :get].each do |meth|
      it "r.#{meth} true should only match if already matched" do
        app do |r|
          r.send(meth, true) do |*args|
            args.length.to_s
          end
          ''
        end

        body('').must_equal '0'
        body.must_equal ''
        body('fo').must_equal ''
        body('foo').must_equal ''
        body('/fo').must_equal ''
        body('/foo').must_equal ''
        body('/foo/').must_equal ''
        body('/foo/1').must_equal ''
      end

      it "r.#{meth} 'string' should match only final segment containing the string" do
        app do |r|
          r.send(meth, 'foo') do |*args|
            "foo-#{args.length}"
          end
          ''
        end

        body.must_equal ''
        body('fo').must_equal ''
        body('foo').must_equal ''
        body('/fo').must_equal ''
        body('/foo').must_equal 'foo-0'
        body('/foo/').must_equal ''
        body('/foo/1').must_equal ''
      end

      it "r.#{meth} String should match only final segment" do
        app do |r|
          r.send(meth, String) do |*args|
            args.inspect
          end
          ''
        end

        body.must_equal ''
        body('fo').must_equal ''
        body('foo').must_equal ''
        body('/fo').must_equal '["fo"]'
        body('/foo').must_equal '["foo"]'
        body('/foo/').must_equal ''
        body('/foo/1').must_equal ''
      end

      it "r.#{meth} Integer should match only final segment" do
        app do |r|
          r.send(meth, Integer) do |*args|
            args.inspect
          end
          ''
        end

        body.must_equal ''
        body('fo').must_equal ''
        body('foo').must_equal ''
        body('/fo').must_equal ''
        body('/foo').must_equal ''
        body('/foo/').must_equal ''
        body('/foo/1').must_equal ''
        body('1').must_equal ''
        body('2').must_equal ''
        body('/1').must_equal '[1]'
        body('/2').must_equal '[2]'
        body('/1/').must_equal ''
        body('/2/1').must_equal ''
      end

      it "r.#{meth} with unsupported class should raise" do
        app do |r|
          r.send(meth, Array) do |*args|
            args.inspect
          end
          ''
        end

        proc{body}.must_raise Roda::RodaError
      end

      it "r.#{meth} /regexp/ should match only final segment" do
        app do |r|
          r.send(meth, /(foo?)/) do |*args|
            args.inspect
          end
          ''
        end

        body.must_equal ''
        body('fo').must_equal ''
        body('foo').must_equal ''
        body('/f').must_equal ''
        body('/fo').must_equal '["fo"]'
        body('/foo').must_equal '["foo"]'
        body('/food').must_equal ''
        body('/foo/').must_equal ''
        body('/foo/1').must_equal ''
      end

      it "r.#{meth} String, Integer should match only string segment followed by final integer segment" do
        app do |r|
          r.send(meth, String, Integer) do |*args|
            args.inspect
          end
          ''
        end

        body.must_equal ''
        body('fo').must_equal ''
        body('foo').must_equal ''
        body('/fo').must_equal ''
        body('/foo').must_equal ''
        body('/foo/').must_equal ''
        body('/foo/1').must_equal '["foo", 1]'
        body('/foo/1/').must_equal ''
      end
    end

    it "r.on without arguments should always match" do
      app do |r|
        r.on do |*args|
          args.length.to_s
        end
        ''
      end

      body('').must_equal '0'
      body.must_equal '0'
      body('fo').must_equal '0'
      body('foo').must_equal '0'
      body('/fo').must_equal '0'
      body('/foo').must_equal '0'
      body('/foo/').must_equal '0'
      body('/foo/1').must_equal '0'
    end

    it "r.on true should always match" do
      app do |r|
        r.on true do |*args|
          args.length.to_s
        end
        ''
      end

      body('').must_equal '0'
      body.must_equal '0'
      body('fo').must_equal '0'
      body('foo').must_equal '0'
      body('/fo').must_equal '0'
      body('/foo').must_equal '0'
      body('/foo/').must_equal '0'
      body('/foo/1').must_equal '0'
    end

    it "r.on 'string' should match string against next segment" do
      app do |r|
        r.on('foo') do |*args|
          "foo-#{args.length}-#{r.remaining_path}"
        end
        ''
      end

      body.must_equal ''
      body('fo').must_equal ''
      body('foo').must_equal ''
      body('/fo').must_equal ''
      body('/foo').must_equal 'foo-0-'
      body('/foo/').must_equal 'foo-0-/'
      body('/foo/1').must_equal 'foo-0-/1'
    end

    it "r.on String should match next segment if non-empty" do
      app do |r|
        r.on(String) do |*args|
          "#{args.inspect}-#{r.remaining_path}"
        end
        ''
      end

      body.must_equal ''
      body('fo').must_equal ''
      body('foo').must_equal ''
      body('/fo').must_equal '["fo"]-'
      body('/foo').must_equal '["foo"]-'
      body('/foo/').must_equal '["foo"]-/'
      body('/foo/1').must_equal '["foo"]-/1'
    end

    it "r.on Integer should match next segment if integer" do
      app do |r|
        r.on(Integer) do |*args|
          "#{args.inspect}-#{r.remaining_path}"
        end
        ''
      end

      body.must_equal ''
      body('fo').must_equal ''
      body('foo').must_equal ''
      body('/fo').must_equal ''
      body('/foo').must_equal ''
      body('/foo/').must_equal ''
      body('/foo/1').must_equal ''
      body('1').must_equal ''
      body('2').must_equal ''
      body('/1').must_equal '[1]-'
      body('/2').must_equal '[2]-'
      body('/1/').must_equal '[1]-/'
      body('/2/1').must_equal '[2]-/1'
    end

    it "r.on with unsupported class should raise" do
      app do |r|
        r.on(Array) do |*args|
          args.inspect
        end
        ''
      end

      proc{body}.must_raise Roda::RodaError
    end

    it "r.on /regexp/ should match regexp against next segment" do
      app do |r|
        r.on(/(foo?)/) do |*args|
          "#{args.inspect}-#{r.remaining_path}"
        end
        ''
      end

      body.must_equal ''
      body('fo').must_equal ''
      body('foo').must_equal ''
      body('/f').must_equal ''
      body('/fo').must_equal '["fo"]-'
      body('/foo').must_equal '["foo"]-'
      body('/food').must_equal ''
      body('/foo/').must_equal '["foo"]-/'
      body('/foo/1').must_equal '["foo"]-/1'
    end

    it "r.on String, Integer should match string segment followed by integer segment" do
      app do |r|
        r.on(String, Integer) do |*args|
          "#{args.inspect}-#{r.remaining_path}"
        end
        ''
      end

      body.must_equal ''
      body('fo').must_equal ''
      body('foo').must_equal ''
      body('/fo').must_equal ''
      body('/foo').must_equal ''
      body('/foo/').must_equal ''
      body('/foo/1').must_equal '["foo", 1]-'
      body('/foo/1/').must_equal '["foo", 1]-/'
      body('/fo/2/a').must_equal '["fo", 2]-/a'
    end

    it "r.is with slash_path_empty should match remaining path with only slash" do
      app(:slash_path_empty) do |r|
        r.is do |*args|
          args.length.to_s
        end
        ''
      end

      body('').must_equal '0'
      body.must_equal '0'
      body('fo').must_equal ''
      body('foo').must_equal ''
      body('/fo').must_equal ''
      body('/foo').must_equal ''
      body('/foo/').must_equal ''
      body('/foo/1').must_equal ''
    end
  end
end
