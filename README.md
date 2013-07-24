# Mooch

*A simple Twitter OAuth proxy.*

[![Build Status]][Latest build]
[![Coverage Status]][Test coverage report]

## What is Mooch?

*Mooch* is a simple app designed to allow unauthenticated access to the [Twitter
API] for web apps that have no server-side components. *Mooch* is designed to be
deployed as a [Heroku] app, which makes deployment of a new *Mooch* service
extremely simple.

## Why is this necessary?

In June 2013, [Twitter officially retired version 1.0 of their API]. Since
version 1.1 of the Twitter API [requires OAuth authentication for every
request], this effectively meant the end of client-side only, unauthenticated
Twitter applications.

This is still the case. It is *still* impossible to write a secure, client-side
only application that uses the Twitter API without forcing users to log in via
Twitter, even for information that is publicly available without authentication
from the Twitter website. That's where *Mooch* comes in.

*Mooch* is the simplest possible server-side component for creating primarily
client-side Twitter applications.

## Demo *Mooch* service

For a demonstration of *Mooch*'s capabilities, check out the [example *Mooch*
service]. This service only allows access to the tweets of [@CountingCrows_];
all other accounts will result in a 403 error.

## Setup

Setting up a new *Mooch* service is very simple, and utilizes [Heroku]. The
deployment process requires the [Heroku Toolbelt] application.

### Step 1: Create a Twitter app

- Visit https://dev.twitter.com/.
- Sign in with a Twitter account.
- [Create a new application].

### Step 2: Get *Mooch*

- Clone the Git repository (`git clone git@github.com:eloquent/mooch.git`).
- Change into the *Mooch* root directory.
- Check out the master branch (`git checkout master`).

### Step 3: Create a Heroku app

- Sign in with [Heroku Toolbelt][] (`heroku login`).
- Create a new app with `heroku create`.

### Step 4: Configuration

#### Step 4.1: Set up OAuth credentials

Variables: **MOOCH_CONSUMER_KEY** and **MOOCH_CONSUMER_SECRET**.

*Mooch* authenticates requests to the Twitter API using the [application-only
authentication] method. This requires the consumer key and secret from the
Twitter application created in [step 1].

##### Example authentication configuration

    heroku config:set MOOCH_CONSUMER_KEY=xvz1evFS4wEEPTGEFPHBog
    heroku config:set MOOCH_CONSUMER_SECRET=L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg

#### Step 4.2: (optional): Set up allowed and forbidden paths

Variables: **MOOCH_ALLOW** and **MOOCH_DENY**.

By default *Mooch* allows access to any part of the Twitter API. This is not
always ideal as anyone could find and use the service for their own
requirements, potentially contributing to the Twitter application being rate
limited.

*Mooch* uses a simple 'whitelist' (MOOCH_ALLOW) and 'blacklist' (MOOCH_DENY) of
regular expressions to restrict access. Any incoming request that is disallowed
will be immediately sent a HTTP 403 response with an imitation Twitter API
[error response] as the body.

*Mooch* accepts these lists as a [JSON] array of regular expression strings
suitable for passing to JavaScript's [RegExp] constructor. In other words, do
not surround the expressions in forward slashes ('/'), and there is no need to
escape forward slashes within expressions either. Remember that backslashes are
also used by [JSON] for escaping, so to pass a single backslash to the [RegExp]
constructor requires two backslashes in the [JSON] string.

*Mooch* first tries to find a matching 'allow' pattern for the request. If
*none* of the patterns match, the request is denied. *Mooch* then tries to find
a matching 'deny' pattern for the request. If *any* of the patterns match, the
request is denied.

##### Example access control configuration

This configuration would allow access to any user's timeline or statuses, with
the exclusion of Justin Bieber.

    heroku config:set MOOCH_ALLOW='["^/1\\.1/statuses/user_timeline\\.json","^/1\\.1/statuses/show\\.json"]'
    heroku config:set MOOCH_DENY='["\\bscreen_name=justinbieber\\b"]'

### Step 5: Deploy

- `git push heroku master`

The new *Mooch* service should now be ready for use. Check the [Heroku
dashboard] for the service's location.

## Running locally

*Mooch* can be started locally using `npm start`, but it requires some
environment variables to be present. Fortunately it is possible to do all of
this in a single line (at least in bash):

    MOOCH_CONSUMER_KEY=xvz1evFS4wEEPTGEFPHBog MOOCH_CONSUMER_SECRET=L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg npm start

<!-- References -->
[@CountingCrows_]: https://twitter.com/CountingCrows_
[application-only authentication]: https://dev.twitter.com/docs/auth/application-only-auth
[Build Status]: https://api.travis-ci.org/eloquent/mooch.png
[Coverage Status]: https://coveralls.io/repos/eloquent/mooch/badge.png
[Create a new application]: https://dev.twitter.com/apps/new
[error response]: https://dev.twitter.com/docs/error-codes-responses
[example *Mooch* service]: http://mooch-demo.herokuapp.com/1.1/statuses/user_timeline.json?screen_name=CountingCrows_
[Heroku dashboard]: https://dashboard.heroku.com/
[Heroku Toolbelt]: https://toolbelt.heroku.com/
[Heroku]: https://www.heroku.com/
[JSON]: http://en.wikipedia.org/wiki/JSON
[Latest build]: http://travis-ci.org/eloquent/mooch
[latest release]: https://github.com/eloquent/mooch/archive/master.zip
[OAuth]: http://oauth.net/
[RegExp]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp
[requires OAuth authentication for every request]: https://dev.twitter.com/docs/api/1.1/overview#Authentication_required_on_all_endpoints
[step 1]: #step-1-create-a-twitter-app
[Test coverage report]: https://coveralls.io/r/eloquent/mooch
[Twitter API]: https://dev.twitter.com/docs/api
[Twitter officially retired version 1.0 of their API]: https://dev.twitter.com/blog/api-v1-is-retired
