assert(allequal([1.01, 2, 3], [1, 2.01, 3], 0.1), ...
       'Same vectors not equal')
assert(~allequal([2, 2, 3], [4, 2, 3], 0.1), ...
       'Dissimilar vectors compared as equal')

