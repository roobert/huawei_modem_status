#!/usr/bin/env ruby

# inspiration: https://github.com/trick77/huawei-hilink-status/

require "httparty"

class Modem
  include HTTParty

  def initialize(base_uri)
    self.class.base_uri(base_uri)
  end

  def signal_level
    status["SignalIcon"]
  end

  def signal_strength
    status["SignalStrength"]
  end

  def roaming_status
    status["RoamingStatus"]
  end

  def wan_ip
    status["WanIPAddress"]
  end

  def wifi_status
    status["WifiStatus"]
  end

  def connection_type
    Connection.type(status["CurrentNetworkType"].to_i)
  end

  def connection_status
    Connection.status(status["ConnectionStatus"].to_i)
  end

  def wan_users_current
    status["CurrentWifiUser"]
  end

  def wan_users_max
    status["TotalWifiUser"]
  end

  def status
    get_xml("/api/monitoring/status")["response"]
  end

  def plan
    get("/api/net/current-plmn")
  end

  def notifications
    get("/api/monitoring/check-notifications")
  end

  private

  def get_xml(path)
    MultiXml.parse(get(path))
  end

  # FIXME: check for 200
  def get(path)
    self.class.get(path, headers: { "Cookie" => cookie })
  end

  def cookie
    @cookie ||= parse_cookie(self.class.get("/html/home.html")).to_cookie_string
  end

  def parse_cookie(response)
    cookie_hash = CookieHash.new
    response.get_fields('Set-Cookie').each { |c| cookie_hash.add_cookies(c) }
    cookie_hash
  end

  module Connection
    def self.type(v)
      case v
      when 0;   "No Service"
      when 1;   "GSM"
      when 2;   "GPRS (2.5G)"
      when 3;   "EDGE (2.75G)"
      when 4;   "WCDMA (3G)"
      when 5;   "HSDPA (3G)"
      when 6;   "HSUPA (3G)"
      when 7;   "HSPA (3G)"
      when 8;   "TD-SCDMA (3G)"
      when 9;   "HSPA+ (4G)"
      when 10;  "EV-DO rev. 0"
      when 11;  "EV-DO rev. A"
      when 12;  "EV-DO rev. B"
      when 13;  "1xRTT"
      when 14;  "UMB"
      when 15;  "1xEVDV"
      when 16;  "3xRTT"
      when 17;  "HSPA+ 64QAM"
      when 18;  "HSPA+ MIMO"
      when 19;  "LTE (4G)"
      when 41;  "UMTS (3G)"
      when 44;  "HSPA (3G)"
      when 45;  "HSPA+ (3G)"
      when 46;  "DC-HSPA+ (3G)"
      when 64;  "HSPA (3G)"
      when 65;  "HSPA+ (3G)"
      when 101; "LTE (4G)"
      else
        "unknown type: #{v}"
      end
    end

    def self.status(v)
      case v
      when 2, 3, 5, 8, 20, 21, 23, 27..33
       "Connection failed, the profile is invalid"
      when 7, 11, 14, 37
        "Network access not allowed"
      when 12, 13
        "Connection failed, roaming not allowed"
      when 201
        "Connection failed, bandwidth exceeded"
      when 900
        "Connecting"
      when 901
        "Connected"
      when 902
        "Disconnected"
      when 903
        "Disconnecting"
      when 904
        "Connection failed or disabled"
      else
        "unknown: #{v}"
      end
    end
  end
end

m = Modem.new("192.168.8.1")

puts m.signal_level
puts m.connection_type
puts m.connection_status
