#!/bin/bash

cd $(dirname $(readlink -f $0))

filename="$(date +%F__%H:%M:%S).png"

wget -q -O"${filename}" "http://pattern.zmaw.de/fileadmin/user_upload/pattern/radar/lawr_4.png"
pngquant --ext .png --force -Q 60 "${filename}"&
find *.png -mmin +120 -exec rm {} \;

images=($(ls *.png))

cat > index.html <<ENDOFHTML
<input id="slider" type="range" min="1" max="${#images[@]}" list="imgs" type="imgs"/>
ENDOFHTML

COUNTER=0
for i in "${images[@]}"; do
let COUNTER=COUNTER+1
cat >> index.html <<ENDOFHTML
    <img src="${i}" id="img${COUNTER}" style="display:none"/>
ENDOFHTML
done


cat >> index.html <<ENDOFHTML
<script>
var slider = document.getElementById('slider');

function showImg(num) {
  console.log("setting img=" + num)
  slider.value=num;
  slider.dispatchEvent(new Event('input'));
}

var play = setInterval(function() {
  showImg((slider.value*1) + 1);
  if(slider.value == slider.max) {
    clearInterval(play);
  }
}, 200);

slider.addEventListener("input", function() {
  var elems = document.getElementsByTagName('img');
  for(var i = 0; i < elems.length; i++) {
    elems[i].style.display='none';
  }
  var active=document.getElementById('img' + slider.value);
  active.style.display = 'block';
});

slider.addEventListener("mousedown", function() {
  clearInterval(play);
})

showImg(Math.max(1, ${#images[@]}-20));


</script>
<style>
input { width: 20em }
img { height: 90% }
</style>
ENDOFHTML
