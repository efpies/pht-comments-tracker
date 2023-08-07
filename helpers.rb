# frozen_string_literal: true

class Hash
  def symbolize_keys
    transform_keys(&:to_sym)
  end
end
