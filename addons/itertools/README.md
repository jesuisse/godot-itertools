
# Iterator tools for GDScript

GDScript supports custom iterators. This allows you to iterate over any object
which implements the iterator protocol using a simple for loop.

This addon provides a single source file library of custom iterators inspired by
Python's itertools module. Most of the Python module's functionality is 
re-implemented in GDScript.

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
   Vector2/Vector3 objects are supported. 
   
   Consider: `iter([22])` builds an iterator with the single element 22. `iter(22)` 
   is an error. `iter([])` builds an empty iterator. `iter()` is an error.
   
   `filter`: Filters values from another iterator based on a predicate function.

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

## Non-iterator helper functions:

`itertools` also provides a few useful functions which *don't* return iterators:

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
`terminate()` method. If it returns true, it guarantees it will terminate
eventually. A false value is *not* a guarantee that it will produce an infinite
number of elements, however.

You can check whether an iterator is guaranteed to return an infinite stream
of elements with the `is_infinite()` method. A true return value guarantees an
infinite stream of elements. A false return value is *not* a guarantee that the
iterator will terminate.

Some iterators and functions, such as `list`, `product` and `permutations`, 
will either stop the program (in debug mode) or produce incomplete results
when you try to call them with non-terminating iterators.

In case you are wondering why infinite iterators could possibly be useful:
Consider that the `enumerate` iterator can be constructed using `zip` and
`integers` like so:
	
    var very_long_array = [...]
    var enumerated = itertools.zip(itertools.integers(), 
                                   itertools.array_slice(very_long_array))

    print(enumerated.terminates())
	# prints true!

## Usage

Download and install itertools in your addons folder (or anywhere else you like). Then make
it available to your scripts:
	
	# Adjust the path as needed
	const itertools = preload("res://addons/itertools/itertools.gd")

	var my_array = ["I", "like", "bananas"]
	for word in itertools.array_rev(my_array):
		print(word)
	# prints bananas, like, I
	
	var lots_of_even_numbers = itertools.integer_range(0, 50000, 2)
	var sum = 0
	for number in lots_of_even_numbers:
		sum += number
	print(sum)
	
	var permutations = itertools.map(func (x): "".join(x), itertools.permutations(itertools.iter("ABC")))
	print(itertools.list(permutations))
	# prints ['ABC', 'ACB', 'BAC', 'BCA', 'CAB', 'CBA']
	
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

However, this behaviour is not tested for all iterators yet, and while iterators based on 
`RangeIterator` and `ArraySliceIterator` behave as advertised, it is possible that you may encounter 
bugs if you use iterators such as `zip_longest` multiple times. Please open an issue if you 
encounter such a problem.

## Unit testing

`itertools` comes with a number of unit tests for GUT. However, the third-party GUT addon is not
 included in this addon. You need to install it yourself if you want to run the tests.

The tests document how the various iterators can be used, so they might be worth a look if you 
have trouble figuring out how to use the iterators.
