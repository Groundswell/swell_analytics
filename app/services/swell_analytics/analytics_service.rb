require 'user_agent_parser'
require 'browser'

module SwellAnalytics
	class AnalyticsService
		SESSION_DIMENSIONS	= %w(user_id ip user_agent country state city landing_page_referrer_url landing_page_referrer_host landing_page_referrer_path landing_page_url landing_page_host landing_page_path campaign_source campaign_medium campaign_term campaign_content campaign_name bot_name bot_search_engine browser_family browser_version browser_major_version browser_minor_version operating_system_name operating_system_version operating_system_major_version operating_system_minor_version device_type device_family device_brand device_model)
		SESSION_METRICS		= %w(campaign_cost)

		EVENT_DIMENSIONS	= %w(event_name event_category referrer_url referrer_host referrer_path goal_name goal_id page_url page_host page_path page_name actor_label actor_id actor_type subject_label subject_id subject_type)
		EVENT_METRICS		= %w(value)

		def log_event( name, options = {} )

			if SwellAnalytics.async_event_logging

				SwellAnalytics.event_worker_class_name.constantize.prepare_and_perform_async( name, options )

			else

				self.save_event( name, options )

			end

		end

		def save_event( name, options = {} )
			data_layer = options[:data_layer] || []
			session_uuid = options.delete(:session_uuid)

			if session_uuid.present?
				# @todo cache session in memory until SwellAnalytics.session_ttl.from_now AND re-up expiration every access
				begin
					analytics_session = AnalyticsSession.find_by( session_uuid: session_uuid )
					analytics_session ||= AnalyticsSession.new( self.get_session_attributes( options ).merge( session_uuid: session_uuid ) )
					analytics_session.save!
				rescue ActiveRecord::RecordNotUnique => e
					analytics_session = AnalyticsSession.find_by( session_uuid: session_uuid )
				end
			end

			event_attributes = self.get_event_attributes( name, options, analytics_session )
			# @todo cache event for SwellAnalytics.event_duplication_cooldown.from_now AND check cache to see if it's a dup before creating it.
			return false if AnalyticsEvent.where( event_attributes ).where('created_at > ?', SwellAnalytics.event_duplication_cooldown.ago ).present?
			analytics_event = AnalyticsEvent.new( event_attributes )
			analytics_event.save!


			# should we be logging data layer events too?
			data_layer.each do |row|
				row.each do |event_group,group_data|
					group_data.each do |event_name,event_data|

						data_layer_event_attributes = event_attributes.merge(
							event_name: name,
							# event_group: event_group, #@todo
							event_data: event_data
						)

						data_layer_analytics_event = AnalyticsEvent.new( data_layer_event_attributes )
						data_layer_analytics_event.save!

					end
				end

			end

		end

		protected

		def get_event_attributes( name, options, analytics_session )
			attributes = { event_name: name }
			attributes[:created_at] = options[:created_at] if options[:created_at].present?

			if analytics_session.present?

				SESSION_DIMENSIONS.each do |attribute_name|
					options.delete(attribute_name.to_sym)
					attributes[attribute_name.to_sym] = analytics_session.try(attribute_name) if analytics_session.respond_to?(attribute_name)
				end

				SESSION_METRICS.each do |attribute_name|
					options.delete(attribute_name.to_sym)
					attributes[attribute_name.to_sym] = analytics_session.try(attribute_name) if analytics_session.respond_to?(attribute_name)
				end

				attributes[:analytics_session] = analytics_session
			else

				attributes = attributes.merge( get_session_attributes( options ) )

			end

			EVENT_DIMENSIONS.each do |attribute_name|
				attributes[attribute_name.to_sym] = options.delete( attribute_name.to_sym ) if options.has_key? attribute_name.to_sym
			end

			EVENT_METRICS.each do |attribute_name|
				attributes[attribute_name.to_sym] = options.delete( attribute_name.to_sym ) if options.has_key? attribute_name.to_sym
			end

			if attributes[:page_url].present?
				begin
					uri = URI(attributes[:page_url])
					attributes[:page_host] ||= uri.host
					attributes[:page_path] ||= ( uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path )
				rescue URI::InvalidURIError => e
				end
			end

			if attributes[:referrer_url].present?
				begin
					uri = URI(attributes[:referrer_url])
					attributes[:referrer_host] ||= uri.host
					attributes[:referrer_path] ||= ( uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path )
				rescue URI::InvalidURIError => e
				end
			end

			attributes[:properties] = options || {}
			attributes[:properties].each do |key,value|
				attributes[:properties][key] = value.to_json unless value.nil?
			end

			attributes
		end

		def get_session_attributes( options )
			attributes = {}

			SESSION_DIMENSIONS.each do |attribute_name|
				attributes[attribute_name.to_sym] = options[attribute_name.to_sym] if options.has_key? attribute_name.to_sym
			end

			SESSION_METRICS.each do |attribute_name|
				attributes[attribute_name.to_sym] = options[attribute_name.to_sym] if options.has_key? attribute_name.to_sym
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
				attributes[:bot_search_engine]				= browser.bot.present? && browser.bot.search_engine?
				attributes[:browser_family]					= user_agent.family
				attributes[:browser_version]				= user_agent.version.to_s
				attributes[:browser_major_version]			= user_agent.version.try(:major)
				attributes[:browser_minor_version]			= user_agent.version.try(:minor)
				attributes[:operating_system_name]			= user_agent.os.try(:name)
				attributes[:operating_system_version]		= user_agent.os.version
				attributes[:operating_system_major_version]	= user_agent.os.version.try(:major)
				attributes[:operating_system_minor_version]	= user_agent.os.version.try(:minor)
				attributes[:device_type]					= 'tablet' if browser.device.try(:tablet?)
				attributes[:device_type]					= 'mobile' if browser.device.try(:mobile?)
				attributes[:device_type]					= 'tv' if browser.device.try(:tv?)
				attributes[:device_type]					= 'console' if browser.device.console?
				attributes[:device_family]					= user_agent.device.try(:family)
				attributes[:device_brand]					= user_agent.device.try(:brand)
				attributes[:device_model]					= user_agent.device.try(:model)

			end

			attributes[:landing_page_referrer_url] = options[:referrer_url]
			attributes[:landing_page_url] = options[:page_url]

			if attributes[:landing_page_referrer_url].present?
				begin
					uri = URI(attributes[:landing_page_referrer_url])
					attributes[:landing_page_referrer_host] ||= uri.host
					attributes[:landing_page_referrer_path] ||= ( uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path )
				rescue URI::InvalidURIError => e
				end
			end

			if attributes[:landing_page_url].present?
				begin
					uri = URI(attributes[:landing_page_url])
					attributes[:landing_page_host] ||= uri.host
					attributes[:landing_page_path] ||= ( uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path )
				rescue URI::InvalidURIError => e
				end
			end

			attributes
		end

	end
end
