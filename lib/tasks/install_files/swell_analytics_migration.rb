class SwellAnalyticsMigration < ActiveRecord::Migration
	def change

		create_table :analytics_session do |t| # cache this model's attributes, and have it expire after session is dead for X minutes (TTL)
			t.integer		:user_id
			t.string		:session_uuid

			t.string		:ip
			t.string		:user_agent

			t.string		:country
			t.string		:state
			t.string		:city

			t.string		:landing_page_referrer_url
			t.string		:landing_page_url

			t.string		:campaign_source
			t.string		:campaign_medium
			t.string		:campaign_term
			t.string		:campaign_content
			t.string		:campaign_name
			t.integer		:campaign_cost

			t.string		:bot_name
			t.boolean		:bot_search_engine
			t.string		:browser_family
			t.string		:browser_version
			t.string		:browser_major_version
			t.string		:browser_minor_version
			t.string		:operating_system_name
			t.string		:operating_system_version
			t.string		:operating_system_major_version
			t.string		:operating_system_minor_version
			t.string		:device_type
			t.string		:device_family
			t.string		:device_brand
			t.string		:device_model

			t.timestamps
		end
		add_index :analytics_session, :session_uuid, unique: true

		create_table :analytics_events do |t|
			t.integer		:user_id
			t.integer		:analytics_session_id
			t.string		:session_uuid

			# SESSION SCOPE
			t.string		:ip
			t.string		:user_agent

			t.string		:country
			t.string		:state
			t.string		:city

			t.string		:landing_page_referrer_url
			t.string		:landing_page_url

			t.string		:campaign_source
			t.string		:campaign_medium
			t.string		:campaign_term
			t.string		:campaign_content
			t.string		:campaign_name
			t.integer		:campaign_cost

			t.string		:bot_name
			t.boolean		:bot_search_engine
			t.string		:browser_family
			t.string		:browser_version
			t.string		:browser_major_version
			t.string		:browser_minor_version
			t.string		:operating_system_name
			t.string		:operating_system_version
			t.string		:operating_system_major_version
			t.string		:operating_system_minor_version
			t.string		:device_type
			t.string		:device_family
			t.string		:device_brand
			t.string		:device_model


			# EVENT SCOPE
			t.string		:event_name
			t.string		:event_category
			t.integer		:value, default: 0
			t.string		:referrer_url

			t.string		:goal_name
			t.string		:goal_id

			t.string		:page_url
			t.string		:page_host
			t.string		:page_path
			t.string		:page_name

			# Actor and Subject (objects) of event
			t.string		:actor_label
			t.integer		:actor_id
			t.string		:actor_type
			t.string		:subject_label
			t.integer		:subject_id
			t.string		:subject_type

			t.hstore		:properties

			t.timestamps
		end
		add_index :analytics_events, :session_uuid

	end
end
