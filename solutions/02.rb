class TodoList

  include Enumerable

  attr_reader :todos

  def initialize(todos)
    @todos = todos
  end

  def each
    return @todos unless block_given?
    @todos.each { |todo| yield todo }
  end

  def filter(criteria)
    filtered_todos = @todos.select { |todo| criteria.core.call(todo) }
    TodoList.new(filtered_todos)
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
    todos = text.lines.map { |line| parse_line(line) }
    TodoList.new(todos)
  end

  def self.parse_line(line)
    todo_raw = line.chomp.split('|').map(&:strip)
    [0, 2].each { |index| todo_raw[index] = todo_raw[index].downcase.to_sym }
    todo_raw[3] = todo_raw[3].nil? ? [] : todo_raw[3].split(',').map(&:strip)
    Todo.new(*todo_raw)
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
    return false unless @status == other.status and @priority == other.priority
    return false unless @description == other.description
    (@tags - other.tags).empty? and (other.tags - @tags).empty?
  end

  def hash
    status.hash + description.hash + priority.hash + tags.sort.hash
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