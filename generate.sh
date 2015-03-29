function usage() {
  echo "usage: $0 test_image <options>"
  echo ""
  echo "Options:"
  echo -e " -g\tset geometry, default 1000x-1"
  echo -e " -t\tset the time waited before taking a screenshot"
  echo -e " \tmight be needed for rendering huge images, default 1"
  echo -e " -s\tspecify scalers to test, default all"
  exit 1
}

if [[ $1 ]] && [[ $1 != -* ]]; then
  img=$1
  imgbase=$(echo $img | sed 's=.*/==;s/\.[^.]*$//')
  shift 1;
else
  usage
fi

#default
geometry="1000x-1"
stime=1
scalers=$(mpv -vo opengl-hq:scale=help | tail -n +2)

blacklist="custom triangle box"
for item in $blacklist; do
    scalers=$(echo "$scalers" | sed -e "s/$item//")
done

#parse opts
while test $# -gt 0; do
  case "$1" in
    -g)
      case "$2" in
        ""|-*) echo "no parameter for $1" ; exit 1 ;;
        *) geometry=$2 ;;
      esac ; shift ;;
    -t)
      case "$2" in
        ""|-*|*[!.0-9]*) echo "no valid parameter for option $1" ; exit 1 ;;
        *) stime=$2 ;;
      esac ; shift ;;
    -s)
      case "$2" in
        ""|-*) echo "no parameter for option $1" ; exit 1 ;;
        *) scalers="$2" ;;
      esac ; shift ;;
    -h|--help)
      usage ;;
    -*) echo "invalid option: $1" ; exit 1 ;;
    *)  echo "internal error at $1" ; exit 1 ;;
  esac
  shift
done

if ! [ -d $imgbase ]; then
  mkdir $imgbase
fi

echo -e "# ${imgbase^}" > ${imgbase^}.md

for scaler in $scalers; do
  (mpv --no-config --use-text-osd=yes --pause $img --title="scaler_test" --geometry=$geometry -vo opengl-hq:dither-depth=8:scale=$scaler:cscale=$scaler:dscale=$scaler) &
  id=$!
  sleep $stime
  import -define png:include-chunk=none -depth 8 -window 'scaler_test' $imgbase/$scaler.png &
  sleep $stime
  kill $id
  echo -e "\n    scale=$scaler\n![]($imgbase/$scaler.png)" >> ${imgbase^}.md
done
