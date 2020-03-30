# tetris

An implementation of tetris in 386 assembly for Dosbox. The code illustrates a
few useful techniques in assembly programming.

## data representation

### tetromino

A tetromino is represented by a small 4x4 grid. Assuming a cell of the grid is
either empty or occupied, such a grid can be represented by a 16 bit word. The
following image shows the codes and their interpretation for the four rotations
of the L-tetromino:

This explains the `PAINTTETRO` procedure, which given an address to a grid
location and a 16 bit word draws the corresponding tetromino at the appropriate
location.

`PAINTTETRO` calls `PAINTCELL`, a procedure that draws a rectangle filled with
the appropriate color `@@COLOR` at the appropriate location `@@Y, @@X` in the
grid. Note that this procedure avoids multiplication by 256 using the following
identity:

```
x * 320 == x * (256 + 64) == x * 256 + x * 64 == x << 8 + x << 6
```

### board

The board is represented by a 25x16 grid. The number 25 was chosen to make the
grid cover the height of the screen for cells of 8x8 pixels. Not surprisingly,
each row is represented by a 16 bit word. Falling tetrominos are committed to
the board by setting the corresponding cells to 1.
