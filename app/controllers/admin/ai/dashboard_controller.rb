class Admin::Ai::DashboardController < Admin::Ai::BaseController
  # Keep dashboard queries bounded while still allowing a full leap year.
  MAX_DATE_RANGE_DAYS = 366

  def index
    set_date_range
    build_dashboard unless @date_range_error
  end

  private

  def set_date_range
    today = Time.zone.today
    default_start = today.beginning_of_month
    default_end = today.end_of_month

    @start_date = parse_date_param(:start_date, default_start)
    @end_date = parse_date_param(:end_date, default_end)

    if @start_date && @end_date && @end_date < @start_date
      @date_range_error = t('admin.ai.dashboard.errors.reversed_range')
    elsif @start_date && @end_date && (@end_date - @start_date).to_i + 1 > MAX_DATE_RANGE_DAYS
      @date_range_error = t('admin.ai.dashboard.errors.range_too_large', count: MAX_DATE_RANGE_DAYS)
    end

    if @date_range_error
      @rows = []
      @totals = empty_totals
      return
    end

    @start_time = @start_date.in_time_zone.beginning_of_day
    # The dates entered in the UI are inclusive; SQL uses an exclusive boundary.
    @end_time = (@end_date + 1.day).in_time_zone.beginning_of_day
  end

  def parse_date_param(name, default)
    return default unless params.key?(name)

    value = params[name].to_s
    raise ArgumentError unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Time.zone.strptime(value, '%Y-%m-%d').to_date
  rescue ArgumentError
    @date_range_error = t('admin.ai.dashboard.errors.invalid_date')
    nil
  end

  def build_dashboard
    @grouped_counts = AiTranscription.where(created_at: @start_time...@end_time)
                                     .group(:model, :status)
                                     .count
    statuses = AiTranscription.statuses.keys
    models = @grouped_counts.keys.map(&:first).uniq.sort

    @rows = models.map do |model|
      counts = statuses.index_with { |status| @grouped_counts.fetch([model, status], 0) }
      total = counts.values.sum
      { model: model, counts: counts, total: total, success_rate: percentage(counts['finished'], total) }
    end

    status_counts = statuses.index_with do |status|
      @grouped_counts.sum { |(_model, grouped_status), count| grouped_status == status ? count : 0 }
    end
    total = status_counts.values.sum
    @totals = { counts: status_counts, total: total, success_rate: percentage(status_counts['finished'], total) }
  end

  def empty_totals
    { counts: AiTranscription.statuses.keys.index_with { 0 }, total: 0, success_rate: 0.0 }
  end

  def percentage(successes, total)
    return 0.0 if total.zero?

    (successes.to_f / total * 100).round(1)
  end
end
