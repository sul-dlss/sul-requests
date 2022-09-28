# frozen_string_literal: true

# Common Symphony record model behaviors
class SymphonyBase
  class_attribute :symphony_client, default: SymphonyClient.new

  attr_reader :response

  def initialize(response = {})
    @response = response || {}
  end

  def key
    response['key']
  end

  def exists?
    fields.present?
  end

  def fields
    response['fields'] || {}
  end
end
