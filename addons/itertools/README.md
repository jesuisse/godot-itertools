
# Iterator tools for GDScript

Godot Engine's GDScript has a custom iterator protocol. This allows you to iterate over any object
which implements this protocol using a simple for loop.

The *itertools* addon provides a single source file library of custom iterators inspired by
Python's itertools module. Most of the Python module's functionality is re-implemented in GDScript.

Requires Godot 4.5 or later.

## Getting started

### Installation

Download and install itertools in your addons folder (or anywhere else you like). Then make
it available to your scripts:
	
	# Adjust the path as needed
	const itertools = preload("res://addons/itertools/itertools.gd")
	
### Usage

	var my_array = ["I", "like", "bananas"]
	for word in itertools.array_rev(my_array):
		print(word)
	# prints bananas, like, I
	
	var lots_of_even_numbers = itertools.integer_range(0, 50000, 2)
	var sum = 0
	for number in lots_of_even_numbers:
		sum += number
	print(sum)
	
	var permutations = itertools.permutations(itertools.iter("ABC"))
	print(itertools.list(itertools.map(func (x): "".join(x), permutations))
	# prints ['ABC', 'ACB', 'BAC', 'BCA', 'CAB', 'CBA']

### Using itertools with your own iterators

All itertools iterators use the `itertools.Iterator` base class as a type for
iterator parameters. This will lead to type errors when you try to pass
your own object to an itertools function:
	
	var your_iterable = IterableObjectYouWroteYourself.new(...)
	for x in itertools.permutations(your_iterable):
		...
	
This won't work; `itertools.permutations` will complain about `your_iterable` 
having the wrong type.

There are two solutions to this problem:
	
  1. Make IterableObjectYouWroteYourself inherit from `itertools.Iterator`
  2. Wrap it in a call to `itertools.iter()`
	
Solution 2 is usually easier and looks like this:
	
	var your_iterable = IterableObjectYouWroteYourself.new(...)
	for x in itertools.permutations(itertools.iter(your_iterable)):
		...

Note that this specific example only works if your class implements 
the `terminates()` and `is_infinite()` methods, because `itertools.permutations`
will not risk an encounter with an infinite stream of elements which might be 
provided by your object - it needs these methods to ensure that it deals
with an iterator that terminates.

## Provided Iterators

The following iterators are implemented:
	
   `integer_range`: Provides iterator version of the builtin `range()` function. Providing
   and increment of 0 generates a warning.

   `integers`: Provides an infinite iterator version of the builtin `range()` 
   function (without the stop value). It is *your responsibility* to provide an exit
   strategy from the for loop which uses this iterator!
   
   `array_slice`: Iterates over a portion of an array (or the whole array).

   `array_rev`: Iterates over an array in reverse. Thin wrapper around array_slice 
   provided for convenience.

   `string_slice`: Iterates over a portion of a string (or the whole string). This 
   is just a thin wrapper around `array_slice` provided for convenience.

   `iter`: Takes any number of arguments and returns an interator which
   yields them in sequence. This is a convenience function to easily pack short
   sequences into an iterator. You can achieve the same thing with array_slice. If
   you only pass a single argument, iter tries to wrap it into a fitting iterator
   depending on the type of the argument. Currently only strings, arrays and 
   Vector2/Vector3 objects are supported, and all objects which support GDScript's
   iterator protocol. 
   
   Consider: `iter([22])` builds an iterator with the single element 22. `iter(22)` 
   is an error. `iter([])` builds an empty iterator. `iter()` is an error.
   
   `oneshot`: Makes the passed iterator into a 'oneshot'. It will only get 
   initialized once, upon object creation, and after all elements are consumed,
   it will stay exhausted. Use this if a) you need Python's iterator behaviour
   or b) if you want to manually take a number of elements from an iterator
   using the oneshot iterator's `take` method. No other iterator provides this
   method (because no other iterator object has access to its own state).

   `filter`: Filters values from another iterator based on a predicate function.

   `dropwhile`: Drops values from a given iterator while predicate function returns
	true and yields the rest of the values.
	
   `takewhile`: Yields values from a given iterator while predicate function returns
	true and drops the rest of the values.

   `compress`: Selects items from a data iterator based on the corresponding truth
   values of a selection iterator.
   
   `map`: Maps elements from a set of n iterators using a function of n arguments.
   
   `batched`: Returns the elements of an iterator batched into arrays of a given number of elements.
   If the last batch cannot be filled, a fill value will be used. So if you have an iterator 
   returning the sequence ABCDEF, batched with a size of 2 will return ['A', 'B'], ['C', 'D'], 
   ['E', 'F'].

   `zip`: Iterates over elements from an arbitrary number of iterators and returns them
   one of each in an array. If you have two sequences ABC and 123, you get ['A', 1], ['B', 2]
   and ['C', 3]. If the iterators don't contain the same amount of elements each, the
   shortest one exhausts the iterator, so with ABC and 12, you only get ['A', 1] and ['B', 2].

   `zip_longest`: Iterates over elements from an arbitrary number of iterators and returns them
   one of each in an array. If you have two sequences ABC and 123, you get ['A', 1], ['B', 2]
   and ['C', 3]. If the iterators don't contain the same amount of elements each, the
   longest one exhausts the iterator, so with ABC and 12, you get ['A', 1], ['B', 2] and ['A', null].
   You must specify the fill value to use as the first argument to zip_longest.

   `enumerate`: Convenience function to add an integer count to the front of the arrays zip 
   returns. The count starts at 0.

   `enumerate_from`: Convenience function to add an integer count to the front of the arrays zip
   returns. The count starts at the value you provide.

   `chain`: Chains an arbitrary number of iterators together and iterates over them in sequence
   
   `repeat`: Takes a constant value and repeats it a certain number of times, or indefinitely.
   In the latter case, it is *your responsibility* to provide an exit strategy from the for 
   loop which uses this iterator!
   
   `cycle`: Takes an iterator and repeats the elements it yields a certain number of times, or
	indefinitely if you want to (In that case, it is *your responsibility* to provide an exit 
	strategy from the for loop which uses this iterator!)
   
   `product`: Takes n iterators and produces all combinations of the values they yield. The
   product iterator returns the combinations as an array.

   Example: If you have iterators that produce the sequences ABC and 12, the cartesian 
   product is A1, A2, B1, B2, C1, C2 and you get an iterator which will yield ['A', 1], 
   ['A', 2], ['B', 1'] etc.
   
   Empty iterators produce null values in the arrays the iterator returns.

   `permutations`: Takes an iterator and produces all possible orderings of it's elements,
   without element repetitions.
   
   Given 1,2,3, returns [1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2] and [3,2,1].

   You can specifiy get smaller output sizes as well:
	
   Given 1,2,3, a size of 2 returns [1,2], [1,3], [2,1], [2,3], [3,1], [3,3]


## Non-iterator helper functions:

   `list`: Takes an iterator as an argument and returns an array of all the elements the
   iterator yields. Obviously, this only works for finite iterators. Don't use this with
   iterators which yield infinite streams of objects. 

   `reduce`: Takes a two-argument function and calls it with the first and second values
	of the iterator, then calls the function with the result and the next value successively
	until all the elements are processed.
   
## Terminating and infinite iterators
	
Some iterators return an infinite stream of elements, such as `integers`. Others may
not exhaust themselves depending on the arguments you pass at object construction. 
Examples would be `repeat()` and `cycle()` without a repeat count.

You can check whether an iterator is guaranteed to terminate by calling it's
`terminates()` method. If it returns true, it guarantees it will terminate
eventually. A false value is *not* a guarantee that it will produce an infinite
number of elements, however.

You can check whether an iterator is guaranteed to return an infinite stream
of elements with the `is_infinite()` method. A true return value guarantees an
infinite stream of elements. A false return value is *not* a guarantee that the
iterator will terminate.

Some iterators and functions, such as `list`, `product` and `permutations`, 
will log an error and produce incomplete results when you try to call them with 
non-terminating iterators. That's arguably better than the alternative, which 
would be for your application to hang in a quasi-infinite loop until your 
computer ran out of memory.

In case you are wondering why infinite iterators could possibly be useful:
Consider that the `enumerate` iterator can be constructed using `zip` and
`integers` like so:
	
	var very_long_array = [...]
	var enumerated = itertools.zip(itertools.integers(), 
								   itertools.array_slice(very_long_array))

	print(enumerated.terminates())
	# prints true!
	
## Important difference to Python's itertools

Python iterators do not get reinitialized when they are reused. Once a Python iterator is 
exhausted, it will stay exhausted. GDScript iterators are reinitialized in every for loop. This
means that the following behaves differently from what you'd expect in Python:
	
	var santa_says = itertools.repeat("ho", 3)
	var result1 = list(santa_says)
	var result2 = list(santa_says)
	
In Python `result1` would be `['ho', 'ho', 'ho']` and `result2` would be an empty list because the 
`santa_says` iterator was fully consumed by the first `list` call. GDscript's itertools
will yield `['ho', 'ho', 'ho']` for both `result1` and `result2` because each for loop in GDScript
re-initializes the iterator, and itertools respects GDScripts decision instead of trying to 
imitate Python's behaviour in this.

If you need Pythonic iterator behaviour, wrap iterators using the `oneshot` iterator, which only
gets initialized once upon object creation and will stay exhausted once all its elements are
consumed:
	
	var santa_says = itertools.oneshot(itertools.repeat("ho", 3))
	var result1 = list(santa_says)
	var result2 = list(santa_says)
	print(result2)
	# prints [], an empty list

(The deeper difference between GDScript's and Python's iterator behaviour is that GDScript 
iterator objects provide iterator behaviour, but generally do not have access to their iteration
state. This is why most itertools iterators cannot provide you with a take() method - they have no 
way to change the iterator's state, e.g. advance it after the take.)

## Unit testing

`itertools` comes with a number of unit tests for GUT. The third-party GUT addon is *not*
 included in this addon. You need to install it yourself if you want to run the tests.

The tests cover most of the public-facing itertools API and document how the various iterators can
be used, so they might be worth a look if you have trouble figuring out how to use the iterators.
