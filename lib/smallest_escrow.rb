require 'dm-core'
require 'dm-redis-adapter'
require 'redis'

require 'smallest_escrow/deal'

# Datamapper
DataMapper.setup(:default, {:adapter  => "redis"})