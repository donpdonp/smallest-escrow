require 'dm-core'
require 'dm-redis-adapter'
require 'redis'
require 'bitbank'
require 'savon'

require 'smallest_escrow/deal'

# Datamapper
DataMapper.setup(:default, {:adapter  => "redis", :host => "localhost", :port => 6380})

# bitcoind
BITBANK = Bitbank.new('bitbank.yml')

# Dwolla
DWOLLA = Dwolla.new('dwolla.yml')
