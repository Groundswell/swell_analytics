
require 'stripe'
require 'tax_cloud'

module SwellAnalytics


	class << self
		mattr_accessor :event_worker_class_name
		mattr_accessor :async_event_logging
		mattr_accessor :event_worker_options
		mattr_accessor :session_ttl
		mattr_accessor :event_duplication_cooldown

		self.event_worker_class_name = "SwellAnalytics::EventWorker"
		self.async_event_logging = defined?( Sidekiq::Worker )
		self.event_worker_options = { :queue => :medium }
		self.session_ttl = 10.minutes
		self.event_duplication_cooldown = 10.seconds

	end

	# this function maps the vars from your app into your engine
     def self.configure( &block )
        yield self
     end



  class Engine < ::Rails::Engine
    isolate_namespace SwellAnalytics
	config.generators do |g|
		g.test_framework :rspec, :fixture => false
		g.fixture_replacement :factory_girl, :dir => 'spec/factories'
		g.assets false
		g.helper false
	end
  end
end
