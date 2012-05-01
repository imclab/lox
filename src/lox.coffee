routes = require './routes'

User = null

setUser = (req, res, next) ->
  if (req.session.user)
    getUser req.session.user, (err, user) ->
      req.user = user
      res.locals {user}
      next err, user
  else do next

connect = (mongoDb) ->
  connection = require('./db')(mongoDb)
  User = connect.User = require('./user')(connection)

  (req, res, next) ->
    unless req.session
      next new Error "Express Session middleware required for auth"
    req.login = login(req, res)
    req.logout = logout(req, res)
    setUser req, res, next

login = (req, res) ->
  (email, password = "", callback) ->
    getUser email, (err, user) ->
      callback err if err
      if user?.verify(password)
        req.session.user = user.email
      setUser req, res, (err, user) ->
        callback(err, user)

logout = (req, res) ->
  (callback) ->
    req.user = null
    do req.session.destroy
    do callback

getUser = (query, callback) ->
  if typeof query is "string"
    query = email: query
  User.findOne query, callback

create = (email, password, callback) ->
  new User({email, password}).save (err) -> callback(err)

destroy = (query, callback) ->
  getUser query, (err, user) ->
    if user then user.remove callback(null, user)
    else callback err

find = (query, callback) ->
  unless callback
    callback = query
    query = {}
  User.find query, (err, users) -> callback(err, users)

module.exports = connect
connect.middleware = connect
connect.login = login
connect.logout = logout
connect.getUser = getUser
connect.create = create
connect.destroy = destroy
connect.find = find
connect.routes = routes