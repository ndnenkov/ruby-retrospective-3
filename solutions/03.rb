module Graphics
  class Canvas
    attr_reader :width
    attr_reader :height

    def initialize(width, height)
      @width = width
      @height = height
      @pixels = {}
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
      renderer.new(self).render
    end
  end

   module Renderers
    class Base
      attr_reader :canvas

      def initialize(canvas)
        @canvas = canvas
      end

      def render
        pixels = 0.upto(canvas.height.pred).map do |y|
          0.upto(canvas.width.pred).map { |x| pixel_at(x, y) }
        end

        join_lines pixels.map { |line| join_pixels_in line }
      end

      private

      def pixel_at(x, y)
        canvas.pixel_at?(x, y) ? full_pixel : blank_pixel
      end

      def join_pixels_in(line)
        line.join('')
      end
    end

    class Ascii < Base
      private

      def full_pixel
        '@'
      end

      def blank_pixel
        '-'
      end

      def join_lines(lines)
        lines.join("\n")
      end
    end

    class Html < Base
      TEMPLATE = '<!DOCTYPE html>
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
            %s
          </div>
        </body>
        </html>
      '.freeze

      def render
        TEMPLATE % super
      end

      private

      def full_pixel
        '<b></b>'
      end

      def blank_pixel
        '<i></i>'
      end

      def join_lines(lines)
        lines.join('<br>')
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
      delta_x, delta_y = end_x - start_x, end_y - start_y
      y_sign = delta_y <=> 0
      if delta_x >= delta_y.abs
        bresenham(delta_x, delta_y.abs).map { |x, y| [x + start_x, y_sign * y + start_y] }
      else
        bresenham(delta_y.abs, delta_x).map { |y, x| [x + start_x, y_sign * y + start_y] }
      end
    end

    def bresenham(x, y)
      return [[0, 0]] if x.zero?
      0.upto(x).map { |n| [n, (x + 2 * n * y) / (2 * x)] }
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
      Point.new([@left.x, @right.x].max, [@left.y, @right.y].min)
    end

    def bottom_left
      Point.new([@left.x, @right.x].min, [@left.y, @right.y].max)
    end

    def bottom_right
      Point.new([@left.x, @right.x].max, [@left.y, @right.y].max)
    end

    def eql?(other)
      [top_left, bottom_right].eql?([other.top_left, other.bottom_right])
    end

    def hash
      [top_left, bottom_right].hash
    end

    alias_method :==, :eql?

    def to_a
      [
        Line.new(top_left, top_right),
        Line.new(top_right, bottom_right),
        Line.new(bottom_right, bottom_left),
        Line.new(bottom_left, top_left),
      ].map(&:to_a).flatten(1).uniq
    end
  end
end