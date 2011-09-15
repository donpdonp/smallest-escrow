require 'dm-core'
require 'dm-redis-adapter'
require 'redis'
require 'bitbank'
require 'savon'
require 'faraday'
require 'oauth'

require 'smallest_escrow/deal'
require 'smallest_escrow/util'
require 'smallest_escrow/dwolla/api'
require 'smallest_escrow/dwolla/auth'

# Datamapper
DataMapper.setup(:default, {:adapter  => "redis", :host => "localhost", :port => 6380})

# bitcoind
BITBANK = Bitbank.new('bitbank.yml')

# Dwolla
DWOLLA = SmallestEscrow::Dwolla::API.new('dwolla.yml')
