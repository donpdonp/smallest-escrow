class Deal
  attr_accessor :uuid

  def to_s
    "#{@uuid} -> "
  end

  def parse(uuid, data)
    @uuid = uuid
  end

  def self.load(redis, uuid)
    data = eval redis.get("deal:#{uuid}")
    deal = Deal.new
    deal.parse(uuid, data)
    deal
  end

  def self.store(redis, uuid, params)
    redis.set("deal:#{uuid}", params)
    load(redis, uuid)
  end
end

