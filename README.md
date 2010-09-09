russ forth
==========

A simple Forth interpreter in Ruby (1.9).

    1 2 dup + +
    .
    5
    
    3 2 1 + *
    .
    9

    : sq dup * ;
    
    2 sq
    .
    4

This is based on a sweet hack by [Russ Olsen](http://jroller.com/rolsen/) presented to me in a [GoodReads comment](http://www.goodreads.com/review/show/120660311).
