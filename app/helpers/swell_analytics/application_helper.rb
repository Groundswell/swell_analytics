module SwellAnalytics
	module ApplicationHelper

		def log_analytics_event( name, options = {} )
			@analytics_service ||= SwellAnalytics::AnalyticsService.new

			session_uuid = cookies[:swasuuid] || SecureRandom.uuid

			options = { params: params, request: request, session_uuid: session_uuid }.merge options
			options[:page_name] ||= @page_meta[:title] if defined?( SwellMedia )
			options[:data_layer] ||= @page_event_data if defined?( SwellMedia ) && @page_event_data.present?

			@analytics_service.log_event( name, options )

			cookies[:swasuuid] = {
				:value => session_uuid,
				:expires => SwellAnalytics.session_ttl.from_now
			}
		end

	end
end
