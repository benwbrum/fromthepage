FactoryGirl.define do

  factory :interaction1, class: Interaction do
    user_id 1
    collection_id 1
    work_id 1
    page_id 1
    action 'session_list'
    params  '{"offset"=>"50", "ol"=>"adm_sl_next50", "controller"=>"admin", "action"=>"session_list"}'
    browser 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:19.0) Gecko/20100101 Firefox/19.0'
    session_id '2112'
    ip_address '127.0.0.1'
    status 'incomplete'
  end

end
