EL-IXIR
=======

**El-Ixir** is a two-player same-computer game (although it is possible to
use a shared tmux for remote play).

It appears to have been invented by a company named Isoft in 1981, released
as a booter floppy for PC/XT.  Alas, no copy seems to be available anywhere
on the 'Net.  Two other remakes can be found on defunct-but-archived
webpages, although each of them has rules slightly different from the
original (or at least from how I remember the original).

Unlike those two, this remake (which I made somewhere around 1990) tries to
be exactly same as the original, in both gameplay and appearance — again, as
exact as a 12 years old kid remembered a game he last played at an age of
six.

What's missing is music and an alternate display mode that used CGA 40x25
text.  On the other hand, the game is playable on any modern Unix-like
system, with a vt100ish terminal whose character set includes glyphs of IBM
ROM BIOS (aka CP437), obviously using Unicode.

Rules
=====

The object of the game is to connect as much of blocks in your colour to the
corners.  The players take turns, being presented with four random tiles
each turn.

## Moving:
To make a move, choose one of the four tiles that were rolled for you. 
Next, choose a direction (up, left, right, down) and length (1-4).  If a
block of that length won't fit, it's silently cut to the longest length
there's space for.  (Hint: it's almost always beneficial to choose length
4).

## Anchoring:
If the block you placed causes some blocks to be connected to one of the
corners, you will be credited a point for every tile covered by a block in
your color that's connected to a corner by an unbroken line (via cardinal
directions only — diagonals are not enough).

## Embracing:
There are two types of embraces:

 * complete embrace, when your blocks either completely enclose a part of
   the board or wall it in into a border
 * anchored embraces, which trade the requirement of enclosing only parts of
   the board that contain no free tiles for allowing braces that are
   connected only diagonally

Whichever player gets the most points, wins.
