## itertools.gd (c) 2026-present by Pascal Schuppli
##
## This provides a selection of custom iterators inspired by Python's
## itertools module.
##
## Requires Godot >= 4.5 for variadic argument list support.

const version = "1.2.0-unstable"

const _protocol_methods = [&'_iter_init', &'_iter_next', &'_iter_get']

static func _wrap_in_iterator(data) -> Iterator:
	if data is Array:
		return array_slice(data)
	elif data is String:
		return string_slice(data)
	elif data is Vector2 or data is Vector2i:
		# this changes the default Godot behaviour, which is to iterate from x to y as a range
		return array_slice([data.x, data.y])
	elif data is Vector3 or data is Vector3i:
		return array_slice([data.x, data.y, data.z])
	elif is_instance_of(data, Object):
		var is_compatible = true
		for method in _protocol_methods:
			if not data.has_method(method):
				is_compatible = false
				break
		if is_compatible:
			return WrapperIterator.new(data)
		else:
			push_error("object %s is not compatible with iterator protocol" % str(data))
			# return empty iterator as a failsafe
			return integer_range(0)
	else:
		push_error("cannot wrap data of unsupported type into an iterator!")
		# return empty iterator as a failsafe
		return integer_range(0)

## Convenience function. If you pass only a single argument, this tries to return an iterator
## for the data. Only some data types are supported. If you pass more than one 
## argument, the arguments are wrapped into an iterator which will return them in sequence.
## Calling iter without arguments produces an error. So: [br]
## iter(22, 23) builds an iterator with the two elements 22 and 23.[br] 
## iter([22]) builds an iterator with the single element 22. `iter(22)` is an error. [br]
## iter([]) builds an empty iterator. `iter()` is an error.
static func iter(...args) -> Iterator:
	if len(args) == 0:
		push_error("cannot call iter() without arguments!")
		return integer_range(0)
	elif len(args) > 1:
		return ArraySliceIterator.new(args)
	else:
		return _wrap_in_iterator(args[0])

## Convenience function which generates all elements of the provided [param iterator]
## and returns them as a list. This only makes sense for finite iterators!
static func list(iterator: Iterator) -> Array:
	var results = []
		
	if not iterator.terminates():
		push_error("list() argument is a non-terminating iterator - aborted")
		return []
	
	for x in iterator:
		results.append(x)
	return results

## Returns an iterator for the [param array] slice starting at 
## [param start] up to, but excluding [param stop]. If you do not specify
## stop, all elements of the array will be iterated over starting
## at start.
static func array_slice(array: Array, start: int = 0, stop: int = -1, increment: int = 0) -> Iterator:
	return ArraySliceIterator.new(array, start, stop, increment)

## Returns an iterator for the [param array] but walks the array
## backwards.
static func array_rev(array: Array) -> Iterator:
	var l = -1 if array.is_empty() else array.size()-1
	return ArraySliceIterator.new(array, l, -1, -1)

## Convenience function that returns an iterator which iterates over
## a slice of a string. See array_slice for details, as this simply
## wraps array_slice around a string.
static func string_slice(str: String, start: int = 0, stop: int = -1) -> Iterator:
	var array = []
	array.resize(len(str))
	for i in len(str):	
		array[i] = str[i]
	return ArraySliceIterator.new(array, start, stop)

## Convenience function which returns a Zip Iterator which iterates
## over a dictionary's (key, value) pairs.
static func dict_items(dictionary: Dictionary) -> IteratorOfArray:
	return ZipIterator.new([array_slice(dictionary.keys()), array_slice(dictionary.values())])

## This is an iterator version of the range() function. It
## returns an iterator which will produce a sequence of values
## starting with [param start], stopping before [param stop],
## in increments of [param increment]. The increment can be
## negative. [br]
## If you only pass one argument n, the range (0, ... n( will be 
## produced. Two arguments a, b produce the range (a, ... b(. If 
## a is larger than b, the range will count down from a up to, but
## not including b. If you provide three arguments, the last one
## defines the step size.
static func integer_range(first: int, ...args) -> IteratorOfInt:
	var start
	var stop
	var increment
	if len(args) == 0:
		start = 0
		stop = first
		increment = 1
	elif len(args) == 1:
		start = first
		stop = args[0]
		if start > stop:
			increment = -1
		else:
			increment = 1
	elif len(args) >= 2:
		start = first
		stop = args[0]
		increment = args[1]
	if len(args) > 2:
		push_warning("superfluous arguments were ignored")
	assert(increment > 0 or stop <= start, "Iterator cannot reach stop value")
	assert(increment < 0 or stop >= start, "Iterator cannot reach stop value")
	return RangeIterator.new(start, stop, increment)

## Returns all integers starting with [param start] at an step of [param increment]
static func integers(start: int=0, increment: int = 1) -> IteratorOfInt:
	# We provide a stop value that can't be reached, which means the iterator
	# will never exhaust itself.
	if increment == 0:
		push_warning("Iterator cannot proceed with an increment of 0. Use repeat to produce a stream of constant values")
	
	return InfiniteRangeIterator.new(start, increment)

## Enumerates the elements of the iterators, yielding [0, value 0], [1, value 1] etc. Works with
## multiple iterators and stops as soon as the first iterator is exhausted. [br]
## This is a convenience function which wraps zip.
static func enumerate(...iterators) -> IteratorOfArray:
	var args = [integers()]
	args.append_array(iterators)
	return zip.callv(args)

## Enumerates the elements of the iterators, starting at [param start] and yielding 
## [start, value 0], [start+1, value 1] etc. Works with multiple iterators and stops
## as soon as the first iterator is exhausted. [br]
## This is a convenience function which wraps zip.
static func enumerate_from(start: int, ...iterators) -> IteratorOfArray:
	var args = [integers(start)]
	args.append_array(iterators)
	return zip.callv(args)

## Returns an iterator which filters [param iterator] using the
## [param predicate] callable.
##
## ex: filter(range(5), func (x): x<2) will yield 0,1
static func filter(predicate: Callable, iterator: Iterator) -> Iterator:
	return FilterIterator.new(predicate, iterator)

## Returns an iterator which maps all elements using
## [param function]. If there is more than a single 
## iterator passed in, the function must take exactly
## as many arguments as there are iterators, and return
## a single mapped result. 
## If the iterators yield an unequal number of elements,
## map stops when the first iterator is exhausted.
static func map(function: Callable, ...iterators) -> Iterator:
	if OS.is_debug_build():
		for item in iterators:
			assert(item is Iterator, "all arguments to map() following the Callable must be of type Iterator")
	return MapIterator.new(function, iterators)

## Drops elements from the iterator as long as [param predicate] returns
## true and then returns the rest of the elements.
static func dropwhile(function: Callable, iterator: Iterator) -> Iterator:
	return DropWhileIterator.new(function, iterator)
	
## Takes elements from the iterator as long as [param predicate] returns
## true and then drops the rest of the elements.
static func takewhile(function: Callable, iterator: Iterator) -> Iterator:
	return TakeWhileIterator.new(function, iterator)


## Returns an iterator which will yield an array of values, 
## each value obtained by kicking one of the [param iterators].
## If the iterators don't supply the same amount of values, the
## zip iterator will return the shortest sequence. 
static func zip(...iterators) -> IteratorOfArray:
	if OS.is_debug_build():
		for item in iterators:
			assert(item is Iterator, "all arguments to zip() must be of type Iterator")
	return ZipIterator.new(iterators)

## Returns an iterator which will yield an array of values,
## each value obtained from one of the argument iterators. 
## If the iterators don't supply the same amount of vlues, the
## zip_longest iterator will return the longest sequence, filling
## the missing values with a fill value that you can optionally pass
## as the last parameter. The fill value cannot be an Iterator.
static func zip_longest(fill_value, ...iterators) -> IteratorOfArray:
	if OS.is_debug_build():
		for item in iterators:
			assert(item is Iterator, "all arguments to zip_longest() after the fill value must be of type Iterator")
	return ZipLongestIterator.new(fill_value, iterators)


## Returns an iterator which chains together the iterators passed
## as arguments. These iterators will be iterated over in sequence,
## starting with the first.
static func chain(...iterators) -> Iterator:
	# we do the type check only if we're running in the editor
	if OS.is_debug_build():
		for item in iterators:
			assert(item is Iterator, "all arguments to chain(...) must be of type Iterator")
	return ChainIterator.new(iterators)

## Repeats [param value] exactly [param count] number
## of times. If count is -1 or left out, this will repeat 
## the value indefinitely, so be careful as this will yield
## an infinite stream of the value.
static func repeat(value: Variant, count : int=-1) -> Iterator:
	return RepeatIterator.new(value, count)

## This cycles through another [param iterator] exactly [param count] times,
## or indefinitely if count is -1 or unspecified. Note that values are not
## cached and the provided iterator is expected to be restartable. 
static func cycle(iterator: Iterator, count: int=-1) -> Iterator:
	return CycleIterator.new(iterator, count)

## Returns an iterator which yields only the items from the [param data] iterator
## for which there is a corresponding true value in the [param selectors] iterator,
## e.g. data[0] if selectors[0], data[1] if selectors[1] etc.
static func compress(data: Iterator, selectors: Iterator) -> Iterator:
	return CompressIterator.new(data, selectors)
	
## Returns an iterator which returns the cartesian product of all the elements in 
## the provided iterators. So if you pass ABC and 12, you will get A1, A2, B1,
## B2, C1, C2. The returned iterator represents each combination as an array of
## individual values.[br]
## If you pass an empty iterator or one that's already consumed, it will be
## represented by null values in the Arrays the iterator returns. [br]
## Implementation note: Each iterator is consumed at initialization and the 
## values each iterator yields are stored in memory. Therefore, this iterator 
## cannot deal with iterators which yield an infinite stream of elements.
static func product(...iterators) -> IteratorOfArray:
	if OS.is_debug_build():
		for item in iterators:
			assert(item is Iterator, "all argument of product(...) must be of type Iterator")
	return CartesianProductIterator.new(iterators)

## Returns all possible orderings of the elements of [param iterator] as arrays.
## elements are not repeated. [param size] determines the number of positions
## you want in the permutation.
## The iterator is consumed and its elements stored a single time upon iterator
## construction, so it must be finite!
## Given 1,2,3, returns [1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2] and [3,2,1]
## A size of 2 with the same input iterator returns [1,2], [1,3], [2,1], [2,3],
## [3,1],[3,2].
static func permutations(iterator: Iterator, size : int = 0) -> IteratorOfArray:
	return PermutationsIterator.new(iterator, size)


## Returns an iterator returns the elements of [param iterator] batched into
## arrays of [param size] elements. If the last batch cannot be filled, 
## [param fill_value] will be used.
## Example: ABCDEF with size 2 returns ['A', 'B'], ['C', 'D'], ['E', 'F']
static func batched(iterator: Iterator, size: int, fill_value=null) -> IteratorOfArray:
	return BatchIterator.new(iterator, size, fill_value)

static func oneshot(iterator: Iterator) -> Iterator:
	return OneshotIterator.new(iterator)

## Returns a value by passing the first two elements of [param iterator] to [param function]
## and then calling the function again with the result and the third element, etc, until the
## whole iterator has been processed. 
## You can provide an [param initializer] value, which will be used as the first value. If you do
## not provide an initializer and the iterator is empty, this is an error. If you do not provide
## an initializer and the iterator has exactly one element, the element is returned as the
## result of reduce.
static func reduce(function: Callable, iterator: Iterator, initializer=&'unset') -> Variant:
	var state = [null]
	var remaining = iterator._iter_init(state)
	if not remaining:
		if initializer is StringName and initializer == &'unset':
			push_error("cannot reduce with no available values and no initializer")
			return null
		else:
			return initializer
	var first 
	if initializer is StringName and initializer == &'unset':
		first = iterator._iter_get(state[0])
		remaining = iterator._iter_next(state)
	else:
		first = initializer
	while remaining:
		first = function.call(first, iterator._iter_get(state[0]))
		remaining = iterator._iter_next(state)
	return first

## This simply defines the custom iterator protocol used by GDScript to make
## the function signatures of the iterator functions explicit. This may help
## users of itertools understand better when they can expect a return value
## to be an iterator, and which iterators return which types. Unfortunately,
## GDScript does not let us provide better types.
## DEPRECATED: Use Iterator as a base class instead!
@abstract class AbstractIterator:
	@abstract func _iter_init(state) -> bool
	@abstract func _iter_next(state) -> bool
	@abstract func _iter_get(state) -> Variant

## Future base class (instead of AbstractIterator)
@abstract class Iterator extends AbstractIterator:
	## Returns true if this iterator is finite. If this returns true,
	## it guarantees that the iterator will exhaust itself sooner or 
	## later. If it returns false, it might still be finite.
	@abstract func terminates() -> bool

	# Returns true if this iterator produces an infinite series of elements.
	# A return value of true is guaranteed to be correct. A return value of
	# false may be wrong.
	@abstract func is_infinite() -> bool


## Iterator which yields integers
@abstract class IteratorOfInt extends Iterator:
	pass

## Iterator which yields Arrays
@abstract class IteratorOfArray extends Iterator:
	pass

## A iterator which is only initialized once; upon object creation.
class OneshotIterator extends Iterator:
	var _it: Iterator
	var _state: Array
	var _remaining: bool	
	
	func _init(iterator: Iterator):
		_it = iterator
		_state = [&'blah']
		_remaining = _it._iter_init(_state)
			
	func _iter_init(state) -> bool:
		return _remaining
	
	func _iter_next(state) -> bool:
		# Hack: use our _state instead of passed-in state.
		_remaining = _it._iter_next(_state)
		return _remaining
	
	func _iter_get(state):
		# Hack: state is null for some reason I can't see. _state should work.
		return _it._iter_get(_state[0])
		
	func terminates() -> bool:
		return _it.terminates()
	
	func is_infinite() -> bool:
		return _it.is_infinite()
		
	## Returns [param count] elements, or all which are left if
	## there are less than count elements left. For count > 1,
	## this returns an Array. count = 0 returns [param novalue],
	#  as does a call to take(1) when the iterator is exhausted.
	func take(count: int, no_value=null):
		if count == 0:
			return no_value
		var values = []
		var i = 0
		while _remaining and i < count:
			values.append(_iter_get(_state[0]))
			i += 1
			_remaining = _iter_next(_state)
		if count == 1:
			if values.is_empty():
				return no_value
			else:
				return values[0]
		else:
			return values


## An iterator which will iterate over a slice of an array
class ArraySliceIterator extends Iterator:
	
	var _start: int
	var _stop: int
	var _increment: int
	var _array: Array

	func _init(array, start: int = 0, stop: int = -1, increment = 0):
		if stop == -1 and increment == 0: 
			stop = array.size()		
		if increment == 0:
			increment = 1		
		assert(increment < 0 or (start >= 0 and stop <= array.size()), "invalid parameters (out of array bounds)")
		assert(increment != 0, "invalid parameter increment (can't be 0)")
		_start = start
		_stop = stop
		_increment = increment
		_array = array

	func terminates() -> bool:
		return true
	
	func is_infinite() -> bool:
		return false
		
	func _should_continue(index):
		if _increment > 0:
			return index < _stop
		elif _increment < 0:
			return index > _stop
		else:
			# an increment of 0 means we stop immediately
			return false
			
	func _iter_init(state):
		state[0] = _start
		return _should_continue(state[0])
	
	func _iter_next(state):
		state[0] += _increment
		return _should_continue(state[0])
	
	func _iter_get(index):
		return _array[index]

	func _to_string() -> String:
		return "<ArrayIterator %d %d %d>" % [_start, _stop, _increment]


## This iterator simulates range(start, stop, increment)
class RangeIterator extends IteratorOfInt:
	var _start: int
	var _stop: int
	var _increment: int

	func _init(start : int, stop: int, increment: int =1):
		_start = start
		_stop = stop
		_increment = increment

	func terminates() -> bool:
		if _increment > 0:
			return _stop >= _start
		elif _increment < 0:
			return _stop <= _start
		else: 
			return false
	
	func is_infinite() -> bool:
		return not terminates()
		
	func _should_continue(index):
		if _increment > 0:
			return index < _stop
		elif _increment < 0:
			return index > _stop
		else:
			# an increment of 0 means we stop immediately
			return false
	
	func _iter_init(state):
		state[0] = _start
		return _should_continue(state[0])
	
	func _iter_next(state):
		state[0] += _increment
		return _should_continue(state[0])
	
	func _iter_get(index) -> int:
		return index
		
	func _to_string() -> String:
		return "<RangeIterator %d %d %d>" % [_start, _stop, _increment]
			

class InfiniteRangeIterator extends IteratorOfInt:
	var _start: int	
	var _increment: int

	func _init(start : int, increment: int =1):
		_start = start		
		_increment = increment
		assert(increment != 0, "iterator cannot proceed with increment of 0")

	func terminates() -> bool:
		return false
		
	func is_infinite() -> bool:
		return true
	
	func _iter_init(state):
		state[0] = _start
		return true
	
	func _iter_next(state):
		state[0] += _increment
		return true
	
	func _iter_get(index):
		return index	

	func _to_string() -> String:
		return "<IntegerIterator %d %d>" % [_start, _increment]
	

## An iterator which will kick another iterator and only return
## values for which a given predicate function returns true
class FilterIterator extends Iterator:
	
	var _predicate: Callable
	var _it
	
	func _init(predicate, iterator):
		_it = iterator
		_predicate = predicate

	func terminates() -> bool:
		return _it.terminates()
		
	func is_infinite() -> bool:
		return _it.is_infinite()

	func _forward_to_matching_item(state):
		state = state[0]
		while state[2]:
			var item = _it._iter_get(state[0][0])
			if _predicate.call(item):
				state[1] = item
				break
			state[2] = _it._iter_next(state[0])

	func _iter_init(state) -> bool:
		# state of _it and current element
		state[0] = [[null], null, false]
		
		state[0][2] = _it._iter_init(state[0][0])
		_forward_to_matching_item(state)
		return state[0][2]

	func _iter_next(state) -> bool:		
		state[0][2] = _it._iter_next(state[0][0])
		_forward_to_matching_item(state)
		return state[0][2]
			
	func _iter_get(state):
		return state[1]
		
	func _to_string() -> String:
		return "<FilterIterator>"


# Applies a function to every iterable
class MapIterator extends Iterator:
	var _its: Array
	var _func: Callable
	
	func _init(function: Callable, iterators):
		_its = iterators
		_func = function

	func _iter_init(state):
		var l = _its.size()
		var mystate = []
		state[0] = mystate
		mystate.resize(l)
		var remaining = true
		for i in range(l):
			mystate[i] = [null]
			remaining = remaining and _its[i]._iter_init(mystate[i])
		return remaining
	
	func _iter_next(state):
		var remaining : bool = true
		var l = _its.size()
		for i in range(l):
			remaining = remaining and _its[i]._iter_next(state[0][i])
		return remaining
	
	func _iter_get(states):
		if _its.size() == 1:
			# special case for just a single iterator. No need to allocate
			# an array
			return _func.call(_its[0]._iter_get(states[0][0]))
		var args = []
		for i in _its.size():
			args.append(_its[i]._iter_get(states[i][0]))
		return _func.callv(args)

	func terminates() -> bool:
		for it in _its:
			if it.terminates():
				return true
		return false
		
	func is_infinite() -> bool:
		for it in _its:
			if not it.is_infinite():
				return false
		return true

class DropWhileIterator extends Iterator:
	var _predicate: Callable
	var _it: Iterator
		
	func _init(predicate: Callable, iterator: Iterator):
		_predicate = predicate
		_it = iterator
	
	func terminates() -> bool:
		return _it.terminates()
		
	func is_infinite() -> bool:
		return _it.is_infinite()

	func _forward_to_matching_item(superstate, remaining) -> bool:
		while remaining:
			var item = _it._iter_get(superstate[0])
			if not _predicate.call(item):
				break
			remaining = _it._iter_next(superstate)
		return remaining
	
	func _iter_init(superstate) -> bool: 
		# state of _it and current element		
		var remaining = _it._iter_init(superstate)
		remaining = _forward_to_matching_item(superstate, remaining)
		return remaining

	func _iter_next(superstate) -> bool:		
		return _it._iter_next(superstate)
			
	func _iter_get(state):
		return _it._iter_get(state)
		
	func _to_string() -> String:
		return "<DropWhileIterator>"

class TakeWhileIterator extends Iterator:
	var _predicate: Callable
	var _it: Iterator
		
	func _init(predicate: Callable, iterator: Iterator):
		_predicate = predicate
		_it = iterator
	
	func terminates() -> bool:
		return _it.terminates()
		
	func is_infinite() -> bool:
		return _it.is_infinite()
	
	func _iter_init(superstate) -> bool:
		var remaining = _it._iter_init(superstate)
		if remaining:
			var item = _it._iter_get(superstate[0])
			remaining = _predicate.call(item)
		return remaining

	func _iter_next(superstate) -> bool:
		var remaining = _it._iter_next(superstate)
		if remaining:
			var item = _it._iter_get(superstate[0])
			remaining = _predicate.call(item)
		return remaining
			
	func _iter_get(state):
		return _it._iter_get(state)
		
	func _to_string() -> String:
		return "<TakeWhileIterator>"

class ZipIterator extends IteratorOfArray:	
	var _its: Array
	
	func _init(iterators):
		_its = iterators

	func _iter_init(args) -> bool:
		# Initialize state for each sub-iterator
		args[0] = []
		var l = _its.size()
		args[0].resize(l)
		for i in range(l):
			args[0][i] = [null]
		
		var remaining : bool = true
		for i in range(l):
			remaining = remaining and _its[i]._iter_init(args[0][i])
		return remaining

	func _iter_next(args) -> bool:
		var remaining : bool = true
		var l = _its.size()
		for i in range(l):
			remaining = remaining and _its[i]._iter_next(args[0][i])
		return remaining
		
	func _iter_get(states) -> Array:
		var l = _its.size()
		var zipped = []
		zipped.resize(l)
		for i in range(l):
			zipped[i] = _its[i]._iter_get(states[i][0])
		return zipped
		
	func terminates() -> bool:
		for it in _its:
			if it.terminates():
				return true
		return false
	
	func is_infinite() -> bool:
		for it in _its:
			if not it.is_infinite():
				return false
		return true
		
	func _to_string() -> String:
		return "<ZipIterator>"
		

class ZipLongestIterator extends IteratorOfArray:
	var _its: Array
	var _exhausted: Array[bool]
	var _fill_value 
	
	func _init(fill_value, iterators):
		_its = iterators
		_fill_value = fill_value
		_exhausted = []
		_exhausted.resize(iterators.size())

	func _iter_init(args) -> bool:
		# Initialize state for each sub-iterator
		args[0] = []
		var l = _its.size()
		args[0].resize(l)
		for i in range(l):
			args[0][i] = [null]
		
		var remaining : bool = false
		for i in range(l):
			_exhausted[i] = not _its[i]._iter_init(args[0][i])
			remaining = remaining or not _exhausted[i]
		return remaining

	func _iter_next(args) -> bool:
		var remaining : bool = false
		var l = _its.size()
		for i in range(l):
			if not _exhausted[i]:
				_exhausted[i] = not _its[i]._iter_next(args[0][i])
			remaining = remaining or not _exhausted[i]
		return remaining
		
	func _iter_get(states) -> Array:
		var l = _its.size()
		var zipped = []
		zipped.resize(l)
		for i in range(l):
			if _exhausted[i]:
				zipped[i] = _fill_value
			else:
				zipped[i] = _its[i]._iter_get(states[i][0])
		return zipped

	func terminates() -> bool:
		for it in _its:
			if not it.terminates():
				return false
		return true

	func is_infinite() -> bool:
		for it in _its:
			if it.is_infinite():
				return true
		return false

	func _to_string() -> String:
		return "<ZipLongestIterator>"

class BatchIterator extends IteratorOfArray:
	var _it: Iterator
	var _fill_value
	var _batch_size
	
	func _init(iterator: Iterator, size: int, fill_value=null):
		assert(size > 0, "Can't create batches smaller than 1")
		_it = iterator
		_fill_value = fill_value
		_batch_size = size

	func _iter_init(args) -> bool:
		# Initialize state for each sub-iterator
		args[0] = [[null], false]
		args[0][1] = _it._iter_init(args[0][0])
		return args[0][1]
		
	func _iter_next(args) -> bool:
		if args[0][1]:
			args[0][1] = _it._iter_next(args[0][0])
		return args[0][1]
					
	func _iter_get(state) -> Array:
		var zipped = []
		zipped.resize(_batch_size)
		var exhausted = false
		for i in range(_batch_size):
			if state[1]:
				zipped[i] = _it._iter_get(state[0][0])
				if i < _batch_size -1:
					state[1] = _it._iter_next(state[0])
			else:
				zipped[i] = _fill_value
		return zipped

	func terminates() -> bool:
		return _it.terminates()
	
	func is_infinite() -> bool:
		return _it.is_infinite()

	func _to_string() -> String:
		return "<BatchIterator>"


class ChainIterator extends Iterator:	
	var _its : Array
	
	func _init(iterators):
		_its = iterators
	
	func _iter_init(args) -> bool:
		# Initialize state for each sub-iterator
		args[0] = [[null], 0]
		var l = _its.size()
		if l == 0:
			return false
		var i = 0		
		var remaining = _its[i]._iter_init(args[0][0])
		while not remaining:
			i += 1
			args[0][1] = i
			if i >= l:
				return false
			args[0][0] = [null]
			remaining = _its[i]._iter_init(args[0][0])
		return true

	func _iter_next(args) -> bool:		
		var i = args[0][1]
		var l = _its.size()
		
		var remaining = _its[i]._iter_next(args[0][0])
		while not remaining and i < l:
			# current iterator is exhausted. initialize the next one
			i += 1
			args[0][1] = i
			if i >= l:
				# no more chained iterators to initialize, so we're done
				return false
			else:
				args[0][0] = [null]
				remaining = _its[i]._iter_init(args[0][0])
		return i < l
	
	func _iter_get(args):
		return _its[args[1]]._iter_get(args[0][0])

	func terminates() -> bool:		
		for it in _its:
			if not it.terminates():
				return false
		return true
	
	func is_infinite() -> bool:
		for it in _its:
			if it.is_infinite():
				return true
		return false
		
	func _to_string() -> String:
		return "<ChainIterator>"


class CycleIterator extends Iterator:
	var _it
	var _count
	
	func _init(iterator, count=-1):
		_it = iterator
		_count = count
	
	func _iter_init(state) -> bool:
		# Initialize state
		state[0] = [[null], _count]
		return _it._iter_init(state[0][0])
		
	func _iter_next(state) -> bool:		
		var remaining = _it._iter_next(state[0][0])
		if remaining:
			return true
		
		if state[0][1] != -1:
			# one less round remaining
			state[0][1] -= 1
		if not state[0][1]:
			# we're out of repeats
			return false
		else:
			# prepare next round - reinitialize iterator
			state[0][0] = [null]
			return _it._iter_init(state[0][0])
			
	func _iter_get(state):
		return _it._iter_get(state[0][0])

	func terminates() -> bool:
		return _count != -1
		
	func is_infinite() -> bool:
		return _count == -1
		
	func _to_string() -> String:
		return "<CycleIterator>"


class RepeatIterator extends Iterator:
	var _value
	var _count
	
	func _init(value, count=-1):
		_value = value
		_count = count
	
	func _iter_init(state) -> bool:
		# Initialize state
		state[0] = _count
		return _count != 0
		
	func _iter_next(state) -> bool:		
		if state[0] != -1:
			# one less round remaining
			state[0] -= 1
		return state[0] != 0
			
	func _iter_get(state):
		return _value
	
	func terminates() -> bool:
		return _count != -1
		
	func is_infinite() -> bool:
		return _count == -1
	
	func _to_string() -> String:
		return "<RepeatIterator>"



class CompressIterator extends Iterator:
	
	var _data : Iterator
	var _selector: Iterator
	
	func _init(data: Iterator, selectors: Iterator):
		_data = data
		_selector = selectors

	func _forward_to_selected_item(state):
		state = state[0]
		var remaining_sel = true
		var remaining_data = true
		while remaining_sel and remaining_data:
			var is_selected = _selector._iter_get(state[1][0])
			# found a selected item
			if is_selected:
				break
			remaining_sel = _selector._iter_next(state[1])
			remaining_data = _data._iter_next(state[0])
		return remaining_sel and remaining_data
	
	func _iter_init(state) -> bool:
		# state of _it and current element
		state[0] = [[null], [null]]
		var remaining_sel = _selector._iter_init(state[0][1])
		var remaining_data = _data._iter_init(state[0][0])
		if remaining_sel and remaining_data:
			return _forward_to_selected_item(state)
		else:
			return false

	func _iter_next(state) -> bool:		
		var remaining_sel = _selector._iter_next(state[0][1])
		var remaining_data = _data._iter_next(state[0][0])
		if remaining_sel and remaining_data:
			return _forward_to_selected_item(state)
		else:
			return false

	func _iter_get(state):
		return _data._iter_get(state[0][0])

	func terminates() -> bool:
		return _data.terminates() or _selector.terminates()
		
	func is_infinite() -> bool:
		return _data.is_infinite() and _selector.is_infinite()
	
	func _to_string() -> String:
		return "<CompressIterator>"


class CartesianProductIterator extends IteratorOfArray:
	
	var _values: Array = []
	
	func _init(iterators):
		# build lists of all values by consuming all iterators
		_values.resize(iterators.size())
		for i in range(iterators.size()):
			_values[i] = []			
			if iterators[i].terminates():
				# we protect production code from infinite loops by only doing this for terminating
				# iterators
				for value in iterators[i]:
					_values[i].append(value)
			else:
				push_error("Cannot handle non-terminating iterator #%d" % (i+1))

	func _add_one(state) -> bool:
		state = state[0]
		var l = _values.size()
		var i = l-1
		while i >= 0:
			state[i] += 1
			if state[i] >= _values[i].size():
				state[i] = 0
			else:
				break
			i -= 1
		# we are fully consumed if we've overflowed
		return i > 0 or state[0] > 0

	func _iter_init(state) -> bool:
		state[0] = []
		var l = _values.size()
		state[0].resize(l)
		var count = 0
		for i in range(l):
			state[0][i] = 0
			count += _values[i].size()
		return count > 0
		
	func _iter_next(state) -> bool:
		return _add_one(state)
	
	func _iter_get(state) -> Array:
		var result = []
		var l = _values.size()
		result.resize(l)
		for i in range(l):
			if _values[i].size() == 0:
				result[i] = null
			else:
				result[i] = _values[i][state[i]]
		return result

	func terminates() -> bool:
		return true
		
	func is_infinite() -> bool:
		return false
	
	func _to_string() -> String:
		return "<CartesianProductIterator (%d values)>" % _values.size()



class PermutationsIterator extends IteratorOfArray:
		
	var _values : Array	
	var _size: int
		
	func _init(iterator: Iterator, size: int = 0):
		_values = []
		if iterator.terminates():
			# we protect production code from an endless loop by only doing this
			# with iterators guaranteed to terminate
			for item in iterator:
				_values.append(item)
		else:
			push_error("Cannot handle non-terminating iterators")
		if size < 1:
			_size = _values.size()
		else:
			_size = size
			
			
	func _iter_init(superstate) -> bool:
		var state : Array[int]= []
		var indices : Array[int] = []
		if _values.is_empty():
			return false
		state.resize(_size)
		indices.resize(_values.size())
		superstate[0] = [state, indices]
		var n = _values.size()
		for i in range(n):
			indices[i] = i
		for i in range(_size):
			state[i] = n-i
		
		return not _values.is_empty()
	
	func _iter_next(superstate) -> bool:
		return _subone(superstate[0][0], superstate[0][1])
		
	func _iter_get(state) -> Array:
		var permutation : Array = []
		for i in range(_size):
			permutation.append(_values[state[1][i]])
		return permutation
			
	func terminates() -> bool:
		return true
		
	func is_infinite() -> bool:
		return false

	# to understand what happens here, imagine a combination lock where the
	# leftmost wheel has n numbers, the wheel to its right has only n-1 
	# numbers etc and we're counting down from the largest number to 0. i 
	# denotes the position of the wheel we're currently turning. assuming we
	# have 4 different elements (say A-D), the initial combination is 4321.
	# Each number represents the index of the position with which we swap. 
	# Assume we're dealing with only 2 positions. Our initial state is 43.
	# when we call _subone, we change this state to 42 (with i=1). We then
	# use the number 2 at state pos 1 (named j) as the target to swap the
	# i and j target values in _indices, meaning we get 0 2 1 3 (AC). Now
	# that state is 42, it will be decremented to 41, and the swap will
	# therefore swap indices 1 and 4-1=3, to get 0 3 1 2 (AD). In the next
	# round, we get to state 40 and move the index at pos 1 to the end, 
	# shifting the rest on position to the left to yield 0 1 2 3 (the 
	# original configuration). The state is reset to the max for position i,
	# so it switches back to 43. However, i now gets decremented and in the
	# next round we have i=0 and decrement the state to 33. This will swap
	# indices 0 and 1, yielding 1 0 2 3 (BA), and so on.
	func _subone(state, indices) -> bool:
		var index : int
		var j : int
		var n : int = _values.size()
		var i : int = _size-1
		while i>=0:
			state[i] -= 1
			if state[i] == 0:
				# rotate indices from pos i leftwards to restore initial ordering
				# from pos i onwards. e.g. [0 3 1 2] -> [0 1 2 3] (for i=1)
				index = indices[i]
				j = i
				while j < n-1:
					indices[j] = indices[j+1]
					j += 1
				indices[n-1] = index
				state[i] = n - i # set maximum for this position
			else:
				j = state[i]
				# swap indices at i and n-j
				index = indices[i]
				indices[i] = indices[n-j]
				indices[n-j] = index
				return true
			i -= 1
		# if we've exhausted all permutations, signal stop (false)
		return i >= 0

	func _to_string() -> String:
		return "<PermutationsIterator (n=%d k=%d)>" % [_values.size(), _size]
		
		

class WrapperIterator extends Iterator:
	
	var _object
	var _fully_compatible = false
		
	func _init(iterable_object):
		_object = iterable_object
		_fully_compatible = _object.has_method(&'terminates') and _object.has_method(&'_is_infinite')
		
	func _iter_init(state) -> bool:
		return _object._iter_init(state)
	
	func _iter_next(state) -> bool:
		return _object._iter_next(state)
		
	func _iter_get(state): 
		return _object._iter_get(state)
		
	func terminates() -> bool:
		if _fully_compatible:
			return _object.terminates()
		else:
			# means we don't know
			return false
			
	func is_infinite() -> bool:
		if _fully_compatible:
			return _object._is_infinite()
		else:
			# means we don't know
			return false
	
	func _to_string() -> String:
		return "<WrapperIterator for %s >" % str(_object)
