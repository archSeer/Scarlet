require 'spec_helper'
require 'scarlet/core_ext/hash'
require 'scarlet/parser'

# Scarlet's magical parser which seems to parse anything and everything irc related (possibly)
describe Scarlet::Parser do
  before :all do
    @parser = Scarlet::Parser.new('(qaohv)~&@%+')
  end

  describe '#parse_names_list' do
    it 'correctly parses response with one prefix' do
      expect(@parser.parse_names_list("@Op")).to eq ["Op", {:owner=>false, :admin=>false, :op=>true, :hop=>false, :voice=>false}]
    end

    it 'correctly parses response with multiple prefixes' do
      expect(@parser.parse_names_list("~@Speed")).to eq ["Speed", {:owner=>true, :admin=>false, :op=>true, :hop=>false, :voice=>false}]
    end

    it 'correctly parses response without prefixes' do
      expect(@parser.parse_names_list("Nick")).to eq ["Nick", {:owner=>false, :admin=>false, :op=>false, :hop=>false, :voice=>false}]
    end
  end

  describe '#parse_line' do
    it 'correctly parses a simple 001 response' do
      result = {:prefix=>"server.net", :command=>"001", :params=>["Welcome to the IRC Network Scarlet!~name@host.net"], :target=>"Scarletto"}
      expect(Scarlet::Parser.parse_line(':server.net 001 Scarletto :Welcome to the IRC Network Scarlet!~name@host.net')).to eq result
    end

    it 'parses a complex MODE response' do
      result = {:prefix=>"Speed!~Speed@lightspeed.org", :command=>"MODE", :params=>["-mivv", "Speed", "Scarletto"], :target=>"#bugs"}
      expect(Scarlet::Parser.parse_line(':Speed!~Speed@lightspeed.org MODE #bugs -mivv Speed Scarletto')).to eq result
    end
  end

  #describe '#parse_mode' do
  #  it 'parses a complex MODE list' do
  #    test = []
  #    @parser.parse_user_modes(["-miv+v", "Speed", "Scarletto", "#test"], test)
  #    test.should eq [[:remove, "m", "#test"], [:remove, "i", "#test"], [:remove, "v", "Speed"], [:add, "v", "Scarletto"]]
  #  end
  #
  #  it 'parses a MODE list targetting only the channel' do
  #    test = []
  #    @parser.parse_user_modes(["-mi", "#test"], test)
  #    test.should eq [[:remove, "m", "#test"], [:remove, "i", "#test"]]
  #  end
  #end
end
