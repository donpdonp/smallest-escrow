module SmallestEscrow
  module Dwolla
    class API
      def initialize(config)
        @config = config
        @soap = Savon::Client.new { wsdl.document = "https://www.dwolla.com/api/API.svc?wsdl"}
      end

      # SOAP API
      def request_payment_key(deal)
        result = @soap.request :wsdl, :request_payment_key, 
                                     { :ApiKey => @config['soap_key'], 
                                       :ApiCode => @config['soap_secret'], 
                                       :Amount => deal.usd, 
                                       :Description => "SE:#{deal.uuid}", 
                                       :CustomerId => deal.dwolla_receiving_address }
      end

      def receiving_address
        @config['receiving_address']
      end
    end
  end
end