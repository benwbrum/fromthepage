class Interaction < ActiveRecord::Base
  belongs_to :collection
  belongs_to :work
  belongs_to :page
  belongs_to :user

  # 'which_where' could mean "Which where clause to use?"
  # not tested
  def self.list_sessions(which_where = 2, user_id)
    select_fields = "session_id, browser, ip_address, count(*) as total, min(created_on) as started"

    if which_where == 1
      where_clause = "user_id = #{user_id}"
    elsif which_where == 2
      where_clause = "user_id is null and " +
        "(browser not like '%google%' or '%Yahoo! Slurp%' or '%msnbot%' " +
        "or '%Twiceler%' or '%Alexa Toolbar%' or '%Baiduspider%' or '%majestic12%')"
    end

    return Interaction.select(select_fields).where(where_clause)
      .group("session_id, browser, ip_address")
      .order("started desc")
  end

end