$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start { add_filter '/test/' }

require 'tech404/index'

require 'minitest/spec'
require 'mocha/mini_test'
require 'minitest/autorun'

include Tech404::Index
