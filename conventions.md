SauceBot Coding Conventons
==========================

Whitespace
----------
* Use **four** spaces for indentation. Never use tabs.
* Insert **two** blank lines after every method.
* Insert blank lines to separate logic.

  **Bad:**
  ```coffeescript
    doSomeStuff: ->
        start = @start
        count = @getCount()
        end = count + start
        console.log "Doing stuff from #{start} to #{end}"
        for i in [start..(end-1)]
            console.log "#{i}..."
            doStuff i
  ```
  **Good:**
  ```coffeescript
    doSomeStuff: ->
        start = @start
        count = @getCount()
        end = count + start
        
        console.log "Doing stuff from #{start} to #{end}"
        
        for i in [start..(end-1)]
            console.log "#{i}..."
            doStuff i
  ```
  
Variables
---------
* Always use the @ when refering to instance variables.

  **Bad:**
  ```coffeescript
    class User
        constructor: (@username, @password) ->
                @login username, password
  ```
  **Good:**
  ```coffeescript
    class User
        constructor: (@username, @password) ->
                @login @username, @password
  ```
  
* Constants should be written in all-caps.

  **Good:**
  ```coffeescript
    MAX_REQUESTS  = 20
    CACHE_TIMEOUT = 40
  ```
* Enum-like objects should be written in CamelCase.

  **Good:**
  ```coffeescript
    Level =
        User   : 0
        Mod    : 1
        Admin  : 2
        Owner  : 3
        Global : 4
  ```
* When constructing multi-line lists/hashes, always omit the separator-comma.

  **Bad:**
  ```coffeescript
    data =
        type: 'message',
        chan: '#ravn_tm',
        user: 'testperson'
  ```
  **Good:**
  ```coffeescript
    data =
        type: 'message'
        chan: '#ravn_tm'
        user: 'testperson'
  ```
  
Comments
--------
* All public methods should have at least one leading comment.
* Long comments should be split to form a block of text.

  **Bad:**
  ```coffeescript
    # This is a really long comment explaining the following method. It has some crazy stuffs in it that's hard to understand, yo.
  ```
  **Good:**
  ```coffeescript
    # This is a really long comment explaining the following method.
    # It has some crazy stuffs in it that's hard to understand, yo.
  ```
* Methods should be commented like this:
  ```coffeescript
    # Connects to the server.
    #
    # * host: The host to connect to.
    # * port: The port to connect to.
    #         Defaults to 23775.
    # = returns whether the connection was successful.
    connect: (host, port) ->
        ...
  ```
