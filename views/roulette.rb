module Views
  class Roulette < Layout
    def image1 
      @image1['path']+"/"+@image1['filename']
    end
    def image2 
      @image2['path']+"/"+@image2['filename']
    end
    def url1 
      @image1['filename']
    end
    def url2 
      @image2['filename']
    end
  end
end
