
# Iterator tools for GDScript

This is a small addon which provides a library of custom iterators inspired
by Python's itertools module.

## Custom Iterators

GDScript supports custom iterators. This allows you to use for loops to iterate 
over any object which implements the iterator protocol. This addon provides 
a set of useful custom iterators for you. 

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

   `compress`: Selects items from a data iterator bassed on the corresponding truth
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
   product iterator returns the combinations as an array.[br]
   Example: If you have iterators that produce the sequences ABC and 12, the cartesian 
   product is A1, A2, B1, B2, C1, C2 and you get an iterator which will yield ['A', 1], 
   ['A', 2], ['B', 1'] etc. [br]
   Empty iterators produce null values in the arrays the iterator returns.

## Non-iterator helper functions:

`itertools` also provides a few useful functions which *don't* return iterators:

   `list`: Takes an iterator as an argument and returns a list of all the elements the
   iterator yields. Obviously, this only works for finite iterators. Don't use this with
   iterators which yield infinite streams of objects.

   `reduce`: Takes a two-argument function and calls it with the first and second values
	of the iterator, then calls the function with the result and the next value successively
	until all the elements are processed.

## Usage

Download and install itertools in your addons folder (or anywhere else you like). Then load
it into scripts as follows:
	
	# Adjust the path as needed
	const itertools = preload("res://addons/itertools/itertools.gd")

Then use them like so:
	
	var lots_of_even_numbers = itertools.integer_range(0, 50000, 2)
	var sum = 0
	for number in lots_of_even_numbers:
		sum += number
	print(sum)
	
	var no_multiples_of_five = itertools.filter(func (x): return x % 5 != 0, itertools.integer_range(0, 100))
	for number in no_multiples_of_five:
		print(number)

## Unit testing

`itertools` comes with a number of unit tests for GUT. However, the third-party GUT addon is not
 included in this addon. You need to install it yourself if you want to run the tests.

The tests document how the various iterators can be used, so they might be worth a look if you 
have trouble figuring out how to use the iterators.
