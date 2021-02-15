# 2.1.2
  * Change white/black lists to allow/deny lists

# 2.1.1
  * Update phantomjs_options to use 'TLSv1.2'

# 2.1.0
  * Delete `driver_options` configuration key as it was never used.
  * `cleanup_all_processes` is a self method as intended to.

# 2.0.0
  * New configuration key `on_periodic_restart`.
  * CrawlerManager.cleanup_all_processes method destroy all instances of phantomjs in this machine.

  * Breaking changes
    - Requires Ruby 2.1 or later.
    - Crawler.start_crawling does not accept options anymore, all options are passed to Crawler.new.
    - Crawler's methods `restart` and `quit` have been moved to CrawlerManager.
    - Crawler gets whitelist and blacklist as configuration options instead of being set in specific methods.

# 1.6.11
  * Ensure all links are loaded by waiting for Ajax requests to complete
  * Add '@evaluate_in_each_page' option to evaluate before extracting links (e.g. $('.dropdown').addClass('open');)

# 1.6.10
  * Avoid following JS href links, add missing dependencies to fix Travis build

# 1.6.9
  * Avoid following links when disabled by CSS (1.6.8 worked only for Javascript)

# 1.6.8
  * Avoid following disabled links

# 1.6.7
  * Increment '@times_visited' first to avoid infinite retries when rescuing errors

# 1.6.6
  * Updated phantomjs_logger not to open '/dev/null'

# 1.6.5
  * Added #quit to Crawler

# 1.6.4
  * Added #quit to Capybara driver

# 1.6.3
  * Only follow visible links

# 1.6.2
  * Reset Capybara driver to Puffing Billy (used to rewrite URL requests in specs)
  * Use float timestamp for Poltergeist driver name to support fast test executions

# 1.6.1
  * Use non-static name to support registering Poltergeist crawler multiple times
  * More exception handling, store redirected URLs in addition to original URL

# 1.6
  * Support custom URL comparison when adding new pages during crawling
  * Don't rescue Timeout error, so that Delayed Job can properly terminate hanging jobs
  * Fail early if Capybara doesn't initialize properly

# 1.5.1
  * Fixed deprecation warning (Thanks scott)
  * Updated Poltergeist dependency

# 1.5.0
  * Grell will follow redirects.
  * Added #followed_redirects? #error? #current_url methods to the Page class

# 1.4.0
  * Added crawler.restart to restart browser process
  * The block of code can make grell retry any given page.

# 1.3.2
  * Rescue Timeout error and return an empty page when that happens

# 1.3.1
  * Added whitelisting and blacklisting
  * Better info in gemspec

# 1.3
  * The Crawler object allows you to provide an external logger object.
  * Clearer semantics when an error happens, special headers are returned so the user can inspect the error
  * Caveats:
    - The 'debug' option in the crawler does not have any affect anymore. Provide an external logger with 'logger' instead
    - The errors provided in the headers by grell has changed from 'grell_status' to 'grellStatus'.
    - The 'visited' property in the page was never supposed to be accesible. Use 'visited?' instead.

# 1.2.1
  * Solve bug: URLs are case insensitive

# 1.2
  * Grell now will consider two links to point to the same page only when the whole URL is exactly the same.
    Versions previously would only consider two links to be the same when they shared the path.

# 1.1.2
  * Solve bug where we were adding links in heads as if there were normal links in the body

# 1.1.1
  * Solve bug with the new data-href functionality

# 1.1
  * Solve problem with randomly failing spec
  * Search for elements with 'href' or 'data-href' to find links

# 1.0.1
  * Rescueing Javascript errors

# 1.0
  * Initial implementation
  * Basic support to crawling pages.
