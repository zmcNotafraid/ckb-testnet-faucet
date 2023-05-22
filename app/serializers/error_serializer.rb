# frozen_string_literal: true

class ErrorSerializer
  include JSONAPI::Serializer

  def initialize(error)
    @error = error
  end

  def to_h
    serializable_hash
  end

  def to_json(_payload = nil)
    to_h.to_json
  end

    private
      def serializable_hash
        {
          errors: [error.serializable_hash].flatten
        }
      end

      attr_reader :error
end
