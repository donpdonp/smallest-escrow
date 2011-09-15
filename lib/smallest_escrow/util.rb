module SmallestEscrow
  class Util
    def self.tcp_accepting?(port)
      begin
        Socket.tcp('localhost',port) 
        true
      rescue Errno::ECONNREFUSED
        false
      end
    end
  end
end