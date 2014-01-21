module Graphics
  class Canvas
    attr_reader :width
    attr_reader :height

    def initialize(width, height)
      @width = width
      @height = height
      @pixels = Hash.new(false)
    end

    def set_pixel(x, y)
      @pixels[[x, y]] = true
    end

    def pixel_at?(x, y)
      @pixels[[x, y]]
    end

    def draw(shape)
      shape.to_a.each { |x, y| set_pixel(x, y) }
    end

    def render_as(renderer)
      renderer.render(self)
    end
  end

  module Renderers
    def render(canvas)#TODO refactor
      indexes = 0.upto(canvas.width.pred).to_a.product(0.upto(canvas.height.pred).to_a)
      pixels = indexes.map(&:reverse).map { |x, y| canvas.pixel_at?(x, y) }
      rendered_lines = pixels.map { |pixel| render_pixel(pixel) }.each_slice(canvas.width)
      canvas_to_string = rendered_lines.map { |line| add_new_line(line) }.join.chomp
      prefix + canvas_to_string + suffix
    end

    class Ascii
      extend Renderers

      class << self
        private

        def render_pixel(pixel)
          pixel ? "@" : "-"
        end

        def add_new_line(slice)
          slice << "\n"
        end

        def prefix
          ""
        end

        def suffix
          ""
        end
      end
    end

    class Html
      extend Renderers

      class << self
        private

        PREFIX = <<-html.gsub /^\s+|$\n/, ""#TODO experiment with .freeze
        <!DOCTYPE html>
        <html>
        <head>
          <title>Rendered Canvas</title>
          <style type="text/css">
            .canvas {
              font-size: 1px;
              line-height: 1px;
            }
            .canvas * {
              display: inline-block;
              width: 10px;
              height: 10px;
              border-radius: 5px;
            }
            .canvas i {
              background-color: #eee;
            }
            .canvas b {
              background-color: #333;
            }
          </style>
        </head>
        <body>
          <div class="canvas">
        html

        SUFFIX = <<-html.gsub /^\s+|$\n/, ""#TODO experiment with .freeze
          </div>
        </body>
        </html>
        html

        def render_pixel(pixel)
          pixel ? "<b></b>" : "<i></i>"
        end

        def add_new_line(slice)
          slice << "<br>"
        end

        def prefix
          PREFIX
        end

        def suffix
          SUFFIX
        end
      end
    end
  end

  class Point
    attr_reader :x
    attr_reader :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def eql?(other)
      [@x, @y].eql?([other.x, other.y])
    end

    def hash
      [@x, @y].hash
    end

    alias_method :==, :eql?

    def to_a
      [[@x, @y]]
    end
  end

  class Line
    attr_reader :from
    attr_reader :to

    def initialize(first_point, second_point)
      if first_point.x != second_point.x
        @from, @to = [first_point, second_point].minmax_by(&:x)
      else
        @from, @to = [first_point, second_point].minmax_by(&:y)
      end
    end

    def eql?(other)
      [@from, @to].eql?([other.from, other.to])
    end

    def hash
      [@from, @to].hash
    end

    alias_method :==, :eql?

    def to_a
      line_coordinates(@from.x, @from.y, @to.x, @to.y)
    end

    private

    def line_coordinates(start_x, start_y, end_x, end_y)
      delta_x = end_x - start_x
      delta_y = end_y - start_y
      if delta_x >= delta_y
        bresenham(delta_x, delta_y).map { |x, y| [x + start_x, y + start_y] }
      else
        bresenham(delta_y, delta_x).map { |y, x| [x + start_x, y + start_y] }
      end
    end

    def bresenham(x, y)#TODO rename height and n
      height = x
      0.upto(x).map do |n|
        coordinates =  [n, height / (2 * x)]
        height += 2 * y
        coordinates
      end
    end
  end

  class Rectangle
    attr_reader :left
    attr_reader :right

    def initialize(first_point, second_point)
      if first_point.x != second_point.x
        @left, @right = [first_point, second_point].minmax_by(&:x)
      else
        @left, @right = [first_point, second_point].minmax_by(&:y)
      end
    end

    def top_left
      Point.new([@left.x, @right.x].min, [@left.y, @right.y].min)
    end

    def top_right
      Point.new([@left.x, @right.x].min, [@left.y, @right.y].max)
    end

    def bottom_left
      Point.new([@left.x, @right.x].max, [@left.y, @right.y].min)
    end

    def bottom_right
      Point.new([@left.x, @right.x].max, [@left.y, @right.y].max)
    end

    def eql?(other)
      [@left, @right].eql?([other.left, other.right])
    end

    def hash
      [@left, @right].hash
    end

    alias_method :==, :eql?

    def to_a
      all_pixels = []
      all_pixels.concat(Line.new(top_left, top_right).to_a)
      all_pixels.concat(Line.new(top_right, bottom_right).to_a)
      all_pixels.concat(Line.new(bottom_right, bottom_left).to_a)
      all_pixels.concat(Line.new(bottom_left, top_left).to_a)
      all_pixels.uniq
    end
  end
end