#!/bin/sh

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
    rm -f "${filename}"
  else
    compress "${filename}"
    echo "${new_md5}" > "previous_md5_${1}"
  fi
}

list() {
  ls -1 ${1}_*.png | sort | tr '\n' ' '
}

get_all() {
  # cuts out middle part
  convert tmp_all.png mask_all.img -compose Dst_out -composite -strip "all_${suffix}"
  compress_or_discard "all"
}

get_zoom() {
  # keeps middle part
  convert tmp_all.png mask_all.img -compose Dst_in -composite -strip "zoom_${suffix}"
  compress_or_discard "zoom"
}

clean_old

wget -q -O tmp_all.png "https://mi-pub.cen.uni-hamburg.de/fileadmin/files/ninjo/Batch/pattern_c_hhg.png"

get_all&
get_zoom&
cp base.html tmp_index.html&
wait

rm -f tmp_all.png&


files_all=$(list "all")
sed -i "s/###FILES_ALL###/${files_all}/" tmp_index.html

files_zoom=$(list "zoom")
sed -i "s/###FILES_ZOOM###/${files_zoom}/" tmp_index.html

mv tmp_index.html index.html
