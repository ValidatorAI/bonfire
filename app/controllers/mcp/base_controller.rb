module Mcp
  class BaseController < ActionController::API
    include Mcp::Authentication
    include Mcp::ErrorHandling
  end
end
