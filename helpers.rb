# frozen_string_literal: true

class Hash
  def symbolize_keys
    transform_keys(&:to_sym)
  end
end

class String
  def date?
    !!(self =~ /\d{1,2}\.\d{1,2}\.\d{2,4}/)
  end
end
