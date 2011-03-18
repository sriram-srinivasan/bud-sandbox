require 'rubygems'
require 'bud'

module CartProtocol
  include BudModule

  state do
    # PAA -- took the '@'s off all occurrences of :server below
    channel :action_msg, 
      [:server, :client, :session, :reqid] => [:item, :action]
    channel :checkout_msg, 
      [:server, :client, :session, :reqid]
    channel :response_msg, 
      [:client, :server, :session, :item] => [:cnt]
  end
end

module CartClientProtocol
  include BudModule

  state do
    interface input, :client_checkout, [:server, :session, :reqid]
    interface input, :client_action, [:server, :session, :reqid] => [:item, :action]
    interface output, :client_response, [:client, :server, :session] => [:item, :cnt]
  end
end

module CartClient
  include CartProtocol
  include CartClientProtocol

  bloom :client do
    action_msg <~ client_action.map{|a| [a.server, @addy, a.session, a.reqid, a.item, a.action]}
    checkout_msg <~ client_checkout.map{|a| [a.server, @addy, a.session, a.reqid]}
    client_response <= response_msg.map {|r| r }
  end
end
