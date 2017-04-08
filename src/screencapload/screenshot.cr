require "http/client"
require "http" # FormData

module Screencapload
  class Screenshot
    @tempfile : Tempfile
    @url : String | Nil
    
    getter :url
    
    # Take a screenshot on OSX
    # -x = do not play sounds
    # -i = capture interactively (via mouse, or press space to toggle full window capture)
    # -c = force capture to go to the clipboard (could be usefull for 100% in-memory handling)
    def initialize
      @tempfile = Tempfile.new "screenshot-#{Time.now.epoch_ms}.png"
      if system("/usr/sbin/screencapture", ["-x", "-i", @tempfile.path])
        log "Screenshot taken."
      else
        puts "Failed to take screenshot."
        exit(1)
      end
    end
    
    # We use the default trimming of GraphicsMagick (1%)
    def trim!
      delta = VERBOSE ? File.size(@tempfile.path) : 0
      trimmed_tempfile = Tempfile.new "screenshot-trimmed-#{Time.now.epoch_ms}.png"
      if system(GRAPHICS_MAGICK_PATH, ["convert", @tempfile.path, "-trim", "-depth", "8", "-colors", "256", "+dither", "png8:#{trimmed_tempfile.path}"])
      # if system(GRAPHICS_MAGICK_PATH, ["convert", @tempfile.path, "-trim", trimmed_tempfile.path])
        @tempfile.unlink
        @tempfile = trimmed_tempfile
        delta -= File.size(@tempfile.path) if VERBOSE
        log "Trimmed screenshot edges (#{delta} bytes removed)."
      else
        log "! Failed to trim screenshot edges. Keeping original version."
        trimmed_tempfile.unlink
      end
    end
    
    # We use optipng with low compression setting (-o1). It requires a
    # fraction of a second to recompress and save 5 to 30 %.
    # You can use -o3 too but it will add nearly a second to the whole process.
    def lossless_recompress!
      delta = VERBOSE ? File.size(@tempfile.path) : 0
      if system(OPTIPNG_PATH, ["-silent", "-o1", @tempfile.path])
        delta -= File.size(@tempfile.path) if VERBOSE
        log "Optimized screenshot lossless compression (#{delta} bytes removed)."
      else
        log "! Failed to recompress screenshot. Keeping original version."
      end
    end

    # pngquant reduces bit depth to 1 byte per pixel  while keeping it visually
    # similar.
    #
    # The --ext ".png" flag mean the original file is replaced, otherwise
    # another file is created with the "-fs8.png" extension.
    #
    # Speed 1 and Speed 3 are almost equal in CPU time, so we use the best
    # quality possible.
    def quantize!
      delta = VERBOSE ? File.size(@tempfile.path) : 0
      if system(PNGQUANT_PATH, ["--strip", "--force", "--skip-if-larger", "--ext", ".png", @tempfile.path])
        delta -= File.size(@tempfile.path) if VERBOSE
        log "Reduced screenshot bit depth (#{delta} bytes removed)."
      else
        log "! Failed to reduce screenshot bit depth."
      end
    end
    
    def upload!
      curl_upload!
      !@url.nil?
    end
    
    # Sample response
    # {
    #   "data": {
    #     "id": "Yf2rCLl",
    #     "title": null,
    #     "description": null,
    #     "datetime": 1491638665,
    #     "type": "image\\/png",
    #     "animated": false,
    #     "width": 428,
    #     "height": 166,
    #     "size": 21207,
    #     "views": 0,
    #     "bandwidth": 0,
    #     "vote": null,
    #     "favorite": false,
    #     "nsfw": null,
    #     "section": null,
    #     "account_url": null,
    #     "account_id": 0,
    #     "is_ad": false,
    #     "tags": [],
    #     "in_most_viral": false,
    #     "in_gallery": false,
    #     "deletehash": "Bt4UTLgsdAyjOoe",
    #     "name": "",
    #     "link": "http:\\/\\/i.imgur.com\\/Yf2rCLl.png"
    #   },
    #   "success": true,
    #   "status": 200
    # }
    def curl_upload!
      log "Uploading screenshot ..."
      response = `curl --header 'Authorization: Client-ID #{IMGUR_API_KEY}' --silent -X POST -F 'image=@#{@tempfile.path}' 'https://api.imgur.com/3/upload'`
      @tempfile.unlink
      parse_imgur_response(response)
    end
    
    def parse_imgur_response(response)
      json = JSON.parse(response)
      @url = json["data"]["link"].as_s if json["success"]
    end

    def crystal_upload!
      # Upload it to imgur.com
      headers = HTTP::Headers{"Authorization" => "Client-ID #{IMGUR_API_KEY}"}
      
      io = IO::Memory.new
      builder = HTTP::FormData::Builder.new(io)
      builder.field("title", "Screenshot #{Time.now.to_s}")
      builder.field("type", "file")
      File.open(tempfile.path) do |file|
        metadata = HTTP::FormData::FileMetadata.new(filename: "screenshot.png", size: File.size(tempfile.path))
        # headers = HTTP::Headers{"Content-Type" => "image/png"}
        builder.file("image", file, metadata)
      end
      builder.finish
      response = HTTP::Client.post_form("https://api.imgur.com/3/upload", io, headers)
      if response.status_code == 200
        parse_imgur_response(response.body)
      end
    end
  end
end
