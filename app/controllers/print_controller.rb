class PrintController < ApplicationController
  def make_pdf
    string = render_without_rtex
    #string = render_to_string
    logger.debug(string)
    erase_render_results
    @printed_before = nil
    forget_variables_added_to_assigns
    reset_variables_added_to_assigns
    render_with_rtex
  end
end
