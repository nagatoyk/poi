{BrowserWindow} = require 'electron'
path = require 'path'
global.windows = windows = []
global.windowsIndex = windowsIndex = {}

forceClose = false
state = []  # Window state before hide
hidden = false
pluginUnload = false

module.exports =
  createWindow: (options) ->
    options = Object.assign
      show: false
      icon: path.join ROOT, 'assets', 'icons', 'poi.ico'
      webPreferences:
        plugins: true
    , options
    current = new BrowserWindow options
    if options.indexName?
      windowsIndex[options.indexName] = current
    current.setMenu options.menu || null
    current.reloadArea = null
    show = current.show
    current.show = ->
      if current.isMinimized()
        current.restore()
      else
        show.call(current)
    # Disable OSX zoom
    current.webContents.on 'dom-ready', ->
      current.webContents.executeJavaScript '''
        require('electron').webFrame.setZoomLevelLimits(1, 1);
      '''
    # Close window really
    if options.realClose
      current.on 'closed', (e) ->
        if options.indexName?
          delete windowsIndex[options.indexName]
        idx = windows.indexOf current
        windows.splice idx, 1
    else if options.forceMinimize
      current.on 'close', (e) ->
        current.minimize()
        e.preventDefault() unless forceClose || pluginUnload
      current.on 'closed', (e) ->
        pluginUnload = false
        if options.indexName?
          delete windowsIndex[options.indexName]
        idx = windows.indexOf current
        windows.splice idx, 1
    else
      current.on 'close', (e) ->
        if current.isFullScreen()
          current.once 'leave-full-screen', current.hide
          current.setFullScreen(false)
        else
          current.hide()
        e.preventDefault() unless forceClose || pluginUnload
      current.on 'closed', (e) ->
        pluginUnload = false
        if options.indexName?
          delete windowsIndex[options.indexName]
        idx = windows.indexOf current
        windows.splice idx, 1
    # Draggable
    unless options.navigatable
      current.webContents.on 'will-navigate', (e) ->
        e.preventDefault()
    windows.push current
    return current
  # Warning: Don't call this method manually
  # It will be called before mainWindow closed
  closeWindows: ->
    forceClose = true
    for win, i in windows
      continue unless win?
      win.close()
      windows[i] = null
  closeWindow: (win) ->
    pluginUnload = true
    win.close()
  rememberMain: ->
    win = global.mainWindow
    win.setResizable true # Remove after https://github.com/atom/electron/issues/4483 is fixed
    isFullScreen = win.isFullScreen()
    win.setFullScreen(false) if isFullScreen
    isMaximized = win.isMaximized() # This must be checked AFTER exiting full screen
    win.unmaximize() if isMaximized
    b = win.getBounds()
    b.isFullScreen = isFullScreen
    b.isMaximized = isMaximized
    require('./config').set 'poi.window', b
  toggleAllWindowsVisibility: ->
    for w in BrowserWindow.getAllWindows()
      if !hidden
        state[w.id] = w.isVisible()
        w.hide()
      else
        w.show() if state[w.id]
    hidden = !hidden
  openFocusedWindowDevTools: ->
    BrowserWindow.getFocusedWindow()?.openDevTools
      detach: true
  getWindowsIndex: ->
    return global.windowsIndex
  getWindow: (name) ->
    return global.windowsIndex[name]
  getMainWindow: ->
    return global.mainWindow
