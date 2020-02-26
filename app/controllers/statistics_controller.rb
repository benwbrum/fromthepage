require 'csv'

class StatisticsController < ApplicationController

  def collection
    @works = @collection.works
    @stats = @collection.get_stats_hash
    @recent_stats = @collection.get_stats_hash(7.days.ago)
  #  @works.sort { |w1, w2| w2.work_statistic.pct_transcribed <=> w1.work_statistic.pct_transcribed }

    @users = User.all
    @all_transcribers = build_user_array(DeedType::PAGE_TRANSCRIPTION)
    @all_editors      = build_user_array(DeedType::PAGE_EDIT)
    @all_indexers     = build_user_array(DeedType::PAGE_INDEXED)
  end

  def export_csv
    rows = []
    header = ['User Login', 'User Name', 'Email', 'Opt-In']
    owner = User.find 'ushmmarchives'
    collection_ids = owner.collections.map { |c| c.id }.sort
    deed_map = Deed.where(:collection_id => collection_ids).group(:user_id, :collection_id).count
    user_ids = deed_map.keys.map {|e| e[0]}.uniq
    Collection.where(:id => collection_ids).order(:id).each { |c| header << c.title }

    User.find(user_ids).each do |user|
      row = []
      row << user.login
      row << user.display_name
      row << user.email
      row << user.activity_email

      collection_ids.each do |collection_id|
        row << deed_map[[user.id,collection_id]] || 0
      end

      rows << row
    end

    csv_string = CSV.generate(headers: true) do |csv|
      csv << header

      rows.each do |row|
        csv << row
      end
    end

    send_data csv_string, filename: "ushmm_users.csv"
  end

  private
  def build_user_array(deed_type)
    user_array = []
    deeds_by_user = Deed.group('user_id').where(work_id: @collection.works.ids).where(deed_type: deed_type).order('count_id desc').count('id')
    deeds_by_user.each { |user_id, count| user_array << [ @users.find { |u| u.id == user_id }, count ] }

    return user_array
  end

end
