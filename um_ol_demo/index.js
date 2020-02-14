import 'ol/ol.css';
import {Map, View} from 'ol';
import TileLayer from 'ol/layer/Tile';
import ImageLayer from 'ol/layer/Image';
import OSM from 'ol/source/OSM';
import ImageSource from 'ol/source/ImageStatic';
import {fromLonLat} from 'ol/proj';

import {fromArrayBuffer as geoTiffFromArrayBuffer} from 'geotiff.js'

let session = null;
let channel = null;
let url_array = [];

window.onload = isLoaded;

function isLoaded() {
    session = Nirvana.createSession({
        realms: ['http://159.69.72.183:9876'],
        // this can be an array of realms
        debugLevel: 4, // 1-9 (1 = noisy, 8 = severe, 9 = default = off)
        sessionTimeoutMs: 10000,
        enableDataStreams: false,
        drivers: [ // an array of transport drivers in preferred order:
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

    function umEventHandler(event) {
        let dictionary = event.getDictionary();
        document.querySelector('#outputTextarea').value += dictionary.get("timestamp") + ' | ' + dictionary.get("category") + ' | ' + dictionary.get("source") + ' | ' + dictionary.get("url") + '\n'
        url_array.push(dictionary.get("url"));
        let url = dictionary.get("url");

        // Nothing new until here

        // Check that timestamps make sense
        var date = new Date(parseInt(dictionary.get("timestamp")));
        var day = date.getDate();
        var month = date.getMonth();
        var year = date.getFullYear();
        var hours = date.getHours();
        var minutes = "0" + date.getMinutes();
        var seconds = "0" + date.getSeconds();
        var pingtime = day + ' ' + month + ' ' + year + ' ' + hours + ':' + minutes.substr(-2) + ':' + seconds.substr(-2);
        console.log(pingtime);
        // Can be removed

        if (url.endsWith("e.tif")) {
            try {
                fetch(url).then(response => response.arrayBuffer()).then(onGeotiffLoaded);
            } catch (err) {}
        };
    };

    channel.on(Nirvana.Observe.DATA, umEventHandler);
    channel.subscribe();
};

// Parser and plotter for incoming GeoTiffs
function onGeotiffLoaded(data) {

    geoTiffFromArrayBuffer(data).then(tiff => {
      console.log(tiff);

      const image = tiff.getImage().then(image => {
        console.log(image);
        const rawBox = image.getBoundingBox();
        // make bbox order OL-compatible
        const box = [rawBox[0], rawBox[1] - (rawBox[3] - rawBox[1]), rawBox[2], rawBox[1]];


        const bands = image.readRasters().then(bands => {
          let canvas = document.createElement('canvas');
          const minValue = 0;
          const maxValue = 256;

          const plot = new plotty.plot({
              canvas: canvas,
              data: bands[0],
              width: image.getWidth(),
              height: image.getHeight(),
              domain: [minValue, maxValue],
              colorScale: 'magma',
              clampLow: true,
              clampHigh: true
          });

          plot.render();

          const geotiffSource = new ImageSource({
              url: canvas.toDataURL("image/png"),
              imageExtent: box,
              projection: 'EPSG:3857'
          })
          geotiffLayer.setSource(geotiffSource);
          geotiffLayer.setOpacity(0.5);

          // set map view to GeoTIFF's extent
          map.getView().fit(box);
        });

      });
    });
};

// create a empty layer, which is overwritten in UM message callback (onGeotiffLoaded)
const geotiffLayer = new ImageLayer({
  source: new ImageSource({
    url: null,
    imageExtent: [0, 0, 0, 0],
    projection: 'EPSG:3857'
  })
});

const map = new Map({
  target: 'map',
  layers: [
    new TileLayer({
      source: new OSM()
    }),
    geotiffLayer
  ],
  view: new View({
    center: fromLonLat([9.19, 48.784]),
    zoom: 13
  })
});
