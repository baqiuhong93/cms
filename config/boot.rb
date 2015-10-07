require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'dalli'
DEFINE_APP_ID = 3
LOGIN_SUC_CODE = "_system_login_next"
SYSTEM_ADMIN_USER_NAME = "wangxiao_admin@qq.com"
PUBLIC_CACHE = Dalli::Client.new(['127.0.0.1:16080:10'],:namespace => "public@")
APP_CACHE = Dalli::Client.new(["127.0.0.1:1608#{DEFINE_APP_ID}:10"],:namespace => "app#{DEFINE_APP_ID}@")

