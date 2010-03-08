class Interaction < ActiveRecord::Base
  belongs_to :collection
  belongs_to :work
  belongs_to :page
  belongs_to :user
  
  def self.sessions_for_anonymous(limit=50, offset=0)
    condition = "user_id is null " 
    sql = session_sql(condition)

    self.connection.add_limit_offset!(sql, 
                                       { :limit => limit,
                                         :offset => offset } )
    logger.debug(sql)
    return self.connection.select_all(sql)  
  end
  
  def self.sessions_for_user(user_id, limit=50, offset=0)
    condition = "user_id = #{user_id} "
    sql = session_sql(condition)
    self.connection.add_limit_offset!(sql, 
                                       { :limit => limit,
                                         :offset => offset } )
    logger.debug(sql)
    @sessions = 
      Interaction.connection.select_all(sql)
  
  end
  
  def self.sessions_for_ip(ip_address, limit=50, offset=0)
    condition = "ip_address = '#{ip_address}' "
    sql = session_sql(condition)
    self.connection.add_limit_offset!(sql, 
                                       { :limit => limit,
                                         :offset => offset } )
    logger.debug(sql)
    @sessions = 
      Interaction.connection.select_all(sql)
  
  end
  
  def self.delete_spiders
    condition = "user_id is null " +
      "and (browser like '%google%' "+
      "or browser like '%Yahoo! Slurp%' "+ 
      "or browser like '%msnbot%' "+ 
      "or browser like '%Yandex%' "+ 
      "or browser like '%seoprofiler%' "+ 
      "or browser like '%Twiceler%' "+ 
      "or browser like '%Alexa Toolbar%' "+ 
      "or browser like '%Baiduspider%' "+ 
      "or browser like '%majestic12%' " +
      "or browser like '%Slurp%'" +
      "or browser like '%Exabot%'" +
      "or browser like '%cuil.com%'" +
      "or browser like 'DoCoMo%'" +
      "or browser like '%DotBot%'" +
      "or browser like 'Tasapspider%'" +
      "or browser like '%discobot%'" +
      "or browser like '%Purebot%'" +
      "or browser like '%Ask Jeeves/Teoma%'" +
      ")"
    Interaction.delete_all(condition)
  end

  def self.session_sql(condition)
    'select session_id, '+
    'browser, '+
    'ip_address, '+
    'count(*) as total, '+
    'min(created_on) as started '+
    'from interactions '+
    'where ' + condition +
    'group by session_id, browser, ip_address ' +
    'order by started desc '
  end
end
