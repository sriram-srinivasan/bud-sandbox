require 'rubygems'
require 'bud'
require 'bud/rendezvous'
require 'test/unit'
require 'delivery/reliable_delivery'

class RED
  include Bud
  include ReliableDelivery

  state do
    table :pipe_perm, [:dst, :src, :ident, :payload]
  end

  bloom :recall do
    pipe_perm <= pipe_sent
  end
end

class TestBEDelivery < Test::Unit::TestCase
  def ntest_delivery1
    rd = RED.new(:port => 12222, :dump => true)
    rd.run_bg

    sendtup = ['localhost:12223', 'localhost:12222', 1, 'foobar']
    rd.sync_do{ rd.pipe_in <+ [ sendtup ] }

    # transmission not 'complete'
    rd.sync_do{ assert(rd.pipe_perm.empty?) }
    rd.stop_bg
  end

  def test_besteffort_delivery2
    rd = RED.new(:port => 13333)
    rd2 = RED.new(:port => 13334)
    rd.run_bg
    rd2.run_bg
    ren = Rendezvous.new(rd, rd.pipe_sent)

    sendtup = ['localhost:13334', 'localhost:13333', 1, 'foobar']
    rd.sync_do{ rd.pipe_in <+ [ sendtup ] }
    res = ren.block_on(5)
    # transmission 'complete'
    rd.sync_do{ assert_equal(1, rd.pipe_perm.length) }

    # gc done
    rd.sync_do{ assert(rd.buf.empty?) }
    rd.stop_bg
    rd2.stop_bg
    ren.stop
  end
end
