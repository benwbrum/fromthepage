module PageVersionsHelper
    def render_status_icon(status)
        case status
        when "transcribed"
            image_tag("icons/circle-check-solid.svg", alt: "Conplete Icon", class: "complete-icon", style: "width: 20px; height: 20px; display: inline; margin-left: 10px;", title: status)
        when "incomplete"
            image_tag("icons/caution-icon.svg", alt: "Incomplete Icon", class: "incomplete-icon", style: "width: 20px; height: 20px; display: inline; margin-left: 10px;", title: status)
        when "review"
            image_tag("icons/magnifying-glass-solid.svg", alt: "Review Icon", class: "review-icon", style: "width: 20px; height: 20px; display: inline; margin-left: 10px;", title: status)
        when "blank"
            image_tag("icons/circle.svg", alt: "Review Icon", class: "review-icon", style: "width: 20px; height: 20px; display: inline; margin-left: 10px;", title: status)
        else
            image_tag("icons/custom-icon.svg", alt: "Custom Icon", class: "custom-icon", style: "width: 20px; height: 20px; display: inline; margin: 10px;", title: status)
        end
    end
end
