module Problema1 where

import Cp
import Nat

k2 a b c (x, (y, z)) = a * z + b * y + c * x

f _ _ _ 0 = 0
f _ _ _ 1 = 1
f _ _ _ 2 = 1
f a b c n = a * (f a b c (n - 1)) + b * (f a b c (n - 2)) + c * (f a b c (n - 3))

f1 a b c = p1 . for (split (p1 . p2) (split (p2 . p2) (k2 a b c))) (0, (1,1))