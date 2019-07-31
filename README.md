__Simple URL shortening service__

    ## Overview

    seeder.rb is run once. It creates the initial tables and
    generates a set of short urls using Ruby's built in array permutations
    of all 'safe' URI characters.

    I have only created permutations of max length 2, which results in a
    little over 5000 potential URLs.  This is due to the upper threshold
    of the Heroku free tier (max of 10K rows in the database).

    In theory we should be able to use Mean's algorithm to predict the
    next permutation, but in practicality a lookup table will always
    perform better.

    The main Sinatra application resides in app.rb where
    it defines REST end points for creating short URLs, short URL
    redirection, and the TOP 100 accessed short URLs.

    ### Background Title Scraping

    I have used the Sucker Punch gem in conjunction with Faraday for
    parsing titles in the background.  Sucker Punch is lightweight and works
    well with heroku's process model.  It uses concurrent ruby processes to
    queue jobs in the background.  Sucker Punch has the downside that it
    is all running on processes without a backing store for the queue.  Any
    type of outage with unprocessed jobs would result in lost jobs on the
    queue.  Fast and simple for a prototype like this; but unlikely I
    would use it in a production scenario.

    ## Endpoints

    __Short URL Creation__

    Short URLs can be created at the URL endpoint such as follows (using url encoding)
      curl -X POST https://salty-wildwood-68121.herokuapp.com/url -d "url=https://www.reddit.com"
      * this endpoint also accepts the application/json content type as
        an alternative *

    __Top 100__
      The top 100 URLs can be retrieved at the top endpoint
      curl https://salty-wildwood-68121.herokuapp.com/top

    __Redirect__
      Any indexed short URL will redirect to the underlying original URL
      by going to appending the short code to the end of https://salty-wildwood-68121.herokuapp.com/
      * Example - https://salty-wildwood-68121.herokuapp.com/a will
        redirect to www.yahoo.com.
