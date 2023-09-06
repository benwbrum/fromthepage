module PageVersionsHelper
    def render_status_icon(status)

        status_translation = I18n.t("page_version.show.page_version_status_#{status}", default: status)

        if status == "transcribed" || status == "incomplete" || status == "review" || status == "blank"
            image_tag(
                "icons/#{status}-icon.svg",
                alt: "#{status_translation} Icon",
                class: "#{status}-icon",
                style: "width: 20px; height: 20px; display: inline; margin-left: 10px; margin-right: 10px;",
                title: status_translation
            )
        else
            image_tag("icons/custom-icon.svg", alt: "Custom Icon", class: "custom-icon", style: "width: 20px; height: 20px; display: inline; margin: 10px;", title: status)
        end
    end
end
