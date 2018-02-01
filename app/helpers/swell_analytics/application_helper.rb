module SwellAnalytics
	module ApplicationHelper

		def log_analytics_event( name, options = {} )
			@analytics_service ||= SwellAnalytics::AnalyticsService.new

			session_uuid = cookies[:swasuuid] || SecureRandom.uuid

			options = {
				session_uuid: session_uuid,
				user_agent: request.user_agent,
				country: request['CF-IPCountry'],
				ip: request.remote_ip,
				campaign_source: params[:utm_source],
				campaign_medium: params[:utm_medium],
				campaign_term: params[:utm_term],
				campaign_content: params[:utm_content],
				campaign_name: params[:utm_campaign],
			}.merge( options )


			@analytics_service.log_event( name, options )

			cookies[:swasuuid] = {
				:value => session_uuid,
				:expires => SwellAnalytics.session_ttl.from_now
			}
		end

	end
end
