
# Iterator tools for GDScript

This is a small addon which provides a library of custom iterators inspired
by Python's itertools module.

The following iterators are implemented:
	
   `integers`: Provides iterator version of the builtin `range()` function.
   
   `array_slice`: Iterates over a portion of an array.
   
   `filter`: Filters another iterator based on a predicate function.
   
   `map`: Maps each element of an iterator onto another value using a callable.
   
   `zip`: Iterates over elements from an arbitrary number of iterators and returns them as an array
   
   `chain`: Chains an arbitrary number of iterators together and iterates over them in sequence
   
   `repeat`: Takes an iterator and repeats the elements it yields a specific number of times
   
   `cycle`: Takes an iterator and repeats the elements it yields indefinitely.
   
## Usage

Download and install itertools in your addons folder (or anywhere else you like). Then load
it into scripts as follows:
	
    # Adjust the path as needed
	const itertools = preload("res://addons/itertools/itertools.gd")

Then use them like so:
	
	var lots_of_even_numbers = itertools.integers(0, 50000, 2)
	var sum = 0
	for number in lots_of_even_numbers:
		sum += number
	print(sum)
	
	var no_multiples_of_five = itertools.filter(itertools.integers(100), func (x): return x % 5 != 0)
	for number 	in no_multiples_of_five:
		print(number)
		
