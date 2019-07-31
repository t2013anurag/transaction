# frozen_string_literal: true

def symbolize_keys!(response = {})
  response.keys.each do |key|
    response[(begin
                key.to_sym
              rescue StandardError
                key
              end) || key] = response.delete(key)
  end

  response
end
