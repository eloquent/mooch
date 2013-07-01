Server = require './Server'

options =
  consumerKey: process.env.MOOCH_CONSUMER_KEY
  consumerSecret: process.env.MOOCH_CONSUMER_SECRET
  port: process.env.PORT
  twitterUri: process.env.MOOCH_TWITTER_URI
server = new Server options
server.start()
