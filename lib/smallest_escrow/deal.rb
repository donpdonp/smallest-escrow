module SmallestEscrow
 class Deal
  include DataMapper::Resource

  property :uuid,                       String, :key => true
  property :btc,                        String
  property :btc_receiving_address,      String
  property :usd,                        String
  property :dwolla_checkout_id,         String
  property :dwolla_request_payment_key, String
  property :dwolla_tx_in,               String, :index => true
  property :dwolla_tx_refund,           String
  property :dwolla_tx_out,              String

  def self.parse(uuid, data)
    {:uuid => uuid,
     :btc => data["btc"],
     :btc_receiving_address => data["btc_receiving_address"],
     :usd => data["usd"]}
  end

  def self.true_load(uuid)
    first(:uuid => uuid)
  end

  def self.true_store(uuid, params)
    new_deal = create(self.parse(uuid, params))
  end

  def to_s
    "Deal ##{uuid}"
  end

  def usd_paid?
    !!dwolla_tx_in
  end

  def btc_transactions
    btc_tx = BITBANK.account_by_address(btc_receiving_address).transactions
  end

  def usd_transactions
    cred = SmallestEscrow::Dwolla::Auth.get_token
    dwolla_at = DWOLLA.access_token(cred)
    dwolla_tx = JSON.parse(dwolla_at.get("https://www.dwolla.com/oauth/rest/accountapi/transactions").body)
  end
 end
end

