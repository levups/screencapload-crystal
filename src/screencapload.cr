require "./screencapload/*"
require "tempfile"
require "json"

def log(message)
  puts message if VERBOSE
end

def exit_fail(message)
  puts message
  exit 1
end

def read_imgur_api_key
  return ARGV[0] unless ARGV.empty? || ARGV[0].blank?

  if File.exists?(IMGUR_CONFIG_FILE_PATH)
    api_key = File.read(IMGUR_CONFIG_FILE_PATH).strip
  else
    exit_fail <<-MSG
      Usage: screencapload [imgur_api_key]
      You can also type your imgur api key in ~/.imgur
      MSG
  end
end

unless File.exists? GRAPHICS_MAGICK_PATH
  exit_fail "You have to install graphicsmagick to allow automatic image trimming."
end

unless File.exists? OPTIPNG_PATH
  exit_fail "You have to install optipng to allow smaller file size (faster uploads/downloads)."
end

unless File.exists? OPTIPNG_PATH
  exit_fail "You have to install pngquant to allow reducing PNG color depth, to get smaller file size (faster uploads/downloads)."
end

GRAPHICS_MAGICK_PATH = "/usr/local/bin/gm"
OPTIPNG_PATH  = "/usr/local/bin/optipng"
PNGQUANT_PATH = "/usr/local/bin/pngquant"
IMGUR_CONFIG_FILE_PATH = "#{ENV["HOME"]}/.imgur"
IMGUR_API_KEY = read_imgur_api_key
VERBOSE = true

screenshot = Screencapload::Screenshot.new
screenshot.trim!
# screenshot.quantize!
screenshot.lossless_recompress!
if screenshot.upload!
  puts screenshot.url
else
  exit_fail "Failed to upload screenshot to imgur !"
end
