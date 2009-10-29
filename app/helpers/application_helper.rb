# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # Method join_hash. Take a hash and return its elements joined by two delimiters
  # Used to turn a params hash into a param string: key1=value1&key2=value2
  def join_hash(hash, delim_1, delim_2)
    keys = Array.new
    hash.each {|a,b| keys << [a.to_s, b.to_s].join(delim_1)}
    return keys.join(delim_2)
  end  
  
end
