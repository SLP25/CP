import Cp
import Svg hiding (dup)
import Nat
import Rose
import Control.Concurrent

--------------------GIVEN CODE--------------------

drawSq x = picd'' [Svg.scale 0.44 (0, 0) (x >>= sq2svg)]
sq2svg (p, l) = (color "#67AB9F" . polyg) [p, p .+ (0, l), p .+ (l, l), p .+ (l, 0)]
await = threadDelay 1000000


type Square = (Point, Side)
type Side = Double
type Point = (Double, Double)

defaultSquare = ((0, 0), 32)
sierp4 = drawSq (sierpinski (defaultSquare, 3))
constructSierp5 = do
    drawSq (sierpinski (defaultSquare, 0))
    await
    drawSq (sierpinski (defaultSquare, 1))
    await
    drawSq (sierpinski (defaultSquare, 2))
    await
    drawSq (sierpinski (defaultSquare, 3))
    await
    drawSq (sierpinski (defaultSquare, 4))
    await

constructSierp :: Int -> IO [()]
constructSierp = present . carpets


sierpinski :: (Square, Int) -> [Square]
sierpinski = rose2List . squares --hyloRose gr2l gsq

--------------------ANSWERS--------------------

squares :: (Square, Int) -> Rose Square
squares = anaRose gr2l

rose2List :: Rose a -> [a]
rose2List = cataRose gsq


gr2l :: (Square, Int) -> (Square, [(Square, Int)])
gr2l = (split (middleSquare . p1) ((either nil ((uncurry zip) . (sideSquares >< repeat))) . distr)) . (id >< outNat)
--gr2l (sq, 0) = (middleSquare sq, [])
--gr2l (sq, n) = (middleSquare sq, map (\x -> (x, n - 1)) $ sideSquares sq)
--    lambda: split id (const (n - 1))

gsq :: (a, [[a]]) -> [a]
gsq = concat . cons . (singl >< id)

carpets :: Int -> [[Square]]
carpets n = map (sierpinski . (split (const defaultSquare) id)) [0..n]

present :: [[Square]] -> IO [()]
present = sequence . (map ((>> await) . drawSq))

--------------------AUX FUNCTIONS--------------------

middleSquare :: Square -> Square
middleSquare = (split ((uncurry addTup) . (id >< dup)) p2) . (id >< (/3))
--middleSquare (xy, l) = (addTup xy (dup l'), l')
--    where l' = l / 3

sideSquares :: Square -> [Square]
sideSquares (xy, l) = map (split ((addTup xy) . (scaleTup l')) (const l')) [(1,2),(2,2),(2,1),(2,0),(1,0),(0,0),(0,1),(0,2)]
    where l' = l / 3

addTup (a,b) (c,d) = (a + c, b + d)

scaleTup a (b,c) = (a * b, a * c)