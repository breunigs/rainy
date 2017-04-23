var map = L.map('map').setView([53.50000, 10.0], 11);
L.tileLayer('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiYnJldW5pZ3MiLCJhIjoiY2oxdWplZWl3MDA4bjM0bW81dzdtYm55YyJ9.lHUbRUDgmKBgUCQot8PPsw', {
  maxZoom: 15,
  attribution: 'Radar data <a href="http://wetterradar.uni-hamburg.de" target="_blank">PATTERN</a>, ' +
    'Map data &copy; <a href="http://openstreetmap.org" target="_blank">OpenStreetMap</a> contributors, ' +
    '<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
    'Imagery © <a href="http://mapbox.com">Mapbox</a>',
  id: 'akio.l35p3fje'
}).addTo(map);

// new images every 60s, history for two hours
var interval = 60;
var maxImages = 2*60*(60/interval);
var start = Math.floor(Date.now() / 1000) - maxImages*interval;
var startIndex = maxImages - 20*(60/interval); // 20 minutes ago


// Load Radar image layer
var boundsAll = [[53.17102800, 9.01568100], [54.09236200, 11.23351900]];
// TODO: fix bbox. Currently defines circle on n/e/s/w coordinates
var boundsZoom = [[53.7466, 9.6739], [53.3851, 10.2896]];

map.addLayer(L.imageOverlay("/" + files_all[files_all.length-1], boundsAll, {opacity:0.7}));
// map.addLayer(L.imageOverlay("/" + files_zoom[files_zoom.length-1], boundsZoom, {opacity:0.7}));

var slider = L.control();
slider.onAdd = function(map) {
  this._div = L.DomUtil.create('div', 'slidercont');
  this._div.innerHTML = '<input id="slider" type="range" min="0" max="'+(maxImages-1)+'" value="'+(startIndex)+'" list="imgs" type="imgs"/>'
  return this._div;
}
slider.addTo(map);
var div = slider.getContainer();
if (!L.Browser.touch) {
  L.DomEvent.disableClickPropagation(div);
  L.DomEvent.on(div, 'mousewheel', L.DomEvent.stopPropagation);
} else {
  L.DomEvent.on(div, 'click', L.DomEvent.stopPropagation);
}

function replace(layer, new_image) {
  console.log("Trying to replace: " + layer + " to " + new_image);
  if(new_image == null || new_image == undefined || new_image == "") return;

  var img = document.querySelector('.leaflet-image-layer[src^="/'+layer+'"]');
  if(img.src == new_image) return;
  img.src = new_image;
}

function find(array, timestamp) {
  return array.find(function(f) {
    return parseInt(f.substr(-14, 10)) > timestamp;
  }) || array[array.length-1];
}

function showImg(num) {
  slider.value=num;
  slider.dispatchEvent(new Event('input'));
}

var slider = document.getElementById("slider");
slider.addEventListener("input", function() {
  var time = start + interval*slider.value;

  replace("all", "/" + find(files_all, time));
  // replace("zoom", "/" + find(files_zoom, time));
});

var play = setInterval(function() {
  if(slider.value == slider.max) {
    return clearInterval(play);
  }

  var cur = slider.value*1;
  showImg(cur + 1);
}, 200);

slider.addEventListener("mousedown", function() {
  clearInterval(play);
})
