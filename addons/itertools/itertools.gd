## itertools.gd (c) 2026-present by Pascal Schuppli
##
## This provides a selection of custom iterators inspired by Python's
## itertools module.
##
## Requires Godot >= 4.5 for variadic argument list support.

static func _wrap_in_iterator(data):
	if data is Array:
		return array_slice(data)
	elif data is String:
		return string_slice(data)
	elif data is Vector2 or data is Vector2i:
		return array_slice([data.x, data.y])
	elif data is Vector3 or data is Vector3i:
		return array_slice([data.x, data.y, data.z])
	else:
		push_error("cannot wrap data of unsupported type into an iterator!")
		return null

## Convenience function. If you pass only a single argument, this tries to return an iterator
## for the data. Only some data types are supported. If you pass more than one 
## argument, the arguments are wrapped into an iterator which will return them in sequence.
## Calling iter without arguments produces an error. So: [br]
## iter(22, 23) builds an iterator with the two elements 22 and 23.[br] 
## iter([22]) builds an iterator with the single element 22. `iter(22)` is an error. [br]
## iter([]) builds an empty iterator. `iter()` is an error.
static func iter(...args):
	if len(args) == 0:
		push_error("cannot call iter() without arguments!")
		return null
	elif len(args) > 1:
		return ArraySliceIterator.new(args)
	else:
		return _wrap_in_iterator(args[0])

## Convenience function which generates all elements of the provided [param iterator]
## and returns them as a list. This only makes sense for finite iterators!
static func list(iterator: AbstractIterator) -> Array:
	var results = []
	for x in iterator:
		results.append(x)
	return results

## Returns an iterator for the [param array] slice starting at 
## [param start] with size [param count]. If you do not specify
## count, all elements of the array will be iterated over starting
## at start.
static func array_slice(array: Array, start: int = 0, stop: int = -1) -> AbstractIterator:
	return ArraySliceIterator.new(array, start, stop)

## Convenience function that returns an iterator which iterates over
## a slice of a string. See array_slice for details, as this simply
## wraps array_slice around a string.
static func string_slice(str: String, start: int = 0, stop: int = -1) -> AbstractIterator:
	var array = []
	array.resize(len(str))
	for i in len(str):	
		array[i] = str[i]
	return ArraySliceIterator.new(array, start, stop)

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
static func integer_range(first: int, ...args) -> AbstractIterator:
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
static func integers(start: int=0, increment: int = 1) -> AbstractIterator:
	# We provide a stop value that can't be reached, which means the iterator
	# will never exhaust itself.
	if increment == 0:
		push_warning("Iterator cannot proceed with an increment of 0. Use repeat to produce a stream of constant values")
	
	return InfiniteRangeIterator.new(start, increment)

## Enumerates the elements of the iterators, yielding [0, value 0], [1, value 1] etc. Works with
## multiple iterators and stops as soon as the first iterator is exhausted. [br]
## This is a convenience function which wraps zip.
static func enumerate(...iterators) -> AbstractIterator:
	var args = [integers()]
	args.append_array(iterators)
	return zip.callv(args)

## Enumerates the elements of the iterators, starting at [param start] and yielding 
## [start, value 0], [start+1, value 1] etc. Works with multiple iterators and stops
## as soon as the first iterator is exhausted. [br]
## This is a convenience function which wraps zip.
static func enumerate_from(start: int, ...iterators) -> AbstractIterator:
	var args = [integers(start)]
	args.append_array(iterators)
	return zip.callv(args)

## Returns an iterator which filters [param iterator] using the
## [param predicate] callable.
##
## ex: filter(range(5), func (x): x<2) will yield 0,1
static func filter(predicate: Callable, iterator: AbstractIterator) -> AbstractIterator:
	return FilterIterator.new(predicate, iterator)

## Returns an iterator which maps all elements using
## [param function]. If there is more than a single 
## iterator passed in, the function must take exactly
## as many arguments as there are iterators, and return
## a single mapped result. 
## If the iterators yield an unequal number of elements,
## map stops when the first iterator is exhausted.
static func map(function: Callable, ...iterators) -> AbstractIterator:
	return MapIterator.new(function, iterators)

## Returns an iterator which will yield an array of values, 
## each value obtained by kicking one of the [param iterators].
## If the iterators don't supply the same amount of values, the
## zip iterator gets exhausted with the shortest iterator. 
static func zip(...iterators) -> AbstractIterator:
	return ZipIterator.new(iterators)

## Returns an iterator which chains together the iterators passed
## as arguments. These iterators will be iterated over in sequence,
## starting with the first.
static func chain(...iterators) -> AbstractIterator:
	return ChainIterator.new(iterators)

## Repeats [param value] exactly [param count] number
## of times. If count is -1 or left out, this will repeat 
## the value indefinitely, so be careful as this will yield
## an infinite stream of the value.
static func repeat(value: Variant, count : int=-1) -> AbstractIterator:
	return RepeatIterator.new(value, count)

## This cycles through another [param iterator] exactly [param count] times,
## or indefinitely if count is -1 or unspecified. Note that values are not
## cached and the provided iterator is expected to be restartable. 
static func cycle(iterator: AbstractIterator, count: int=-1) -> AbstractIterator:
	return CycleIterator.new(iterator, count)

## Returns an iterator which yields only the items from the [param data] iterator
## for which there is a corresponding true value in the [param selectors] iterator,
## e.g. data[0] if selectors[0], data[1] if selectors[1] etc.
static func compress(data: AbstractIterator, selectors: AbstractIterator) -> AbstractIterator:
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
static func product(...iterators) -> AbstractIterator:
	return CartesianProductIterator.new(iterators)

## Returns a value by passing the first two elements of [param iterator] to [param function]
## and then calling the function again with the result and the third element, etc, until the
## whole iterator has been processed. 
## You can provide an [param initializer] value, which will be used as the first value. If you do
## not provide an initializer and the iterator is empty, this is an error. If you do not provide
## an initializer and the iterator has exactly one element, the element is returned as the
## result of reduce.
static func reduce(function: Callable, iterator: AbstractIterator, initializer=&'unset') -> Variant:
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
## the function signatures of the iterator functions explicit.
@abstract class AbstractIterator:
	@abstract func _iter_init(state) -> bool
	@abstract func _iter_next(state) -> bool
	@abstract func _iter_get(state) -> Variant


## An iterator which will iterate over a slice of an array
class ArraySliceIterator extends AbstractIterator:
	
	var _start: int
	var _stop: int
	var _array: Array

	func _init(array, start: int = 0, stop: int = -1):
		if stop == -1: 
			stop = array.size()
		assert(start >= 0 and stop <= array.size(), "invalid parameters (out of array bounds)")
		_start = start
		_stop = stop
		_array = array
		
	func _should_continue(index):
		return index < _stop	
	
	func _iter_init(state):
		state[0] = _start
		return _should_continue(state[0])
	
	func _iter_next(state):
		state[0] += 1
		return _should_continue(state[0])
	
	func _iter_get(index):
		return _array[index]

## This iterator simulates range(start, stop, increment)
class RangeIterator extends AbstractIterator:
	var _start: int
	var _stop: int
	var _increment: int

	func _init(start : int, stop: int, increment: int =1):
		_start = start
		_stop = stop
		_increment = increment
		
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
		return index

class InfiniteRangeIterator extends AbstractIterator:
	var _start: int	
	var _increment: int

	func _init(start : int, increment: int =1):
		_start = start		
		_increment = increment
		assert(increment != 0, "iterator cannot proceed with increment of 0")
	
	func _iter_init(state):
		state[0] = _start
		return true
	
	func _iter_next(state):
		state[0] += _increment
		return true
	
	func _iter_get(index):
		return index	


## An iterator which will kick another iterator and only return
## values for which a given predicate function returns true
class FilterIterator extends AbstractIterator:
	
	var _predicate: Callable
	var _it
	
	func _init(predicate, iterator):
		_it = iterator
		_predicate = predicate

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

# Applies a function to every iterable
class MapIterator extends AbstractIterator:
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


class ZipIterator extends AbstractIterator:	
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

class ChainIterator extends AbstractIterator:	
	var _its : Array
	
	func _init(iterators):
		_its = iterators
	
	func _iter_init(args) -> bool:
		# Initialize state for each sub-iterator
		args[0] = [[null], 0]
		if _its.size() > 0:
			return _its[0]._iter_init(args[0][0])
		else:
			return false

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


class CycleIterator extends AbstractIterator:
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
			# prepare next round
			state[0][0] = [null]
			return _it._iter_init(state[0][0])
			
	func _iter_get(state):
		return _it._iter_get(state[0][0])


class RepeatIterator extends AbstractIterator:
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


class CompressIterator extends AbstractIterator:
	
	var _data : AbstractIterator
	var _selector: AbstractIterator
	
	func _init(data: AbstractIterator, selectors: AbstractIterator):
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
		

class CartesianProductIterator extends AbstractIterator:
	
	var _values: Array = []
	
	func _init(iterators):
		# build lists of all values by consuming all iterators
		_values.resize(iterators.size())
		for i in range(iterators.size()):
			_values[i] = []
			for value in iterators[i]:
				_values[i].append(value)

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
		
		
		
		
		
		
		
		
	
