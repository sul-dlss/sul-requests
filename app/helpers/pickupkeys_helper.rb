module PickupkeysHelper
  
  def get_lib_codes_for_pickupkeys( pk_libs )
    
    lib_list = ''
    
    pk_libs.each do |l|
      lib_list = lib_list + l.lib_code + ' '
    end
    
    return lib_list
    
  end
end
