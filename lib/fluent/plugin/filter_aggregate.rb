module Fluent
  class FilterAggregate < Filter
    Fluent::Plugin.register_filter('aggregate', self)
    config_param :aggregator_suffix_name, :string, :default => nil
    config_param :time_format, :string, :default =>'%Y-%m-%dT%H:%M:%S.%L%:z'
    config_param :output_time_format, :string, :default =>'%Y-%m-%dT%H:%M:%S.%L%z'
    config_param :intervals, :array, :default =>[5], value_type: :time,
	         :desc => 'Interval for accumulative  aggregation'
    config_param :interval, :array, :default =>nil, value_type: :time,
	         :desc => 'Interval for accumulative  aggregation, legacy option',
                 :deprecated => 'Use intervals instead'
    config_param :flush_interval, :time, :default =>5,
	         :desc => 'Interval for emmit  aggregation events'
    config_param :keep_interval, :time, :default =>10,
	         :desc => 'Interval to wait for events to aggregate'
    config_param :group_fields, :array, :default => ['field1','field2'], value_type: :string
    config_param :aggregate_fields, :array, :default => ['aggregate_field1','aggregate_field2'], value_type: :string
    config_param :time_field, :string, :default =>'timestamp'
    config_param :field_no_data_value, :string, :default =>'no_data'
    config_param :emit_original_message, :bool, :default => true
    config_param :aggregate_event_tag, :string, :default => 'aggregate'
    config_param :aggregations, :array, :default => ['sum','min','max','mean','median','variance','standard_deviation'], value_type: :string
    config_param :buckets, :array, :default => [], value_type: :integer
    config_param :bucket_metrics, :array, :default => [], value_type: :string
    config_param :temporary_status_file_path, :string, :default => nil, :desc => 'File to store aggregate information when the agent down'
    config_param :load_temporarystatus_file_enabled, :bool, :default => true, :desc => 'Enable load saved data from file (if exist status file)'
    config_param :processing_mode, :string, :default => 'online', :desc => 'Processing mode (batch/online)'
    config_param :time_started_mode, :string, :default => 'first_event', :desc => 'Time started mode (first_event/last_event)'

    VALID_AGGREGATIONS = ['sum','min','max','mean','median','variance','standard_deviation','bucket']

    def initialize
      super
    end

    def configure(conf)
      super

      require 'dataoperations-aggregate'

      @intervals = @interval unless @interval.nil?
      @hash_time_format = "%Y-%m-%dT%H"
      @interval_seconds = 3600
      @intervals[1..-1].each{|interval|
        case interval
        when 1,5,10,20,30,60,120,180,240,300,600,900,1200,1800,3600
    	  if ! (interval % @intervals[0]) == 0
            raise Fluent::ConfigError, "interval must be multiple of default_aggregate_interval(#{@default_aggregate_interval}s)"
	  end
        else
          raise Fluent::ConfigError, "interval must set to 1s,5s,10s,20s,30s,1m,5m,10m"
        end
      }

      @group_field_names = @group_fields
      @aggregate_field_names = @aggregate_fields
      @aggregation_names = @aggregations
      @aggregator_name = "#{Socket.gethostname}"
      @aggregator_name = "#{@aggregator_name}-#{@aggregator_suffix_name}" unless @aggregator_suffix_name.nil?

      @aggregation_names.each {|operation|
        if ! VALID_AGGREGATIONS.include?(operation)
          raise Fluent::ConfigError, "aggregations must set any combination of sum,min,max,mean,median,variance,standard_deviation "
        end
      }

      if @aggregation_names.include?("bucket") && (buckets.empty? || bucket_metrics.empty?)
        log.warn "bucket aggregation disabled, need buckets & bucket_metrics parameters to work, please review documentation."
      else
        log.info "bucket aggregation enabled, bucket count bucket_metrics with values <= buckets parameter"
      end

      @aggregator = {}
      if load_temporarystatus_file_enabled && ! @temporary_status_file_path.nil? && File.exist?(@temporary_status_file_path) && file_status = File.open(@temporary_status_file_path,'r')
        begin
          @aggregator=eval(file_status.read)
          file_status.close
          File.delete(@temporary_status_file_path)
          log.info "Temporary information loaded from temporary_status_file_path:#{@temporary_status_file_path} before startup"
        rescue Exception => e
          log.warn "Failed to load temporary_status_file_path:#{@temporary_status_file_path}"
          log.warn e.message
          log.warn e.backtrace.inspect
        end
      end

      @aggregator = {} unless @aggregator.is_a?(Hash)

      log.warn "temporary_status_file_path is empty, is recomended using to avoid lost statistic information beetween restarts." if @temporary_status_file_path.nil?
      @aggregator_mutex = Mutex.new
      @processing_mode_type=@processing_mode=='batch' ? :batch : :online
      @time_started_mode_type=@time_started_mode=='first_event' ? :fist_event : :last_event
      @data_operations = DataOperations::Aggregate.new(aggregator: @aggregator,
                          time_format: @time_format,
                          time_field: @time_field,
                          output_time_format: @output_time_format,
                          intervals: @intervals,
                          flush_interval: @flush_interval,
                          keep_interval: @keep_interval,
                          field_no_data_value: @field_no_data_value,
                          processing_mode: @processing_mode_type,
                          time_started_mode: @time_started_mode_type,
                          log: log,
                          aggregator_name: @aggregator_name,
                          aggregation_names: @aggregation_names,
                          group_field_names: @group_field_names,
                          aggregate_field_names: @aggregate_field_names,
                          buckets: @buckets,
                          bucket_metrics: @bucket_metrics
                         )
    end

    def filter(tag, time, record)
      result = nil
      begin
        result = record unless ! emit_original_message

        @data_operations.add_events(record)
      rescue => e
        log.warn "failed to filter events", :error_class => e.class, :error => e.message
        log.warn_backtrace
      end
      result
    end

    def start
      super
      @loop = Coolio::Loop.new
      tw = TimerWatcher.new(@flush_interval, true, @log, &method(:aggregate_events))
      tw.attach(@loop)
      @thread = Thread.new(&method(:run))
    end

    def run
      @loop.run
    rescue
      log.error "unexpected error", :error=>$!.to_s
      log.error_backtrace
    end

    def shutdown
      @loop.stop
      @thread.join

      if load_temporarystatus_file_enabled && ! @temporary_status_file_path.nil? && file_status = File.open(@temporary_status_file_path,'w')
        begin
          file_status.write @aggregator
          file_status.close
          log.info "Temporary information stored in temporary_status_file_path:#{@temporary_status_file_path} before shutdown"
        rescue Exception => e
          log.warn "Failed to load temporary_status_file_path:#{@temporary_status_file_path}"
          log.warn e.message
          log.warn e.backtrace.inspect
        end
      end

      super
    end

    def aggregate_events

      #log.trace @aggregator
      @aggregator_mutex.synchronize do
	data_aggregated = @data_operations.aggregate_events
        data_aggregated.each{|s_interval,data_aggregated|
          #log.trace data_aggregated
          es = MultiEventStream.new
          data_aggregated.each {|item|
             es.add(item['time'], item)
          }
          unless es.empty?
            tag="#{@aggregate_event_tag}.#{s_interval}"
            router.emit_stream(tag, es)
          end
        } if data_aggregated
      end

    #rescue Exception => e
    #  $log.error e
    end

    class TimerWatcher < Coolio::TimerWatcher
      def initialize(interval, repeat, log, &callback)
        @callback = callback
        @log = log
        super(interval, repeat)
      end
      def on_timer
        @callback.call
      rescue
        @log.error $!.to_s
        @log.error_backtrace
      end
    end
  end
end
