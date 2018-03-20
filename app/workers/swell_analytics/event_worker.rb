module SwellAnalytics
	class EventWorker
		if defined?( Sidekiq::Worker )
			include Sidekiq::Worker
			sidekiq_options( SwellAnalytics.event_worker_options ) if SwellAnalytics.event_worker_options.present?
		end


		def perform( name, options )

			# Process Event
			begin

				options = JSON.parse( options, symbolize_names: true )
				options[:created_at] = Time.at( options[:created_at] ) if options[:created_at].present?

				AnalyticsService.new.save_event( name, options )

			rescue Exception => e
				puts e

				raise e if Rails.env.development?

				begin
					NewRelic::Agent.notice_error( e, custom_params: args )
				rescue
					NewRelic::Agent.notice_error( e )
				end
			end

		end

		def self.prepare_and_perform_async( name, options )
			options[:created_at] ||= Time.now
			options[:created_at] = options[:created_at].to_f

			self.perform_async( name, options.to_json )
		end

	end

end
