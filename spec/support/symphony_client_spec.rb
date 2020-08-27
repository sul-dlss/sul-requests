# frozen_string_literal: true

def stub_symphony(method, response)
  allow_any_instance_of(SymphonyClient).to receive(method).and_return(response)
end
