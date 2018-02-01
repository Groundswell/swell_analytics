require 'user_agent_parser'
require 'browser'

module SwellAnalytics
	class AnalyticsService
		SESSION_DIMENSIONS	= %w(user_id ip user_agent country state city landing_page_referrer_url landing_page_url campaign_source campaign_medium campaign_term campaign_content campaign_name bot_name bot_search_engine browser_family browser_version browser_major_version browser_minor_version operating_system_name operating_system_version operating_system_major_version operating_system_minor_version device_type device_family device_brand device_model)
		SESSION_METRICS		= %w(campaign_cost)

		EVENT_DIMENSIONS	= %w(event_name event_category referrer_url goal_name goal_id page_url page_host page_path page_name actor_label actor_id actor_type subject_label subject_id subject_type)
		EVENT_METRICS		= %w(value)

		def log_event( name, options = {} )

			params = options.delete(:params)
			request = options.delete(:request)

			options[:country] = request['CF-IPCountry'] if request.present? && request.headers['CF-IPCountry'].present?

			if SwellAnalytics.async_event_logging

				SwellAnalytics.event_worker_class_name.constantize.perform_async( args )

			else

				self.save_event( name, options )

			end

		end

		def save_event( name, options = {} )

			analytics_session = AnalyticsSession.find_by( session_uuid: options.delete(:session_uuid) ) if options[:session_uuid].present?
			# analytics_session = AnalyticsSession.create( self.get_session_attributes( options ) )

			analytics_event = AnalyticsEvent.new( event_name: name, analytics_session: analytics_session )
			analytics_event.attributes = get_event_attributes( options, analytics_session )

			# should we be logging data layer events too?
			if ( data_layer = options[:data_layer] ).present?

				data_layer.each do |row|
					row.each do |event_group,group_data|
						group_data.each do |event_name,event_data|

							event_options = options.merge( event_group: event_group )
							event_options = event_options.merge( event_data: event_data )

							analytics_event = AnalyticsEvent.new( event_name: event_name, analytics_session: analytics_session )
							analytics_event.attributes = get_event_attributes( event_options, analytics_session )

						end
					end

				end

			end

		end

		protected

		def get_event_attributes( options, analytics_session )
			attributes = {}

			if analytics_session.present?

				SESSION_DIMENSIONS.each do |attribute_name|
					options.delete(attribute_name.to_sym)
					attributes[attribute_name.to_sym] = analytics_session.call(attribute_name) if analytics_session.respond_to?(attribute_name)
				end

				SESSION_METRICS.each do |attribute_name|
					options.delete(attribute_name.to_sym)
					attributes[attribute_name.to_sym] = analytics_session.call(attribute_name) if analytics_session.respond_to?(attribute_name)
				end

			else

				attributes = get_session_attributes( options )

			end

			EVENT_DIMENSIONS.each do |attribute_name|
				attributes[attribute_name.to_sym] = options.delete( attribute_name.to_sym ) if options[attribute_name.to_sym].present?
			end

			EVENT_METRICS.each do |attribute_name|
				attributes[attribute_name.to_sym] = options.delete( attribute_name.to_sym ) if options[attribute_name.to_sym].present?
			end

			attributes[:properties] = options || {}
			attributes[:properties].each do |key,value|
				attributes[:properties][key] = value.to_json
			end

			attributes
		end

		def get_session_attributes( options )
			attributes = {}

			SESSION_DIMENSIONS.each do |attribute_name|
				attributes[attribute_name.to_sym] = options[attribute_name.to_sym] if options[attribute_name.to_sym].present?
			end

			SESSION_METRICS.each do |attribute_name|
				attributes[attribute_name.to_sym] = options[attribute_name.to_sym] if options[attribute_name.to_sym].present?
			end


			if attributes[:ip]
				attributes[:country]
				attributes[:state]
				attributes[:city]
			end

			if attributes[:user_agent].present?

				user_agent = UserAgentParser.parse attributes[:user_agent]
				browser = Browser.new attributes[:user_agent]

				attributes[:bot_name]						= browser.bot.name if browser.bot.present?
				attributes[:bot_search_engine]				= browser.bot.present? && browser.bot.seach_engine?
				attributes[:browser_family]					= user_agent.family
				attributes[:browser_version]				= user_agent.version.to_s
				attributes[:browser_major_version]			= user_agent.version.major
				attributes[:browser_minor_version]			= user_agent.version.minor
				attributes[:operating_system_name]			= user_agent.os.name
				attributes[:operating_system_version]		= user_agent.os.version
				attributes[:operating_system_major_version]	= user_agent.os.version.major
				attributes[:operating_system_minor_version]	= user_agent.os.version.minor
				attributes[:device_type]					= 'tablet' if browser.tablet?
				attributes[:device_type]					= 'mobile' if browser.mobile?
				attributes[:device_type]					= 'tv' if browser.tv?
				attributes[:device_type]					= 'console' if browser.console?
				attributes[:device_family]					= user_agent.device.family
				attributes[:device_brand]					= user_agent.device.brand
				attributes[:device_model]					= user_agent.device.model

			end

			attributes
		end

	end
end
