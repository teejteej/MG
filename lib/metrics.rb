require 'metrics/version'
require 'metrics/mongo_metrics'
require 'metrics/railtie' if defined?(Rails)

module Metrics
  
  class << self
    
    attr_writer :config
    attr_writer :realtime_config
    attr_writer :realtime_connection
    attr_writer :nps_config
    attr_writer :nps_cache
    
    # For metrics
    def config
      @config || {}
    end
    
    # For fnordmetrics
    def realtime_config
      @realtime_config || {}
    end
    
    def realtime_connection
      @realtime_connection || {}
    end
    
    # For NPS
    def nps_config
      @nps_config || {}
    end
    
    def nps_cache
      @nps_cache || {}
    end
    
    attr_accessor :logger
    
    def init(host, port, db, config = {})
      begin
        self.config = config
        
        self.logger = defined?(Rails) ? Logger.new(Rails.root.join('log/metrics.log')) : Logger.new(STDOUT)
        self.logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.iso8601} [#{severity}] #{msg}\n"
        end
        
        MongoMetrics.connection = Mongo::Connection.new host, port
        MongoMetrics::Config.cookie_expiration = 3600*24*999
        MongoMetrics::Config.database_name = db

        logger.info "Metrics initialized: #{host}:#{port}@#{db} [#{config}]" if self.config[:log_delays] && logger
      rescue => e
        if self.config[:exception_on_init_fail] && (!defined?(Rails) || (defined?(Rails) && Rails.env.production?))
          raise e
        else
          logger.warn "Track metrics not enabled (no MongoDB available)." if logger
        end
      end
    end
    
    def init_realtime(host, port, config = {})
      begin
        self.realtime_config = {:event_prefix => 'fnordmetric'}.merge(config)
        self.realtime_connection = Redis.new :host => host, :port => port

        logger.info "Realtime Metrics initialized: #{host}:#{port} [#{realtime_config}]" if self.realtime_config[:log_delays] && logger
      rescue => e
        if self.realtime_config[:exception_on_init_fail] && (!defined?(Rails) || (defined?(Rails) && Rails.env.production?))
          raise e
        else
          logger.warn "track_realtime metrics not enabled (no Redis available)" if logger
        end
      end
    end
   
    def init_nps(config = {})
      begin
        self.nps_config = {:cache_server => '127.0.0.1:11211', :votes_needed => 200, :event_name => 'nps_score_1', :event_type => 'nps_score', :cache_cohort => proc{'nps_score'}, :once_per_user => true}.merge(config)
        self.nps_cache = Dalli::Client.new config[:cache_server]

        logger.info "NPS Survey initialized: #{config}" if self.config[:log_delays] && logger
      rescue => e
        if self.config[:exception_on_init_fail] && (!defined?(Rails) || (defined?(Rails) && Rails.env.production?))
          raise e
        else
          logger.warn "NPS not enabled (no Memcached available)" if logger
        end
      end
    end
    
  end

end