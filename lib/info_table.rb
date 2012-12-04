﻿module Scarlet
  class ColumnTable
    VERSION = 0.0002
    def self.mk_table width,height, &block
      Array.new(width) { Array.new(height,&block) }
    end
    attr_accessor :padding
    def initialize width, height
      @cell_color= {}
      @col_color = {}
      @row_color = {}
      @padding = 2
      resize! width, height
    end
    attr_reader :width, :height
    def resize! width, height
      @width, @height = width,height
      @data = ColumnTable.mk_table(@width,@height) { " " }
      self
    end
    def clear
      @cell_color.clear
      @col_color.clear
      @row_color.clear
      resize! @width, @height
      self
    end
    def get_cell x, y
      return nil unless(x.between?(0,@width) && y.between?(0,@height))
      @data[x][y]
    end
    def set_cell x,y,value
      return unless(x.between?(0,@width) && y.between?(0,@height))
      @data[x][y] = value
      self
    end
    def set_row sx,y,*values
      values.each_with_index do |str,x|
        set_cell(sx+x,y,str)
      end
      self
    end
    def set_column x,sy,*values
      values.each_with_index do |str,y|
        set_cell(x,sy+y,str)
      end
      self
    end
    # // color_a = [int background,int text]
    def cell_color x, y
      @cell_color[[x,y]]
    end
    def col_color x
      @col_color[x]
    end
    def row_color y
      @row_color[y]
    end
    def set_cell_color x, y, *color_a
      @cell_color[[x,y]] = color_a
      self
    end
    def set_col_color x, *color_a
      @col_color[x] = color_a
      self
    end
    def set_row_color y, *color_a
      @row_color[y] = color_a
      self
    end
    def join_cells *xys
      # // Uggggh
      self
    end
    alias :[] get_cell
    alias :[]= set_cell
    def column_widths
      (0...@width).collect { |x| @data[x].max_by{|s|s.size}.size+@padding+(@padding%2) }
    end
    def row_width
      column_widths.inject(:+)
    end
    # // @data[x] => [String, String, String...]
    def compile
      x,y,r,color_a,width=[nil]*5
      column_width = column_widths
      wr,hr = (0...@width), (0...@height)
      hr.collect do |y|
        (wr.collect do |x|
          color_a = cell_color(x,y) || col_color(x) || row_color(y) || [0,1]
          width = column_width[x]
          @data[x][y].dup.align(width,:left,@padding).irc_color(*color_a)
        end).join("")
      end
    end
  end
  class InfoTable
    VERSION = 0.0002
    attr_accessor :colors, :width, :padding
    def initialize width=50
      @width     = width
      @padding   = 0
      @colors    = {}
      @colors[0] = [1,0] # // Content
      @colors[1] = [0,1] # // Header
      @colors[2] = [1,8] # // Warning
      @lines     = []
      @headers   = []
    end
    def clear
      clear_lines
      clear_headers
      self
    end
    def clear_headers
      @headers.clear
      self
    end
    def clear_lines
      @lines.clear
      self
    end
    def addHeader string
      @headers << string
    end
    def addRow string
      @lines << string
      self
    end
    def compile
      @headers.collect{|s|s.align(@width,:center,@padding).irc_color(*@colors[1])} +
      @lines.collect{|s|s.align(@width,:left,@padding).irc_color(*@colors[0])}
    end
  end
end