module Components::TimeagoHelper
  def fe_timeago(time:, classes: 'legend legend-left')
    classes = [classes, 'timeago'].compact.join(' ')

    render('shared/components/timeago', time: time, classes: classes)
  end
end
