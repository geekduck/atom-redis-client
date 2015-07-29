url = require 'url'
RedisClientView = require './atom-redis-client-view'
{CompositeDisposable} = require 'atom'

module.exports = RedisClient =
  subscriptions: null
  protocol: ""

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'redis-client:open': => @open()

    atom.workspace.addOpener (uriToOpen) =>
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return
      return unless protocol is "redis-client:"

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is "view"
        new RedisClientView

  deactivate: ->
    @subscriptions.dispose()

  open: ->
    atom.workspace.open("redis-client://view/")
