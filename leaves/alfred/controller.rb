# Controller for the alfred leaf.

require 'net/http'
require 'uri'

class Alfred
  attr_accessor :api_key

  def initialize
    @api_key = ''
  end

  def login(username, password)
    json = request('Alfred.Login', { :username => username, :password => password })

    @api_key = json['data']['key']
  end

  def request(method, params = {})
    data = '{"alfred":"0.1","key":"' + @api_key + '","method":"' + method +
      '","params":{' + params.map{|key,value| "\"#{key}\":\"#{value}\"" }.flatten.join(',') + '}}'
    uri = URI.parse('http://alf.re/d/')

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = data

    response = http.request(request)

    JSON.parse(response.body)
  end
end

class Controller < Autumn::Leaf
  attr_accessor :alfred

  def did_start_up
    @alfred = Alfred.new
    @alfred.login('guest', 'hunter2')
  end

  def food_command(stem, sender, reply_to, msg)
    food
  end

  def wmtu_command(stem, sender, reply_to, msg)
    wmtu
  end

  def weather_command(stem, sender, reply_to, msg)
    weather(msg)
  end

  def money_command(stem, sender, reply_to, msg)
    data = msg.split(' in ')
    amount = data[0].split(' ')[0]
    from = data[0].split(' ')[1]
    to = data[1]

    money(amount, from, to)
  end

  def ping_command(stem, sender, reply_to, msg)
    if msg.nil?
      "Please specify a host"
    else
      data = alfred.request('Net.Ping', { :host => msg })
      data['data']['response']
    end
  end

  def dig_command(stem, sender, reply_to, msg)
    if msg.nil?
      "Please specify a host"
    else
      data = alfred.request('Net.DNS', { :host => msg })
      data['data']['response']
    end
  end

  def shorten_command(stem, sender, reply_to, msg)
    if msg.nil?
      "Please provide a URL"
    else
      data = alfred.request('Net.Shorten', { :url => msg })
      data['data']['url']
    end
  end

  def lmgtfy_command(stem, sender, reply_to, msg)
    if msg.nil?
      "Please provide a query"
    else
      data = alfred.request('Net.LMGTFY', { :text => msg })
      data['data']['url']
    end
  end

  def lasttweet_command(stem, sender, reply_to, msg)
    if msg.nil?
      "Please provide a username"
    else
      data = alfred.request('Net.Twitter.LastTweet', { :user => msg })
      data['data']['tweet']
    end
  end

  def status_command(stem, sender, reply_to, msg)
    if msg.nil?
      "Please provide a service"
    else
      msg = msg.downcase
      if msg == 'heroku'
        data = alfred.request('Net.Heroku.Status')
        "Production: #{data['data']['status']['Production']}, Development: #{data['data']['status']['Development']}"
      elsif msg == 'github'
        data = alfred.request('Net.Github.Status')
        "As of #{data['data']['time']}: #{data['data']['description']}"
      elsif msg == 'bitbucket'
        data = alfred.request('Net.Bitbucket.Status')
        "As of #{data['data']['time']}: #{data['data']['description']}"
      else
        "Unknown service"
      end
    end
  end

  def food
    data = alfred.request('MTU.Dining')
    var :breakfast => data['data']['breakfast']
    var :lunch => data['data']['lunch']
    var :dinner => data['data']['dinner']
  end

  def money(amount, from, to)
    data = alfred.request('Location.Currency', { :amount => amount, :from => from, :to => to })
    var :amount => data['data']['amount']
    var :to => to
  end

  def weather(zip)
    if zip.nil? || zip == ''
      data = alfred.request('Location.Weather')
    else
      data = alfred.request('Location.Weather', { :zip => zip })
    end
    var :location => data['data']['location']
    var :temp => data['data']['temp']
    var :text => data['data']['text']
  end

  def wmtu
    data = alfred.request('MTU.WMTU')
    var :song => data['data']['song']
    var :artist => data['data']['artist']
    var :album => data['data']['album']
  end
end
