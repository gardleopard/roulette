module Views
  class Roulette < Layout
    def image1 
      "/img/" + @image1['filename']
    end
    def image2 
      "/img/" + @image2['filename']
    end
  end
end
