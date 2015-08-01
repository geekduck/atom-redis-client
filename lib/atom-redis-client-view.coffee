{$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
_ = require 'underscore-plus'
redis = require 'redis'
{Emitter, Disposable, CompositeDisposable} = require 'atom'

module.exports =
class RedisClientView extends View
  atom.deserializers.add(this)

  @deserialize: (state) ->
    new RedisClientView(state)

  @content: ->
    @div class: 'redis-client-view', =>
      @div class: "block", =>
        @div class: "redis-setting inline-block", =>
          @div class: "block", =>
            @label class: "inline-block", for: "redis-host", "Host:"
            @subview "inputRedisHost", new TextEditorView mini: true, placeholderText: "localhost"
          @div class: "block", =>
            @label class: "inline-block", for: "redis-port", "Port:"
            @subview "inputRedisPort", new TextEditorView mini: true, placeholderText: "6379"
          @div class: "block", =>
            @div class: "button inline-block", =>
              @button outlet: "connectButton", id: "redis-connect", class: 'btn', "connect"
            @div class: "button inline-block", =>
              @button outlet: "disconnectButton", id: "redis-disconnect", class: 'btn', "disconnect"
        @div outlet: "redisInfo", class: "redis-info inline-block", =>
      @div class: "redis-console block", =>
        @subview "redisInput", new TextEditorView mini: true
        @div class: "button inline-block", =>
          @button outlet: "execButton", id: "redis-exec", class: 'btn', "exec"
      @div outlet: "redisOutput", id: "redis-output"

  constructor: ->
    super
    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @eventHandler()

  eventHandler: ->
    @connectButton.on "click", =>
      @connect()

    @disconnectButton.on "click", =>
      @disconnect()

    @execButton.on "click", =>
      @execCommand()

  connect: ->
    @redisclient.quit() if @redisclient

    host = @inputRedisHost.getText().trim() || "localhost"
    port = @inputRedisPort.getText().trim() || "6379"
    options =
      max_attempts: 2
    @redisclient = redis.createClient port, host, options
    @redisclient.on "ready", =>
      @emitter.emit 'did-change-title'
      @redisclient.info (err, info) =>
        return if err
        @renderServerInfo(info)
    @redisclient.on "end", =>
      @emitter.emit 'did-change-title'
    @redisclient.on "error", (err) =>
      console.dir err

  renderServerInfo: (serverInfo)->
    @redisInfo.empty()
    serverInfo.split("\n").forEach (info) =>
      info.trim()
      domClass = ""
      if info.charAt(0) is "#"
        domClass = "category text-info"
      else
        domClass = "info-item"
      @redisInfo.append "<div class='#{domClass}'>#{info}</div>"

  disconnect: ->
    @redisclient?.quit()
    @redisInfo.empty()

  execCommand: ->
    args = @redisInput.getText().trim().split(/\s+/)
    method = args.shift()
    return unless _.isFunction @redisclient[method]

    args.push (err, resp) =>
      resp = JSON.stringify resp
      @redisOutput.prepend "<div>#{resp}</div>"

    @redisclient[method].apply @redisclient, args

  serialize: ->
    deserializer: 'RedisClientView'

  destroy: ->
    @redisclient?.quit()
    @disposables.dispose()

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  getTitle: ->
    if @redisclient?.ready
      "Redis client " + @redisclient.address
    else
      "Redis client"

  getURI: ->
    "redis-client://view"