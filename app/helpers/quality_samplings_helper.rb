module QualitySamplingsHelper

  def approval_delta_to_display(mean_approval_delta,max_approval_delta)
    t(".approval_delta_display_#{approval_delta_to_quintile(mean_approval_delta,max_approval_delta)}")
  end
  def approval_delta_to_style(mean_approval_delta,max_approval_delta)
    "approval-delta approval-delta-#{approval_delta_to_quintile(mean_approval_delta,max_approval_delta)}"
  end
  def approval_delta_to_quintile(mean_approval_delta,max_approval_delta)
    if max_approval_delta && max_approval_delta > 0
      ((mean_approval_delta / max_approval_delta)*4).round
    else
      0
    end
  end
end
