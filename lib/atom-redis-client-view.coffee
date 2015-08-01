{$, $$$, View} = require 'space-pen'
_ = require 'underscore-plus'
redis = require 'redis'
{Emitter, Disposable, CompositeDisposable} = require 'atom'

module.exports =
class RedisClientView extends View
  atom.deserializers.add(this)

  @deserialize: (state) ->
    new RedisClientView(state)

  @content: ->
    @div class: 'redis-client-view native-key-bindings', tabindex: -1, =>
      @div class: "block", =>
        @div class: "redis-setting inline-block", =>
          @div class: "block", =>
            @label class: "inline-block", for: "redis-host", "Host:"
            @input outlet: "inputRedisHost", id: "redis-host", class: 'inline-block', type: 'text', placeholder: "localhost"
          @div class: "block", =>
            @label class: "inline-block", for: "redis-port", "Port:"
            @input outlet: "inputRedisPort", id: "redis-port", class: 'inline-block', type: 'text', placeholder: "6379"
          @div class: "block", =>
            @div class: "button inline-block", =>
              @button outlet: "connectButton", id: "redis-connect", class: 'btn', "connect"
            @div class: "button inline-block", =>
              @button outlet: "disconnectButton", id: "redis-disconnect", class: 'btn', "disconnect"
        @div outlet: "redisInfo", class: "redis-info inline-block", =>
      @div class: "redis-console block", =>
        @input outlet: "redisInput", id: "redis-input", class: 'inline-block', type: 'text'
        @div class: "button inline-block", =>
          @button outlet: "execButton", id: "redis-exec", class: 'btn', "exec"
      @div outlet: "redisOutput", id: "redis-output"

  constructor: ->
    super
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

    @redisclient = redis.createClient()
    @redisclient.on "ready", =>
      @redisclient.info (err, info) =>
        return if err
        @renderServerInfo(info)

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

  execCommand: ->
    args = @redisInput.val().trim().split(/\s+/)
    method = args.shift()
    return unless _.isFunction @redisclient[method]

    args.push (err, resp) =>
      resp = JSON.stringify resp
      @redisOutput.prepend "<div>#{resp}</div>"

    @redisclient[method].apply @redisclient, args

  serialize: ->
    deserializer: 'RedisClientView'

  # 新規メソッド イベント関連のオブジェクトを破棄
  destroy: ->
    @redisclient?.quit()
    @disposables.dispose()

  getTitle: ->
    "Redis client"

  getURI: ->
    "redis-client://view"