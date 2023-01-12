import Cp
import Svg hiding (dup)
import Nat
import Rose
import List
import Control.Concurrent
import Control.Monad

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
sierpinski = hyloRose gr2l gsq --rose2List . squares

--------------------ANSWERS--------------------

squares :: (Square, Int) -> Rose Square
squares = anaRose gsq

rose2List :: Rose a -> [a]
rose2List = cataRose gr2l


gsq :: (Square, Int) -> (Square, [(Square, Int)])
gsq = (split (middleSquare . p1) ((either nil ((uncurry zip) . (sideSquares >< repeat))) . distr)) . (id >< outNat)
--gsq (sq, 0) = (middleSquare sq, [])
--gsq (sq, n) = (middleSquare sq, map (\x -> (x, n - 1)) $ sideSquares sq)
--    lambda: split id (const (n - 1))

gr2l :: (a, [[a]]) -> [a]
gr2l = concat . cons . (singl >< id)

carpets :: Int -> [[Square]]
carpets = anaList gene
    where gene = (id -|- split (sierpinski . (split (const defaultSquare) id)) id) . outNat
--carpets n = map (sierpinski . (split (const defaultSquare) id)) [0..n-1]

present :: [[Square]] -> IO [()]
present = cataList gene
    where gene = either (return . nil) (myLift cons . ((>> await) . drawSq >< id))
--present = sequence . map ((>> await) . drawSq)


--------------------AUX FUNCTIONS--------------------

myLift :: Monad m => ((a, b) -> c) -> (m a, m b) -> m c
myLift f = uncurry (liftM2 (curry (f . swap))) . swap
--myLift f (a, b) = do {b' <- b;a' <- a;return (f (a', b'))}

middleSquare :: Square -> Square
middleSquare = (split ((uncurry addTup) . (id >< dup)) p2) . (id >< (/3))
--middleSquare (xy, l) = (addTup xy (dup l'), l')
--    where l' = l / 3

sideSquares :: Square -> [Square]
sideSquares (xy, l) = [(addTup xy $ scaleTup l' (x,y), l') | x <- [0..2], y <- [0..2], x * y /= 1]
    where l' = l / 3

addTup (a,b) (c,d) = (a + c, b + d)

scaleTup a (b,c) = (a * b, a * c)