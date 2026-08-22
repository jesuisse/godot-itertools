## itertools.gd (c) 2026 by Pascal Schuppli
##
## This provides a selection of custom iterators inspired by Python's
## itertools module.
##
## Requires Godot >= 4.5 for variadic argument list support.


## Returns an iterator for the [param array] slice starting at 
## [param start] with size [param count]. If you do not specify
## count, all elements of the array will be iterated over starting
## at start.
static func array_slice(array: Array, start: int = 0, stop: int = -1) -> AbstractIterator:
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
static func integers(first: int, ...args) -> AbstractIterator:
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
	return RangeIterator.new(start, stop, increment)
	

## Returns an iterator which filters [param iterator] using the
## [param predicate] callable.
##
## ex: filter(range(5), func (x): x<2) will yield 0,1
static func filter(iterator: AbstractIterator, predicate: Callable) -> AbstractIterator:
	return FilterIterator.new(iterator, predicate)

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

## Repeats [param iterator] a specific ([param count]) number
## of times. If count is -1 or left out, this is equal to the
## behaviour of the cycle iterator.
static func repeat(iterator: AbstractIterator, count : int=-1) -> AbstractIterator:
	return RepeatIterator.new(iterator, count)

## This is an iterator which never exhausts; it simple starts
## from the beginning when it's iterator is exhausted.
static func cycle(iterator: AbstractIterator) -> AbstractIterator:
	return RepeatIterator.new(iterator)


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
		assert(increment != 0, "Iterator cannot proceed")
		assert(increment > 0 or stop <= start, "Iterator cannot reach stop value")
		assert(increment < 0 or stop >= start, "Iterator cannot reach stop value")
			
		_start = start
		_stop = stop
		_increment = increment
		
	func _should_continue(index):
		if _increment > 0:
			return index < _stop
		else:
			return index > _stop
	
	func _iter_init(state):
		state[0] = _start
		return _should_continue(state[0])
	
	func _iter_next(state):
		state[0] += _increment
		return _should_continue(state[0])
	
	func _iter_get(index):
		return index


## An iterator which will kick another iterator and only return
## values for which a given predicate function returns true
class FilterIterator extends AbstractIterator:
	
	var _predicate: Callable
	var _it
	
	func _init(iterator, predicate):
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


class RepeatIterator extends AbstractIterator:
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
