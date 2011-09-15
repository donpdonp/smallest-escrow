module SmallestEscrow
 class Deal
  include DataMapper::Resource

  property :uuid,                       String, :key => true
  property :btc,                        String
  property :btc_receiving_address,      String
  property :usd,                        String
  property :dwolla_checkout_id,         String
  property :dwolla_request_payment_key, String
  property :dwolla_tx_id,               String

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
    !!dwolla_tx_id
  end
 end
end

