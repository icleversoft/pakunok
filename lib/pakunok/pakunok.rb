
module Pakunok
  class Pakunok
    attr_accessor :render_types

    def initialize
      @render_types = {:javascript => :script, :stylesheet => :link} 
    end

    def self.current(opts=nil)
      @current = nil if opts && opts[:clear]
      @current ||= Pakunok.new
    end

    def asset(path)
      @managed ||= Hash.new
      asset = @managed[path]
      return asset if asset
      asset = @managed[path] = ManagedAsset.new(self, path)
    end

    def add_dependencies(pairs)
      pairs.each_pair do |path, dependent|
        asset(path).needs(dependent)
      end
      return self
    end

    def renderer_for(name)
      @renderers ||= Hash.new
      renderer = @renderers[name]
      unless renderer
        require "pakunok/renderers/#{name}_renderer"
        renderer = ::Pakunok::AssetRenderers.const_get(name.to_s.capitalize + 'Renderer').new(self)
        @renderers[name] = renderer
      end
      return renderer
    end

    def assets
      @managed
    end
  end

  class HttpContext
    attr_accessor :request

    def initialize(request, rails_assets = nil)
      @request = request
      @rails_assets = rails_assets
    end

    def rails_assets
      # TODO: do actually pass it in
      @rails_assets or Rails.application.config.assets
    end
  end

  class ManagedAsset
    attr_accessor :path, :cdn, :async, :embedded, :dependencies

    def initialize(manager, path)
      @manager, @path = manager, path
      @async          = false
      @embedded       = false
      @dependencies   = []
    end

    def needs(*deps)
      deps.map {|path| @manager.asset(path) }.each do |asset|
        @dependencies.push asset
      end      
      return self
    end

    def embed
      @embedded = true
      return self
    end      

    def replace_with(options)
      @cdn = options[:cdn]
      return self
    end

    def as_async
     @async = true
     return self
    end

    def async?;     @async end
    def embedded?;  @embedded end


    def url(context)
      cdn ? cdn_url(context) : asset_url(context)
    end

    def cdn_url(context)
      if cdn.match /^https?:\/\//i
        cdn
      else
        context.request.protocol + cdn
      end
    end

    def asset_url(context)
      context.rails_assets.asset_path path
    end

    def depends_on
      full_dependencies.map {|asset| asset.path }
    end
    
    def full_dependencies(visit_map = {})
      return [] if visit_map[self]
      visit_map[self] = true
      @dependencies.reverse.map do |asset| 
        asset.full_dependencies(visit_map) + [asset]
      end.flatten - [self]
    end
  end
end
