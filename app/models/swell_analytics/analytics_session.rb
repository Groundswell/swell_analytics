module SwellAnalytics
	class AnalyticsSession < ActiveRecord::Base
		self.table_name = 'analytics_sessions'

		has_many :analytics_events
	end
end
