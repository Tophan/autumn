# An IRC server and channel. The server property is of the form
# "[address]:[port]".

class Channel
  include DataMapper::Resource
  
  property :id, Serial
  property :server, String, :key => true
  property :name, String, :key => true
  
  has n, :scores
  
  # Returns a channel by name.
  
  def self.named(name)
    all(:name => name)
  end
end
