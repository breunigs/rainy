#!/bin/sh

# TODO: zoomed images do not get rendered separately anymore, it seems.
# it should be possible to split inner/outer part, though, to gain better cache
# efficiency

set -e

cd $(dirname $(readlink -f $0))

suffix="$(date +%s).png"

clean_old() {
  find *.png -mmin +120 -exec rm {} \; || true
  find *.png.webp -mmin +120 -exec rm {} \; || true
  find previous_md5_* -mmin +120 -exec rm {} \; || true
}

compress() {
  pngquant --ext .png --force -Q 60 "${1}"
  cwebp -quiet -lossless -m 6 "${1}" -o "${1}.webp"
}

compress_or_discard() {
  filename="${1}_${suffix}"
  new_md5=$(md5sum "${filename}" | cut -f1 -d" ")
  old_md5=$(cat "previous_md5_${1}" || true)
  if [ "${new_md5}" = "${old_md5}" ]; then
    # new and old file are equal, just keep using old file
    rm -f "${1}"
  else
    compress "${filename}"
    echo "${new_md5}" > "previous_md5_${1}"
  fi
}

list() {
  ls -1 ${1}_*.png | sort | tr '\n' ' '
}

get_all() {
  wget -q -O tmp_all.png "http://37.120.170.199/uploads/pattern_c_hhg.png" || wget -q -O tmp_all.png "https://mi-pub.cen.uni-hamburg.de/fileadmin/files/ninjo/Batch/pattern_c_hhg.png"
  # XXX: It's important to cut out the middle before comparison, since that changes
  # more often than the outer part

  # cut out middle part, for which we have a higher resolution
  # convert tmp_all.png mask_all.img -compose Dst_out -composite -strip "all_${suffix}"
  # rm -f tmp_all.png&
  mv tmp_all.png "all_${suffix}"
  compress_or_discard "all"
}

get_zoom() {
  wget -q -O "zoom_${suffix}"  "http://37.120.170.199/uploads/pattern_hhg.png"
  compress_or_discard "zoom"
}

clean_old
get_all&
# get_zoom& ### broken :(
cp base.html tmp_index.html&
wait

files_all=$(list "all")
sed -i "s/###FILES_ALL###/${files_all}/" tmp_index.html

# files_zoom=$(list "zoom")
# sed -i "s/###FILES_ZOOM###/${files_zoom}/" tmp_index.html

mv tmp_index.html index.html
