class Dwolla
  def initialize(yml_config)
    @config = YAML.load(File.open(yml_config))
    @api = Savon::Client.new { wsdl.document = "https://www.dwolla.com/api/API.svc?wsdl"}
  end

  def request_payment_key(deal)
    result = @api.request :wsdl, :request_payment_key, 
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