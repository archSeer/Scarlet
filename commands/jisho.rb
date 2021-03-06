require 'scarlet/helpers/http_helper'
require 'scarlet/expiration_cache'

display_jisho = lambda do |value|
  data = value['data'][0, 5]
  words = data.map do |entry|
    e = entry['japanese'].first
    e['word'] || e['reading']
  end
  str = words.each_with_index.map { |*e| e.reverse.join(' ') }.join(' | ')
  reply "#{words.size} hits: #{str}"
  data.each do |entry|
    japs = entry['japanese'].map do |e|
      e['word'] ? "#{e['word']} ［#{e['reading']}］" : e['reading']
    end
    senses = entry['senses'].map do |e|
      eng = e['english_definitions']
      eng.join("; ")
    end.each_with_index.map {|d, i| "(#{i}) #{d}" }
    reply "#{japs.join(",　")}"
    reply "#{senses.join(" ")}"
    break
  end
end

hear(/jisho (?<keyword>.+)/) do
  clearance nil
  description ''
  usage 'jisho <word>'
  helpers Scarlet::HttpHelper
  on do
    keyword = params[:keyword]
    cache = Scarlet::ExpirationCache.instance.fetch(:jisho, {})
    if data = cache[keyword]
      instance_exec data, &display_jisho
    else
      http = json_request('http://jisho.org/api/v1/search/words').get query: { keyword: keyword }
      http.errback { reply "ERROR: Jisho go boom!" }
      http.callback do
        if value = http.response.value
          cache[keyword] = value
          instance_exec value, &display_jisho
        else
          reply "No response from jisho."
        end
      end
    end
  end
end
