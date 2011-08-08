class Deal
  def self.load(redis, uuid)
    redis.get("deal:#{uuid}")
  end

  def self.tore(redis, uuid, params)
    redis.set("deal:#{uuid}", params)
  end
end

