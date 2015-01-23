class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :set_status

  def set_status
    @status = {}
    @status[:ac] = Account.count
    @status[:acc] = @status[:ac] - Account.can_used.count
    @status[:pc] = Proxy.can_used.count
  end
end
