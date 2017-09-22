require 'benchmark'

# class MyArray
#   THREADS_NUM = 2
#
#   def initialize(array)
#     @array = array
#     @size = array.size
#   end
#
#   def map_multi(&block)
#     threads('map', &block)
#   end
#
#   def map(&block)
#     @array.map(&block)
#   end
#
#   def threads(method, &block)
#     arrays = @array.each_slice(@size/THREADS_NUM).to_a
#     result_array = Array.new(THREADS_NUM)
#     threads = []
#
#     i = 0
#     arrays.each do |arr|
#       threads << Thread.new(i) do |num|
#         array = arr.method(method).call(&block)
#         result_array[num] = array
#       end
#       i += 1
#     end
#
#     threads.each {|t| t.join}
#
#     result_array.flatten
#   end
#   private :threads
#
# end

# myarr = MyArray.new((1..100000))
#
# puts myarr.map_multi {|n| n * 2}

class Array
  THREADS_NUM = 4

  def map_parallel(&block)
    parallel('map', &block)
  end

  def any_parallel(&block)
    parallel('any?', &block)
  end

  def all_parallel(&block)
    parallel('all?', &block)
  end

  def select_parallel(&block)
    parallel('select', &block)
  end

  def parallel(method, &block)
    arrays = (0...THREADS_NUM).reduce([]) do |accum, thread_number|
      number_of_elements = self.size / THREADS_NUM

      number_of_elements = self.size / THREADS_NUM + 1 unless self.size % 2 == 0

      if number_of_elements < 2
        number_of_elements = 2
      end

      left_bound = thread_number * number_of_elements
      right_bound = thread_number != THREADS_NUM - 1 ? (thread_number + 1) * number_of_elements : self.size

      accum + [(left_bound...right_bound).map {|index| self[index]}]
    end

    arrays = arrays.select {|n| n != []}

    arrays.map do |arr|
      Thread.new do
        Thread.current[:output] = arr.method(method).call(&block)
      end
    end.reduce([]) do |accum, t|
      t.join
      accum + [t[:output]]
    end
  end
end

arr = (0..100).to_a

Benchmark.bm do |x|
  x.report('Single thread:') {arr.map {|n| n * 2 }}
  x.report('Multi thread :') {arr.map_parallel {|n| n * 2 }}
end

print arr.map_parallel {|n| n*2}
puts
print arr.all_parallel {|n| n%2 == 0}
puts
print arr.any_parallel {|n| n%2 == 0}
puts
print arr.select_parallel {|n| n % 3 == 0}