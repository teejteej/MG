# (Optional) Installing without Gemfile
	- http://raflabs.com/blogs/silence-is-foo/2010/07/19/installing-a-gem-fork-from-github-source/

# Add to your Gemfile

	gem 'aarrr', :git => 'git://github.com/teejteej/aarrr.git'
	gem 'metrics', :git => 'git://github.com/teejteej/mg.git'

	gem 'mongo'
	gem 'bson_ext'
	gem 'redis'
	gem 'dalli'
	gem 'kgio'
	gem 'uuidtools'

# Add to your ApplicationController

	before_filter :set_metrics_identity
	before_filter :track_extra_metrics

# Add to your environments

	Metrics::init('localhost', 27017, 'metrics', {:no_bounce_seconds => 10, :long_visit_seconds => 120, :log_delays => true})

# Optionally

- When using a/b testing, init your environment like this (where `:ab_framework` can be `:vanity`, `:abingo` or `:abongo`):

	Metrics::init('localhost', 27017, 'metrics', {:no_bounce_seconds => 10, :long_visit_seconds => 120, :log_delays => true, :ab_framework => :vanity})

- To track landing bounces and long visits, use this at your landing action: `session[:visit_start] ||= Time.now`

- In each `Metrics::init` or `Metrics::init_realtime`, two extra options can be added:
	- `:log_delays_as_realtime_event => 'metrics_delay', :log_delays_realtime_sample => 0.1`
	- If these two are set, the time needed to call `track_metric` or `track_realtime` is automatically tracked as a realtime event, with the delay in MS as extra parameter to track in the fnordmetric event handler.
	- `log_delays_realtime_sample => 0.1` means that only 1/10th of all calls to track / track_realtime are sampled with a delay, using 1.0 would mean all is sampled.

# Tracking realtime metrics

	`Metrics::init_realtime('localhost', 6379, {:event_prefix => 'fnordmetric'})`

# Tracking NPS survey metrics

- `Metrics::init_nps({:votes_needed => 200, :event_name => 'nps_score_1', :event_type => 'nps_score', :cache_cohort => proc{"nps_score_#{Time.now.month}_#{Time.now.year}"}, :once_per_user => true, :cache_server => '127.0.0.1:11211'})`
- _Note:_ `event_name` also functions as unique identification to see if the users already voted or not. If `config[:once_per_user] == true`, and we change event_name after the user has voted once already, he can vote again.
