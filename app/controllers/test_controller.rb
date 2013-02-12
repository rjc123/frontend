class TestController < ApplicationController
  def epdq
  end

  def epdq_submit
    @total = params["quantity"].to_i * 6 + params["postage_total"].to_f
    @epdq_request = EPDQ::Request.new(
      #:orderid => 2,
      :amount => (@total * 100).round,
      :currency => "GBP",
      :language => "en_GB",
      :accepturl => "http://www.dev.gov.uk/epdq-test/done"
    )
  end

  def done
    @epdq_response = EPDQ::Response.new(request.query_string)
    if @epdq_response.valid_shasign?
      @payment_id = @epdq_response.parameters[:payid]
    else
      @payment_id = "Invalid signature"
    end
  end
end
