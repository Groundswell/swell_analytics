module SwellAnalytics
	class AnalyticsEvent < ActiveRecord::Base
		self.table_name = 'analytics_events'

		belongs_to :analytics_session, optional: true
	end
end
