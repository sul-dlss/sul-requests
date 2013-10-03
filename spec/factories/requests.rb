# spec/factories/requests.rb 

FactoryGirl.define do 
  factory :not_needed_after do
    
  end
  
  factory :request do |f|   
    params = { 'ckey' => '2504272', 'home_lib' => 'SAL3', 'home_loc' => 'STACKS', 'current_loc' => 'STACKS', 'not_needed_after' => '12/20/2013' }
    blah1 = 'blah'
    blah2 = 'blah'
    #f.ckey "2504272"
    #f.home_lib "SAL3"
    #f.home_loc "STACKS"
    #f.current_loc "STACKS"
    initialize_with{ new(params, blah1, blah2 )}
  end 
end  