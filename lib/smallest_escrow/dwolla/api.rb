module SmallestEscrow
  module Dwolla
    class API
      def initialize(yml_config)
        @config = YAML.load(File.open(yml_config))
        @soap = Savon::Client.new { wsdl.document = "https://www.dwolla.com/api/API.svc?wsdl"}
        @rest = Faraday.new(:url => 'https://www.dwolla.com') do |builder|
                  builder.request  :json
                  builder.adapter  :net_http
                end
        @accountapi = "https://www.dwolla.com/oauth/rest/accountapi/"
        @oauth_consumer = OAuth::Consumer.new(@config['key'], 
                                              @config['secret'], 
                                              :site => "https://www.dwolla.com",
                                              :request_token_path => "/oauth/oauth.ashx",
                                              :authorize_path => "/oauth/oauth.ashx",
                                              :access_token_path => "/oauth/oauth.ashx" )
      end

      # Offsite Payments API
      def request(deal)
        data = { :Key => @config['key'],
                 :Secret => @config['secret'],
                 :OrderId => deal.uuid.gsub('-',''),
                 :Callback => @config['host']+"/dwolla/payment",
                 :Redirect => @config['host']+"/#{deal.uuid}",
                 :PurchaseOrder => {
                        :DestinationId => DWOLLA.receiving_address,
                             :Discount => 0,
                           :OrderItems => [:Name => "Bitcoin Escrow deal ##{deal.uuid}",
                                           :Price => deal.usd,
                                           :Quantity => 1],
                             :Shipping => 0,
                                  :Tax => 0,
                                :Total => deal.usd }}
        result = @rest.post('/payment/request', data)
        JSON.parse(result.body)
      end

      def checkout(id)
        "https://www.dwolla.com/payment/checkout/#{id}"
      end

      # REST API
      def request_token(scope = 'AccountAPI:transactions|AccountAPI:send')
        @oauth_consumer.get_request_token({:oauth_callback => @config['host']+"/dwolla/oauth"},
                                          {:scope => scope})
        # One time setup: admin visits @request_token.authorize_url to enable app with escrow dwolla account
      end

      def access_token(cred)
        OAuth::AccessToken.new(@oauth_consumer, cred.token, cred.secret)
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