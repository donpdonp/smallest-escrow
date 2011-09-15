# config.ru
$LOAD_PATH.unshift ::File.expand_path(::File.dirname(__FILE__) + '/lib')
require 'smallest_escrow'

map SmallestEscrow::Config["rack"]["map"] do
  run SmallestEscrow::Web
end

