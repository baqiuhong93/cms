class Ability
  include CanCan::Ability

  def initialize(user)
    if user.email == SYSTEM_ADMIN_USER_NAME
      can :manage, :all
    else
      user_visits = PUBLIC_CACHE.fetch("#{DEFINE_APP_ID}_user_visits_" + user.uid.to_s) do
          Net::HTTP.get(GlobalSettings.security_host, "/api/users/#{DEFINE_APP_ID}/#{user.uid}/permissions/#{user.security_key}", GlobalSettings.security_port).force_encoding('UTF-8')
      end
      user_visits = eval(user_visits.gsub(":","=>"))
      user_visits.each do |user_visit|
          can user_visit["action_name"].to_sym, user_visit["controller_name"].constantize if user_visit["rest"]
          can user_visit["action_name"].to_sym, user_visit["controller_name"].to_sym unless user_visit["rest"]
      end unless user_visits.nil?
      can :index, :home if user_visits.length > 0
    end
  end
end
