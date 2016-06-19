{React, ReactDOM} = window
{Collapse} = ReactBootstrap
__ = window.i18n.others.__.bind(i18n.others)
__n = window.i18n.others.__n.bind(i18n.others)
keyCount = 0
alertStyle = document.createElement 'style'
alertStyle.innerHTML = """
  poi-alert {
    height: 30px;
  }
  #alert-container {
    height: 30px;
  }
  #alert-main {
    height: 182px;
    overflow: hidden;
    position: relative;
    bottom: 152px;
  }
  .alert-history-hidden {
    top: 182px;
  }
"""
remote.getCurrentWindow().webContents.on 'dom-ready', (e) ->
  document.body.appendChild alertStyle

# Alert info
PoiAlert = React.createClass
  getInitialState: ->
    history = []
    for i in [0..4]
      history.push <div key={keyCount++} className='alert alert-default alert-history-contents'>　</div>
    @lastMessage = '　'
    message: __ 'Waiting for response...'
    type: 'default'
    overflow: false
    messagewidth: 0
    history: history
    showHistory: false

  updateAlert: (e, overflow, alertChanged) ->
    displayMessage = @message
    @setState
      message: displayMessage
      overflowAnim: if overflow then 'overflow-anim' else ''
    if alertChanged then @handleAlertChanged()

  alertWidthChange: (e) ->
    @alertWidth = e.detail.alertWidth
    if @state.overflowAnim isnt ''
      @message = @messageOld
    @needUpdate = true
    @updateAlert(null, @state.overflowAnim)

  handleMessageScroll: (overflow) ->
    overflowed = @state.overflowAnim isnt ''
    return if overflow is overflowed && !@needUpdate
    if overflow
      if React.isValidElement @message
        @message = <span>{@message}<span>　　　　　</span>{@message}<span>　　　　　</span></span>
      else
        @message = "#{@message}　　　　　#{@message}　　　　　"
    @updateAlert(null, overflow)

  handleAlertChanged: (e) ->
    @setState
      messageWidth: document.getElementById('alert-area').offsetWidth
    contentWidth = document.getElementById('alert-area').offsetWidth
    overflow = @alertWidth < contentWidth
    @handleMessageScroll(overflow)

  handleAlert: (e) ->
    # Format:
    #     message: <string-to-display>
    #     type: 'default'|'success'|'warning'|'danger'
    #     priority: 0-5, the higher the more important
    #     stickyFor: time in milliseconds

    # Make a message sticky to avoid from refreshing
    thisPriority = e.detail.priority || 0
    update = !@stickyEnd || @stickyEnd < (new Date).getTime()
    update = update || !@stickyPriority || @stickyPriority <= thisPriority
    if !@dontReserve
      history = @state.history
      history.push <div key={keyCount++} className='alert alert-default alert-history-contents'>{@lastMessage}</div>
      if history.length > 5 then history.shift()
      @setState {history}
    @lastMessage = e.detail.message
    @dontReserve = e.detail.dontReserve
    if (update)
      @stickyPriority = thisPriority
      if e.detail.stickyFor
        @stickyEnd = (new Date).getTime() + e.detail.stickyFor
      else
        @stickyEnd = null
      @message = e.detail.message
      @messageOld = @message
      @messageType = e.detail.type
      @updateAlert()
      @handleStyleChange()
    else if !@dontReserve
      history = @state.history
      history.push <div key={keyCount++} className='alert alert-default alert-history-contents'>{@lastMessage}</div>
      if history.length > 5 then history.shift()
      @setState {history}
      @dontReserve = true

  toggleHistory: ->
    @setState
      showHistory: !@state.showHistory

  handleStyleChange: ->
    setTimeout =>
      try
        alertHeight = $('poi-control').offsetHeight
        historyHeight = $('.alert-history').offsetHeight
      catch error
        alertHeight = 30
        historyHeight = 152
      alertStyle.innerHTML = """
        poi-alert {
          height: #{alertHeight}px;
        }
        #alert-container.alert-default, .alert-history.panel {
          background-color: #{window.getComputedStyle($('body'))?.backgroundColor};
        }
        #alert-container {
          height: #{alertHeight}px;
        }
        #alert-main {
          height: #{historyHeight + alertHeight}px;
          overflow: #{if @state.showHistory then 'auto' else 'hidden'};
          position: relative;
          bottom: #{historyHeight}px;
        }
        .alert-history-hidden {
          top: #{historyHeight + alertHeight}px;
        }
        .alert-default {
          #{if window.theme == 'paper' || window.theme == 'lumen' then 'color: #000' else ''}
        }
      """
    , 100

  componentDidMount: ->
    window.addEventListener 'poi.alert', @handleAlert
    window.addEventListener 'alert.change', @alertWidthChange
    window.addEventListener 'theme.change', @handleStyleChange
    @alertWidth = document.getElementById('alert-container').offsetWidth
    @message = @state.message
    @messageOld = @message
    @needUpdate = false
    observer = new MutationObserver(@handleAlertChanged)
    target = document.getElementById('alert-area')
    options =
      childList: true
      attributes: true
      subtree: true
    observer.observe(target, options)
    @handleStyleChange()
  componentDidUpdate: ->
    setTimeout =>
      @alertWidth = document.getElementById('alert-container').offsetWidth
    , 350
    if @needUpdate then @handleAlertChanged()
    @needUpdate = false
  componentWillUnmount: ->
    window.removeEventListener 'poi.alert', @handleAlert
    window.removeEventListener 'alert.change', @alertWidthChange
    window.removeEventListener 'theme.change', @handleStyleChange
  render: ->
    <div id='alert-main' className='alert-main'>
      <div id='alert-history'
           className="alert-history panel #{if @state.showHistory then 'alert-history-show' else 'alert-history-hidden'}"
           onClick={@toggleHistory}>
        {@state.history}
      </div>
      <div id='alert-container'
           className="alert alert-#{@messageType} alert-container"
           onClick={@toggleHistory}>
        <div className='alert-position' style={width: @state.messageWidth}>
          <span id='alert-area' className={@state.overflowAnim}>
            {@state.message}
          </span>
        </div>
      </div>
    </div>

newAlert = (details) ->
  event = new CustomEvent 'poi.alert',
    bubbles: true
    cancelable: true
    detail: details
  window.dispatchEvent event

module.exports =
  PoiAlert: PoiAlert,
  newAlert: newAlert
