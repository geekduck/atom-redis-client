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
      @div class: "redis-setting", =>
        @div class: "block", =>
          @label class: "inline-block", for: "redis-host", "Host:"
          @input outlet: "inputRedisHost", id: "redis-host", class: 'inline-block', type: 'text', placeholder: "localhost"
        @div class: "block", =>
          @label class: "inline-block", for: "redis-port", "Port:"
          @input outlet: "inputRedisPort", id: "redis-port", class: 'inline-block', type: 'text', placeholder: "6379"
        @div class: "block", =>
          @button outlet: "connectButton", id: "redis-connect", class: 'inline-block', "connect"
          @button outlet: "disconnectButton", id: "redis-disconnect", class: 'inline-block', "disconnect"
      @div class: "redis-console", =>
        @input outlet: "method", id: "redis-method", class: 'inline-block', type: 'text'
        @input outlet: "key", id: "redis-key", class: 'inline-block', type: 'text'
        @input outlet: "value", id: "redis-value", class: 'inline-block', type: 'text'
        @button outlet: "execButton", id: "redis-exec", class: 'inline-block', "exec"

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
    @redisclient.on "ready", ->
      console.dir @.server_info

  disconnect: ->
    @redisclient?.quit()

  execCommand: ->
    method = @method.val()
    if method == "set"
      @redisclient.set @key.val(), @value.val()
    else if method == "get"
      @redisclient.get @key.val() , (err, resp) ->
        console.dir resp

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