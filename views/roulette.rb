module Views
  class Roulette < Layout
    def image1 
      "/images/"+@image1['file']
    end
    def image2 
      "/images/"+@image2['file']
    end
    def url1 
      @image1['file']
    end
    def url2 
      @image2['file']
    end
  end
end
