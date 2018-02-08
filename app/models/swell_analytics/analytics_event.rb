module SwellAnalytics
	class AnalyticsEvent < ActiveRecord::Base
		self.table_name = 'analytics_events'

		belongs_to :analytics_session, optional: true if Rails.version.to_i > 4
		belongs_to :analytics_session if Rails.version.to_i <= 4
	end
end
