require "slimmer/headers"

class CampaignController < ApplicationController

  before_filter :setup_slimmer_artefact
  before_filter :set_expiry

  def unimoney
  end

  def workplace_pensions
  end

  def uk_welcomes
  end

  def sort_my_tax
  end

  def new_licence_rules
  end

  def fire_kills
  end

  def know_before_you_go
  end

  def business_support
  end

protected
  def setup_slimmer_artefact
    set_slimmer_headers(format: 'campaign')
  end

end
