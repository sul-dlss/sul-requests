module Admin::PickupkeysHelper
  
  def get_lib_codes_for_pickupkeys( pk_libs )
    
    lib_list = ''
    
    pk_libs_sorted = pk_libs.sort_by { |c| c['lib_code'] }
    
    pk_libs_sorted.each do |l|
      lib_list = lib_list + l.lib_code + ' '
    end
    
    return lib_list
    
  end
end
