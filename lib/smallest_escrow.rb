require 'dm-core'
require 'dm-redis-adapter'
require 'redis'

require 'smallest_escrow/deal'

DataMapper.setup(:default, {:adapter  => "redis"})