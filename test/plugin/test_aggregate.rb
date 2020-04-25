require 'helper'
require 'fluent/test/driver/filter'

class AggregateFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    intervals 5s
    group_fields tx
    aggregate_fields response_ms
    aggregator_suffix_name  aggregator
    processing_mode batch
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::FilterAggregate).configure(conf)
  end

  #def test_configure1
    #assert_raise(Fluent::ConfigError) {
    # d = create_driver('')
    #}
    #assert_raise(Fluent::ConfigError) {
    #  d = create_driver %[
    #  interval 5s
    #  group_fields tx
    #  ]
    #}
    #assert_nothing_raised {
    #  d = create_driver %[
    #       intervals 5s
    #       group_fields tx
    #       aggregate_fields response_ms
    #       aggregator_suffix_name  aggregator
    #       processing_mode :batch
    #  ]
    #}
    #assert_equal 5, d.instance.interval

  #end
  def test_filter(data)
    expected, target = data
    inputs = [
      {'tx' => 'tx1', 'response_ms' => 100},
      {'tx' => 'tx1', 'response_ms' => 100},
      {'tx' => 'tx2', 'response_ms' => 200},
      {'tx' => 'tx2', 'response_ms' => 200},
      {'tx' => 'tx3', 'response_ms' => 300},
    ]
    d = create_driver(CONFIG)
    d.run(default_tag: 'test.input') do
      inputs.each do |dat|
        d.feed dat
      end
    end
    assert_equal expected, d.filtered.map{|e| e.last}.length
  end

end
