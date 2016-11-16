# Grell

[![Build Status](https://travis-ci.org/mdsol/grell.svg?branch=develop)](https://travis-ci.org/mdsol/grell)

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

Grell uses PhantomJS as a browser, you will need to download and install it in your
system. Check for instructions in http://phantomjs.org/
Grell has been tested with PhantomJS v2.1.x

## Usage

### Crawling an entire site

The main entry point of the library is Grell::Crawler#start_crawling.
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

### Re-retrieving a page
If you want Grell to revisit a page and return the data to you again,
return the symbol :retry in your block for the start_crawling method.
For instance
```ruby
require 'grell'
crawler = Grell::Crawler.new
crawler.start_crawling('http://www.google.com') do |current_page|
  if current_page.status == 500 && current_page.retries == 0
    crawler.manager.restart
    :retry
  end
end
```

### Pages' id

Each page has an unique id, accessed by the property `id`. Also each page stores the id of the page from which we found this page, accessed by the property `parent_id`.
The page object generated by accessing the first URL passed to the start_crawling(the root) has a `parent_id` equal to `nil` and an `id` equal to 0.
Using this information it is possible to construct a directed graph.


### Restart and quit

Grell can be restarted. The current list of visited and yet-to-visit pages list are not modified when restarting
but the browser is destroyed and recreated, all cookies and local storage are lost. After restarting, crawling is resumed with a
new browser.
To destroy the crawler, call the `quit` method. This will free the memory taken in Ruby and destroys the PhantomJS process.
```ruby
require 'grell'
crawler = Grell::Crawler.new
crawler.manager.restart # restarts the browser
crawler.manager.quit # quits and destroys the crawler
```

### Options

The `Grell:Crawler` class can be passed options to customize its behavior:
- `logger`: Sets the logger object, for instance `Rails.logger`. Default: `Logger.new(STDOUT)`
- `on_periodic_restart`: Sets periodic restarts of the crawler each certain number of visits. Default: 100 pages.
- `whitelist`: Setups a whitelist filter for URLs to be visited. Default: all URLs are whitelisted.
- `blacklist`: Setups a blacklist filter for URLs to be avoided. Default: no URL is blacklisted.
- `add_match_block`: Block evaluated to consider if a given page should be part of the pages to be visited. Default: add unique URLs.
- `evaluate_in_each_page`: Javascript block to be evaluated on each page visited. Default: Nothing evaluated.
- `driver_options`: Driver options will be passed to the Capybara driver which connects to PhantomJS.

Grell by default will follow all the links it finds in the site being crawled.
It will never follow links linking outside your site.
If you want to further limit the amount of links crawled, you can use
whitelisting, blacklisting or manual filtering.
Below further details on these and other options.


#### Automatically restarting PhantomJS
If you are doing a long crawling it is possible that phantomJS gets into an inconsistent state or it starts leaking memory.
The crawler can be restarted manually by calling `crawler.manager.restart` or automatically by using the
`on_periodic_restart` configuration key as follows:

 ```ruby
 require 'grell'

 crawler = Grell::Crawler.new(on_periodic_restart: { do: my_restart_procedure, each: 200 })

 crawler.start_crawling('http://www.google.com') do |current_page|
 ...
 endd
 ```

 This code will setup the crawler to be restarted every 200 pages being crawled and to call `my_restart_procedure`
 between restarts. A restart will destroy the cookies so for instance this custom block can be used to relogin.


 #### Whitelisting

 ```ruby
 require 'grell'

 crawler = Grell::Crawler.new(whitelist: [/games\/.*/, '/fun'])
 crawler.start_crawling('http://www.google.com')
 ```

 Grell here will only follow links to games and '/fun' and ignore all
 other links. You can provide a regexp, strings (if any part of the
 string match is whitelisted) or an array with regexps and/or strings.

 #### Blacklisting

 ```ruby
 require 'grell'

 crawler = Grell::Crawler.new(blacklist: /games\/.*/)
 crawler.start_crawling('http://www.google.com')
 ```

 Similar to whitelisting. But now Grell will follow every other link in
 this site which does not go to /games/...

 If you call both whitelist and blacklist then both will apply, a link
 has to fullfill both conditions to survive. If you do not call any, then
 all links on this site will be crawled. Think of these methods as
 filters.

#### Manual link filtering

If you have a more complex use-case, you can modify the list of links
manually.
Grell yields the page to you before it adds the links to the list of
links to visit. So you can modify in your block of code "page.links" to
add and delete links to instruct Grell to add them to the list of links
to visit next.

#### Custom URL Comparison
By default, Grell will detect new URLs to visit by comparing the full URL
with the URLs of the discovered and visited links. This functionality can
be changed by passing a block of code to Grells `start_crawling` method.
In the below example, the path of the URLs (instead of the full URL) will
be compared.

```ruby
require 'grell'

add_match_block = Proc.new do |collection_page, page|
  collection_page.path == page.path
end

crawler = Grell::Crawler.new(add_match_block: add_match_block)

crawler.start_crawling('http://www.google.com') do |current_page|
...
end
```

#### Evaluate script

You can evalute a JavaScript snippet in each page before extracting links by passing the snippet to the 'evaluate_in_each_page' option:

```ruby
require 'grell'

crawler = Grell::Crawler.new(evaluate_in_each_page: "typeof jQuery !== 'undefined' && $('.dropdown').addClass('open');")

```

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
Grell is (c) Medidata Solutions Worldwide and owned by its major contributors:
* [Teruhide Hoshikawa](https://github.com/thoshikawa-mdsol)
* [Jordi Polo Carres](https://github.com/jcarres-mdsol)
