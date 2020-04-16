# fluent-plugin-aggregate , a plugin for [Fluentd](http://fluentd.org)

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
