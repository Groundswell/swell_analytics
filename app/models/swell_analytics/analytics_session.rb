module SwellAnalytics
	class AnalyticsSession < ActiveRecord::Base
		self.table_name = 'analytics_events'

		has_many :analytics_events
	end
end
