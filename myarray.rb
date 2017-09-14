require 'benchmark'

class MyArray
  THREADS_NUM = 2

  def initialize(array)
    @array = array
    @size = array.size
  end

  def map_multi(&block)
    threads('map', &block)
  end

  def map(&block)
    @array.map(&block)
  end

  def threads(method, &block)
    arrays = @array.each_slice(@size/THREADS_NUM).to_a
    result_array = Array.new(THREADS_NUM)
    threads = []

    i = 0
    arrays.each do |arr|
      threads << Thread.new(i) do |num|
        array = arr.method(method).call(&block)
        result_array[num] = array
      end
      i += 1
    end

    threads.each {|t| t.join}

    result_array.flatten
  end
  private :threads

end

myarr = MyArray.new((1..100000))

puts myarr.map_multi {|n| n * 2}

Benchmark.bm do |x|
  x.report('Single thread:') {myarr.map {|n| n * 2 }}
  x.report('Multi thread :') {myarr.map_multi {|n| n * 2 }}
end
