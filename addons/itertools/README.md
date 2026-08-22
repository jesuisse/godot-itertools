
# Iterator tools for GDScript

This is a small addon which provides a library of custom iterators inspired
by Python's itertools module.

## Custom Iterators

GDScript supports custom iterators. This allows you to iterate over any object which implements
the iterator protocol.

The following iterators are implemented:
	
   `integers`: Provides iterator version of the builtin `range()` function.
   
   `array_slice`: Iterates over a portion of an array (or the whole array)

   `string_slice`: Iterates over a portion of a string (or the whole string). This is 
   just a thin wrapper around `array_slice` provided for convenience.
   
   `filter`: Filters values from another iterator based on a predicate function.

   `compress`: Selects items from a data iterator bassed on the corresponding truth
   values of a selection iterator.
   
   `map`: Maps elements from a set of n iterators using a function of n arguments.
   
   `zip`: Iterates over elements from an arbitrary number of iterators and returns them as an array
   
   `chain`: Chains an arbitrary number of iterators together and iterates over them in sequence
   
   `repeat`: Takes an iterator and repeats the elements it yields a specific number of times
   
   `cycle`: Takes an iterator and repeats the elements it yields indefinitely. (It is *your 
   responsibility* to provide an exit strategy from the for loop which uses this iterator!)
   
   `product`: Takes n iterators and produces all combinations of the values they yield. So if
   you have iterators that produce the sequences ABC and 12, you get A1, A2, B1, B2, C1, C2.
   Empty iterators produce null values in the arrays the iterator returns.

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
		
