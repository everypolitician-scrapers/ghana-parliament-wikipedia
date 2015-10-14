#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(term, url)
  warn term
  noko = noko_for(url)
  rows = noko.xpath('//table[.//th[text()="Constituency"]]//tr[td]')

  rows.each do |tr|
    td = tr.css('td')
    next unless td[3]
    tr.css('sup').remove
    data = { 
      name: td[1].text.lines.first.tidy,
      constituency: td[0].text.lines.first.tidy,
      region: tr.xpath('preceding-sibling::tr[td[@colspan="6"]]').last.text.split(' - ').first.tidy,
      wikiname: td[1].xpath('.//a[not(@class="new")]/@title').text.strip,
      party: td[2].text.tidy,
      term: term,
      source: url,
    }
    data.delete :wikiname if data[:wikiname].include? 'constituency'
    data[:area] = "%s (%s)" % [data[:constituency], data[:region]]
    ScraperWiki.save_sqlite([:name, :constituency, :party, :term], data)
  end
end

scrape_list(6, 'https://en.wikipedia.org/wiki/MPs_elected_in_the_Ghanaian_parliamentary_election,_2012')
scrape_list(5, 'https://en.wikipedia.org/wiki/MPs_elected_in_the_Ghanaian_parliamentary_election,_2008')
scrape_list(4, 'https://en.wikipedia.org/wiki/MPs_elected_in_the_Ghanaian_parliamentary_election,_2004')
scrape_list(3, 'https://en.wikipedia.org/wiki/MPs_elected_in_the_Ghanaian_parliamentary_election,_2000')
scrape_list(2, 'https://en.wikipedia.org/wiki/MPs_elected_in_the_Ghanaian_parliamentary_election,_1996')
