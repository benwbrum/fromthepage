module Components::InfosHelper
  def fe_infos(icon:, type: :info, &block)
    render('shared/components/info_box', icon: icon, type: type) do
      capture(&block)
    end
  end
end
