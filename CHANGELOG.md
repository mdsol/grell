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
