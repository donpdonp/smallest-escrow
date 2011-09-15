require 'dm-core'
require 'dm-redis-adapter'
require 'redis'
require 'bitbank'
require 'savon'
require 'faraday'
require 'oauth'

require 'smallest_escrow/deal'
require 'smallest_escrow/util'
require 'smallest_escrow/web'
require 'smallest_escrow/dwolla/api'
require 'smallest_escrow/dwolla/auth'

module SmallestEscrow
  Config = YAML.load(File.open('config.yml'))
end

# Datamapper
DataMapper.setup(:default, SmallestEscrow::Config["datamapper"])

# bitcoind
BITBANK = Bitbank.new(SmallestEscrow::Config["bitbank"])

# Dwolla
DWOLLA = SmallestEscrow::Dwolla::API.new(SmallestEscrow::Config["dwolla"])
