class TodoList

  include Enumerable

  attr_reader :todos

  def initialize(todos)
    @todos = todos
  end

  def each(&block)
    @todos.each &block
  end

  def filter(criteria)
    TodoList.new(@todos.select { |todo| criteria.core.call(todo) })
  end

  def adjoin(other)
    TodoList.new(@todos | other.todos)
  end

  def tasks_todo
    @todos.select { |todo| todo.status == :todo }.count
  end

  def tasks_in_progress
    @todos.select { |todo| todo.status == :current }.count
  end

  def tasks_completed
    @todos.select { |todo| todo.status == :done }.count
  end

  def completed?
    @todos.all? { |todo| todo.status == :done }
  end

  def self.parse(text)
    Parser.new.parse(text)
  end

  class Parser
    def parse(text)
      TodoList.new(text.lines.map { |line| parse_line(line) })
    end

    def parse_line(line)
      todo_raw = split_properties(line)
      todo_raw = status_and_priority_proper_symbols(todo_raw)
      todo_raw[3] = parse_tags(todo_raw[3])

      Todo.new(*todo_raw)
    end

    def split_properties(line)
      line.chomp.split('|').map(&:strip)
    end

    def parse_tags(tags)
      tags.nil? ? [] : tags.split(',').map(&:strip)
    end

    def status_and_priority_proper_symbols(todo_raw)
      todo_raw.each_with_index.map do |property, index|
        property_as_symbol_if_status_or_priority(property, index)
      end
    end

    def property_as_symbol_if_status_or_priority(property, index)
      status_or_priority_index?(index)? proper_symbol(property) : property
    end

    def status_or_priority_index?(index)
      index.even?
    end

    def proper_symbol(property)
      property.downcase.to_sym
    end
  end
end

class Todo

  attr_reader :status
  attr_reader :description
  attr_reader :priority
  attr_reader :tags

  def initialize(status, description, priority, tags)
    @status = status
    @description = description
    @priority = priority
    @tags = tags
  end

  def eql?(other)
    todo_raw == other.todo_raw
  end

  def hash
    todo_raw.hash
  end

  protected

  def todo_raw
    [@status, @priority, @tags.sort, @description]
  end
end

class Criteria

  attr_reader :core

  def initialize(core)
    @core = core
  end

  def self.status(todo_status)
    status_filter = proc { |todo| todo.status == todo_status }
    Criteria.new(status_filter)
  end

  def self.priority(todo_priority)
    priority_filter = proc { |todo| todo.priority == todo_priority }
    Criteria.new(priority_filter)
  end

  def self.tags(todo_tags)
    tags_filter = proc { |todo| (todo_tags - todo.tags).empty? }
    Criteria.new(tags_filter)
  end

  def !
    negative = proc { |todo| not core.call(todo) }
    Criteria.new(negative)
  end

  def |(other)
    union = proc { |todo| core.call(todo) or other.core.call(todo) }
    Criteria.new(union)
  end

  def &(other)
    intersection = proc { |todo| core.call(todo) and other.core.call(todo) }
    Criteria.new(intersection)
  end
end