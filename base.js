var extraAttribution = new mapboxgl.AttributionControl({
  customAttribution: 'Radar data <a href="http://wetterradar.uni-hamburg.de" target="_blank">PATTERN</a>',
});
var geolocation = new mapboxgl.GeolocateControl({
  positionOptions: { enableHighAccuracy: true },
  fitBoundsOptions: {maxZoom: 12},
  trackUserLocation: true
});


mapboxgl.accessToken = 'pk.eyJ1IjoiYnJldW5pZ3MiLCJhIjoiY2oxdWplZWl3MDA4bjM0bW81dzdtYm55YyJ9.lHUbRUDgmKBgUCQot8PPsw';
var map = new mapboxgl.Map({
  container: 'map', // container id
  style: 'mapbox://styles/breunigs/cjrdomp7u10e32snuy4db6299', // stylesheet location
  center: [10.0, 53.50000], // starting position [lng, lat]
  zoom: 11,
  maxZoom: 15,
  maxBounds: [[9.01568100, 53.17], [11.23351900, 54.09236200]],
  hash: true,
  pitchWithRotate: false,
  attributionControl: false
}).addControl(extraAttribution, 'top-left');

if( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
  map.addControl(geolocation, 'top-right');
}

console.log(map);

var bounds = [
  [9.01568100, 54.09236200],
  [11.23351900, 54.09236200],
  [11.23351900, 53.17102800],
  [9.01568100, 53.17102800],
];

var interval = 60;
var maxImages = 2*60*(60/interval);
var start = Math.floor(Date.now() / 1000) - maxImages*interval;
var startIndex = maxImages - 20*(60/interval); // 20 minutes ago

var slider = document.getElementById('slider')
var timestamp = document.getElementById('timestamp')
slider.max = maxImages-1;
slider.value = startIndex;

const paint = {
  "raster-resampling": "nearest",
  "raster-fade-duration": 0,
  "raster-opacity": 0.7,
}

map.on('load', function () {
  let zoomAdded = false;
  let allAdded = false;
  let layerAdder = function(data) {
    if(data.sourceId === 'zoom' && !zoomAdded) {
      zoomAdded = true;
      map.addLayer({
        "id": "layerZoom",
        "type": "raster",
        "source": "zoom",
        "paint": paint,

      }, 'building');
    }

    if(data.sourceId === 'all' && !allAdded) {
      allAdded = true;
      map.addLayer({
        "id": "layerAll",
        "type": "raster",
        "source": "all",
        "paint": paint
      }, 'building');
    }

    if(allAdded && zoomAdded) {
      map.off('sourcedata', layerAdder)
      setTimeout(function() {
        // set correct "ago"
        slider.dispatchEvent(new Event('input'));
        startPlay();
      }, 0);
    }
  };

  map.on('sourcedata', layerAdder);

  map.addSource("zoom", {
    "type": "image",
    "url": filesZoom[startIndex] || '/blank.png',
    "coordinates": bounds,
  });
  map.addSource("all", {
    "type": "image",
    "url": filesAll[startIndex] || '/blank.png',
    "coordinates": bounds,
  });
});

map.dragRotate.disable();
map.touchZoomRotate.disableRotation();


function find(array, timestamp) {
  return array.find(function(f) {
    return parseInt(f.substr(-14, 10)) > timestamp;
  }) || array[array.length-1];
}


var sliderReact = null;
slider.addEventListener("input", function() {
  if(sliderReact) clearTimeout(sliderReact);
  sliderReact = setTimeout(function() {
    var data = findImagesForSliderPos(slider.value);
    var ago = Math.floor((new Date()/1000 - data.time) / 60);

    preload(data).then(function() {
      map.getSource("all").updateImage({ url: data.all });
      map.getSource("zoom").updateImage({ url: data.zoom });
      timestamp.innerHTML = "~ " + ago + " min ago";
    })
  }, 100);
});

function findImagesForSliderPos(position) {
  var time = start + interval*position;
  return {all: find(filesAll, time), zoom: find(filesZoom, time), time: time}
}

function loadImage(src) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      resolve(src);
    };
    img.onerror = () => {
      console.error(`${src} failed`);
      resolve(src);
    };
    img.src = src;
  });
}

function preload(data) {
  let prAll = loadImage(data.all);
  let prZoom = loadImage(data.zoom);

  return Promise.all([prAll, prZoom])
}

function startPlay() {
  var prevDesired = null;
  var play = null;

  function start() {
    console.log("starting")
    play = setInterval(function() {
      if(slider.value == slider.max) {
        return clearInterval(play);
      }

      var cur = slider.value*1;
      var desired = cur + 1;

      if(desired == prevDesired) {
        return
      }

      prevDesired = desired;
      var data = findImagesForSliderPos(desired);
      preload(data).then(function() {
        // console.log("advancing slider to ", desired)
        slider.value=desired;
        slider.dispatchEvent(new Event('input'));
      });
    }, 200);
  }

  function stop() {
    console.log("stopping")
    clearInterval(play);
    prevDesired = null;
  }


  slider.addEventListener("mousedown", stop)
  slider.addEventListener("touchstart", stop)

  start();
}
