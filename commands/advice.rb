require 'scarlet/helpers/http_command_helper'
# Ported to ruby for Scarlet from https://github.com/github/hubot-scripts/blob/master/src/scripts/advice.coffee
# Get some valuable advice from adviceslip.com

all_hope_is_lost = lambda { |c| c.reply "You're on your own bud." }
display_advice = lambda do |c, response|
  return all_hope_is_lost.call c if response.blank?
  # usually from a /advice/search
  if slips = response['slips'].presence
    c.reply slips.sample['advice']
  # usually from an /advice request
  elsif slip = response['slip']
    c.reply slip['advice']
  # nope mate, can't help ya
  else
    all_hope_is_lost.call c
  end
end

random_advice = lambda do |c|
  http = c.json_request("http://api.adviceslip.com/advice").get
  http.errback { reply 'Error' }
  http.callback do
    display_advice.call c, http.response.value
  end
end

hear (/what (?:do you|should I) do (?:when|about) (?<query>.*)/i),
  (/how do you handle (?<query>.*)/i),
  (/some advice about (?<query>.*)/i),
  (/think about (?<query>.*)/i) do
  clearance nil
  description 'Ask about the wonders of the world!'
  helpers Scarlet::HttpCommandHelper
  on do
    query = params[:query]
    http = json_request("http://api.adviceslip.com/advice/search/#{query}").get
    http.errback { reply 'Error' }
    http.callback do
      value = http.response.value.presence
      if value && !value.key?('message')
        display_advice.call self, value
      else
        random_advice.call self
      end
    end
  end
end

hear (/advice/i) do
  clearance nil
  description 'Ask for random advice.'
  usage 'advice'
  helpers Scarlet::HttpCommandHelper
  on do
    random_advice.call self
  end
end
