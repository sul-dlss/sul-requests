# frozen_string_literal: true

###
#  Class to handle dashboard metrics
###
class Dashboard
  def metrics
    [:hold_recalls, :mediated_pages, :pages, :scans].select do |metric|
      send(metric) > 0
    end
  end

  def hold_recalls
    @hold_recall ||= HoldRecall.count
  end

  def mediated_pages
    @mediated_pages ||= MediatedPage.count
  end

  def pages
    @pages ||= Page.count
  end

  def scans
    @scans ||= Scan.count
  end

  def recent_requests(page, per)
    @recent_requests ||= Request.page(page).per(per).recent.includes(:user)
  end
end
