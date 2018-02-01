module SwellAnalytics
  module ApplicationHelper

	  def log_analytics_event( name, options = {} )
		  @analytics_service ||= SwellAnalytics::AnalyticsService.new

		  @analytics_service.log_event( name, options.merge( params: params, request: request ) )
	  end

  end
end
