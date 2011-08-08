
class Deal
  include DataMapper::Resource

  property :uuid,   String, :key => true
  property :btc,    String
  property :usd,    String

  def to_s
    "Deal ##{uuid}"
  end

  def self.parse(uuid, data)
    {:uuid => uuid,
     :btc => data["btc"],
     :usd => data["usd"]}
  end

  def self.true_load(uuid)
    first(:uuid => uuid)
  end

  def self.true_store(uuid, params)
    new_deal = create(self.parse(uuid, params))
  end
end

