#!/bin/bash

cd $(dirname $(readlink -f $0))

filename="$(date +%s).png"

wget -q -O"${filename}" "http://pattern.zmaw.de/fileadmin/user_upload/pattern/radar/lawr_4.png"
cwebp -quiet -preset picture -q 80 -m 5 -af "${filename}" -o "${filename}.webp"
pngquant --ext .png --force -Q 60 "${filename}"&

find *.png -mmin +120 -exec rm {} \;
find *.png.webp -mmin +120 -exec rm {} \;&

images=($(ls *.png))

cat > index.html <<ENDOFHTML
<input id="slider" type="range" min="1" max="${#images[@]}" list="imgs" type="imgs"/>
(~2h available. yellow crosses = lightning)
<a href="http://pattern.zmaw.de/index.php?id=2106">Hard work was done by PATTERN</a>
<br/>
ENDOFHTML

COUNTER=0
for i in "${images[@]}"; do
let COUNTER=COUNTER+1
cat >> index.html <<ENDOFHTML
  <picture id="img${COUNTER}" class="hidden">
    <source srcset="${i}.webp" type="image/webp">
    <img src="${i}">
  </picture>

ENDOFHTML
done


cat >> index.html <<ENDOFHTML
<style>
input { width: 20em }
img, source { height: 100% }
picture { height: 90%; max-height: 703px; }
#slider { zoom: 150% }

.hidden { display: none }
.show { display: block }
.preload { visibility: hidden; width: 0px; height: 0px; overflow: hidden; }
</style>

<script>
var slider = document.getElementById('slider');

function preloadImg(num) {
  var img = document.getElementById('img' + num);
  if(img) img.className = 'preload';
}

function showImg(num) {
  console.log("setting img=" + num)
  slider.value=num;
  slider.dispatchEvent(new Event('input'));
  preloadImg((num*1)+1);
}

var play = setInterval(function() {
  var cur = slider.value*1;
  if(slider.value == slider.max) {
    return clearInterval(play);
  }
  showImg(cur + 1);
}, 200);

slider.addEventListener("input", function() {
  var elems = document.getElementsByTagName('picture');
  for(var i = 0; i < elems.length; i++) {
    elems[i].className = 'hidden';
  }
  var active=document.getElementById('img' + slider.value);
  active.className = 'show';
});

slider.addEventListener("mousedown", function() {
  clearInterval(play);
})

showImg(Math.max(1, ${#images[@]}-20));


</script>
ENDOFHTML
