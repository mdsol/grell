# Grell

Grell is a generic crawler for the web written in Ruby.
It can be used to gather data, test pages in a given domain, etc.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grell'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grell

## Usage

Grell will yield to your code with each page it finds:

```ruby
require 'grell'

crawler = Grell::Crawler.new
crawler.start_crawling('http://www.google.com') do |page|
  puts "yeees we crawled #{page.url}"
end

```
