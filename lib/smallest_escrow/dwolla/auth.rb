module SmallestEscrow
  module Dwolla
    class Auth
      include DataMapper::Resource

      property :id, Serial
      property :token,   String
      property :secret,  String

      def self.save_token(access_token)
        auth = first || create
        auth.token = access_token.token
        auth.secret = access_token.secret
        auth.save ? auth : nil
      end

      def self.get_token
        first
      end

      def self.remove_token
        token = first
        token.destroy if token
      end

    end
  end
end
