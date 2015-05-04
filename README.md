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

Grell uses PhantomJS, you will need to download and install it in your
system. Check for instructions in http://phantomjs.org/
Grell has been tested with PhantomJS v1.9.x

## Usage


### Crawling an entire site

The main entry point of the library is Grell#start_crawling.
Grell will yield to your code with each page it finds:

```ruby
require 'grell'

crawler = Grell::Crawler.new
crawler.start_crawling('http://www.google.com') do |page|
  #Grell will keep iterating this block which each unique page it finds
  puts "yes we crawled #{page.url}"
  puts "status: #{page.status}"
  puts "headers: #{page.headers}"
  puts "body: #{page.body}"
  puts "We crawled it at #{page.timestamp}"
  puts "We found #{page.links.size} links"
  puts "page id and parent_id #{page.id}, #{page.parent_id}"
end

```

Grell keeps a list of pages previously crawled and do not visit the same page twice.
This list is indexed by the complete url, including query parameters.

### Pages' id

Each page has an unique id, accessed by the property 'id'. Also each page stores the id of the page from which we found this page, accessed by the property 'parent_id'.
The page object generated by accessing the first URL passed to the start_crawling(the root) has a 'parent_id' equal to 'nil' and an 'id' equal to 0.
Using this information it is possible to construct a directed graph.


### Errors
When there is an error in the page or an internal error in the crawler (Javascript crashed the browser, etc). Grell will return with status 404 and the headers will have the following keys:
- grellStatus: 'Error'
- errorClass: The class of the error which broke this page.
- errorMessage: A descriptive message with the information Grell could gather about the error.


## Tests

Run the tests with
```ruby
bundle exec rake ci
```

## Contributors
* [Teruhide Hoshikawa](https://github.com/thoshikawa-mdsol)
* [Jordi Carres](https://github.com/jcarres-mdsol)
