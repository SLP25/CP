import Cp
import Exp
import List
import Data.List
import NEList
import Cp2223data

--------------------GIVEN CODE--------------------

tax :: [String] -> Exp String String
tax = anaExp gene

tudo :: [String] -> [[String]]
tudo = post . tax

--------------------ANSWERS--------------------


gene :: [String] -> Either String (String, [[String]])
gene = ((id) -|- ( id >< ((groupBy (const canTrim)) . (map trim)))) . out
--gene = cond (null . tail) (i1 . head) (i2 . (split head ((splitWhen canTrim) . (map trim) . tail)))
{-
gene (x:[]) = Left x
gene (x:xs) = Right (x, (splitWhen canTrim) $ (map trim) xs)
-}

post :: Exp String String -> [[String]]
post = cataExp g

g = either (singl . singl) ((uncurry map) . ((:) >< concat))
{-
    where g (Left s) = [[s]]
          g (Right (s, l)) = map (s:) $ concat l
-}

--------------------AUX FUNCTIONS--------------------

trim :: String -> String
trim (' ':' ':' ':' ':r) = r

canTrim :: String -> Bool
canTrim (' ':' ':' ':' ':_) = True
canTrim _                   = False

{-splitWhen :: (a -> Bool) -> [a] -> [[a]]
splitWhen f = tail . (cataList g)
    where g = either (singl . nil) ((cond (f . p1) p2 (([]:) . p2)) . (split p1 (uncurry appendHead)))
          appendHead y (x:xs) = (y:x):xs

splitWhen f xs = tail $ splitWhenRec f xs
    where splitWhenRec _ []     = [[]]
          splitWhenRec f (x:xs) | f x = (x:h):t
                                | otherwise = []:(x:h):t
                                    where h:t = splitWhenRec f xs
-}