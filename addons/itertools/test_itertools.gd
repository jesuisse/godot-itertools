## These are unittests which you can run if you install the GUT addon.
## The addon is a third-party addon not affiliated with itertools, and is
## not included in the itertools codebase.

extends GutTest

const itertools = preload("itertools.gd")

func test_integer_range_it_empty():
	var it = itertools.integer_range(0, 0)
	var expected = []
	var result = []
	for i in it:
		result.append(i)	
	assert_eq(result, expected)

func test_integer_range_it_simple():
	var it = itertools.integer_range(0, 5)
	var expected = [0, 1, 2, 3, 4]
	var result = []
	for i in it:
		result.append(i)	
	assert_eq(result, expected)

func test_integer_range_it_single_arg():
	var it = itertools.integer_range(5)
	var expected = [0, 1, 2, 3, 4]
	var result = []
	for i in it:
		result.append(i)	
	assert_eq(result, expected)
	
func test_integer_range_it_simple_with_different_start():
	var it = itertools.integer_range(2, 5)
	var expected = [2, 3, 4]
	var result = []
	for i in it:
		result.append(i)	
	assert_eq(result, expected)
	
func test_integer_range_it_even():
	var it = itertools.integer_range(2, 10, 2)
	var expected = [2, 4, 6, 8]
	var result = []
	for i in it:
		result.append(i)	
	assert_eq(result, expected)

func test_integer_range_it_reverse():
	var it = itertools.integer_range(5, 2, -1)
	var expected = [5, 4, 3]
	var result = []
	for i in it:
		result.append(i)	
	assert_eq(result, expected)

func test_integer_range_it_two_arg_reverse():
	var it = itertools.integer_range(5, 2)
	var expected = [5, 4, 3]
	var result = []
	for i in it:
		result.append(i)	
	assert_eq(result, expected)

func test_all_integer_range_forward():
	var result = []	
	# we can't really test an infinite iterator, so we just see whether it
	# produces 15 values...
	var count = 15
	for i in itertools.integers(10, 2):
		result.append(i)		
		count -= 1
		if count == 0:
			break
	assert_eq(result, [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38])
		

func test_all_integer_range_backward():
	var result = []	
	# we can't really test an infinite iterator, so we just see whether it
	# produces 15 values...
	var count = 15
	for i in itertools.integers(10, -2):
		result.append(i)		
		count -= 1
		if count == 0:
			break
	assert_eq(result, [10, 8, 6, 4, 2, 0, -2, -4, -6, -8, -10, -12, -14, -16, -18])
				
	

func test_array_it_identity():
	var test_array = range(10)
	var it = itertools.array_slice(test_array)
	var result = []
	for i in it:
		result.append(i)
	assert_eq(result, test_array)

func test_array_it_empty():
	var test_array = range(10)
	var it = itertools.array_slice(test_array, 2, 2)
	var result = []
	for i in it:
		result.append(i)
	assert_eq(result, [])

func test_array_it_simple():
	var test_array = range(10)
	var it = itertools.array_slice(test_array, 3, 8)
	var expected = [3,4,5,6,7]
	var result = []
	for i in it:
		result.append(i)
	assert_eq(result, expected)
	
func test_string_it_simple():
	var test_string = "HELLO WORLD"
	var it = itertools.string_slice("HELLO WORLD!", 6, 11)
	var result = []
	var expected = ['W', 'O', 'R', 'L', 'D']
	for i in it:
		result.append(i)
	assert_eq(result, expected)
	
	
func test_filter_it_identity():
	var test_array = range(10)
	var it = itertools.array_slice(test_array, 0, 10)
	var filter_it = itertools.filter(it, func (x): return true)
	var result = []
	for i in filter_it:
		result.append(i)
	assert_eq(result, test_array)
	
func test_filter_it_empty():
	var test_array = []
	var it = itertools.array_slice(test_array, 0, 0)
	var filter_it = itertools.filter(it, func (x): return true)
	var result = []
	for i in filter_it:
		result.append(i)
	assert_eq(result, [])
	
func test_filter_it_even():
	var test_array = range(10)
	var it = itertools.array_slice(test_array, 0, 10)
	var filter_it = itertools.filter(it, func (x): return x % 2 == 0)
	var result = []
	for i in filter_it:
		result.append(i)
	assert_eq(result, [0, 2, 4, 6, 8])
	
func test_zip_it_simple():
	var it1 = itertools.array_slice(range(3))
	var it2 = itertools.array_slice(['A', 'B', 'C'])
	var zip = itertools.zip(it1, it2)
	var result = []
	for pair in zip:
		result.append(pair)
	assert_eq(result, [[0, 'A'], [1, 'B'], [2, 'C']])

func test_zip_it_empty():
	var it1 = itertools.array_slice(range(3))
	var it2 = itertools.array_slice([])
	var zip = itertools.zip(it1, it2)
	var result = []
	for pair in zip:
		result.append(pair)
	assert_eq(result, [])	
	
func test_zip_it_triple():
	var it1 = itertools.integer_range(3)
	var it2 = itertools.array_slice(['A', 'B', 'C'])
	var it3 = itertools.integer_range(3, 0, -1)	
	var zip = itertools.zip(it1, it2, it3)
	var result = []
	for triple in zip:
		result.append(triple)
	assert_eq(result, [[0, 'A', 3], [1, 'B', 2], [2, 'C', 1]])

func test_enumerate():
	var it1 = itertools.string_slice("ABCDEFG")
	var it2 = itertools.string_slice("abcd")
	var result = []
	for x in itertools.enumerate(it1, it2):
		result.append(x)
	assert_eq(result, [[0, 'A', 'a'], [1, 'B', 'b'], [2, 'C', 'c'], [3, 'D', 'd']])
	
func test_enumerate_from():
	var it1 = itertools.string_slice("ABCDEFG")
	var it2 = itertools.string_slice("abcd")
	var result = []
	for x in itertools.enumerate_from(5, it1, it2):
		result.append(x)
	assert_eq(result, [[5, 'A', 'a'], [6, 'B', 'b'], [7, 'C', 'c'], [8, 'D', 'd']])

func test_chain_it_single():
	var it1 = itertools.integer_range(3)
	var chain = itertools.chain(it1)
	var result = []
	for item in chain:
		result.append(item)
	assert_eq(result, [0, 1, 2])
	
func test_chain_it_empty():
	var it1 = itertools.integer_range(0)
	var chain = itertools.chain(it1)
	var result = []
	for item in chain:
		result.append(item)
	assert_eq(result, [])

func test_chain_it_simple():
	var it1 = itertools.integer_range(3)
	var it2 = itertools.integer_range(4, 8)
	var chain = itertools.chain(it1, it2)
	var result = []
	for item in chain:
		result.append(item)
	assert_eq(result, [0, 1, 2, 4, 5, 6, 7])

func test_chain_it_second_empty():
	var it1 = itertools.integer_range(3)
	var it2 = itertools.integer_range(0)	
	var chain = itertools.chain(it1, it2)
	var result = []
	for item in chain:
		result.append(item)
	assert_eq(result, [0, 1, 2])


func test_chain_it_successors_empty():
	var it1 = itertools.integer_range(3)
	var it2 = itertools.integer_range(0)	
	var it3 = itertools.integer_range(0)
	var chain = itertools.chain(it1, it2, it3)
	var result = []
	for item in chain:
		result.append(item)
	assert_eq(result, [0, 1, 2])
	

func test_chain_it_middle_empty():
	var it1 = itertools.integer_range(3)
	var it2 = itertools.integer_range(0)	
	var it3 = itertools.integer_range(5, 7)
	var chain = itertools.chain(it1, it2, it3)
	var result = []
	for item in chain:
		result.append(item)
	assert_eq(result, [0, 1, 2, 5, 6])	
	
func test_cycle_it():
	var it1 = itertools.integer_range(3)
	var cycle = itertools.cycle(it1)
	var i = 0
	var result = []
	for item in cycle:
		result.append(item)
		i += 1
		if i >= 9:
			break
	assert_eq(result, [0, 1, 2, 0, 1, 2, 0, 1, 2])
			
func test_cycle_it_empty():
	var it1 = itertools.integer_range(0)
	var cycle = itertools.cycle(it1)
	var i = 0
	var result = []
	for item in cycle:
		result.append(item)
		i += 1
		if i >= 9:
			break
	assert_eq(result, [])
	assert_eq(i, 0)

func test_cycle_it_simple():
	var it1 = itertools.integer_range(4)
	var cycle = itertools.cycle(it1, 3)
	var result = []
	for item in cycle:
		result.append(item)		
	assert_eq(result, [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3])
	
func test_cycle_it_cycling():
	var it1 = itertools.integer_range(2)
	var cycle = itertools.cycle(it1)
	var result = []
	var i = 0
	for item in cycle:
		result.append(item)
		i += 1
		if i >= 8:
			break
	assert_eq(result, [0, 1, 0, 1, 0, 1, 0, 1])

func test_repeat_it_n_times():	
	# we test the iterator with n repeats, where n is 0-9
	for i in range(10):
		var repeat = itertools.repeat('A', i)
		var result = []
		var expected = []
		expected.resize(i)
		expected.fill('A')
		for item in repeat:
			result.append(item)
		assert_eq(result, expected)

func test_repeat_it_forever():	
	var repeat = itertools.repeat('A')
	var result = []
	var expected = []
	# we can't really test an infinite sequence, so we
	# see if we can produce 100 elements before aborting
	expected.resize(100)
	expected.fill('A')	
	var i = 0
	for item in repeat:
		result.append(item)
		if i == 99:
			break
		i += 1
	assert_eq(result, expected)

func test_map_it_single():
	var it1 = itertools.integer_range(1, 5)
	var map = itertools.map(func (x): return x*x, it1)
	var result = []	
	for item in map:
		result.append(item)
	assert_eq(result, [1, 4, 9, 16])

func test_map_it_multiple():
	var it1 = itertools.integer_range(1, 5)
	var it2 = itertools.array_slice(["one", "two", "three", "four"])
	var map = itertools.map(func (x, y): return str(x) + y, it1, it2)
	var result = []	
	for item in map:
		result.append(item)
	assert_eq(result, ["1one", "2two", "3three", "4four"])

	
func test_map_it_nonequal_sizes():
	var it1 = itertools.integer_range(1, 3)
	var it2 = itertools.array_slice(["one", "two", "three", "four"])
	var map = itertools.map(func (x, y): return str(x) + y, it1, it2)
	var result = []	
	for item in map:
		result.append(item)
	assert_eq(result, ["1one", "2two"])
	
func test_compress_identity():
	var sel = itertools.array_slice([1, 1, 1])
	var data = itertools.integer_range(0, 3)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [0, 1, 2])

func test_compress_empty_selector():
	var sel = itertools.array_slice([])
	var data = itertools.integer_range(0, 3)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [])
	
func test_compress_empty_data():
	var sel = itertools.array_slice([1, 1, 1])
	var data = itertools.integer_range(0)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [])

func test_compress_different_sizes_longer_data():
	var sel = itertools.array_slice([1, 1, 1])
	var data = itertools.integer_range(10)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [0, 1, 2])

func test_compress_different_sizes_longer_selector():
	var sel = itertools.array_slice([1, 1, 1, 1, 1])
	var data = itertools.integer_range(3)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [0, 1, 2])

func test_compress_selection_pattern1():
	var sel = itertools.array_slice([1, 0, 1, 1, 1])
	var data = itertools.integer_range(5)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [0, 2, 3, 4])
	
func test_compress_selection_pattern2():
	var sel = itertools.array_slice([1, 1, 1, 0, 0])
	var data = itertools.integer_range(5)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [0, 1, 2])

func test_compress_selection_pattern3():
	var sel = itertools.array_slice([0, 0, 0, 1, 1])
	var data = itertools.integer_range(5)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [3, 4])	
	
func test_compress_selection_pattern5():
	var sel = itertools.array_slice([0, 0, 1, 1, 0])
	var data = itertools.integer_range(5)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [2, 3])	

func test_compress_selection_pattern6():
	var sel = itertools.array_slice([1, 1, 0, 0, 1])
	var data = itertools.integer_range(5)
	var compress = itertools.compress(data, sel)
	var result = []	
	for item in compress:
		result.append(item)
	assert_eq(result, [0, 1, 4])	


func test_product_no_iterators():	
	var product = itertools.product()
	var result = []
	for item in product:
		result.append(item)
	assert_eq(result, [])
	
func test_product_empty():
	var it1 = itertools.integer_range(0)
	var it2 = itertools.integer_range(0)
	# note we can't use the same iterator because prodcut will exhaust it!
	var product = itertools.product(it1, it2)
	var result = []
	for item in product:
		result.append(item)
	assert_eq(result, [])

func test_product_identity():
	var it1 = itertools.integer_range(5)
	var product = itertools.product(it1)
	var result = []
	for item in product:
		result.append(item)
	assert_eq(result, [[0], [1], [2], [3], [4]])
	
func test_product_simple():
	var it1 = itertools.integer_range(3)
	var it2 = itertools.integer_range(2)
	# note we can't use the same iterator because prodcut will exhaust it!
	var product = itertools.product(it1, it2)
	var result = []
	for item in product:
		result.append(item)
	assert_eq(result, [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]])
	
func test_product_with_empty():
	var it1 = itertools.integer_range(3)
	var it2 = itertools.integer_range(0)
	var it3 = itertools.integer_range(2)
	var product = itertools.product(it1, it2, it3)
	var result = []
	for item in product:
		result.append(item)
	assert_eq(result, [[0, null, 0], [0, null, 1], [1, null, 0], [1, null, 1], [2, null, 0], [2, null, 1]])

func test_product_with_single_value():
	var it1 = itertools.integer_range(3)
	var it2 = itertools.integer_range(1)
	var it3 = itertools.integer_range(2)	
	var product = itertools.product(it1, it2, it3)
	var result = []
	for item in product:
		result.append(item)
	assert_eq(result, [[0, 0, 0], [0, 0, 1], [1, 0, 0], [1, 0, 1], [2, 0, 0], [2, 0, 1]])


func test_generate_seq():
	var result = []
	for word in itertools.generate_seq("one", "two", "three"):
		result.append(word)
	assert_eq(result, ["one", "two", "three"])

func test_list():
	var result = []
	var l = itertools.list(itertools.integer_range(10))
	assert_eq(l, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
