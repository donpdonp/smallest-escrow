module SmallestEscrow
  module Dwolla
    class Auth
      include DataMapper::Resource

      property :access_token,   String
      property :access_secret,  String

    end
  end
end
