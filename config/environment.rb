# encoding: utf-8
# Load the rails application
require File.expand_path('../application', __FILE__)
require 'josh_id'
# Initialize the rails application
Cms::Application.initialize!

require 'will_paginate'
WillPaginate::ViewHelpers.pagination_options[:previous_label] = '上一页'
WillPaginate::ViewHelpers.pagination_options[:next_label] = '下一页'
