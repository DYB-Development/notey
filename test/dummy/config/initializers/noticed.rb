ActiveSupport.on_load :noticed_event do
  before_save { self.account_id ||= Notey::Current.account_id }
end
