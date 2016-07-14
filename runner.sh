#!/bin/bash

# Automatically serve webp images if available:
# nginx.conf:
# http {
#   map $http_accept $webp_suffix {
#     default   "";
#     "~*webp"  ".webp";
#   }
# }
#
# site.conf:
# server {
#   location ~* ^.+\.(png|jpg)$ {
#     add_header Vary Accept;
#     try_files $uri$webp_suffix $uri =404;
#   }
# }

cd $(dirname $(readlink -f $0))

filename="$(date +%s).png"

wget -q -O"${filename}" "http://pattern.zmaw.de/fileadmin/user_upload/pattern/radar/lawr_4.png"
cwebp -quiet -preset picture -q 75 -m 5 -af "${filename}" -o "${filename}.webp"
pngquant --ext .png --force -Q 60 "${filename}"&

find *.png -mmin +120 -exec rm {} \;
find *.png.webp -mmin +120 -exec rm {} \;&

images=($(ls *.png))

cat > index.html <<ENDOFHTML
<html>
<head>
  <style>
  input { width: 20em }
  img { height: 90%; max-height: 703px; position: absolute; top: 50px; left: 5px; }
  #slider { zoom: 150% }

  .hidden { display: none }
  .preload { opacity: 50%; }
  </style>
</head>

<body>
  <input id="slider" type="range" min="1" max="${#images[@]}" list="imgs" type="imgs"/>
  (~2h available. yellow crosses = lightning)
  <a href="http://pattern.zmaw.de/index.php?id=2106">Hard work was done by PATTERN</a>
  <br/>
ENDOFHTML

COUNTER=0
for i in "${images[@]}"; do
let COUNTER=COUNTER+1
cat >> index.html <<ENDOFHTML
  <img data-src="${i}" id="img${COUNTER}" class="hidden"/>
ENDOFHTML
done


cat >> index.html <<ENDOFHTML
<script>
var slider = document.getElementById('slider');
var body = document.getElementsByTagName('body')[0];

function preloadAfter(num) {
  var next = (num*1)+1;

  var img = document.getElementById('img' + next);
  if(img && img.src == '')  img.src = img.dataset.src;
}

function showImg(num) {
  console.log("setting img=" + num)
  slider.value=num;
  slider.dispatchEvent(new Event('input'));
}

var play = setInterval(function() {
  if(slider.value == slider.max) {
    return clearInterval(play);
  }

  var cur = slider.value*1;

  if(!document.getElementById('img' + cur).complete) {
    console.log('not complete, waiting for current img');
    preloadAfter(cur);
    return;
  }

  if(!document.getElementById('img' + (cur+1)).complete) {
    console.log('not complete, waiting for next img to preload');
    preloadAfter(cur+1);
    return;
  }

  showImg(cur + 1);
  preloadAfter(cur+2);
  preloadAfter(cur+3);
}, 200);

slider.addEventListener("input", function() {
  var toHide = document.querySelectorAll('img:not(#img' + slider.value + ')');

  var toShow = document.getElementById('img' + slider.value);
  if(toShow.src == '') toShow.src = toShow.dataset.src;
  toShow.className = '';

  for(var i = 0; i < toHide.length; i++) {
    toHide[i].className = 'hidden'
  }
});

slider.addEventListener("mousedown", function() {
  clearInterval(play);
})

showImg(Math.max(1, ${#images[@]}-20));

</script>
</body>
</html>
ENDOFHTML
