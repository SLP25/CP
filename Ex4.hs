import Cp
import List
import LTree
import RelCalc
import Probability

import NEList
import Data.List

--------------------GIVEN CODE--------------------

type Team = String
type Group = [Team]
type Match = (Team, Team)

--------data--------

groups :: [Group]
groups = [["Qatar", "Ecuador", "Senegal", "Netherlands"],
    ["England", "Iran", "USA", "Wales"],
    ["Argentina", "Saudi Arabia", "Mexico", "Poland"],
    ["France", "Denmark", "Tunisia", "Australia"],
    ["Spain", "Germany", "Japan", "Costa Rica"],
    ["Belgium", "Canada", "Morocco", "Croatia"],
    ["Brazil", "Serbia", "Switzerland", "Cameroon"],
    ["Portugal", "Ghana", "Uruguay", "Korea Republic"]]

rankings :: [(Team, Float)]
rankings = [
    ("Argentina", 4.8),
    ("Australia", 4.0),
    ("Belgium", 5.0),
    ("Brazil", 5.0),
    ("Cameroon", 4.0),
    ("Canada", 4.0),
    ("Costa Rica", 4.1),
    ("Croatia", 4.4),
    ("Denmark", 4.5),
    ("Ecuador", 4.0),
    ("England", 4.7),
    ("France", 4.8),
    ("Germany", 4.5),
    ("Ghana", 3.8),
    ("Iran", 4.2),
    ("Japan", 4.2),
    ("Korea Republic", 4.2),
    ("Mexico", 4.5),
    ("Morocco", 4.2),
    ("Netherlands", 4.6),
    ("Poland", 4.2),
    ("Portugal", 4.6),
    ("Qatar", 3.9),
    ("Saudi Arabia", 3.9),
    ("Senegal", 4.3),
    ("Serbia", 4.2),
    ("Spain", 4.7),
    ("Switzerland", 4.4),
    ("Tunisia", 4.1),
    ("USA", 4.4),
    ("Uruguay", 4.5),
    ("Wales", 4.3)]

--------general--------

consolidate :: (Eq a, Num b) => [(a, b)] -> [(a, b)]
consolidate = cataList cgene

mmbin :: Monad m => ((a, b) -> m c) -> (m a, m b) -> m c
mmbin f (a, b) = do {x <- a; y <- b; f (x, y)}

mbin :: Monad m => ((a, b) -> c) -> (m a, m b) -> m c
mbin = mmbin . (return.)

--is, defined in RelCalc

--collect, defined in RelCalc


arrangement :: [Group] -> [Team]
arrangement = (>>=swapTeams) . (chunksOf 4)
    where swapTeams [[a1, a2], [b1, b2], [c1, c2], [d1, d2]] = [a1, b2, c1, d2, b1, a2, d1, c2]

rank :: Team -> Float
rank x = 4 ** ((pap rankings x) - 3.8)

best :: Int -> [(Team, Int)] -> [Team]
best n = (map p1) . (take n) . reverse . (presort p2)


rcons :: ([a], a) -> [a]
rcons (x, a) = x ++ [a]


genGroupStageMatches :: [Group] -> [[Match]]
genGroupStageMatches = map generateMatches

generateMatches :: Group -> [Match]
generateMatches = pairup

--------Normal--------

gsCriteria :: Match -> Maybe Team
gsCriteria = s . (split (id >< id) (rank >< rank))
    where s ((s1, s2), (r1, r2)) = let d = r1 - r2 in
            if d > 0.5 then Just s1
                       else if d < -0.5 then Just s2
                                            else Nothing

koCriteria :: Match -> Team
koCriteria = s . (split (id >< id) (rank >< rank))
    where s ((s1, s2), (r1, r2)) = let d = r1 - r2 in
            if d == 0 then s1
                      else if d > 0 then s1
                                    else s2

simulateGroupStage :: [[Match]] -> [[Team]]
simulateGroupStage = map (groupWinners gsCriteria)
    where groupWinners criteria = (best 2) . consolidate . (>>= (matchResult criteria))
          groupWinners :: (Match -> Maybe Team) -> [Match] -> [Team]

initKnockoutStage :: [[Team]] -> LTree Team
initKnockoutStage = (anaLTree glt) . arrangement

groupStage :: [Group] -> LTree Team
groupStage = initKnockoutStage . simulateGroupStage . genGroupStageMatches


knockoutStage :: LTree Team -> Team
knockoutStage = cataLTree (either id koCriteria)


wcup :: [Group] -> Team
wcup = knockoutStage . groupStage

winner :: Team
winner = wcup groups

--------Probabilistic--------
pgsCriteria :: Match -> Dist (Maybe Team)
pgsCriteria = s . (split (id >< id) (rank >< rank))
    where s ((s1, s2), (r1, r2)) = if abs (r1 - r2) > 0.5 then fmap Just (pkoCriteria (s1, s2))
                                                          else f (s1, s2)
          f = D . ((Nothing, 0.5):) . (map (Just >< (/2))) . unD . pkoCriteria

pkoCriteria :: Match -> Dist Team
pkoCriteria (e1, e2) = D [(e1, 1 - r2 / (r1 + r2)), (e2, 1 - r1 / (r1 + r2))]
    where r1 = rank e1
          r2 = rank e2


psimulateGroupStage :: [[Match]] -> Dist [[Team]]
psimulateGroupStage = trim . (map (pgroupWinners pgsCriteria))
    where trim = (top 5) . sequence . (map (filterP . norm))
          trim :: [Dist Group] -> Dist [Group]
          filterP (D x) = D [(a, p) | (a, p) <- x, p > 0.0001]
          top n = vec2Dist . (take n) . reverse . (presort p2) . unD
          vec2Dist x = D [(a, n / t) | (a, n) <- x]
            where t = sum (map p2 x)

pgroupStage :: [Group] -> Dist (LTree Team)
pgroupStage = pinitKnockoutStage .! psimulateGroupStage . genGroupStageMatches

pknockoutStage :: LTree Team -> Dist Team
pknockoutStage = mcataLTree0 (either return pkoCriteria)
mcataLTree0 g = k
    where k (Leaf a)      = g1 a
          k (Fork (x, y)) = mmbin g2 (k x, k y)
          g1 = g . i1
          g2 = g . i2

pwcup :: [Group] -> Dist Team
pwcup = pknockoutStage .! pgroupStage

pwinner :: Dist Team
pwinner = mbin f x >>= pknockoutStage
    where f (x, y) = initKnockoutStage (x ++ y)
          x = split (g . take 4) (g . drop 4) groups
          g = psimulateGroupStage . genGroupStageMatches

--------------------ANSWERS--------------------

---Normal---

cgene::(Eq a, Num b) => Either () ((a,b),[(a,b)]) -> [(a,b)]
cgene = either (const [])  addPoints

pairup :: Eq b => [b] -> [(b, b)]
pairup = concat . ((uncurry (zipWith zip))) . (split repeat (tail . suffixes))

matchResult :: (Match -> Maybe Team) -> Match -> [(Team, Int)]
matchResult f = ((uncurry (++)) . (split (resultTeam p1)  (resultTeam p2)))
    where resultTeam pi = (singl . (matchResultTeam f) . (split id pi))


glt :: [Team] -> Either Team ([Team], [Team])
glt = (id -|- (splitInHalf . (uncurry (:)))) . out


---Probabilistic---

pinitKnockoutStage :: [[Team]] -> Dist (LTree Team)
pinitKnockoutStage = undefined


pgroupWinners :: (Match -> Dist (Maybe Team)) -> [Match] -> Dist [Team]
pgroupWinners = undefined   --usar pmatchResult aqui dentro

pmatchResult :: (Match -> Dist (Maybe Team)) -> Match -> Dist [(Team, Int)]
pmatchResult = undefined

--------------------AUX FUNCTIONS--------------------

toLTree :: [a] -> LTree a
toLTree [a] = Leaf a
toLTree (h:t) = Fork ((toLTree (take l (h:t))), (toLTree (drop l (h:t))))
    where l = length (h:t) `div` 2

addPoints :: (Eq a, Num b) => ((a,b), [(a,b)]) -> [(a,b)]
addPoints (p, []) = [p]
addPoints ((a1,b1), ((a2,b2):t)) | a1 == a2  = (a1, b1 + b2):t
                                 | otherwise = (a2,b2):(addPoints ((a1,b1), t))

splitInHalf :: [a] -> ([a], [a])
splitInHalf l = split (take half) (drop half) l
    where half = (length l) `div` 2

teamResult :: Maybe Team -> Team -> (Team, Int)
teamResult Nothing t = (t,1)
teamResult (Just t1) t2 | t1 == t2  = (t2, 3)
                        | otherwise = (t2, 0)

matchResultTeam :: (Match -> Maybe Team) -> (Match, Team) -> (Team, Int)
matchResultTeam f = (uncurry teamResult). (f >< id)