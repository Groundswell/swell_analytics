class EventWorker
	if defined?( Sidekiq::Worker )
		include Sidekiq::Worker
		sidekiq_options :queue => :medium
	end


	def perform( name, options )
		options = JSON.parse options, symbolize_keys: true

		# Process Event
		begin

			AnalyticsService.new.save_event( name, options )

		rescue Exception => e
			puts e

			begin
				NewRelic::Agent.notice_error( e, custom_params: args )
			rescue
				NewRelic::Agent.notice_error( e )
			end
		end

	end

end
