express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)

server.listen(process.env.PORT || 5000);

#redis = require('redis').createClient # could use this to do SUBSCRIBE or BRPOP(?) instead of an HTTP POST

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'ejs'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + '/public')

app.configure 'development', ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true }) 

app.configure 'production', ->
  app.use express.errorHandler()

io.configure ->
  io.set "transports", ["xhr-polling"] # for Heroku. no WS :(
  io.set "polling duration", 10

io.sockets.on 'connection', (socket) ->
  io.sockets.emit 'broadcast', "new_client:#{socket.id}"

app.get '/', (req, res) ->
	res.render 'index.ejs', {host: req.headers.host}

app.post '/broadcast', (req, res) ->
	if req.body.secret == process.env.BROADCAST_SECRET
		res.send 200, 'OK' # immediately reply	
		io.sockets.emit 'broadcast', req.body.data
	else
		res.send 402, 'NOPE'