class Dwolla
  def initialize(yml_config)
    @config = YAML.load(File.open(yml_config))
    @soap = Savon::Client.new { wsdl.document = "https://www.dwolla.com/api/API.svc?wsdl"}
    @rest = Faraday.new(:url => 'https://www.dwolla.com') do |builder|
              builder.request  :json
              builder.adapter  :net_http
            end
  end

  # GRID API
  def request(deal)
    data = { :Key => @config['key'],
             :Secret => @config['secret'],
             :PurchaseOrder => {
                    :DestinationId => deal.dwolla_receiving_address,
                         :Discount => 0,
                       :OrderItems => [:Name => "Bitcoin Escrow",
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

  # SOAP API
  def request_payment_key(deal)
    result = @soap.request :wsdl, :request_payment_key, 
                                 { :ApiKey => @config['key'], 
                                   :ApiCode => @config['secret'], 
                                   :Amount => deal.usd, 
                                   :Description => "SE:#{deal.uuid}", 
                                   :CustomerId => deal.dwolla_receiving_address }
  end

  def receiving_address
    @config['receiving_address']
  end
end