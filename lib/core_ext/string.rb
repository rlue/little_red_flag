class String
  def intersection(str)
    return '' if [self, str].any?(&:empty?)
    
    matrix = Array.new(self.length) { Array.new(str.length) { 0 } }

    intersection = Struct.new(:length, :end) do
      def start
        self.end - length + 1
      end
    end.new(0, 0)

    self.length.times do |x|
      str.length.times do |y|
        next unless self[x] == str[y]
        matrix[x][y] = 1 + (([x, y].all?(&:zero?)) ? 0 : matrix[x-1][y-1])

        next unless matrix[x][y] > intersection.length
        intersection.length = matrix[x][y]
        intersection.end    = x
      end
    end

    slice(intersection.start..intersection.end)
  end

  def unescape
    self.gsub(/[\\"]/, '')
  end
end
