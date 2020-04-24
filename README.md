# fluent-plugin-aggregate , a plugin for [Fluentd](http://fluentd.org)
[![Build Status](https://api.travis-ci.org/superguillen/fluent-plugin-aggregate.svg?branch=master)](https://api.travis-ci.org/superguillen/fluent-plugin-aggregate)

A fluentd plugin to aggregate events by fields over time.

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-aggregate'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-aggregate --no-document

## Requirements

- Ruby 2.1 or later
- fluentd v0.12 or later
- aggregate v0.0.1 or later

## Usage
### Filter plugin (@type 'aggregate')

Aggregate events grouping by fields over time.

```
<filter>
  @type aggregate
  intervals 5s
  keep_interval 1s
  group_fields field_group1,field_group2
  aggregate_fields numeric_field1, numeric_field2
  aggregations mean,median
</filter>
```
### Common parameters
### intervals
Intervals for the aggregatios, this plugin support multi interval aggregatios
```
intervals 5s,10s,20s
```
### keep_interval
Additional time to wait fof arrive events (used when events has a delay in the origin)
```
keep_interval 5s
```
### group_fields
Fields to group events (like group by in SQL)
```
group_fields tx,region
```
### aggregate_fields
Fields to apply aggregation funtions (like mean, median, sum, etc), this plugin support multiple aggregations fields.
```
aggregate_fields response_time,pressure
```
### aggregations
Aggregate funtions to apply, this plugin support multiple aggregations fields.
```
aggregations sum,min,max,mean,median,variance,standard_deviation
```
### aggregate_event_tag
#### Default: aggregate
Tag prefix for events generated in the aggregation process. Full tag format is #{aggregate_event_tag}.#{interval}.
```
aggregate_event_tag aggregate
```
### Example
Example with dummy input.
```
<system>
  workers 1
</system>
<source>
  @type dummy
  dummy {"tx":"test", "response_ms":500}
  tag test
  rate 1
</source>
<filter test>
  @type aggregate
  intervals 5s,10s
  keep_interval 1s
  group_fields tx
  aggregate_fields response_ms
  aggregator_suffix_name "aggregator#{worker_id}"
  aggregate_event_tag aggregate
</filter>
<match test>
  @type stdout
</match>
<match aggregate.**>
  @type stdout
</match>
```
### Advanced parameters
### time_field
#### Default: timestamp
Field that conatins time for the event.
```
time_field timestamp
```
### time_format
#### Default: %Y-%m-%dT%H:%M:%S.%L%:z
Time format for the time_field.
```
time_format %Y-%m-%dT%H:%M:%S.%L%:z
```
### output_time_format
#### Default: %Y-%m-%dT%H:%M:%S.%L%:z
Time format for the generated aggregated event.
```
output_time_format %Y-%m-%dT%H:%M:%S.%L%:z
```
### field_no_data_value
#### Default: no_data
The value for group fields in the aggregate event no present in the original event.
```
field_no_data_value no_data
```
### emit_original_message
#### Default: true
The value for group fields in the aggregate event no present in the original event.
```
emit_original_message true
```
### temporary_status_file_path
#### Default: nil
File to store aggregate information when the agent down.
```
temporary_status_file_path path_to_file.json
```
### load_temporarystatus_file_enabled
#### Default: true
Load file #{temporary_status_file_path} on startup.
```
load_temporarystatus_file_enabled true
```
