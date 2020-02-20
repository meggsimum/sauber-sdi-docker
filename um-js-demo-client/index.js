var session = null;
var channel = null;

window.onload = isLoaded;

function isLoaded() {

  session = Nirvana.createSession({
      realms            : [ "http://159.69.72.183:9876" ],
                          // this can be an array of realms
      debugLevel        : 1, // 1-9 (1 = noisy, 8 = severe, 9 = default = off)
      sessionTimeoutMs  : 10000,
      enableDataStreams : false,
      drivers           : [ // an array of transport drivers in preferred order:
        Nirvana.Driver.WEBSOCKET,
        Nirvana.Driver.XHR_STREAMING_CORS,
        Nirvana.Driver.XDR_STREAMING,
        Nirvana.Driver.JSONP_LONGPOLL,
        Nirvana.Driver.XHR_LONGPOLL_CORS
      ]
    });

    function sessionStarted(s) {
        console.log("Session started with ID " + s.getSessionID());

        document.querySelector('#connected').innerHTML = 'Connected (Session ' + s.getSessionID() + ')'
    }

    session.on(Nirvana.Observe.START, sessionStarted);

    session.start();

    channel = session.getChannel("HeartbeatChannel");

    // Assign a handler function for Universal Messaging Events received on the Channel,
    // then subscribe:
    function myEventHandler(event) {
        var dictionary = event.getDictionary();
        document.querySelector('#outputTextarea').value += dictionary.get("timestamp") + ' | ' + dictionary.get("category") + ' | ' + dictionary.get("source") + '\n'
    }

    channel.on(Nirvana.Observe.DATA, myEventHandler);

    channel.subscribe();
}

function publishMessage() {
  var evt = Nirvana.createEvent();
  var evtDict = evt.getDictionary();

  evtDict.putString("timestamp", new Date().getTime());
  evtDict.putString("category", "realtime");
  evtDict.putString("source", "hhi");
  evtDict.putString("url", "https://sauber-projekt.meggsimum.de/demo-data/sauber_stuttgart_example.tif");
  channel.publish(evt);
  console.log(evtDict);
}
