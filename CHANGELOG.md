* Version 1.5.0
  Grell will follow redirects.
  Added #followed_redirects? #error? #current_url methods to the Page class

* Version 1.4.0
  Added crawler.restart to restart browser process
  The block of code can make grell retry any given page.

* Version 1.3.2
  Rescue Timeout error and return an empty page when that happens

* Version 1.3.1
  Added whitelisting and blacklisting
  Better info in gemspec

* Version 1.3
  The Crawler object allows you to provide an external logger object.
  Clearer semantics when an error happens, special headers are returned so the user can inspect the error

  Caveats:
  - The 'debug' option in the crawler does not have any affect anymore. Provide an external logger with 'logger' instead
  - The errors provided in the headers by grell has changed from 'grell_status' to 'grellStatus'.
  - The 'visited' property in the page was never supposed to be accesible. Use 'visited?' instead.

* Version 1.2.1
  Solve bug: URLs are case insensitive

* Version 1.2
  Grell now will consider two links to point to the same page only when the whole URL is exactly the same.
  Versions previously would only consider two links to be the same when they shared the path.

* Version 1.1.2
  Solve bug where we were adding links in heads as if there were normal links in the body

* Version 1.1.1
  Solve bug with the new data-href functionality

* Version 1.1
  Solve problem with randomly failing spec
  Search for elements with 'href' or 'data-href' to find links

* Version 1.0.1
  Rescueing Javascript errors

* Version 1.0
  Initial implementation
  Basic support to crawling pages.
